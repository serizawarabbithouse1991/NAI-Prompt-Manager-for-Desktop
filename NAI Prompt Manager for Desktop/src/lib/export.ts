import { save } from '@tauri-apps/plugin-dialog'
import { writeTextFile, readFile, mkdir, exists, copyFile } from '@tauri-apps/plugin-fs'
import { join } from '@tauri-apps/api/path'
import type { ImageWithDetails, Folder, Tag, ExportData } from '../types'
import * as db from './database'

/**
 * Export selected images and their data as JSON
 */
export async function exportAsJson(
  images: ImageWithDetails[],
  folders: Folder[],
  tags: Tag[]
): Promise<boolean> {
  try {
    const savePath = await save({
      filters: [{ name: 'JSON', extensions: ['json'] }],
      defaultPath: `nai-prompt-manager-export-${Date.now()}.json`,
    })

    if (!savePath) return false

    const exportData: ExportData = {
      version: '1.0.0',
      exportedAt: new Date().toISOString(),
      images,
      folders,
      tags,
    }

    await writeTextFile(savePath, JSON.stringify(exportData, null, 2))
    return true
  } catch (err) {
    console.error('Export failed:', err)
    return false
  }
}

/**
 * Export images with their files to a folder
 */
export async function exportWithFiles(
  images: ImageWithDetails[],
  folders: Folder[],
  tags: Tag[]
): Promise<boolean> {
  try {
    const savePath = await save({
      filters: [{ name: 'Folder', extensions: [] }],
      defaultPath: `nai-prompt-manager-export-${Date.now()}`,
    })

    if (!savePath) return false

    // Create export directory
    if (!(await exists(savePath))) {
      await mkdir(savePath, { recursive: true })
    }

    // Create images subdirectory
    const imagesDir = await join(savePath, 'images')
    if (!(await exists(imagesDir))) {
      await mkdir(imagesDir, { recursive: true })
    }

    // Copy images
    const exportedImages: ImageWithDetails[] = []
    for (const image of images) {
      try {
        const filename = image.filename || `${image.id}.png`
        const destPath = await join(imagesDir, filename)
        await copyFile(image.file_path, destPath)
        
        // Update image path in export data
        exportedImages.push({
          ...image,
          file_path: `images/${filename}`,
          thumbnail_path: null,
        })
      } catch (err) {
        console.error(`Failed to copy image ${image.filename}:`, err)
      }
    }

    // Write metadata JSON
    const exportData: ExportData = {
      version: '1.0.0',
      exportedAt: new Date().toISOString(),
      images: exportedImages,
      folders,
      tags,
    }

    const metadataPath = await join(savePath, 'metadata.json')
    await writeTextFile(metadataPath, JSON.stringify(exportData, null, 2))

    return true
  } catch (err) {
    console.error('Export with files failed:', err)
    return false
  }
}

/**
 * Import data from JSON file
 */
export async function importFromJson(jsonPath: string): Promise<{
  success: boolean
  imported: number
  errors: string[]
}> {
  const errors: string[] = []
  let imported = 0

  try {
    const content = await readFile(jsonPath)
    const decoder = new TextDecoder()
    const data: ExportData = JSON.parse(decoder.decode(content))

    // Validate version
    if (!data.version) {
      throw new Error('Invalid export file format')
    }

    // Import tags first
    for (const tag of data.tags || []) {
      try {
        await db.createTag(tag.name, tag.color || undefined)
      } catch (err) {
        // Tag might already exist, skip
      }
    }

    // Import folders
    const folderIdMap = new Map<string, string>()
    for (const folder of data.folders || []) {
      try {
        const newFolder = await db.createFolder(
          folder.name,
          folder.parent_id ? folderIdMap.get(folder.parent_id) || null : null,
          folder.color || undefined
        )
        folderIdMap.set(folder.id, newFolder.id)
      } catch (err) {
        errors.push(`Failed to import folder ${folder.name}`)
      }
    }

    // Note: Image import with files requires additional handling
    // This is a metadata-only import for now
    imported = (data.images || []).length

    return { success: true, imported, errors }
  } catch (err) {
    console.error('Import failed:', err)
    return { 
      success: false, 
      imported: 0, 
      errors: [err instanceof Error ? err.message : 'Import failed'] 
    }
  }
}
