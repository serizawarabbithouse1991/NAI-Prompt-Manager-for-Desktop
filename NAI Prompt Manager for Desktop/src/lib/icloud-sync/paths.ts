import { join } from '@tauri-apps/api/path'

export async function getSyncRoot(syncPath: string): Promise<string> {
  return syncPath.replace(/[/\\]+$/, '')
}

export async function getSyncDirs(syncPath: string) {
  const root = await getSyncRoot(syncPath)
  return {
    root,
    sync: await join(root, 'sync'),
    changes: await join(root, 'sync', 'changes'),
    images: await join(root, 'images'),
    thumbnails: await join(root, 'thumbnails'),
    meta: await join(root, 'meta'),
    tags: await join(root, 'tags'),
    folders: await join(root, 'folders'),
    deviceFile: await join(root, 'sync', 'device.json'),
    manifestFile: await join(root, 'sync', 'manifest.json'),
  }
}

export function imageExtension(filename: string | null, filePath: string): string {
  const fromName = filename?.split('.').pop()?.toLowerCase()
  if (fromName && ['png', 'jpg', 'jpeg', 'webp', 'gif'].includes(fromName)) {
    return fromName === 'jpeg' ? 'jpg' : fromName
  }
  const fromPath = filePath.split(/[/\\]/).pop()?.split('.').pop()?.toLowerCase()
  if (fromPath && ['png', 'jpg', 'jpeg', 'webp', 'gif'].includes(fromPath)) {
    return fromPath === 'jpeg' ? 'jpg' : fromPath
  }
  return 'png'
}

export function imageFileName(imageId: string, ext: string): string {
  return `${imageId}.${ext}`
}

export function thumbnailFileName(imageId: string): string {
  return `${imageId}.webp`
}
