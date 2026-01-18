import { create } from 'zustand'
import type { ImageWithDetails, Image, Prompt, Tag } from '../types'
import * as db from '../lib/database'

interface ImageState {
  // Data
  images: ImageWithDetails[]
  loading: boolean
  error: string | null

  // Actions
  loadImages: () => Promise<void>
  addImage: (image: Image, prompt?: Prompt | null) => void
  updateImage: (id: string, updates: Partial<Image>) => void
  deleteImage: (id: string) => Promise<void>
  deleteImages: (ids: string[]) => Promise<void>

  // Tags
  addTagToImage: (imageId: string, tag: Tag) => Promise<void>
  removeTagFromImage: (imageId: string, tagId: string) => Promise<void>

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
      const images = await db.getAllImages()
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
    } catch (err) {
      console.error('Failed to delete images:', err)
      throw err
    }
  },

  addTagToImage: async (imageId, tag) => {
    try {
      await db.addTagToImage(imageId, tag.id)
      set((state) => ({
        images: state.images.map((img) =>
          img.id === imageId
            ? { ...img, tags: [...img.tags, tag] }
            : img
        ),
      }))
    } catch (err) {
      console.error('Failed to add tag:', err)
      throw err
    }
  },

  removeTagFromImage: async (imageId, tagId) => {
    try {
      await db.removeTagFromImage(imageId, tagId)
      set((state) => ({
        images: state.images.map((img) =>
          img.id === imageId
            ? { ...img, tags: img.tags.filter((t) => t.id !== tagId) }
            : img
        ),
      }))
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
      set((state) => ({
        images: state.images.map((img) =>
          img.id === imageId
            ? {
                ...img,
                rating: {
                  image_id: imageId,
                  is_favorite: newFavorite,
                  rating: img.rating?.rating ?? null,
                },
              }
            : img
        ),
      }))
    } catch (err) {
      console.error('Failed to toggle favorite:', err)
      throw err
    }
  },

  updatePrompt: async (imageId, promptData) => {
    try {
      await db.updatePrompt(imageId, promptData)
      set((state) => ({
        images: state.images.map((img) =>
          img.id === imageId
            ? { ...img, prompt: img.prompt ? { ...img.prompt, ...promptData } : null }
            : img
        ),
      }))
    } catch (err) {
      console.error('Failed to update prompt:', err)
      throw err
    }
  },

  moveToFolder: async (imageIds, folderId) => {
    try {
      await db.moveImagesToFolder(imageIds, folderId)
      set((state) => ({
        images: state.images.map((img) =>
          imageIds.includes(img.id)
            ? { ...img, folder_id: folderId }
            : img
        ),
      }))
    } catch (err) {
      console.error('Failed to move images:', err)
      throw err
    }
  },
}))
