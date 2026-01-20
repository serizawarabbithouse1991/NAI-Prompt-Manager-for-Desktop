import { create } from 'zustand'
import * as db from '../lib/database'
import { supabase, STORAGE_BUCKETS, uploadFile, deleteFile } from '../lib/supabase'
import type { ImageWithDetails, FilterOptions, Prompt } from '../types'
import { parsePngMetadata } from '../lib/png-metadata'

interface ImageState {
  images: ImageWithDetails[]
  loading: boolean
  error: string | null
  
  fetchImages: (filters?: FilterOptions) => Promise<void>
  uploadImage: (file: File, folderId?: string | null) => Promise<void>
  deleteImage: (imageId: string) => Promise<void>
  deleteImages: (imageIds: string[]) => Promise<void>
  updateImageRating: (imageId: string, isFavorite: boolean) => Promise<void>
  moveToFolder: (imageIds: string[], folderId: string | null) => Promise<void>
}

export const useImageStore = create<ImageState>((set, get) => ({
  images: [],
  loading: false,
  error: null,

  fetchImages: async (filters?: FilterOptions) => {
    set({ loading: true, error: null })
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      const images = await db.getAllImages(user.id, filters)
      set({ images, loading: false })
    } catch (error) {
      console.error('Failed to fetch images:', error)
      set({ 
        error: error instanceof Error ? error.message : '画像の取得に失敗しました',
        loading: false 
      })
    }
  },

  uploadImage: async (file: File, folderId?: string | null) => {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      // Parse PNG metadata
      let promptData: Partial<Prompt> = {}
      let width: number | undefined
      let height: number | undefined

      try {
        const metadata = await parsePngMetadata(file)
        if (metadata) {
          promptData = {
            positive_prompt: metadata.positivePrompt,
            negative_prompt: metadata.negativePrompt,
            model: metadata.model,
            sampler: metadata.sampler,
            steps: metadata.steps,
            cfg_scale: metadata.cfgScale,
            seed: metadata.seed,
            resolution_width: metadata.width,
            resolution_height: metadata.height,
            noise_schedule: metadata.noiseSchedule,
            raw_metadata: metadata.rawMetadata,
            source_type: 'nai',
          }
          width = metadata.width ?? undefined
          height = metadata.height ?? undefined
        }
      } catch (e) {
        console.warn('Failed to parse PNG metadata:', e)
      }

      // Get image dimensions if not from metadata
      if (!width || !height) {
        const img = new Image()
        const url = URL.createObjectURL(file)
        await new Promise<void>((resolve) => {
          img.onload = () => {
            width = img.width
            height = img.height
            URL.revokeObjectURL(url)
            resolve()
          }
          img.src = url
        })
      }

      // Upload to storage
      const fileExt = file.name.split('.').pop() || 'png'
      const fileName = `${crypto.randomUUID()}.${fileExt}`
      const storagePath = `${user.id}/${fileName}`

      const uploadResult = await uploadFile(STORAGE_BUCKETS.IMAGES, storagePath, file, {
        contentType: file.type,
      })

      if (!uploadResult) {
        throw new Error('Failed to upload file')
      }

      // Create database record
      await db.createImage(
        user.id,
        {
          folder_id: folderId ?? null,
          storage_path: storagePath,
          thumbnail_path: storagePath, // Use same path for now
          filename: file.name,
          width: width ?? null,
          height: height ?? null,
          file_size: file.size,
          file_hash: null,
          is_nsfw: false,
          nsfw_score: null,
          nsfw_category: null,
        },
        Object.keys(promptData).length > 0 ? promptData as Omit<Prompt, 'id' | 'user_id' | 'image_id' | 'created_at'> : null
      )

      // Refresh images
      await get().fetchImages()
    } catch (error) {
      console.error('Failed to upload image:', error)
      throw error
    }
  },

  deleteImage: async (imageId: string) => {
    try {
      const image = get().images.find(img => img.id === imageId)
      if (image) {
        // Delete from storage
        await deleteFile(STORAGE_BUCKETS.IMAGES, [image.storage_path])
        if (image.thumbnail_path && image.thumbnail_path !== image.storage_path) {
          await deleteFile(STORAGE_BUCKETS.THUMBNAILS, [image.thumbnail_path])
        }
      }

      await db.deleteImage(imageId)
      
      // Update local state
      set(state => ({
        images: state.images.filter(img => img.id !== imageId)
      }))
    } catch (error) {
      console.error('Failed to delete image:', error)
      throw error
    }
  },

  deleteImages: async (imageIds: string[]) => {
    try {
      const images = get().images.filter(img => imageIds.includes(img.id))
      
      // Delete from storage
      for (const image of images) {
        await deleteFile(STORAGE_BUCKETS.IMAGES, [image.storage_path])
        if (image.thumbnail_path && image.thumbnail_path !== image.storage_path) {
          await deleteFile(STORAGE_BUCKETS.THUMBNAILS, [image.thumbnail_path])
        }
      }

      await db.deleteImages(imageIds)
      
      // Update local state
      set(state => ({
        images: state.images.filter(img => !imageIds.includes(img.id))
      }))
    } catch (error) {
      console.error('Failed to delete images:', error)
      throw error
    }
  },

  updateImageRating: async (imageId: string, isFavorite: boolean) => {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      await db.updateImageRating(user.id, imageId, { is_favorite: isFavorite })
      
      // Update local state
      set(state => ({
        images: state.images.map(img =>
          img.id === imageId
            ? { ...img, rating: { ...img.rating, image_id: imageId, user_id: user.id, is_favorite: isFavorite, rating: img.rating?.rating ?? null } }
            : img
        )
      }))
    } catch (error) {
      console.error('Failed to update rating:', error)
      throw error
    }
  },

  moveToFolder: async (imageIds: string[], folderId: string | null) => {
    try {
      await db.moveImagesToFolder(imageIds, folderId)
      
      // Update local state
      set(state => ({
        images: state.images.map(img =>
          imageIds.includes(img.id)
            ? { ...img, folder_id: folderId }
            : img
        )
      }))
    } catch (error) {
      console.error('Failed to move images:', error)
      throw error
    }
  },
}))
