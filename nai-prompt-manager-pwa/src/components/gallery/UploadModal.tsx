import { useState, useCallback } from 'react'
import { useImageStore } from '../../stores/imageStore'
import { useFolderStore } from '../../stores/folderStore'

interface UploadModalProps {
  onClose: () => void
  onUploadComplete: () => void
}

export function UploadModal({ onClose, onUploadComplete }: UploadModalProps) {
  const [files, setFiles] = useState<File[]>([])
  const [selectedFolderId, setSelectedFolderId] = useState<string | null>(null)
  const [uploading, setUploading] = useState(false)
  const [progress, setProgress] = useState({ current: 0, total: 0 })
  const [errors, setErrors] = useState<string[]>([])
  const [isDragging, setIsDragging] = useState(false)

  const { uploadImage } = useImageStore()
  const { folders } = useFolderStore()

  const handleFileSelect = useCallback((selectedFiles: FileList | null) => {
    if (!selectedFiles) return
    
    const imageFiles = Array.from(selectedFiles).filter(
      file => file.type.startsWith('image/')
    )
    
    setFiles(prev => [...prev, ...imageFiles])
  }, [])

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
    handleFileSelect(e.dataTransfer.files)
  }, [handleFileSelect])

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(true)
  }, [])

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
  }, [])

  const removeFile = (index: number) => {
    setFiles(prev => prev.filter((_, i) => i !== index))
  }

  const handleUpload = async () => {
    if (files.length === 0) return

    setUploading(true)
    setProgress({ current: 0, total: files.length })
    setErrors([])

    const uploadErrors: string[] = []

    for (let i = 0; i < files.length; i++) {
      const file = files[i]
      try {
        await uploadImage(file, selectedFolderId)
        setProgress({ current: i + 1, total: files.length })
      } catch (error) {
        console.error(`Failed to upload ${file.name}:`, error)
        uploadErrors.push(`${file.name}: アップロード失敗`)
      }
    }

    setUploading(false)
    setErrors(uploadErrors)

    if (uploadErrors.length === 0) {
      onUploadComplete()
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80" onClick={onClose}>
      <div 
        className="w-full max-w-lg bg-dark-800 rounded-xl overflow-hidden"
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-dark-700">
          <h2 className="text-lg font-semibold text-white">画像をアップロード</h2>
          <button
            onClick={onClose}
            className="p-2 text-dark-400 hover:text-white transition-colors"
          >
            <CloseIcon className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-4 space-y-4">
          {/* Drop zone */}
          <div
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            className={`
              border-2 border-dashed rounded-lg p-8 text-center transition-colors
              ${isDragging
                ? 'border-primary-500 bg-primary-500/10'
                : 'border-dark-600 hover:border-dark-500'
              }
            `}
          >
            <UploadIcon className="w-12 h-12 mx-auto mb-4 text-dark-400" />
            <p className="text-dark-300 mb-2">
              ドラッグ＆ドロップ または
            </p>
            <label className="inline-block">
              <span className="px-4 py-2 bg-primary-600 hover:bg-primary-500 text-white rounded-lg cursor-pointer transition-colors">
                ファイルを選択
              </span>
              <input
                type="file"
                accept="image/*"
                multiple
                onChange={(e) => handleFileSelect(e.target.files)}
                className="hidden"
              />
            </label>
            <p className="text-xs text-dark-500 mt-2">
              PNG, JPEG, GIF, WebP対応
            </p>
          </div>

          {/* Folder selection */}
          <div>
            <label className="block text-sm text-dark-400 mb-2">保存先フォルダ</label>
            <select
              value={selectedFolderId || ''}
              onChange={(e) => setSelectedFolderId(e.target.value || null)}
              className="w-full px-3 py-2 bg-dark-700 border border-dark-600 rounded-lg text-white focus:outline-none focus:border-primary-500"
            >
              <option value="">未分類</option>
              {folders.map(folder => (
                <option key={folder.id} value={folder.id}>
                  {folder.name}
                </option>
              ))}
            </select>
          </div>

          {/* File list */}
          {files.length > 0 && (
            <div className="max-h-48 overflow-auto">
              <label className="block text-sm text-dark-400 mb-2">
                選択したファイル ({files.length}件)
              </label>
              <div className="space-y-2">
                {files.map((file, index) => (
                  <div
                    key={`${file.name}-${index}`}
                    className="flex items-center justify-between p-2 bg-dark-700 rounded"
                  >
                    <div className="flex items-center gap-2 min-w-0">
                      <ImageIcon className="w-5 h-5 text-dark-400 flex-shrink-0" />
                      <span className="text-sm text-white truncate">{file.name}</span>
                    </div>
                    <button
                      onClick={() => removeFile(index)}
                      className="p-1 text-dark-400 hover:text-red-400 flex-shrink-0"
                    >
                      <CloseIcon className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Progress */}
          {uploading && (
            <div>
              <div className="flex justify-between text-sm text-dark-400 mb-1">
                <span>アップロード中...</span>
                <span>{progress.current} / {progress.total}</span>
              </div>
              <div className="h-2 bg-dark-700 rounded-full overflow-hidden">
                <div
                  className="h-full bg-primary-500 transition-all duration-300"
                  style={{ width: `${(progress.current / progress.total) * 100}%` }}
                />
              </div>
            </div>
          )}

          {/* Errors */}
          {errors.length > 0 && (
            <div className="p-3 bg-red-500/20 border border-red-500/50 rounded-lg">
              <p className="text-sm text-red-400 font-medium mb-1">
                一部のファイルでエラーが発生しました
              </p>
              <ul className="text-xs text-red-300 space-y-1">
                {errors.map((error, i) => (
                  <li key={i}>{error}</li>
                ))}
              </ul>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-2 p-4 border-t border-dark-700">
          <button
            onClick={onClose}
            className="px-4 py-2 text-dark-300 hover:text-white transition-colors"
          >
            キャンセル
          </button>
          <button
            onClick={handleUpload}
            disabled={files.length === 0 || uploading}
            className="px-4 py-2 bg-primary-600 hover:bg-primary-500 disabled:bg-primary-800 disabled:cursor-not-allowed text-white rounded-lg transition-colors"
          >
            {uploading ? 'アップロード中...' : `アップロード (${files.length}件)`}
          </button>
        </div>
      </div>
    </div>
  )
}

function CloseIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
    </svg>
  )
}

function UploadIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
    </svg>
  )
}

function ImageIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
    </svg>
  )
}
