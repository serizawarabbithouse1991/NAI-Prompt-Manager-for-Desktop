import type { Image, ImageRating, ImageWithDetails, Prompt, Tag } from '../../types'

export const SYNC_PROTOCOL_VERSION = '1.0.0'

export type SyncEntityType = 'image' | 'tag' | 'folder' | 'manifest'

export type SyncAction = 'create' | 'update' | 'delete'

export interface SyncDeviceInfo {
  deviceId: string
  deviceName: string
  platform: string
  lastSyncedAt: string | null
}

export interface SyncManifestImageEntry {
  updatedAt: string
  deletedAt?: string | null
  fileHash?: string | null
  filename?: string | null
}

export interface SyncManifestTagEntry {
  updatedAt: string
  name: string
  deletedAt?: string | null
}

export interface SyncManifestFolderEntry {
  updatedAt: string
  name: string
  parentId?: string | null
  deletedAt?: string | null
}

export interface SyncManifest {
  version: string
  updatedAt: string
  deviceId: string
  images: Record<string, SyncManifestImageEntry>
  tags: Record<string, SyncManifestTagEntry>
  folders: Record<string, SyncManifestFolderEntry>
}

export interface ImageSyncMeta {
  version: string
  updatedAt: string
  image: Omit<Image, 'file_path' | 'thumbnail_path'> & {
    imageFile: string
    thumbnailFile: string | null
  }
  prompt: Omit<Prompt, 'raw_metadata'> | null
  tags: Pick<Tag, 'id' | 'name' | 'color'>[]
  rating: ImageRating | null
}

export interface SyncChangeRecord {
  version: string
  timestamp: string
  deviceId: string
  entityType: SyncEntityType
  entityId: string
  action: SyncAction
  updatedAt: string
}

export interface FullExportProgress {
  phase: 'init' | 'images' | 'tags' | 'folders' | 'manifest' | 'done'
  current: number
  total: number
  message: string
}

export interface FullExportResult {
  success: boolean
  exportedImages: number
  skippedImages: number
  failedImages: number
  exportedTags: number
  exportedFolders: number
  errors: string[]
}

export interface SyncImportProgress {
  phase: 'init' | 'tags' | 'folders' | 'images' | 'done'
  current: number
  total: number
  message: string
}

export interface SyncImportResult {
  success: boolean
  importedImages: number
  importedTags: number
  importedFolders: number
  skippedImages: number
  failedImages: number
  errors: string[]
}

export type ImageSyncSource = ImageWithDetails
