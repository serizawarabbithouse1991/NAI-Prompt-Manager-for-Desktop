import { join } from '@tauri-apps/api/path'
import { copyFile, exists, mkdir } from '@tauri-apps/plugin-fs'
import * as db from './database'

export interface MirrorProgress {
  current: number
  total: number
  message: string
}

export interface MirrorResult {
  copied: number
  skipped: number
  missing: number
  failed: number
  errors: string[]
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

function resolveMirrorFilename(filename: string | null, filePath: string, imageId: string): string {
  if (filename?.trim()) return sanitizeFilename(filename)
  const base = filePath.split(/[/\\]/).pop()
  if (base) return sanitizeFilename(base)
  return `${imageId}.png`
}

export async function mirrorFileToFolder(
  sourcePath: string,
  mirrorPath: string,
  filename: string,
  skipExisting = true
): Promise<'copied' | 'skipped' | 'missing'> {
  if (!mirrorPath) return 'missing'
  if (!(await exists(sourcePath))) return 'missing'

  if (!(await exists(mirrorPath))) {
    await mkdir(mirrorPath, { recursive: true })
  }

  const destPath = await uniqueFilePath(mirrorPath, filename)
  const { base, ext } = splitFilename(filename)
  const directPath = await join(mirrorPath, `${base}${ext}`)

  if (skipExisting && (await exists(directPath))) {
    return 'skipped'
  }

  await copyFile(sourcePath, destPath)
  return 'copied'
}

export async function bulkMirrorExistingImages(
  mirrorPath: string,
  onProgress?: (progress: MirrorProgress) => void,
  options: { skipExisting?: boolean } = {}
): Promise<MirrorResult> {
  const skipExisting = options.skipExisting ?? true
  const result: MirrorResult = {
    copied: 0,
    skipped: 0,
    missing: 0,
    failed: 0,
    errors: [],
  }

  const images = await db.getAllImages()
  const total = images.length

  onProgress?.({ current: 0, total, message: '既存画像のコピーを準備中...' })

  for (let i = 0; i < images.length; i++) {
    const image = images[i]
    const filename = resolveMirrorFilename(image.filename, image.file_path, image.id)

    try {
      const status = await mirrorFileToFolder(
        image.file_path,
        mirrorPath,
        filename,
        skipExisting
      )
      if (status === 'copied') result.copied++
      else if (status === 'skipped') result.skipped++
      else result.missing++
    } catch (err) {
      result.failed++
      result.errors.push(
        `${filename}: ${err instanceof Error ? err.message : String(err)}`
      )
    }

    if ((i + 1) % 50 === 0 || i + 1 === total) {
      onProgress?.({
        current: i + 1,
        total,
        message: `コピー中... ${i + 1}/${total}（新規 ${result.copied} / スキップ ${result.skipped}）`,
      })
      await new Promise((r) => setTimeout(r, 0))
    }
  }

  return result
}
