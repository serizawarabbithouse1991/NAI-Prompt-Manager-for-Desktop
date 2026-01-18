import { create } from 'zustand'
import type { Folder, FolderWithChildren } from '../types'
import * as db from '../lib/database'

interface FolderState {
  folders: Folder[]
  folderTree: FolderWithChildren[]
  loading: boolean
  error: string | null

  loadFolders: () => Promise<void>
  createFolder: (name: string, parentId?: string | null, color?: string) => Promise<Folder>
  updateFolder: (id: string, updates: Partial<Folder>) => Promise<void>
  deleteFolder: (id: string) => Promise<void>
  reorderFolders: (folderId: string, newOrder: number) => Promise<void>
}

function buildFolderTree(folders: Folder[]): FolderWithChildren[] {
  const folderMap = new Map<string, FolderWithChildren>()
  const rootFolders: FolderWithChildren[] = []

  // Create folder objects with children arrays
  folders.forEach((folder) => {
    folderMap.set(folder.id, { ...folder, children: [] })
  })

  // Build tree structure
  folders.forEach((folder) => {
    const folderWithChildren = folderMap.get(folder.id)!
    if (folder.parent_id) {
      const parent = folderMap.get(folder.parent_id)
      if (parent) {
        parent.children.push(folderWithChildren)
      } else {
        rootFolders.push(folderWithChildren)
      }
    } else {
      rootFolders.push(folderWithChildren)
    }
  })

  // Sort by sort_order
  const sortFolders = (folders: FolderWithChildren[]) => {
    folders.sort((a, b) => a.sort_order - b.sort_order)
    folders.forEach((folder) => sortFolders(folder.children))
  }
  sortFolders(rootFolders)

  return rootFolders
}

export const useFolderStore = create<FolderState>((set, get) => ({
  folders: [],
  folderTree: [],
  loading: false,
  error: null,

  loadFolders: async () => {
    set({ loading: true, error: null })
    try {
      const folders = await db.getAllFolders()
      const folderTree = buildFolderTree(folders)
      set({ folders, folderTree, loading: false })
    } catch (err) {
      console.error('Failed to load folders:', err)
      set({
        error: err instanceof Error ? err.message : 'フォルダの読み込みに失敗しました',
        loading: false,
      })
    }
  },

  createFolder: async (name, parentId = null, color) => {
    try {
      const folder = await db.createFolder(name, parentId, color)
      const folders = [...get().folders, folder]
      const folderTree = buildFolderTree(folders)
      set({ folders, folderTree })
      return folder
    } catch (err) {
      console.error('Failed to create folder:', err)
      throw err
    }
  },

  updateFolder: async (id, updates) => {
    try {
      await db.updateFolder(id, updates)
      const folders = get().folders.map((f) =>
        f.id === id ? { ...f, ...updates } : f
      )
      const folderTree = buildFolderTree(folders)
      set({ folders, folderTree })
    } catch (err) {
      console.error('Failed to update folder:', err)
      throw err
    }
  },

  deleteFolder: async (id) => {
    try {
      await db.deleteFolder(id)
      const folders = get().folders.filter((f) => f.id !== id)
      const folderTree = buildFolderTree(folders)
      set({ folders, folderTree })
    } catch (err) {
      console.error('Failed to delete folder:', err)
      throw err
    }
  },

  reorderFolders: async (folderId, newOrder) => {
    try {
      await db.updateFolder(folderId, { sort_order: newOrder })
      const folders = get().folders.map((f) =>
        f.id === folderId ? { ...f, sort_order: newOrder } : f
      )
      const folderTree = buildFolderTree(folders)
      set({ folders, folderTree })
    } catch (err) {
      console.error('Failed to reorder folders:', err)
      throw err
    }
  },
}))
