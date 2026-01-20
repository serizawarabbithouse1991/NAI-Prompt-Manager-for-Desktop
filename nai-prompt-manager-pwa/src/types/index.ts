// ============================================
// Database Types (Supabase)
// ============================================

export interface Folder {
  id: string
  user_id: string
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
  user_id: string
  folder_id: string | null
  storage_path: string
  thumbnail_path: string | null
  filename: string | null
  width: number | null
  height: number | null
  file_size: number | null
  file_hash: string | null
  is_nsfw: boolean
  nsfw_score: number | null
  nsfw_category: string | null
  deleted_at: string | null
  created_at: string
}

export interface Prompt {
  id: string
  user_id: string
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
  raw_metadata: Record<string, unknown> | null
  source_type: string
  workflow_json: Record<string, unknown> | null
  created_at: string
}

export interface Tag {
  id: string
  user_id: string
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
  user_id: string
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
  image_url?: string
  thumbnail_url?: string
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
  rawMetadata: Record<string, unknown>
}

// ============================================
// Auth Types
// ============================================

export interface User {
  id: string
  email: string | null
  created_at: string
}
