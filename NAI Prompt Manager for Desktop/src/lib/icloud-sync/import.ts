import { appDataDir, join } from '@tauri-apps/api/path'
import { copyFile, exists, mkdir, readDir } from '@tauri-apps/plugin-fs'
import type { Folder, Image, Prompt, Tag } from '../../types'
import * as db from '../database'
import { ensureSyncDirs, readJsonFile } from './io'
import type { ImageSyncMeta, SyncImportProgress, SyncImportResult } from './types'

interface TagSyncFile {
  tag: Tag
}

interface FolderSyncFile {
  folder: Folder
}

async function joinRelative(root: string, relativePath: string): Promise<string> {
  const parts = relativePath.split(/[\\/]+/).filter(Boolean)
  return join(root, ...parts)
}

async function ensureAppMediaDirs(): Promise<{ imagesDir: string; thumbnailsDir: string }> {
  const dataDir = await appDataDir()
  const imagesDir = await join(dataDir, 'images')
  const thumbnailsDir = await join(dataDir, 'thumbnails')
  if (!(await exists(imagesDir))) await mkdir(imagesDir, { recursive: true })
  if (!(await exists(thumbnailsDir))) await mkdir(thumbnailsDir, { recursive: true })
  return { imagesDir, thumbnailsDir }
}

async function jsonFilesIn(directory: string): Promise<string[]> {
  if (!(await exists(directory))) return []
  const entries = await readDir(directory)
  return entries
    .map((entry) => entry.name)
    .filter((name): name is string => Boolean(name && name.endsWith('.json')))
}

async function copyMediaIfNeeded(sourcePath: string, destDir: string, filename: string): Promise<string> {
  const dest = await join(destDir, filename)
  if (!(await exists(dest))) {
    await copyFile(sourcePath, dest)
  }
  return dest
}

function sourceFileName(relativePath: string, fallback: string): string {
  return relativePath.split(/[\\/]+/).filter(Boolean).pop() ?? fallback
}

export async function importAllFromICloud(
  syncPath: string,
  onProgress?: (progress: SyncImportProgress) => void
): Promise<SyncImportResult> {
  const result: SyncImportResult = {
    success: false,
    importedImages: 0,
    importedTags: 0,
    importedFolders: 0,
    skippedImages: 0,
    failedImages: 0,
    errors: [],
  }

  const report = (progress: SyncImportProgress) => onProgress?.(progress)

  try {
    report({ phase: 'init', current: 0, total: 1, message: '同期フォルダを確認中...' })
    const dirs = await ensureSyncDirs(syncPath)
    const mediaDirs = await ensureAppMediaDirs()

    const [tagFiles, folderFiles, imageMetaFiles] = await Promise.all([
      jsonFilesIn(dirs.tags),
      jsonFilesIn(dirs.folders),
      jsonFilesIn(dirs.meta),
    ])

    const totalSteps = tagFiles.length + folderFiles.length + imageMetaFiles.length
    let current = 0

    report({ phase: 'tags', current, total: totalSteps, message: 'タグを取り込み中...' })
    for (const fileName of tagFiles) {
      try {
        const data = await readJsonFile<TagSyncFile>(await join(dirs.tags, fileName))
        if (data?.tag) {
          await db.upsertTag(data.tag)
          result.importedTags++
        }
      } catch (err) {
        result.errors.push(`tag ${fileName}: ${err instanceof Error ? err.message : String(err)}`)
      }
      current++
    }

    report({ phase: 'folders', current, total: totalSteps, message: 'フォルダを取り込み中...' })
    const folders: Folder[] = []
    for (const fileName of folderFiles) {
      try {
        const data = await readJsonFile<FolderSyncFile>(await join(dirs.folders, fileName))
        if (data?.folder) folders.push(data.folder)
      } catch (err) {
        result.errors.push(`folder ${fileName}: ${err instanceof Error ? err.message : String(err)}`)
      }
      current++
    }

    folders.sort((a, b) => {
      if (a.parent_id === b.parent_id) return a.sort_order - b.sort_order
      if (!a.parent_id) return -1
      if (!b.parent_id) return 1
      return a.parent_id.localeCompare(b.parent_id)
    })
    for (const folder of folders) {
      try {
        await db.upsertFolder(folder)
        result.importedFolders++
      } catch (err) {
        result.errors.push(`folder ${folder.name}: ${err instanceof Error ? err.message : String(err)}`)
      }
    }

    report({ phase: 'images', current, total: totalSteps, message: '画像を取り込み中...' })
    for (const fileName of imageMetaFiles) {
      try {
        const meta = await readJsonFile<ImageSyncMeta>(await join(dirs.meta, fileName))
        if (!meta?.image || meta.image.deleted_at) {
          result.skippedImages++
          current++
          continue
        }

        for (const tag of meta.tags) {
          await db.upsertTag({
            id: tag.id,
            name: tag.name,
            color: tag.color,
            created_at: meta.updatedAt,
          })
        }

        const imageSource = await joinRelative(dirs.root, meta.image.imageFile)
        if (!(await exists(imageSource))) {
          result.failedImages++
          result.errors.push(`image ${meta.image.id}: 画像ファイルが見つかりません`)
          current++
          continue
        }

        const imageFileName = sourceFileName(meta.image.imageFile, `${meta.image.id}.png`)
        const localImagePath = await copyMediaIfNeeded(imageSource, mediaDirs.imagesDir, imageFileName)

        let localThumbnailPath: string | null = null
        if (meta.image.thumbnailFile) {
          const thumbSource = await joinRelative(dirs.root, meta.image.thumbnailFile)
          if (await exists(thumbSource)) {
            const thumbFileName = sourceFileName(meta.image.thumbnailFile, `${meta.image.id}.webp`)
            localThumbnailPath = await copyMediaIfNeeded(thumbSource, mediaDirs.thumbnailsDir, thumbFileName)
          }
        }

        const image: Image = {
          id: meta.image.id,
          folder_id: meta.image.folder_id,
          file_path: localImagePath,
          thumbnail_path: localThumbnailPath,
          filename: meta.image.filename,
          width: meta.image.width,
          height: meta.image.height,
          file_size: meta.image.file_size,
          file_hash: meta.image.file_hash,
          deleted_at: meta.image.deleted_at,
          created_at: meta.image.created_at,
        }
        await db.upsertImage(image)

        if (meta.prompt) {
          const prompt: Prompt = {
            ...meta.prompt,
            raw_metadata: null,
          }
          await db.upsertPrompt(prompt)
        }

        if (meta.rating) {
          await db.upsertImageRating(meta.rating)
        }
        await db.replaceImageTags(meta.image.id, meta.tags.map((tag) => tag.id))
        result.importedImages++
      } catch (err) {
        result.failedImages++
        result.errors.push(`image ${fileName}: ${err instanceof Error ? err.message : String(err)}`)
      }

      current++
      if (current % 5 === 0 || current === totalSteps) {
        report({
          phase: 'images',
          current,
          total: totalSteps,
          message: `画像を取り込み中... ${result.importedImages}/${imageMetaFiles.length} 件`,
        })
        await new Promise((resolve) => setTimeout(resolve, 0))
      }
    }

    report({ phase: 'done', current: totalSteps, total: totalSteps, message: '同期フォルダからの取り込み完了' })
    result.success = result.failedImages === 0
    return result
  } catch (err) {
    result.errors.push(err instanceof Error ? err.message : String(err))
    return result
  }
}
