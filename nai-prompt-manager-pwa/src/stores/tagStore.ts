import { create } from 'zustand'
import * as db from '../lib/database'
import { supabase } from '../lib/supabase'
import type { Tag } from '../types'

interface TagState {
  tags: Tag[]
  loading: boolean
  error: string | null
  
  fetchTags: () => Promise<void>
  createTag: (name: string, color?: string) => Promise<Tag>
  updateTag: (tagId: string, updates: Partial<Tag>) => Promise<void>
  deleteTag: (tagId: string) => Promise<void>
  addTagToImage: (imageId: string, tagId: string) => Promise<void>
  removeTagFromImage: (imageId: string, tagId: string) => Promise<void>
}

export const useTagStore = create<TagState>((set) => ({
  tags: [],
  loading: false,
  error: null,

  fetchTags: async () => {
    set({ loading: true, error: null })
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      const tags = await db.getAllTags(user.id)
      set({ tags, loading: false })
    } catch (error) {
      console.error('Failed to fetch tags:', error)
      set({ 
        error: error instanceof Error ? error.message : 'タグの取得に失敗しました',
        loading: false 
      })
    }
  },

  createTag: async (name: string, color?: string) => {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      const tag = await db.createTag(user.id, name, color)
      
      // Update local state
      set(state => ({ tags: [...state.tags, tag] }))

      return tag
    } catch (error) {
      console.error('Failed to create tag:', error)
      throw error
    }
  },

  updateTag: async (tagId: string, updates: Partial<Tag>) => {
    try {
      await db.updateTag(tagId, updates)
      
      // Update local state
      set(state => ({
        tags: state.tags.map(t =>
          t.id === tagId ? { ...t, ...updates } : t
        )
      }))
    } catch (error) {
      console.error('Failed to update tag:', error)
      throw error
    }
  },

  deleteTag: async (tagId: string) => {
    try {
      await db.deleteTag(tagId)
      
      // Update local state
      set(state => ({
        tags: state.tags.filter(t => t.id !== tagId)
      }))
    } catch (error) {
      console.error('Failed to delete tag:', error)
      throw error
    }
  },

  addTagToImage: async (imageId: string, tagId: string) => {
    try {
      await db.addTagToImage(imageId, tagId)
    } catch (error) {
      console.error('Failed to add tag to image:', error)
      throw error
    }
  },

  removeTagFromImage: async (imageId: string, tagId: string) => {
    try {
      await db.removeTagFromImage(imageId, tagId)
    } catch (error) {
      console.error('Failed to remove tag from image:', error)
      throw error
    }
  },
}))
