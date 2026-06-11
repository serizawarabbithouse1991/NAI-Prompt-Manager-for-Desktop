import { join } from '@tauri-apps/api/path'
import { writeChangeLog } from './changes'
import { ensureSyncDirs, writeJsonFile } from './io'
import { readManifest, writeManifest } from './manifest'
import type { Folder, Tag } from '../../types'
import { SYNC_PROTOCOL_VERSION } from './types'

export async function syncTagToICloud(
  syncPath: string,
  tag: Tag,
  action: 'create' | 'update' = 'update'
): Promise<void> {
  const dirs = await ensureSyncDirs(syncPath)
  const updatedAt = new Date().toISOString()
  const tagDest = await join(dirs.tags, `${tag.id}.json`)

  await writeJsonFile(tagDest, {
    version: SYNC_PROTOCOL_VERSION,
    updatedAt,
    tag,
  })

  const manifest = await readManifest(syncPath)
  manifest.tags[tag.id] = {
    updatedAt,
    name: tag.name,
    deletedAt: null,
  }
  await writeManifest(syncPath, manifest)
  await writeChangeLog(syncPath, 'tag', tag.id, action)
}

export async function markTagDeletedInICloud(syncPath: string, tagId: string): Promise<void> {
  const updatedAt = new Date().toISOString()
  const manifest = await readManifest(syncPath)
  const existing = manifest.tags[tagId]
  manifest.tags[tagId] = {
    updatedAt,
    name: existing?.name ?? tagId,
    deletedAt: updatedAt,
  }
  await writeManifest(syncPath, manifest)
  await writeChangeLog(syncPath, 'tag', tagId, 'delete')
}

export async function syncFolderToICloud(
  syncPath: string,
  folder: Folder,
  action: 'create' | 'update' = 'update'
): Promise<void> {
  const dirs = await ensureSyncDirs(syncPath)
  const updatedAt = new Date().toISOString()
  const folderDest = await join(dirs.folders, `${folder.id}.json`)

  await writeJsonFile(folderDest, {
    version: SYNC_PROTOCOL_VERSION,
    updatedAt,
    folder,
  })

  const manifest = await readManifest(syncPath)
  manifest.folders[folder.id] = {
    updatedAt,
    name: folder.name,
    parentId: folder.parent_id,
    deletedAt: null,
  }
  await writeManifest(syncPath, manifest)
  await writeChangeLog(syncPath, 'folder', folder.id, action)
}

export async function markFolderDeletedInICloud(syncPath: string, folderId: string): Promise<void> {
  const updatedAt = new Date().toISOString()
  const manifest = await readManifest(syncPath)
  const existing = manifest.folders[folderId]
  manifest.folders[folderId] = {
    updatedAt,
    name: existing?.name ?? folderId,
    parentId: existing?.parentId ?? null,
    deletedAt: updatedAt,
  }
  await writeManifest(syncPath, manifest)
  await writeChangeLog(syncPath, 'folder', folderId, 'delete')
}
