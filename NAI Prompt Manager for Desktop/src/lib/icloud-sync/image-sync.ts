import { join } from '@tauri-apps/api/path'
import { exists } from '@tauri-apps/plugin-fs'
import { writeChangeLog } from './changes'
import { ensureSyncDirs, copyFileAlways, copyFileIfNeeded, readJsonFile, writeJsonFile } from './io'
import { readManifest, writeManifest } from './manifest'
import { imageExtension, imageFileName, thumbnailFileName } from './paths'
import type { ImageSyncMeta, ImageSyncSource } from './types'
import { SYNC_PROTOCOL_VERSION } from './types'

export async function syncImageToICloud(
  syncPath: string,
  image: ImageSyncSource,
  action: 'create' | 'update' = 'update',
  options: { skipExistingFiles?: boolean } = {}
): Promise<void> {
  const dirs = await ensureSyncDirs(syncPath)
  const updatedAt = new Date().toISOString()
  const ext = imageExtension(image.filename, image.file_path)
  const imageFile = imageFileName(image.id, ext)
  const thumbFile = thumbnailFileName(image.id)

  const imageDest = await join(dirs.images, imageFile)
  const thumbDest = await join(dirs.thumbnails, thumbFile)
  const metaDest = await join(dirs.meta, `${image.id}.json`)

  if (image.file_path && (await exists(image.file_path))) {
    if (options.skipExistingFiles) {
      await copyFileIfNeeded(image.file_path, imageDest)
    } else {
      await copyFileAlways(image.file_path, imageDest)
    }
  }

  if (image.thumbnail_path && (await exists(image.thumbnail_path))) {
    if (options.skipExistingFiles) {
      await copyFileIfNeeded(image.thumbnail_path, thumbDest)
    } else {
      await copyFileAlways(image.thumbnail_path, thumbDest)
    }
  }

  const meta: ImageSyncMeta = {
    version: SYNC_PROTOCOL_VERSION,
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
    prompt: image.prompt
      ? {
          id: image.prompt.id,
          image_id: image.prompt.image_id,
          positive_prompt: image.prompt.positive_prompt,
          negative_prompt: image.prompt.negative_prompt,
          model: image.prompt.model,
          sampler: image.prompt.sampler,
          steps: image.prompt.steps,
          cfg_scale: image.prompt.cfg_scale,
          seed: image.prompt.seed,
          resolution_width: image.prompt.resolution_width,
          resolution_height: image.prompt.resolution_height,
          noise_schedule: image.prompt.noise_schedule,
          prompt_guidance_rescale: image.prompt.prompt_guidance_rescale,
          notes: image.prompt.notes,
          created_at: image.prompt.created_at,
        }
      : null,
    tags: image.tags.map((tag) => ({ id: tag.id, name: tag.name, color: tag.color })),
    rating: image.rating,
  }

  await writeJsonFile(metaDest, meta)

  const manifest = await readManifest(syncPath)
  manifest.images[image.id] = {
    updatedAt,
    deletedAt: image.deleted_at,
    fileHash: image.file_hash,
    filename: image.filename,
  }
  await writeManifest(syncPath, manifest)
  await writeChangeLog(syncPath, 'image', image.id, action)
}

export async function markImageDeletedInICloud(syncPath: string, imageId: string): Promise<void> {
  const dirs = await ensureSyncDirs(syncPath)
  const updatedAt = new Date().toISOString()
  const metaDest = await join(dirs.meta, `${imageId}.json`)

  if (await exists(metaDest)) {
    const existing = await readJsonFile<ImageSyncMeta>(metaDest)
    if (existing) {
      existing.updatedAt = updatedAt
      existing.image.deleted_at = updatedAt
      await writeJsonFile(metaDest, existing)
    }
  }

  const manifest = await readManifest(syncPath)
  manifest.images[imageId] = {
    ...(manifest.images[imageId] ?? { updatedAt }),
    updatedAt,
    deletedAt: updatedAt,
  }
  await writeManifest(syncPath, manifest)
  await writeChangeLog(syncPath, 'image', imageId, 'delete')
}
