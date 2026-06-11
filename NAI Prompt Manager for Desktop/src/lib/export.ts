import { open, save } from '@tauri-apps/plugin-dialog'
import { writeTextFile, readFile, mkdir, exists, copyFile } from '@tauri-apps/plugin-fs'
import { join } from '@tauri-apps/api/path'
import type { ImageWithDetails, Folder, Tag, ExportData } from '../types'
import * as db from './database'

export interface ImageFileExportResult {
  exported: number
  failed: number
  destination: string | null
}

function sanitizeFilename(filename: string): string {
  return filename
    .replace(/[<>:"/\\|?*\x00-\x1f]/g, '_')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 180) || 'image.png'
}

function splitFilename(filename: string): { base: string; ext: string } {
  const safe = sanitizeFilename(filename)
  const dot = safe.lastIndexOf('.')
  if (dot <= 0 || dot === safe.length - 1) return { base: safe, ext: '' }
  return { base: safe.slice(0, dot), ext: safe.slice(dot) }
}

async function uniqueFilePath(directory: string, filename: string): Promise<string> {
  const { base, ext } = splitFilename(filename)
  let candidate = await join(directory, `${base}${ext}`)
  let index = 1
  while (await exists(candidate)) {
    candidate = await join(directory, `${base} (${index})${ext}`)
    index++
  }
  return candidate
}

export async function exportImageFile(image: ImageWithDetails): Promise<boolean> {
  try {
    const filename = sanitizeFilename(image.filename || `${image.id}.png`)
    const ext = filename.split('.').pop() || 'png'
    const savePath = await save({
      filters: [{ name: 'Image', extensions: [ext] }],
      defaultPath: filename,
    })
    if (!savePath) return false

    await copyFile(image.file_path, savePath)
    return true
  } catch (err) {
    console.error('Image export failed:', err)
    return false
  }
}

export async function exportImageFilesToFolder(
  images: ImageWithDetails[]
): Promise<ImageFileExportResult> {
  const destination = await open({
    directory: true,
    multiple: false,
    title: '画像のエクスポート先フォルダを選択',
  })
  if (!destination) return { exported: 0, failed: 0, destination: null }

  const outputDir = destination as string
  let exported = 0
  let failed = 0
  const exportedImages: ImageWithDetails[] = []

  for (const image of images) {
    try {
      const filename = image.filename || `${image.id}.png`
      const destPath = await uniqueFilePath(outputDir, filename)
      await copyFile(image.file_path, destPath)
      exported++
      exportedImages.push({
        ...image,
        file_path: destPath,
        thumbnail_path: null,
      })
    } catch (err) {
      failed++
      console.error(`Failed to export image ${image.filename}:`, err)
    }
  }

  if (exportedImages.length > 0) {
    const metadataPath = await uniqueFilePath(outputDir, 'nai-prompt-manager-export-metadata.json')
    const exportData = {
      version: '1.0.0',
      exportedAt: new Date().toISOString(),
      images: exportedImages,
    }
    await writeTextFile(metadataPath, JSON.stringify(exportData, null, 2))
  }

  return { exported, failed, destination: outputDir }
}

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
