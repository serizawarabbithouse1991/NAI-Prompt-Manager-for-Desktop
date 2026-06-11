import { create } from 'zustand'
import { appDataDir, join } from '@tauri-apps/api/path'
import { readFile, writeFile, mkdir, exists } from '@tauri-apps/plugin-fs'
import type { ImageWithDetails, Image, Prompt, Tag } from '../types'
import * as db from '../lib/database'
import {
  notifyImageDeleted,
  notifyImageSynced,
  notifyImagesSynced,
} from '../lib/icloud-sync'
import { generateThumbnailBytes, DEFAULT_THUMBNAIL_MAX_EDGE } from '../lib/thumbnail'

// Guard so the background backfill never runs more than once at a time.
let backfillInProgress = false

interface ImageState {
  // Data
  images: ImageWithDetails[]
  loading: boolean
  error: string | null

  // Actions
  loadImages: () => Promise<void>
  addImage: (image: Image, prompt?: Prompt | null) => void
  addImages: (entries: { image: Image; prompt?: Prompt | null; tags?: Tag[] }[]) => void
  updateImage: (id: string, updates: Partial<Image>) => void
  deleteImage: (id: string) => Promise<void>
  deleteImages: (ids: string[]) => Promise<void>

  // Tags
  addTagToImage: (imageId: string, tag: Tag) => Promise<void>
  addTagToImages: (imageIds: string[], tag: Tag) => Promise<void>
  removeTagFromImage: (imageId: string, tagId: string) => Promise<void>

  // Thumbnails
  backfillThumbnails: (maxEdge?: number) => Promise<void>

  // Favorites
  toggleFavorite: (imageId: string) => Promise<void>

  // Prompt
  updatePrompt: (imageId: string, prompt: Partial<Prompt>) => Promise<void>

  // Folder
  moveToFolder: (imageIds: string[], folderId: string | null) => Promise<void>
}

export const useImageStore = create<ImageState>((set, get) => ({
  images: [],
  loading: false,
  error: null,

  loadImages: async () => {
    set({ loading: true, error: null })
    try {
      // Defense-in-depth: a stuck SQL/IPC call must never leave the gallery
      // spinning on "読み込み中..." forever. If the query doesn't resolve in
      // time, surface an error instead of hanging the dashboard indefinitely.
      const TIMEOUT_MS = 20000
      const images = await Promise.race([
        db.getAllImages(),
        new Promise<never>((_, reject) =>
          setTimeout(() => reject(new Error('画像の読み込みがタイムアウトしました')), TIMEOUT_MS)
        ),
      ])
      set({ images, loading: false })
    } catch (err) {
      console.error('Failed to load images:', err)
      set({
        error: err instanceof Error ? err.message : '画像の読み込みに失敗しました',
        loading: false
      })
    }
  },

  addImage: (image, prompt = null) => {
    const newImage: ImageWithDetails = {
      ...image,
      prompt,
      tags: [],
      rating: null,
    }
    set((state) => ({ images: [newImage, ...state.images] }))
  },

  addImages: (entries: { image: Image; prompt?: Prompt | null; tags?: Tag[] }[]) => {
    if (entries.length === 0) return
    const newImages: ImageWithDetails[] = entries.map(({ image, prompt = null, tags = [] }) => ({
      ...image,
      prompt: prompt ?? null,
      tags,
      rating: null,
    }))
    set((state) => ({ images: [...newImages, ...state.images] }))
    void notifyImagesSynced(newImages)
  },

  backfillThumbnails: async (maxEdge = DEFAULT_THUMBNAIL_MAX_EDGE) => {
    if (backfillInProgress) return
    const targets = get().images.filter((i) => !i.thumbnail_path && !i.deleted_at)
    if (targets.length === 0) return

    backfillInProgress = true
    try {
      const dataDir = await appDataDir()
      const thumbnailsDir = await join(dataDir, 'thumbnails')
      if (!(await exists(thumbnailsDir))) await mkdir(thumbnailsDir, { recursive: true })

      for (const img of targets) {
        // Image may have been deleted while we were working; skip if so.
        if (!get().images.some((i) => i.id === img.id)) continue
        try {
          const bytes = new Uint8Array(await readFile(img.file_path))
          const ext = img.filename?.split('.').pop() || 'png'
          const thumb = await generateThumbnailBytes(bytes, ext, maxEdge)
          if (thumb) {
            const dest = await join(thumbnailsDir, `${img.id}.webp`)
            await writeFile(dest, thumb)
            await db.updateImage(img.id, { thumbnail_path: dest })
            set((state) => ({
              images: state.images.map((i) =>
                i.id === img.id ? { ...i, thumbnail_path: dest } : i
              ),
            }))
          }
        } catch (err) {
          console.error('Backfill thumbnail failed for', img.id, err)
        }
        // Yield to the UI between images so the app stays responsive.
        await new Promise((r) => setTimeout(r, 0))
      }
    } finally {
      backfillInProgress = false
    }
  },

  updateImage: (id, updates) => {
    set((state) => ({
      images: state.images.map((img) =>
        img.id === id ? { ...img, ...updates } : img
      ),
    }))
  },

  deleteImage: async (id) => {
    try {
      await db.deleteImage(id)
      set((state) => ({
        images: state.images.filter((img) => img.id !== id),
      }))
      void notifyImageDeleted(id)
    } catch (err) {
      console.error('Failed to delete image:', err)
      throw err
    }
  },

  deleteImages: async (ids) => {
    try {
      await db.deleteImages(ids)
      set((state) => ({
        images: state.images.filter((img) => !ids.includes(img.id)),
      }))
      for (const id of ids) void notifyImageDeleted(id)
    } catch (err) {
      console.error('Failed to delete images:', err)
      throw err
    }
  },

  addTagToImage: async (imageId, tag) => {
    try {
      await db.addTagToImage(imageId, tag.id)
      const updated = get().images.find((img) => img.id === imageId)
      set((state) => ({
        images: state.images.map((img) =>
          img.id === imageId
            ? { ...img, tags: [...img.tags, tag] }
            : img
        ),
      }))
      if (updated) {
        void notifyImageSynced({ ...updated, tags: [...updated.tags, tag] })
      }
    } catch (err) {
      console.error('Failed to add tag:', err)
      throw err
    }
  },

  addTagToImages: async (imageIds, tag) => {
    if (imageIds.length === 0) return
    try {
      await db.addTagToImages(imageIds, tag.id)
      const idSet = new Set(imageIds)
      const toSync = get().images.filter(
        (img) => idSet.has(img.id) && !img.tags.some((t) => t.id === tag.id)
      )
      set((state) => ({
        images: state.images.map((img) =>
          idSet.has(img.id) && !img.tags.some((t) => t.id === tag.id)
            ? { ...img, tags: [...img.tags, tag] }
            : img
        ),
      }))
      void notifyImagesSynced(toSync.map((img) => ({ ...img, tags: [...img.tags, tag] })))
    } catch (err) {
      console.error('Failed to add tag to images:', err)
      throw err
    }
  },

  removeTagFromImage: async (imageId, tagId) => {
    try {
      await db.removeTagFromImage(imageId, tagId)
      const updated = get().images.find((img) => img.id === imageId)
      set((state) => ({
        images: state.images.map((img) =>
          img.id === imageId
            ? { ...img, tags: img.tags.filter((t) => t.id !== tagId) }
            : img
        ),
      }))
      if (updated) {
        void notifyImageSynced({ ...updated, tags: updated.tags.filter((t) => t.id !== tagId) })
      }
    } catch (err) {
      console.error('Failed to remove tag:', err)
      throw err
    }
  },

  toggleFavorite: async (imageId) => {
    const image = get().images.find((img) => img.id === imageId)
    if (!image) return

    const newFavorite = !image.rating?.is_favorite
    try {
      await db.updateImageRating(imageId, { is_favorite: newFavorite })
      const rating = {
        image_id: imageId,
        is_favorite: newFavorite,
        rating: image.rating?.rating ?? null,
      }
      set((state) => ({
        images: state.images.map((img) =>
          img.id === imageId ? { ...img, rating } : img
        ),
      }))
      void notifyImageSynced({ ...image, rating })
    } catch (err) {
      console.error('Failed to toggle favorite:', err)
      throw err
    }
  },

  updatePrompt: async (imageId, promptData) => {
    try {
      await db.updatePrompt(imageId, promptData)
      const current = get().images.find((img) => img.id === imageId)
      set((state) => ({
        images: state.images.map((img) =>
          img.id === imageId
            ? { ...img, prompt: img.prompt ? { ...img.prompt, ...promptData } : null }
            : img
        ),
      }))
      if (current) {
        void notifyImageSynced({
          ...current,
          prompt: current.prompt ? { ...current.prompt, ...promptData } : null,
        })
      }
    } catch (err) {
      console.error('Failed to update prompt:', err)
      throw err
    }
  },

  moveToFolder: async (imageIds, folderId) => {
    try {
      await db.moveImagesToFolder(imageIds, folderId)
      const toSync = get().images
        .filter((img) => imageIds.includes(img.id))
        .map((img) => ({ ...img, folder_id: folderId }))
      set((state) => ({
        images: state.images.map((img) =>
          imageIds.includes(img.id)
            ? { ...img, folder_id: folderId }
            : img
        ),
      }))
      void notifyImagesSynced(toSync)
    } catch (err) {
      console.error('Failed to move images:', err)
      throw err
    }
  },
}))
