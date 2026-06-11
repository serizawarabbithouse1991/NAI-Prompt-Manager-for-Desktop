/**
 * Headless iCloud full export (Phase 1 operations).
 * Usage: node scripts/icloud-full-export.mjs [syncPath]
 */
import { execFileSync } from 'node:child_process'
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { basename, join } from 'node:path'
import { randomUUID } from 'node:crypto'

const SYNC_VERSION = '1.0.0'
const APP_DATA = join(
  process.env.APPDATA || '',
  'com.nai-prompt-manager.desktop'
)
const DB_PATH = join(APP_DATA, 'nai_prompt_manager.db')
const DEFAULT_SYNC_PATH = 'C:\\Users\\rt032\\iCloudDrive\\NAI-Prompt-Manager'
const SYNC_PATH = process.argv[2] || DEFAULT_SYNC_PATH

function sqlJson(query) {
  const out = execFileSync('sqlite3', ['-json', DB_PATH, query], {
    encoding: 'utf8',
    maxBuffer: 512 * 1024 * 1024,
  }).trim()
  if (!out) return []
  return JSON.parse(out)
}

function ensureDir(path) {
  if (!existsSync(path)) mkdirSync(path, { recursive: true })
}

function writeJson(path, data) {
  writeFileSync(path, JSON.stringify(data, null, 2), 'utf8')
}

function imageExt(filename, filePath) {
  const fromName = filename?.split('.').pop()?.toLowerCase()
  if (fromName && ['png', 'jpg', 'jpeg', 'webp', 'gif'].includes(fromName)) {
    return fromName === 'jpeg' ? 'jpg' : fromName
  }
  const fromPath = basename(filePath).split('.').pop()?.toLowerCase()
  if (fromPath && ['png', 'jpg', 'jpeg', 'webp', 'gif'].includes(fromPath)) {
    return fromPath === 'jpeg' ? 'jpg' : fromPath
  }
  return 'png'
}

function copyIfNeeded(src, dest) {
  if (!src || !existsSync(src)) return false
  if (existsSync(dest)) return false
  copyFileSync(src, dest)
  return true
}

function log(msg) {
  const ts = new Date().toLocaleTimeString('ja-JP')
  console.log(`[${ts}] ${msg}`)
}

function main() {
  if (!existsSync(DB_PATH)) {
    console.error(`DB not found: ${DB_PATH}`)
    process.exit(1)
  }

  const deviceId = randomUUID()
  const now = () => new Date().toISOString()

  const dirs = {
    root: SYNC_PATH,
    sync: join(SYNC_PATH, 'sync'),
    changes: join(SYNC_PATH, 'sync', 'changes'),
    images: join(SYNC_PATH, 'images'),
    thumbnails: join(SYNC_PATH, 'thumbnails'),
    meta: join(SYNC_PATH, 'meta'),
    tags: join(SYNC_PATH, 'tags'),
    folders: join(SYNC_PATH, 'folders'),
  }

  for (const d of Object.values(dirs)) ensureDir(d)

  const manifest = {
    version: SYNC_VERSION,
    updatedAt: now(),
    deviceId,
    images: {},
    tags: {},
    folders: {},
  }

  log(`Sync path: ${SYNC_PATH}`)
  log('Exporting tags...')
  const tags = sqlJson('SELECT * FROM tags ORDER BY name')
  for (const tag of tags) {
    const updatedAt = now()
    writeJson(join(dirs.tags, `${tag.id}.json`), {
      version: SYNC_VERSION,
      updatedAt,
      tag,
    })
    manifest.tags[tag.id] = { updatedAt, name: tag.name, deletedAt: null }
  }
  log(`Tags: ${tags.length}`)

  log('Exporting folders...')
  const folders = sqlJson('SELECT * FROM folders ORDER BY sort_order, name')
  for (const folder of folders) {
    const updatedAt = now()
    writeJson(join(dirs.folders, `${folder.id}.json`), {
      version: SYNC_VERSION,
      updatedAt,
      folder,
    })
    manifest.folders[folder.id] = {
      updatedAt,
      name: folder.name,
      parentId: folder.parent_id,
      deletedAt: null,
    }
  }
  log(`Folders: ${folders.length}`)

  log('Loading image metadata...')
  const images = sqlJson(
    `SELECT * FROM images WHERE deleted_at IS NULL ORDER BY created_at DESC`
  )
  const prompts = sqlJson(`SELECT id, image_id, positive_prompt, negative_prompt, model, sampler,
    steps, cfg_scale, seed, resolution_width, resolution_height, noise_schedule,
    prompt_guidance_rescale, notes, created_at FROM prompts`)
  const promptMap = new Map(prompts.map((p) => [p.image_id, p]))

  const imageTags = sqlJson(`
    SELECT it.image_id, it.tag_id, t.name, t.color
    FROM image_tags it JOIN tags t ON it.tag_id = t.id`)
  const tagsMap = new Map()
  for (const row of imageTags) {
    const list = tagsMap.get(row.image_id) || []
    list.push({ id: row.tag_id, name: row.name, color: row.color })
    tagsMap.set(row.image_id, list)
  }

  const ratings = sqlJson('SELECT * FROM image_ratings')
  const ratingMap = new Map(ratings.map((r) => [r.image_id, r]))

  let exported = 0
  let skippedFiles = 0
  let failed = 0
  const total = images.length

  log(`Exporting ${total} images...`)

  for (let i = 0; i < images.length; i++) {
    const image = images[i]
    const updatedAt = now()
    const ext = imageExt(image.filename, image.file_path)
    const imageFile = `${image.id}.${ext}`
    const thumbFile = `${image.id}.webp`

    try {
      const imageDest = join(dirs.images, imageFile)
      const thumbDest = join(dirs.thumbnails, thumbFile)

      if (!copyIfNeeded(image.file_path, imageDest)) {
        if (existsSync(imageDest)) skippedFiles++
      }
      if (image.thumbnail_path) {
        copyIfNeeded(image.thumbnail_path, thumbDest)
      }

      const prompt = promptMap.get(image.id) || null
      const meta = {
        version: SYNC_VERSION,
        updatedAt,
        image: {
          id: image.id,
          folder_id: image.folder_id,
          filename: image.filename,
          width: image.width,
          height: image.height,
          file_size: image.file_size,
          file_hash: image.file_hash,
          deleted_at: image.deleted_at,
          created_at: image.created_at,
          imageFile: `images/${imageFile}`,
          thumbnailFile: image.thumbnail_path ? `thumbnails/${thumbFile}` : null,
        },
        prompt,
        tags: tagsMap.get(image.id) || [],
        rating: ratingMap.get(image.id) || null,
      }
      writeJson(join(dirs.meta, `${image.id}.json`), meta)

      manifest.images[image.id] = {
        updatedAt,
        deletedAt: image.deleted_at,
        fileHash: image.file_hash,
        filename: image.filename,
      }
      exported++
    } catch (err) {
      failed++
      console.error(`Failed ${image.id}:`, err.message)
    }

    if ((i + 1) % 100 === 0 || i + 1 === total) {
      log(`Progress: ${i + 1}/${total} (exported ${exported}, failed ${failed})`)
    }
  }

  manifest.updatedAt = now()
  writeJson(join(dirs.sync, 'manifest.json'), manifest)
  writeJson(join(dirs.sync, 'device.json'), {
    deviceId,
    deviceName: 'NAI Prompt Manager Desktop (CLI)',
    platform: 'windows',
    lastSyncedAt: now(),
  })

  const changeFile = join(
    dirs.changes,
    `${now().replace(/[:.]/g, '-')}_${deviceId.slice(0, 8)}_full-export.json`
  )
  writeJson(changeFile, {
    version: SYNC_VERSION,
    timestamp: now(),
    deviceId,
    entityType: 'manifest',
    entityId: 'full-export',
    action: 'create',
    updatedAt: now(),
  })

  log('--- Done ---')
  log(`Images exported: ${exported}/${total}`)
  log(`Image files skipped (already exist): ${skippedFiles}`)
  log(`Failed: ${failed}`)
  log(`Tags: ${tags.length}, Folders: ${folders.length}`)
}

main()
