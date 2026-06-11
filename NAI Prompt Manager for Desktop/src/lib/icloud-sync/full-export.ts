import * as db from '../database'
import { getDeviceInfo } from './device'
import { ensureSyncDirs, writeJsonFile } from './io'
import { exists } from '@tauri-apps/plugin-fs'
import { syncFolderToICloud, syncTagToICloud } from './entity-sync'
import { syncImageToICloud } from './image-sync'
import { writeManifest, createEmptyManifest, readManifest } from './manifest'
import type { FullExportProgress, FullExportResult } from './types'

export async function runFullExportToICloud(
  syncPath: string,
  onProgress?: (progress: FullExportProgress) => void
): Promise<FullExportResult> {
  const result: FullExportResult = {
    success: false,
    exportedImages: 0,
    skippedImages: 0,
    failedImages: 0,
    exportedTags: 0,
    exportedFolders: 0,
    errors: [],
  }

  const report = (progress: FullExportProgress) => onProgress?.(progress)

  try {
    report({ phase: 'init', current: 0, total: 1, message: '同期フォルダを準備中...' })
    const dirs = await ensureSyncDirs(syncPath)

    const [images, tags, folders] = await Promise.all([
      db.getAllImages(),
      db.getAllTags(),
      db.getAllFolders(),
    ])

    const totalSteps = tags.length + folders.length + images.length + 1
    let current = 0

    report({ phase: 'tags', current, total: totalSteps, message: 'タグを書き出し中...' })
    for (const tag of tags) {
      try {
        await syncTagToICloud(syncPath, tag, 'create')
        result.exportedTags++
      } catch (err) {
        result.errors.push(`tag ${tag.name}: ${err instanceof Error ? err.message : String(err)}`)
      }
      current++
      if (current % 10 === 0) {
        report({ phase: 'tags', current, total: totalSteps, message: `タグを書き出し中... ${current}/${totalSteps}` })
        await new Promise((r) => setTimeout(r, 0))
      }
    }

    report({ phase: 'folders', current, total: totalSteps, message: 'フォルダを書き出し中...' })
    for (const folder of folders) {
      try {
        await syncFolderToICloud(syncPath, folder, 'create')
        result.exportedFolders++
      } catch (err) {
        result.errors.push(`folder ${folder.name}: ${err instanceof Error ? err.message : String(err)}`)
      }
      current++
      if (current % 10 === 0) {
        report({ phase: 'folders', current, total: totalSteps, message: `フォルダを書き出し中... ${current}/${totalSteps}` })
        await new Promise((r) => setTimeout(r, 0))
      }
    }

    report({ phase: 'images', current, total: totalSteps, message: '画像を書き出し中...' })
    for (const image of images) {
      try {
        await syncImageToICloud(syncPath, image, 'create', { skipExistingFiles: true })
        result.exportedImages++
      } catch (err) {
        result.failedImages++
        result.errors.push(`image ${image.filename ?? image.id}: ${err instanceof Error ? err.message : String(err)}`)
      }
      current++
      if (current % 5 === 0 || current === totalSteps) {
        report({
          phase: 'images',
          current,
          total: totalSteps,
          message: `画像を書き出し中... ${result.exportedImages}/${images.length} 件`,
        })
        await new Promise((r) => setTimeout(r, 0))
      }
    }

    report({ phase: 'manifest', current: totalSteps - 1, total: totalSteps, message: 'マニフェストを更新中...' })
    const manifest = await readManifest(syncPath)
    await writeManifest(syncPath, manifest)

    const lastSyncedAt = new Date().toISOString()
    await writeJsonFile(dirs.deviceFile, getDeviceInfo(lastSyncedAt))

    report({ phase: 'done', current: totalSteps, total: totalSteps, message: '初回エクスポート完了' })
    result.success = result.failedImages === 0
    return result
  } catch (err) {
    result.errors.push(err instanceof Error ? err.message : String(err))
    return result
  }
}

export async function initializeSyncFolder(syncPath: string): Promise<void> {
  const dirs = await ensureSyncDirs(syncPath)
  if (!(await exists(dirs.manifestFile))) {
    await writeManifest(syncPath, createEmptyManifest())
  }
  if (!(await exists(dirs.deviceFile))) {
    await writeJsonFile(dirs.deviceFile, getDeviceInfo(null))
  }
}
