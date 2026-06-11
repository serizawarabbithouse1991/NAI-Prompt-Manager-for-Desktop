import { useAppStore } from '../../stores/appStore'
import type { Folder, ImageWithDetails, Tag } from '../../types'
import * as db from '../database'
import { getDeviceInfo } from './device'
import { markFolderDeletedInICloud, markTagDeletedInICloud, syncFolderToICloud, syncTagToICloud } from './entity-sync'
import { ensureSyncDirs, writeJsonFile } from './io'
import { markImageDeletedInICloud, syncImageToICloud } from './image-sync'
import { initializeSyncFolder, runFullExportToICloud } from './full-export'
import { importAllFromICloud } from './import'
import type { FullExportProgress, FullExportResult, SyncImportProgress, SyncImportResult } from './types'

export * from './types'
export { runFullExportToICloud, initializeSyncFolder, importAllFromICloud }

function getSyncConfig(): { enabled: boolean; path: string } | null {
  const { settings } = useAppStore.getState()
  if (!settings.icloudSyncEnabled || !settings.icloudSyncPath?.trim()) {
    return null
  }
  return { enabled: true, path: settings.icloudSyncPath.trim() }
}

async function touchLastSynced(): Promise<void> {
  const config = getSyncConfig()
  if (!config) return
  const lastSyncedAt = new Date().toISOString()
  const dirs = await ensureSyncDirs(config.path)
  await writeJsonFile(dirs.deviceFile, getDeviceInfo(lastSyncedAt))
  useAppStore.getState().updateSettings({ icloudSyncLastSyncedAt: lastSyncedAt })
}

async function withImageFromStoreOrDb(
  imageId: string,
  fallback?: ImageWithDetails
): Promise<ImageWithDetails | null> {
  if (fallback) return fallback
  const { useImageStore } = await import('../../stores/imageStore')
  const image = useImageStore.getState().images.find((i) => i.id === imageId)
  if (image) return image
  const all = await db.getAllImages()
  return all.find((i) => i.id === imageId) ?? null
}

export async function notifyImageSynced(
  image: ImageWithDetails,
  action: 'create' | 'update' = 'update'
): Promise<void> {
  const config = getSyncConfig()
  if (!config) return
  try {
    await syncImageToICloud(config.path, image, action)
    await touchLastSynced()
  } catch (err) {
    console.error('iCloud image sync failed:', err)
  }
}

export async function notifyImagesSynced(images: ImageWithDetails[]): Promise<void> {
  const config = getSyncConfig()
  if (!config || images.length === 0) return
  for (const image of images) {
    try {
      await syncImageToICloud(config.path, image, 'create', { skipExistingFiles: true })
    } catch (err) {
      console.error(`iCloud batch image sync failed for ${image.id}:`, err)
    }
    await new Promise((r) => setTimeout(r, 0))
  }
  await touchLastSynced()
}

export async function notifyImageDeleted(imageId: string): Promise<void> {
  const config = getSyncConfig()
  if (!config) return
  try {
    await markImageDeletedInICloud(config.path, imageId)
    await touchLastSynced()
  } catch (err) {
    console.error('iCloud image delete sync failed:', err)
  }
}

export async function notifyImageChanged(imageId: string, fallback?: ImageWithDetails): Promise<void> {
  const image = await withImageFromStoreOrDb(imageId, fallback)
  if (!image) return
  await notifyImageSynced(image, 'update')
}

export async function notifyTagSynced(tag: Tag, action: 'create' | 'update' = 'update'): Promise<void> {
  const config = getSyncConfig()
  if (!config) return
  try {
    await syncTagToICloud(config.path, tag, action)
    await touchLastSynced()
  } catch (err) {
    console.error('iCloud tag sync failed:', err)
  }
}

export async function notifyTagDeleted(tagId: string): Promise<void> {
  const config = getSyncConfig()
  if (!config) return
  try {
    await markTagDeletedInICloud(config.path, tagId)
    await touchLastSynced()
  } catch (err) {
    console.error('iCloud tag delete sync failed:', err)
  }
}

export async function notifyFolderSynced(folder: Folder, action: 'create' | 'update' = 'update'): Promise<void> {
  const config = getSyncConfig()
  if (!config) return
  try {
    await syncFolderToICloud(config.path, folder, action)
    await touchLastSynced()
  } catch (err) {
    console.error('iCloud folder sync failed:', err)
  }
}

export async function notifyFolderDeleted(folderId: string): Promise<void> {
  const config = getSyncConfig()
  if (!config) return
  try {
    await markFolderDeletedInICloud(config.path, folderId)
    await touchLastSynced()
  } catch (err) {
    console.error('iCloud folder delete sync failed:', err)
  }
}

export async function setupICloudSync(syncPath: string): Promise<void> {
  await initializeSyncFolder(syncPath)
}

export async function exportAllToICloud(
  onProgress?: (progress: FullExportProgress) => void
): Promise<FullExportResult> {
  const config = getSyncConfig()
  if (!config) {
    return {
      success: false,
      exportedImages: 0,
      skippedImages: 0,
      failedImages: 0,
      exportedTags: 0,
      exportedFolders: 0,
      errors: ['iCloud同期が有効化されていないか、同期フォルダが未設定です'],
    }
  }
  const result = await runFullExportToICloud(config.path, onProgress)
  if (result.success || result.exportedImages > 0) {
    await touchLastSynced()
  }
  return result
}

export async function importAllFromICloudSync(
  onProgress?: (progress: SyncImportProgress) => void
): Promise<SyncImportResult> {
  const config = getSyncConfig()
  if (!config) {
    return {
      success: false,
      importedImages: 0,
      importedTags: 0,
      importedFolders: 0,
      skippedImages: 0,
      failedImages: 0,
      errors: ['iCloud同期が有効化されていないか、同期フォルダが未設定です'],
    }
  }

  const result = await importAllFromICloud(config.path, onProgress)
  if (result.success || result.importedImages > 0 || result.importedTags > 0 || result.importedFolders > 0) {
    await touchLastSynced()
  }
  return result
}
