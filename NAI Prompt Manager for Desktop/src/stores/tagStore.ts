import { create } from 'zustand'
import type { Tag } from '../types'
import * as db from '../lib/database'
import { notifyTagDeleted, notifyTagSynced } from '../lib/icloud-sync'

interface TagState {
  tags: Tag[]
  loading: boolean
  error: string | null

  loadTags: () => Promise<void>
  createTag: (name: string, color?: string) => Promise<Tag>
  updateTag: (id: string, updates: Partial<Tag>) => Promise<void>
  deleteTag: (id: string) => Promise<void>
}

export const useTagStore = create<TagState>((set, get) => ({
  tags: [],
  loading: false,
  error: null,

  loadTags: async () => {
    set({ loading: true, error: null })
    try {
      const tags = await db.getAllTags()
      set({ tags, loading: false })
    } catch (err) {
      console.error('Failed to load tags:', err)
      set({
        error: err instanceof Error ? err.message : 'タグの読み込みに失敗しました',
        loading: false,
      })
    }
  },

  createTag: async (name, color = '#a78bfa') => {
    try {
      const tag = await db.createTag(name, color)
      set((state) => ({ tags: [...state.tags, tag] }))
      void notifyTagSynced(tag, 'create')
      return tag
    } catch (err) {
      console.error('Failed to create tag:', err)
      throw err
    }
  },

  updateTag: async (id, updates) => {
    try {
      await db.updateTag(id, updates)
      const updated = get().tags.find((t) => t.id === id)
      set((state) => ({
        tags: state.tags.map((t) => (t.id === id ? { ...t, ...updates } : t)),
      }))
      if (updated) void notifyTagSynced({ ...updated, ...updates })
    } catch (err) {
      console.error('Failed to update tag:', err)
      throw err
    }
  },

  deleteTag: async (id) => {
    try {
      await db.deleteTag(id)
      set((state) => ({ tags: state.tags.filter((t) => t.id !== id) }))
      void notifyTagDeleted(id)
    } catch (err) {
      console.error('Failed to delete tag:', err)
      throw err
    }
  },
}))
