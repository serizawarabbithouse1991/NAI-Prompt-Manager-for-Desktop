import { useState, useCallback } from 'react'
import { open } from '@tauri-apps/plugin-dialog'
import { readFile, copyFile, mkdir, exists } from '@tauri-apps/plugin-fs'
import { appDataDir, join } from '@tauri-apps/api/path'
import { useImageStore } from '../../stores/imageStore'
import { useAppStore } from '../../stores/appStore'
import * as db from '../../lib/database'
import { extractPromptDataFromPNG, calculateFileHash } from '../../lib/png-metadata'
import { isImageFile } from '../../lib/utils'

interface UploadModalProps {
  isOpen: boolean
  onClose: () => void
}

interface PendingFile {
  path: string
  name: string
  size: number
}

export default function UploadModal({ isOpen, onClose }: UploadModalProps) {
  const [files, setFiles] = useState<PendingFile[]>([])
  const [uploading, setUploading] = useState(false)
  const [progress, setProgress] = useState(0)
  const [currentFile, setCurrentFile] = useState<string | null>(null)
  const [dragActive, setDragActive] = useState(false)
  const { addImage, loadImages } = useImageStore()
  const { filterOptions } = useAppStore()

  const handleSelectFiles = async () => {
    try {
      const selected = await open({
        multiple: true,
        filters: [
          {
            name: 'Images',
            extensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
          },
        ],
      })

      if (selected) {
        const paths = Array.isArray(selected) ? selected : [selected]
        const newFiles: PendingFile[] = []

        for (const path of paths) {
          if (isImageFile(path)) {
            // Get file info
            const name = path.split(/[/\\]/).pop() || path
            // Note: We'll get actual size when processing
            newFiles.push({ path, name, size: 0 })
          }
        }

        setFiles((prev) => [...prev, ...newFiles])
      }
    } catch (err) {
      console.error('Failed to select files:', err)
    }
  }

  const removeFile = (index: number) => {
    setFiles((prev) => prev.filter((_, i) => i !== index))
  }

  const handleUpload = async () => {
    if (files.length === 0) return

    setUploading(true)
    setProgress(0)

    try {
      // Get app data directory for storing images
      const dataDir = await appDataDir()
      const imagesDir = await join(dataDir, 'images')
      const thumbnailsDir = await join(dataDir, 'thumbnails')

      // Create directories if they don't exist
      if (!(await exists(imagesDir))) {
        await mkdir(imagesDir, { recursive: true })
      }
      if (!(await exists(thumbnailsDir))) {
        await mkdir(thumbnailsDir, { recursive: true })
      }

      for (let i = 0; i < files.length; i++) {
        const file = files[i]
        setCurrentFile(file.name)

        try {
          // Read file
          const buffer = await readFile(file.path)
          const uint8Array = new Uint8Array(buffer)

          // Calculate hash for duplicate detection
          const fileHash = await calculateFileHash(uint8Array)

          // Generate unique filename
          const id = crypto.randomUUID()
          const ext = file.name.split('.').pop() || 'png'
          const destFilename = `${id}.${ext}`
          const destPath = await join(imagesDir, destFilename)

          // Copy file to app data directory
          await copyFile(file.path, destPath)

          // Extract PNG metadata
          let promptData = null
          if (ext.toLowerCase() === 'png') {
            promptData = extractPromptDataFromPNG(uint8Array)
          }

          // Get image dimensions (we'll need to implement this properly)
          // For now, use metadata if available
          const width = promptData?.width || null
          const height = promptData?.height || null

          // Create database entry
          const imageData = {
            folder_id: filterOptions.folderId === 'uncategorized' ? null : filterOptions.folderId,
            file_path: destPath,
            thumbnail_path: null, // TODO: Generate thumbnail
            filename: file.name,
            width,
            height,
            file_size: uint8Array.length,
            file_hash: fileHash,
          }

          const promptEntry = promptData ? {
            positive_prompt: promptData.positivePrompt,
            negative_prompt: promptData.negativePrompt,
            model: promptData.model,
            sampler: promptData.sampler,
            steps: promptData.steps,
            cfg_scale: promptData.cfgScale,
            seed: promptData.seed,
            resolution_width: promptData.width,
            resolution_height: promptData.height,
            noise_schedule: promptData.noiseSchedule,
            prompt_guidance_rescale: null,
            notes: null,
            raw_metadata: JSON.stringify(promptData.rawMetadata),
          } : null

          const image = await db.createImage(imageData, promptEntry)

          // Add to store
          addImage(image, promptEntry ? {
            id: crypto.randomUUID(),
            image_id: image.id,
            ...promptEntry,
            prompt_guidance_rescale: null,
            created_at: new Date().toISOString(),
          } : null)

        } catch (err) {
          console.error(`Failed to upload ${file.name}:`, err)
        }

        setProgress(((i + 1) / files.length) * 100)
      }

      // Reload images to ensure consistency
      await loadImages()

    } catch (err) {
      console.error('Upload failed:', err)
    } finally {
      setUploading(false)
      setFiles([])
      setCurrentFile(null)
      onClose()
    }
  }

  const handleDrag = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true)
    } else if (e.type === 'dragleave') {
      setDragActive(false)
    }
  }, [])

  const handleDrop = useCallback(async (e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setDragActive(false)

    // Note: In Tauri, drag-drop gives us file paths directly
    // But we need to handle this through Tauri's API
    // For now, direct the user to use the file picker
  }, [])

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-nai-bg0/95" onClick={onClose} />

      {/* Modal */}
      <div className="relative bg-nai-bg1 rounded-xl p-6 w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto border border-nai-border animate-slide-up">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-nai-text">画像をアップロード</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-nai-bg2 rounded-lg transition-colors"
          >
            <svg className="w-5 h-5 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Drop Zone */}
        <div
          onDragEnter={handleDrag}
          onDragLeave={handleDrag}
          onDragOver={handleDrag}
          onDrop={handleDrop}
          className={`border-2 border-dashed rounded-xl p-8 text-center transition-colors cursor-pointer ${
            dragActive
              ? 'border-nai-accent bg-nai-accent/10'
              : 'border-nai-border hover:border-nai-text-muted'
          }`}
          onClick={handleSelectFiles}
        >
          <div className="w-16 h-16 bg-nai-bg2 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
            </svg>
          </div>
          <p className="text-nai-text font-medium mb-1">
            クリックしてファイルを選択
          </p>
          <p className="text-nai-text-muted text-sm">
            PNG, JPG, WEBP (複数選択可)
          </p>
        </div>

        {/* Selected Files */}
        {files.length > 0 && (
          <div className="mt-6">
            <h3 className="text-sm font-medium text-nai-text-muted mb-3">
              選択されたファイル ({files.length})
            </h3>
            <div className="space-y-2 max-h-48 overflow-y-auto scrollbar-thin">
              {files.map((file, index) => (
                <div
                  key={index}
                  className="flex items-center justify-between bg-nai-bg2 rounded-lg px-4 py-3"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <svg className="w-5 h-5 text-nai-text-muted shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    <span className="text-nai-text text-sm truncate">{file.name}</span>
                  </div>
                  <button
                    onClick={() => removeFile(index)}
                    className="p-1 hover:bg-nai-bg3 rounded transition-colors shrink-0"
                  >
                    <svg className="w-4 h-4 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Progress Bar */}
        {uploading && (
          <div className="mt-6">
            <div className="flex items-center justify-between text-sm mb-2">
              <span className="text-nai-text-muted truncate">
                {currentFile ? `処理中: ${currentFile}` : 'アップロード中...'}
              </span>
              <span className="text-nai-text">{Math.round(progress)}%</span>
            </div>
            <div className="h-2 bg-nai-bg2 rounded-full overflow-hidden">
              <div
                className="h-full bg-nai-accent transition-all duration-300"
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        )}

        {/* Actions */}
        <div className="flex items-center justify-end gap-3 mt-6">
          <button
            onClick={onClose}
            disabled={uploading}
            className="px-4 py-2 text-nai-text-muted hover:text-nai-text transition-colors disabled:opacity-50"
          >
            キャンセル
          </button>
          <button
            onClick={handleUpload}
            disabled={files.length === 0 || uploading}
            className="px-6 py-2 bg-nai-accent hover:bg-nai-accent-hover disabled:bg-nai-accent/50 text-nai-bg0 font-medium rounded-lg transition-colors"
          >
            {uploading ? 'アップロード中...' : `アップロード (${files.length})`}
          </button>
        </div>
      </div>
    </div>
  )
}
