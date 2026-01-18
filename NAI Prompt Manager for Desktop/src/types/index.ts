// ============================================
// Database Types
// ============================================

export interface Folder {
  id: string
  parent_id: string | null
  name: string
  color: string | null
  sort_order: number
  created_at: string
}

export interface FolderWithChildren extends Folder {
  children: FolderWithChildren[]
  image_count?: number
}

export interface Image {
  id: string
  folder_id: string | null
  file_path: string
  thumbnail_path: string | null
  filename: string | null
  width: number | null
  height: number | null
  file_size: number | null
  file_hash: string | null
  deleted_at: string | null
  created_at: string
}

export interface Prompt {
  id: string
  image_id: string
  positive_prompt: string | null
  negative_prompt: string | null
  model: string | null
  sampler: string | null
  steps: number | null
  cfg_scale: number | null
  seed: number | null
  resolution_width: number | null
  resolution_height: number | null
  noise_schedule: string | null
  prompt_guidance_rescale: number | null
  notes: string | null
  raw_metadata: string | null
  created_at: string
}

export interface Tag {
  id: string
  name: string
  color: string | null
  created_at: string
}

export interface ImageTag {
  image_id: string
  tag_id: string
}

export interface ImageRating {
  image_id: string
  is_favorite: boolean
  rating: number | null
}

// ============================================
// Combined Types
// ============================================

export interface ImageWithDetails extends Image {
  prompt: Prompt | null
  tags: Tag[]
  rating: ImageRating | null
}

// ============================================
// UI Types
// ============================================

export type ViewMode = 'grid' | 'list'
export type ThumbnailSize = 'small' | 'medium' | 'large' | 'xlarge'
export type SortBy = 'date' | 'name' | 'size'
export type SortOrder = 'asc' | 'desc'

export interface ViewOptions {
  mode: ViewMode
  thumbnailSize: ThumbnailSize
  sortBy: SortBy
  sortOrder: SortOrder
}

export interface FilterOptions {
  searchQuery: string
  folderId: string | null
  tagIds: string[]
  favoritesOnly: boolean
}

// ============================================
// PNG Metadata Types
// ============================================

export interface NovelAIComment {
  prompt?: string
  steps?: number
  height?: number
  width?: number
  scale?: number
  uncond_scale?: number
  cfg_rescale?: number
  seed?: number
  n_samples?: number
  noise_schedule?: string
  sampler?: string
  sm?: boolean
  sm_dyn?: boolean
  dynamic_thresholding?: boolean
  uc?: string
  uncond?: string
  [key: string]: unknown
}

export interface ParsedPromptData {
  positivePrompt: string | null
  negativePrompt: string | null
  model: string | null
  sampler: string | null
  steps: number | null
  cfgScale: number | null
  seed: number | null
  width: number | null
  height: number | null
  noiseSchedule: string | null
  rawMetadata: Record<string, string>
}

// ============================================
// Settings Types
// ============================================

export interface AppSettings {
  imageStoragePath: string
  thumbnailSize: number
  autoBackupEnabled: boolean
  backupPath: string | null
  theme: 'dark' | 'light'
}

// ============================================
// Import/Export Types
// ============================================

export interface ExportData {
  version: string
  exportedAt: string
  images: ImageWithDetails[]
  folders: Folder[]
  tags: Tag[]
}

export interface ImportResult {
  success: boolean
  imported: number
  skipped: number
  errors: string[]
}
