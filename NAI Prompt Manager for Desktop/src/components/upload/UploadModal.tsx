import { useState, useCallback, useRef } from 'react'
import { open } from '@tauri-apps/plugin-dialog'
import { readFile, copyFile, mkdir, exists, writeFile, open as fsOpen, stat as fsStat } from '@tauri-apps/plugin-fs'
import { appDataDir, join } from '@tauri-apps/api/path'
import { Unzip, UnzipInflate } from 'fflate'
import type { UnzipFile } from 'fflate'
import type { Tag } from '../../types'
import { useImageStore } from '../../stores/imageStore'
import { useAppStore } from '../../stores/appStore'
import { useTagStore } from '../../stores/tagStore'
import * as db from '../../lib/database'
import { extractPromptDataFromPNG, calculateFileHash } from '../../lib/png-metadata'
import { generateThumbnailBytes } from '../../lib/thumbnail'
import { autoTagImageFromPrompt } from '../../lib/danbooru-tags'
import { useI18n } from '../../lib/i18n'

interface UploadModalProps {
  isOpen: boolean
  onClose: () => void
}

// A plan is the user's selection: either a real image file path, or a ZIP file path.
// ZIP entries are NOT extracted into state; extraction happens lazily at upload time.
type ImportPlan =
  | { kind: 'image'; name: string; path: string }
  | { kind: 'zip'; name: string; path: string }

const IMAGE_EXTS = ['png', 'jpg', 'jpeg', 'webp', 'gif']
const PROGRESS_UPDATE_MS = 200
const PER_FILE_TIMEOUT_MS = 30000

// Stream-extract a ZIP file on disk, invoking `onEntry` for each matching image entry.
// Memory stays bounded: only the current entry's decompressed bytes + a small read buffer.
async function streamUnzipAndImport(
  zipPath: string,
  onEntry: (name: string, bytes: Uint8Array) => Promise<void>,
  isCancelled: () => boolean
): Promise<void> {
  const READ_CHUNK = 1024 * 1024 // 1MB

  const handle = await fsOpen(zipPath, { read: true })
  try {
    const info = await fsStat(zipPath)
    const totalSize = info.size

    // Queue of completed entries waiting to be processed
    type PendingEntry = { name: string; chunks: Uint8Array[]; error?: unknown; done: boolean }
    const inflight: Map<UnzipFile, PendingEntry> = new Map()
    const ready: PendingEntry[] = []

    const unzipper = new Unzip((file) => {
      if (!isImageName(file.name)) {
        // Not an image; still need to consume or skip it. Calling start() with no ondata drops data.
        return
      }
      const entry: PendingEntry = { name: file.name, chunks: [], done: false }
      inflight.set(file, entry)
      file.ondata = (err, data, final) => {
        if (err) {
          entry.error = err
          entry.done = true
          ready.push(entry)
          inflight.delete(file)
          return
        }
        if (data && data.length > 0) entry.chunks.push(data)
        if (final) {
          entry.done = true
          ready.push(entry)
          inflight.delete(file)
        }
      }
      file.start()
    })
    unzipper.register(UnzipInflate)

    const drainReady = async () => {
      while (ready.length > 0) {
        if (isCancelled()) return
        const entry = ready.shift()!
        if (entry.error) {
          console.error(`ZIP entry error ${entry.name}:`, entry.error)
          continue
        }
        const total = entry.chunks.reduce((s, c) => s + c.length, 0)
        const merged = new Uint8Array(total)
        let off = 0
        for (const c of entry.chunks) {
          merged.set(c, off)
          off += c.length
        }
        // Release chunk refs
        entry.chunks.length = 0
        const justName = entry.name.split('/').pop() || entry.name
        await onEntry(justName, merged)
      }
    }

    let bytesRead = 0
    while (bytesRead < totalSize) {
      if (isCancelled()) break
      const remaining = totalSize - bytesRead
      const bufSize = Math.min(READ_CHUNK, remaining)
      const buf = new Uint8Array(bufSize)
      const n = await handle.read(buf)
      if (!n) break
      const chunk = n === buf.length ? buf : buf.subarray(0, n)
      bytesRead += n
      const isLast = bytesRead >= totalSize
      unzipper.push(chunk, isLast)
      await drainReady()
    }
    await drainReady()
  } finally {
    try {
      await handle.close()
    } catch {
      /* ignore */
    }
  }
}

// Remove control chars and bare surrogates that can break IPC JSON serialization
function sanitizeForJson(s: string): string {
  let out = ''
  for (let i = 0; i < s.length; i++) {
    const code = s.charCodeAt(i)
    // Skip C0 controls (except \t \n \r), DEL, lone surrogates
    if (code < 0x20 && code !== 0x09 && code !== 0x0a && code !== 0x0d) continue
    if (code === 0x7f) continue
    // Lone high surrogate
    if (code >= 0xd800 && code <= 0xdbff) {
      const next = s.charCodeAt(i + 1)
      if (next < 0xdc00 || next > 0xdfff) continue
      out += s[i] + s[i + 1]
      i++
      continue
    }
    // Lone low surrogate
    if (code >= 0xdc00 && code <= 0xdfff) continue
    out += s[i]
  }
  return out
}

function extOf(name: string): string {
  return (name.split('.').pop() || '').toLowerCase()
}
function isImageName(name: string): boolean {
  return IMAGE_EXTS.includes(extOf(name))
}
function isZipName(name: string): boolean {
  return extOf(name) === 'zip'
}

function sanitizeFilename(filename: string): string {
  return filename
    .replace(/[<>:"/\\|?*\x00-\x1f]/g, '_')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 180) || 'image.png'
}

function splitFilename(filename: string): { base: string; ext: string } {
  const safe = sanitizeFilename(filename)
  const dot = safe.lastIndexOf('.')
  if (dot <= 0 || dot === safe.length - 1) return { base: safe, ext: '' }
  return { base: safe.slice(0, dot), ext: safe.slice(dot) }
}

async function uniqueFilePath(directory: string, filename: string): Promise<string> {
  const { base, ext } = splitFilename(filename)
  let candidate = await join(directory, `${base}${ext}`)
  let index = 1
  while (await exists(candidate)) {
    candidate = await join(directory, `${base} (${index})${ext}`)
    index++
  }
  return candidate
}

async function mirrorImportedImage(
  name: string,
  bytesOrPath: Uint8Array | { path: string },
  mirrorPath: string
): Promise<void> {
  if (!mirrorPath) return
  if (!(await exists(mirrorPath))) await mkdir(mirrorPath, { recursive: true })
  const destPath = await uniqueFilePath(mirrorPath, name)
  if (bytesOrPath instanceof Uint8Array) {
    await writeFile(destPath, bytesOrPath)
  } else {
    await copyFile(bytesOrPath.path, destPath)
  }
}

async function mirrorImportedImageToConfiguredPaths(
  name: string,
  bytesOrPath: Uint8Array | { path: string },
  mirrorSettings: {
    importMirrorEnabled: boolean
    importMirrorPath: string
    onedriveMirrorEnabled: boolean
    onedriveMirrorPath: string
  }
): Promise<void> {
  const targets: string[] = []
  if (mirrorSettings.importMirrorEnabled && mirrorSettings.importMirrorPath) {
    targets.push(mirrorSettings.importMirrorPath)
  }
  if (mirrorSettings.onedriveMirrorEnabled && mirrorSettings.onedriveMirrorPath) {
    targets.push(mirrorSettings.onedriveMirrorPath)
  }

  for (const mirrorPath of targets) {
    try {
      await mirrorImportedImage(name, bytesOrPath, mirrorPath)
    } catch (err) {
      console.error(`Failed to mirror imported image ${name} to ${mirrorPath}:`, err)
    }
  }
}


export default function UploadModal({ isOpen, onClose }: UploadModalProps) {
  const [plans, setPlans] = useState<ImportPlan[]>([])
  const [uploading, setUploading] = useState(false)
  const [completed, setCompleted] = useState(false)
  const [imported, setImported] = useState(0)
  const [failed, setFailed] = useState(0)
  const [skipped, setSkipped] = useState(0)
  const [currentFile, setCurrentFile] = useState<string | null>(null)
  const [status, setStatus] = useState<string | null>(null)
  const [dragActive, setDragActive] = useState(false)
  const cancelRef = useRef(false)
  const { addImages, loadImages } = useImageStore()
  const { loadTags } = useTagStore()
  const { filterOptions, settings } = useAppStore()
  const { t } = useI18n()

  const handleSelectFiles = async () => {
    try {
      const selected = await open({
        multiple: true,
        filters: [
          { name: 'Images & ZIP', extensions: [...IMAGE_EXTS, 'zip'] },
          { name: 'Images', extensions: IMAGE_EXTS },
          { name: 'ZIP archives', extensions: ['zip'] },
        ],
      })
      if (!selected) return
      const paths = Array.isArray(selected) ? selected : [selected]
      const newPlans: ImportPlan[] = []
      for (const p of paths) {
        const name = p.split(/[/\\]/).pop() || p
        if (isZipName(name)) newPlans.push({ kind: 'zip', name, path: p })
        else if (isImageName(name)) newPlans.push({ kind: 'image', name, path: p })
      }
      setPlans((prev) => [...prev, ...newPlans])
    } catch (err) {
      console.error('Failed to select files:', err)
    }
  }

  const removePlan = (index: number) => setPlans((prev) => prev.filter((_, i) => i !== index))
  const clearAll = () => setPlans([])

  const withTimeout = <T,>(p: Promise<T>, ms: number, label: string): Promise<T> =>
    new Promise<T>((resolve, reject) => {
      const t = setTimeout(() => reject(new Error(`Timeout: ${label}`)), ms)
      p.then((v) => { clearTimeout(t); resolve(v) }, (e) => { clearTimeout(t); reject(e) })
    })

  // Import a single image (bytes already in memory, or to be read from path).
  // Returns the new image+prompt records, or null if it was skipped as a
  // duplicate (same content hash already imported). Throws on real failures.
  const importOne = async (
    name: string,
    bytesOrPath: Uint8Array | { path: string },
    imagesDir: string,
    thumbnailsDir: string,
    seenHashes: Set<string>,
    maxEdge: number
  ) => {
    const bytes =
      bytesOrPath instanceof Uint8Array
        ? bytesOrPath
        : new Uint8Array(await readFile(bytesOrPath.path))

    const fileHash = await calculateFileHash(bytes)

    // Duplicate detection: skip if we've already imported this exact content,
    // either earlier in this same batch or in a previous session (DB).
    if (seenHashes.has(fileHash) || (await db.findImageByHash(fileHash))) {
      seenHashes.add(fileHash)
      return null
    }
    seenHashes.add(fileHash)

    const id = crypto.randomUUID()
    const ext = extOf(name) || 'png'
    const destPath = await join(imagesDir, `${id}.${ext}`)

    if (bytesOrPath instanceof Uint8Array) {
      await writeFile(destPath, bytes)
    } else {
      await copyFile(bytesOrPath.path, destPath)
    }

    await mirrorImportedImageToConfiguredPaths(name, bytesOrPath, settings)

    // Generate a downscaled WebP thumbnail so the gallery doesn't load full-size
    // images. Falls back to the full image (thumbnail_path = null) on failure.
    let thumbnailPath: string | null = null
    const thumbBytes = await generateThumbnailBytes(bytes, ext, maxEdge)
    if (thumbBytes) {
      const thumbDest = await join(thumbnailsDir, `${id}.webp`)
      await writeFile(thumbDest, thumbBytes)
      thumbnailPath = thumbDest
    }

    const promptData = ext === 'png' ? extractPromptDataFromPNG(bytes) : null

    const imageData = {
      folder_id: filterOptions.folderId === 'uncategorized' ? null : filterOptions.folderId,
      file_path: destPath,
      thumbnail_path: thumbnailPath,
      filename: name,
      width: promptData?.width || null,
      height: promptData?.height || null,
      file_size: bytes.length,
      file_hash: fileHash,
    }

    const promptEntry = promptData
      ? {
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
          // Strip control chars / NULL bytes that can break IPC JSON serialization
          raw_metadata: sanitizeForJson(JSON.stringify(promptData.rawMetadata)),
        }
      : null

    const image = await db.createImage(imageData, promptEntry)
    let tags: Tag[] = []
    if (settings.danbooruAutoTagEnabled && settings.danbooruDbPath && promptEntry?.positive_prompt) {
      try {
        const result = await autoTagImageFromPrompt(image.id, promptEntry, settings.danbooruDbPath, {
          allowedTagTypes: settings.danbooruAllowedTagTypes,
          maxTagsPerImage: settings.danbooruMaxTagsPerImage,
          minPopularity: settings.danbooruMinPopularity,
        })
        tags = result.tags
      } catch (err) {
        console.error(`Danbooru auto tagging failed for ${name}:`, err)
      }
    }

    return {
      image,
      prompt: promptEntry
        ? {
            id: crypto.randomUUID(),
            image_id: image.id,
            ...promptEntry,
            prompt_guidance_rescale: null,
            created_at: new Date().toISOString(),
          }
        : null,
      tags,
    }
  }

  const handleUpload = async () => {
    if (plans.length === 0) return
    cancelRef.current = false
    setUploading(true)
    setCompleted(false)
    setImported(0)
    setFailed(0)
    setSkipped(0)
    setStatus(null)

    // Resolve the storage root. Honor a user-configured folder if set, falling
    // back to the app data dir if it can't be created (e.g. permission/scope).
    const dataDir = await appDataDir()
    let baseDir = dataDir
    if (settings.imageStoragePath) {
      try {
        if (!(await exists(settings.imageStoragePath))) {
          await mkdir(settings.imageStoragePath, { recursive: true })
        }
        baseDir = settings.imageStoragePath
      } catch (err) {
        console.error('Custom storage path unusable, falling back to app data:', err)
        baseDir = dataDir
      }
    }
    const imagesDir = await join(baseDir, 'images')
    const thumbnailsDir = await join(baseDir, 'thumbnails')
    if (!(await exists(imagesDir))) await mkdir(imagesDir, { recursive: true })
    if (!(await exists(thumbnailsDir))) await mkdir(thumbnailsDir, { recursive: true })

    const maxEdge = settings.thumbnailSize || 400
    const seenHashes = new Set<string>()

    let doneCount = 0
    let failCount = 0
    let skipCount = 0
    const batch: { image: any; prompt: any }[] = []
    let lastFlush = performance.now()

    const flush = (force = false) => {
      const now = performance.now()
      if (!force && now - lastFlush < PROGRESS_UPDATE_MS) return
      lastFlush = now
      setImported(doneCount)
      setFailed(failCount)
      setSkipped(skipCount)
      if (batch.length > 0) addImages(batch.splice(0, batch.length))
    }

    const importBytesEntry = async (name: string, bytes: Uint8Array) => {
      if (cancelRef.current) return
      setCurrentFile(name)
      try {
        const result = await withTimeout(importOne(name, bytes, imagesDir, thumbnailsDir, seenHashes, maxEdge), PER_FILE_TIMEOUT_MS, name)
        if (result) {
          batch.push(result)
          doneCount++
        } else {
          skipCount++
        }
      } catch (err) {
        failCount++
        console.error(`Failed to import ${name}:`, err)
      } finally {
        flush(false)
        // Yield to UI
        await new Promise((r) => setTimeout(r, 0))
      }
    }

    try {
      for (const plan of plans) {
        if (cancelRef.current) break

        if (plan.kind === 'image') {
          if (cancelRef.current) break
          setCurrentFile(plan.name)
          try {
            const result = await withTimeout(
              importOne(plan.name, { path: plan.path }, imagesDir, thumbnailsDir, seenHashes, maxEdge),
              PER_FILE_TIMEOUT_MS,
              plan.name
            )
            if (result) {
              batch.push(result)
              doneCount++
            } else {
              skipCount++
            }
          } catch (err) {
            failCount++
            console.error(`Failed to import ${plan.name}:`, err)
          }
          flush(false)
          await new Promise((r) => setTimeout(r, 0))
        } else {
          // ZIP — stream-decompress one entry at a time to keep memory bounded.
          setStatus(t('zipProcessing', { name: plan.name }))
          try {
            await streamUnzipAndImport(
              plan.path,
              async (entryName, bytes) => {
                await importBytesEntry(entryName, bytes)
              },
              () => cancelRef.current
            )
          } catch (err) {
            failCount++
            console.error(`Failed to read ZIP ${plan.name}:`, err)
          }
          setStatus(null)
        }
      }

      flush(true)
      // Fire-and-forget; if loadImages hangs (known IPC issue), don't block UI
      loadImages().catch((err) => console.error('loadImages failed:', err))
      loadTags().catch((err) => console.error('loadTags failed:', err))
    } catch (err) {
      console.error('Upload failed:', err)
    } finally {
      setUploading(false)
      setCompleted(true)
      setCurrentFile(null)
      setStatus(null)
      // Do NOT auto-close; let user see the result and close manually.
    }
  }

  const handleCancel = () => {
    cancelRef.current = true
    setUploading(false)
    setCompleted(false)
    setPlans([])
    setCurrentFile(null)
    setStatus(null)
    setImported(0)
    setFailed(0)
    setSkipped(0)
    loadImages().catch(() => {})
    onClose()
  }

  const handleDrag = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    if (e.type === 'dragenter' || e.type === 'dragover') setDragActive(true)
    else if (e.type === 'dragleave') setDragActive(false)
  }, [])

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setDragActive(false)
  }, [])

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-nai-bg0/95" onClick={handleCancel} />

      <div className="relative bg-nai-bg1 rounded-xl p-6 w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto border border-nai-border animate-slide-up">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-nai-text">{t('uploadTitle')}</h2>
          <button onClick={handleCancel} className="p-2 hover:bg-nai-bg2 rounded-lg transition-colors">
            <svg className="w-5 h-5 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div
          onDragEnter={handleDrag}
          onDragLeave={handleDrag}
          onDragOver={handleDrag}
          onDrop={handleDrop}
          className={`border-2 border-dashed rounded-xl p-8 text-center transition-colors cursor-pointer ${
            dragActive ? 'border-nai-accent bg-nai-accent/10' : 'border-nai-border hover:border-nai-text-muted'
          }`}
          onClick={handleSelectFiles}
        >
          <div className="w-16 h-16 bg-nai-bg2 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
            </svg>
          </div>
          <p className="text-nai-text font-medium mb-1">{t('clickToSelectFiles')}</p>
          <p className="text-nai-text-muted text-sm">
            {t('uploadHelp')}
          </p>
        </div>

        {plans.length > 0 && (
          <div className="mt-6">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-medium text-nai-text-muted">{t('importTargets', { count: plans.length })}</h3>
              <button onClick={clearAll} disabled={uploading} className="text-xs text-nai-text-muted hover:text-nai-text disabled:opacity-50">
                {t('clearAll')}
              </button>
            </div>
            <div className="space-y-1 max-h-48 overflow-y-auto scrollbar-thin">
              {plans.slice(0, 200).map((plan, index) => (
                <div key={index} className="flex items-center justify-between bg-nai-bg2 rounded-lg px-3 py-2">
                  <div className="flex items-center gap-2 min-w-0">
                    <span className={`text-[10px] font-mono px-1.5 py-0.5 rounded ${
                      plan.kind === 'zip' ? 'bg-nai-accent/20 text-nai-accent' : 'bg-nai-bg3 text-nai-text-muted'
                    }`}>
                      {plan.kind === 'zip' ? 'ZIP' : 'IMG'}
                    </span>
                    <span className="text-nai-text text-xs truncate">{plan.name}</span>
                  </div>
                  {!uploading && (
                    <button onClick={() => removePlan(index)} className="p-1 hover:bg-nai-bg3 rounded transition-colors shrink-0">
                      <svg className="w-3 h-3 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  )}
                </div>
              ))}
              {plans.length > 200 && (
                <p className="text-xs text-nai-text-muted text-center py-1">...{plans.length - 200}</p>
              )}
            </div>
          </div>
        )}

        {uploading && (
          <div className="mt-6">
            <div className="flex items-center justify-between text-sm mb-2">
              <span className="text-nai-text-muted truncate">
                {status || (currentFile ? t('processingFile', { name: currentFile }) : t('processing'))}
              </span>
              <span className="text-nai-text">
                {t('imported')} {imported}
                {skipped > 0 && <span className="text-yellow-400 ml-2">{t('duplicate')} {skipped}</span>}
                {failed > 0 && <span className="text-red-400 ml-2">{t('failed')} {failed}</span>}
              </span>
            </div>
            <div className="h-1 bg-nai-bg2 rounded-full overflow-hidden">
              <div className="h-full bg-nai-accent animate-pulse" style={{ width: '100%' }} />
            </div>
          </div>
        )}

        {completed && !uploading && (
          <div className="mt-6 p-4 bg-nai-bg2 rounded-lg">
            <div className="flex items-center gap-3">
              <svg className="w-6 h-6 text-green-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <div className="flex-1">
                <p className="text-nai-text font-medium">
                  {t('importDone', { count: imported })}
                </p>
                {skipped > 0 && (
                  <p className="text-yellow-400 text-sm">{t('skippedDuplicate', { count: skipped })}</p>
                )}
                {failed > 0 && (
                  <p className="text-red-400 text-sm">{t('failedWithConsole', { count: failed })}</p>
                )}
              </div>
            </div>
          </div>
        )}

        <div className="flex items-center justify-end gap-3 mt-6">
          <button onClick={handleCancel} className="px-4 py-2 text-nai-text-muted hover:text-nai-text transition-colors">
            {uploading ? t('stop') : completed ? t('close') : t('cancel')}
          </button>
          {!completed && (
            <button
              onClick={handleUpload}
              disabled={plans.length === 0 || uploading}
              className="px-6 py-2 bg-nai-accent hover:bg-nai-accent-hover disabled:bg-nai-accent/50 text-nai-bg0 font-medium rounded-lg transition-colors"
            >
              {uploading ? t('processing') : t('importButton', { count: plans.length })}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
