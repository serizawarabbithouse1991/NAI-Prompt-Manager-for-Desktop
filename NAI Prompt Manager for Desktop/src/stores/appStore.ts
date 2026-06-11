import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { ViewOptions, FilterOptions, AppSettings } from '../types'

interface AppState {
  // UI State
  sidebarOpen: boolean
  setSidebarOpen: (open: boolean) => void
  toggleSidebar: () => void

  // View Options
  viewOptions: ViewOptions
  setViewMode: (mode: ViewOptions['mode']) => void
  setThumbnailSize: (size: ViewOptions['thumbnailSize']) => void
  setSortBy: (sortBy: ViewOptions['sortBy']) => void
  setSortOrder: (order: ViewOptions['sortOrder']) => void

  // Filter Options
  filterOptions: FilterOptions
  setSearchQuery: (query: string) => void
  setFolderId: (id: string | null) => void
  setTagIds: (ids: string[]) => void
  toggleTagId: (id: string) => void
  setFavoritesOnly: (only: boolean) => void
  clearFilters: () => void

  // Settings
  settings: AppSettings
  updateSettings: (settings: Partial<AppSettings>) => void

  // Selection
  selectedImageIds: Set<string>
  toggleImageSelection: (id: string) => void
  selectAll: (ids: string[]) => void
  clearSelection: () => void
  batchMode: boolean
  setBatchMode: (mode: boolean) => void
}

const defaultViewOptions: ViewOptions = {
  mode: 'grid',
  thumbnailSize: 'medium',
  sortBy: 'date',
  sortOrder: 'desc',
}

const defaultFilterOptions: FilterOptions = {
  searchQuery: '',
  folderId: null,
  tagIds: [],
  favoritesOnly: false,
}

const defaultSettings: AppSettings = {
  imageStoragePath: '',
  thumbnailSize: 256,
  autoBackupEnabled: false,
  backupPath: null,
  theme: 'dark',
  language: 'ja',
  danbooruDbPath: '',
  danbooruAutoTagEnabled: false,
  danbooruAllowedTagTypes: [0, 1, 3, 4, 5],
  danbooruMaxTagsPerImage: 80,
  danbooruMinPopularity: 0,
  importMirrorEnabled: true,
  importMirrorPath: 'C:\\Users\\rt032\\iCloudDrive\\NovelAI',
  icloudSyncEnabled: false,
  icloudSyncPath: 'C:\\Users\\rt032\\iCloudDrive\\NAI-Prompt-Manager',
  icloudSyncDeviceId: '',
  icloudSyncLastSyncedAt: null,
}

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      // UI State
      sidebarOpen: true,
      setSidebarOpen: (open) => set({ sidebarOpen: open }),
      toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),

      // View Options
      viewOptions: defaultViewOptions,
      setViewMode: (mode) =>
        set((state) => ({ viewOptions: { ...state.viewOptions, mode } })),
      setThumbnailSize: (thumbnailSize) =>
        set((state) => ({ viewOptions: { ...state.viewOptions, thumbnailSize } })),
      setSortBy: (sortBy) =>
        set((state) => ({ viewOptions: { ...state.viewOptions, sortBy } })),
      setSortOrder: (sortOrder) =>
        set((state) => ({ viewOptions: { ...state.viewOptions, sortOrder } })),

      // Filter Options
      filterOptions: defaultFilterOptions,
      setSearchQuery: (searchQuery) =>
        set((state) => ({ filterOptions: { ...state.filterOptions, searchQuery } })),
      setFolderId: (folderId) =>
        set((state) => ({ filterOptions: { ...state.filterOptions, folderId } })),
      setTagIds: (tagIds) =>
        set((state) => ({ filterOptions: { ...state.filterOptions, tagIds } })),
      toggleTagId: (id) =>
        set((state) => {
          const tagIds = state.filterOptions.tagIds.includes(id)
            ? state.filterOptions.tagIds.filter((t) => t !== id)
            : [...state.filterOptions.tagIds, id]
          return { filterOptions: { ...state.filterOptions, tagIds } }
        }),
      setFavoritesOnly: (favoritesOnly) =>
        set((state) => ({ filterOptions: { ...state.filterOptions, favoritesOnly } })),
      clearFilters: () => set({ filterOptions: defaultFilterOptions }),

      // Settings
      settings: defaultSettings,
      updateSettings: (newSettings) =>
        set((state) => ({ settings: { ...state.settings, ...newSettings } })),

      // Selection
      selectedImageIds: new Set(),
      toggleImageSelection: (id) =>
        set((state) => {
          const newSet = new Set(state.selectedImageIds)
          if (newSet.has(id)) {
            newSet.delete(id)
          } else {
            newSet.add(id)
          }
          return { selectedImageIds: newSet }
        }),
      selectAll: (ids) => set({ selectedImageIds: new Set(ids) }),
      clearSelection: () => set({ selectedImageIds: new Set() }),
      batchMode: false,
      setBatchMode: (mode) =>
        set({ batchMode: mode, selectedImageIds: mode ? new Set() : new Set() }),
    }),
    {
      name: 'nai-prompt-manager-storage',
      partialize: (state) => ({
        sidebarOpen: state.sidebarOpen,
        viewOptions: state.viewOptions,
        settings: state.settings,
      }),
      merge: (persisted, current) => {
        const persistedState = persisted as Partial<AppState> | undefined
        return {
          ...current,
          ...persistedState,
          settings: {
            ...current.settings,
            ...persistedState?.settings,
          },
        }
      },
    }
  )
)
