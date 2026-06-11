/**
 * Copy existing gallery images to OneDrive mirror folder.
 * Usage: node scripts/onedrive-mirror-export.mjs [mirrorPath]
 */
import { execFileSync } from 'node:child_process'
import { basename, join } from 'node:path'
import { copyFileSync, existsSync, mkdirSync } from 'node:fs'

const APP_DATA = join(process.env.APPDATA || '', 'com.nai-prompt-manager.desktop')
const DB_PATH = join(APP_DATA, 'nai_prompt_manager.db')
const DEFAULT_MIRROR_PATH = 'C:\\Users\\rt032\\OneDrive\\004-Novel AI'
const MIRROR_PATH = process.argv[2] || DEFAULT_MIRROR_PATH

function sqlJson(query) {
  const out = execFileSync('sqlite3', ['-json', DB_PATH, query], {
    encoding: 'utf8',
    maxBuffer: 512 * 1024 * 1024,
  }).trim()
  if (!out) return []
  return JSON.parse(out)
}

function sanitizeFilename(filename) {
  return (
    filename
      .replace(/[<>:"/\\|?*\x00-\x1f]/g, '_')
      .replace(/\s+/g, ' ')
      .trim()
      .slice(0, 180) || 'image.png'
  )
}

function splitFilename(filename) {
  const safe = sanitizeFilename(filename)
  const dot = safe.lastIndexOf('.')
  if (dot <= 0 || dot === safe.length - 1) return { base: safe, ext: '' }
  return { base: safe.slice(0, dot), ext: safe.slice(dot) }
}

function uniqueFilePath(directory, filename) {
  const { base, ext } = splitFilename(filename)
  let candidate = join(directory, `${base}${ext}`)
  let index = 1
  while (existsSync(candidate)) {
    candidate = join(directory, `${base} (${index})${ext}`)
    index++
  }
  return candidate
}

function resolveFilename(image) {
  if (image.filename?.trim()) return sanitizeFilename(image.filename)
  const base = basename(image.file_path || '')
  if (base) return sanitizeFilename(base)
  return `${image.id}.png`
}

function log(msg) {
  console.log(`[${new Date().toLocaleTimeString('ja-JP')}] ${msg}`)
}

function main() {
  if (!existsSync(DB_PATH)) {
    console.error(`DB not found: ${DB_PATH}`)
    process.exit(1)
  }

  if (!existsSync(MIRROR_PATH)) {
    mkdirSync(MIRROR_PATH, { recursive: true })
  }

  const images = sqlJson(
    `SELECT id, filename, file_path FROM images WHERE deleted_at IS NULL ORDER BY created_at DESC`
  )

  let copied = 0
  let skipped = 0
  let missing = 0
  let failed = 0

  log(`Mirror path: ${MIRROR_PATH}`)
  log(`Copying ${images.length} images...`)

  for (let i = 0; i < images.length; i++) {
    const image = images[i]
    const filename = resolveFilename(image)
    const { base, ext } = splitFilename(filename)
    const directPath = join(MIRROR_PATH, `${base}${ext}`)

    try {
      if (!image.file_path || !existsSync(image.file_path)) {
        missing++
        continue
      }
      if (existsSync(directPath)) {
        skipped++
        continue
      }
      copyFileSync(image.file_path, uniqueFilePath(MIRROR_PATH, filename))
      copied++
    } catch (err) {
      failed++
      console.error(`Failed ${filename}:`, err.message)
    }

    if ((i + 1) % 100 === 0 || i + 1 === images.length) {
      log(`Progress: ${i + 1}/${images.length} (copied ${copied}, skipped ${skipped}, missing ${missing}, failed ${failed})`)
    }
  }

  log('--- Done ---')
  log(`Copied: ${copied}`)
  log(`Skipped (already exists): ${skipped}`)
  log(`Missing source file: ${missing}`)
  log(`Failed: ${failed}`)
}

main()
