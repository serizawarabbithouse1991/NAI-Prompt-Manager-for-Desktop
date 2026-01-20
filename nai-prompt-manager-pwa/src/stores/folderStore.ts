import { create } from 'zustand'
import * as db from '../lib/database'
import { supabase } from '../lib/supabase'
import type { Folder, FolderWithChildren } from '../types'

interface FolderState {
  folders: Folder[]
  folderTree: FolderWithChildren[]
  loading: boolean
  error: string | null
  
  fetchFolders: () => Promise<void>
  createFolder: (name: string, parentId?: string | null, color?: string) => Promise<Folder>
  updateFolder: (folderId: string, updates: Partial<Folder>) => Promise<void>
  deleteFolder: (folderId: string) => Promise<void>
}

function buildFolderTree(folders: Folder[]): FolderWithChildren[] {
  const map = new Map<string, FolderWithChildren>()
  const roots: FolderWithChildren[] = []

  // Create FolderWithChildren objects
  for (const folder of folders) {
    map.set(folder.id, { ...folder, children: [] })
  }

  // Build tree structure
  for (const folder of folders) {
    const node = map.get(folder.id)!
    if (folder.parent_id && map.has(folder.parent_id)) {
      map.get(folder.parent_id)!.children.push(node)
    } else {
      roots.push(node)
    }
  }

  return roots
}

export const useFolderStore = create<FolderState>((set, get) => ({
  folders: [],
  folderTree: [],
  loading: false,
  error: null,

  fetchFolders: async () => {
    set({ loading: true, error: null })
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      const folders = await db.getAllFolders(user.id)
      const folderTree = buildFolderTree(folders)
      set({ folders, folderTree, loading: false })
    } catch (error) {
      console.error('Failed to fetch folders:', error)
      set({ 
        error: error instanceof Error ? error.message : 'フォルダの取得に失敗しました',
        loading: false 
      })
    }
  },

  createFolder: async (name: string, parentId?: string | null, color?: string) => {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      const folder = await db.createFolder(user.id, name, parentId ?? null, color)
      
      // Update local state
      const folders = [...get().folders, folder]
      const folderTree = buildFolderTree(folders)
      set({ folders, folderTree })

      return folder
    } catch (error) {
      console.error('Failed to create folder:', error)
      throw error
    }
  },

  updateFolder: async (folderId: string, updates: Partial<Folder>) => {
    try {
      await db.updateFolder(folderId, updates)
      
      // Update local state
      const folders = get().folders.map(f =>
        f.id === folderId ? { ...f, ...updates } : f
      )
      const folderTree = buildFolderTree(folders)
      set({ folders, folderTree })
    } catch (error) {
      console.error('Failed to update folder:', error)
      throw error
    }
  },

  deleteFolder: async (folderId: string) => {
    try {
      await db.deleteFolder(folderId)
      
      // Update local state
      const folders = get().folders.filter(f => f.id !== folderId)
      const folderTree = buildFolderTree(folders)
      set({ folders, folderTree })
    } catch (error) {
      console.error('Failed to delete folder:', error)
      throw error
    }
  },
}))
