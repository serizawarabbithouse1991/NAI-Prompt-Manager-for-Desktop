import { supabase, STORAGE_BUCKETS, getSignedUrl } from './supabase'
import type {
  Image,
  ImageWithDetails,
  Prompt,
  Tag,
  Folder,
  ImageRating,
  FilterOptions,
} from '../types'

// ============================================
// Image Operations
// ============================================

export async function getAllImages(
  userId: string,
  filters?: FilterOptions
): Promise<ImageWithDetails[]> {
  let query = supabase
    .from('images')
    .select(`
      *,
      prompts (*),
      image_ratings (*),
      image_tags (
        tag_id,
        tags (*)
      )
    `)
    .eq('user_id', userId)
    .is('deleted_at', null)
    .order('created_at', { ascending: false })

  if (filters?.folderId !== undefined) {
    if (filters.folderId === null) {
      query = query.is('folder_id', null)
    } else {
      query = query.eq('folder_id', filters.folderId)
    }
  }

  if (filters?.searchQuery) {
    query = query.or(`filename.ilike.%${filters.searchQuery}%,prompts.positive_prompt.ilike.%${filters.searchQuery}%`)
  }

  const { data, error } = await query

  if (error) {
    console.error('Failed to fetch images:', error)
    throw error
  }

  // Transform data and add signed URLs
  const images: ImageWithDetails[] = await Promise.all(
    (data || []).map(async (img) => {
      const image_url = await getSignedUrl(STORAGE_BUCKETS.IMAGES, img.storage_path)
      const thumbnail_url = img.thumbnail_path
        ? await getSignedUrl(STORAGE_BUCKETS.THUMBNAILS, img.thumbnail_path)
        : image_url

      return {
        ...img,
        prompt: img.prompts?.[0] || null,
        tags: img.image_tags?.map((it: { tags: Tag }) => it.tags).filter(Boolean) || [],
        rating: img.image_ratings?.[0] || null,
        image_url: image_url || undefined,
        thumbnail_url: thumbnail_url || undefined,
      }
    })
  )

  // Apply client-side filters
  let filtered = images

  if (filters?.tagIds && filters.tagIds.length > 0) {
    filtered = filtered.filter(img =>
      filters.tagIds!.some(tagId => img.tags.some(t => t.id === tagId))
    )
  }

  if (filters?.favoritesOnly) {
    filtered = filtered.filter(img => img.rating?.is_favorite)
  }

  return filtered
}

export async function createImage(
  userId: string,
  image: Omit<Image, 'id' | 'user_id' | 'created_at' | 'deleted_at'>,
  prompt?: Omit<Prompt, 'id' | 'user_id' | 'image_id' | 'created_at'> | null
): Promise<Image> {
  const { data: imageData, error: imageError } = await supabase
    .from('images')
    .insert({
      ...image,
      user_id: userId,
    })
    .select()
    .single()

  if (imageError) {
    console.error('Failed to create image:', imageError)
    throw imageError
  }

  if (prompt) {
    const { error: promptError } = await supabase
      .from('prompts')
      .insert({
        ...prompt,
        user_id: userId,
        image_id: imageData.id,
      })

    if (promptError) {
      console.error('Failed to create prompt:', promptError)
    }
  }

  return imageData
}

export async function updateImage(
  imageId: string,
  updates: Partial<Image>
): Promise<void> {
  const { error } = await supabase
    .from('images')
    .update(updates)
    .eq('id', imageId)

  if (error) {
    console.error('Failed to update image:', error)
    throw error
  }
}

export async function deleteImage(imageId: string): Promise<void> {
  // Soft delete
  const { error } = await supabase
    .from('images')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', imageId)

  if (error) {
    console.error('Failed to delete image:', error)
    throw error
  }
}

export async function deleteImages(imageIds: string[]): Promise<void> {
  const { error } = await supabase
    .from('images')
    .update({ deleted_at: new Date().toISOString() })
    .in('id', imageIds)

  if (error) {
    console.error('Failed to delete images:', error)
    throw error
  }
}

// ============================================
// Prompt Operations
// ============================================

export async function updatePrompt(
  userId: string,
  imageId: string,
  updates: Partial<Prompt>
): Promise<void> {
  // Check if prompt exists
  const { data: existing } = await supabase
    .from('prompts')
    .select('id')
    .eq('image_id', imageId)
    .single()

  if (existing) {
    const { error } = await supabase
      .from('prompts')
      .update(updates)
      .eq('image_id', imageId)

    if (error) throw error
  } else {
    const { error } = await supabase
      .from('prompts')
      .insert({
        ...updates,
        user_id: userId,
        image_id: imageId,
      })

    if (error) throw error
  }
}

// ============================================
// Tag Operations
// ============================================

export async function getAllTags(userId: string): Promise<Tag[]> {
  const { data, error } = await supabase
    .from('tags')
    .select('*')
    .eq('user_id', userId)
    .order('name')

  if (error) {
    console.error('Failed to fetch tags:', error)
    throw error
  }

  return data || []
}

export async function createTag(
  userId: string,
  name: string,
  color?: string
): Promise<Tag> {
  const { data, error } = await supabase
    .from('tags')
    .insert({
      user_id: userId,
      name,
      color: color || '#a78bfa',
    })
    .select()
    .single()

  if (error) {
    console.error('Failed to create tag:', error)
    throw error
  }

  return data
}

export async function updateTag(
  tagId: string,
  updates: Partial<Tag>
): Promise<void> {
  const { error } = await supabase
    .from('tags')
    .update(updates)
    .eq('id', tagId)

  if (error) throw error
}

export async function deleteTag(tagId: string): Promise<void> {
  const { error } = await supabase
    .from('tags')
    .delete()
    .eq('id', tagId)

  if (error) throw error
}

export async function addTagToImage(
  imageId: string,
  tagId: string
): Promise<void> {
  const { error } = await supabase
    .from('image_tags')
    .insert({ image_id: imageId, tag_id: tagId })

  if (error && error.code !== '23505') { // Ignore duplicate key error
    throw error
  }
}

export async function removeTagFromImage(
  imageId: string,
  tagId: string
): Promise<void> {
  const { error } = await supabase
    .from('image_tags')
    .delete()
    .eq('image_id', imageId)
    .eq('tag_id', tagId)

  if (error) throw error
}

// ============================================
// Folder Operations
// ============================================

export async function getAllFolders(userId: string): Promise<Folder[]> {
  const { data, error } = await supabase
    .from('folders')
    .select('*')
    .eq('user_id', userId)
    .order('sort_order')
    .order('name')

  if (error) {
    console.error('Failed to fetch folders:', error)
    throw error
  }

  return data || []
}

export async function createFolder(
  userId: string,
  name: string,
  parentId: string | null = null,
  color?: string
): Promise<Folder> {
  // Get max sort_order
  const { data: maxOrder } = await supabase
    .from('folders')
    .select('sort_order')
    .eq('user_id', userId)
    .is('parent_id', parentId)
    .order('sort_order', { ascending: false })
    .limit(1)
    .single()

  const sortOrder = (maxOrder?.sort_order ?? -1) + 1

  const { data, error } = await supabase
    .from('folders')
    .insert({
      user_id: userId,
      parent_id: parentId,
      name,
      color,
      sort_order: sortOrder,
    })
    .select()
    .single()

  if (error) {
    console.error('Failed to create folder:', error)
    throw error
  }

  return data
}

export async function updateFolder(
  folderId: string,
  updates: Partial<Folder>
): Promise<void> {
  const { error } = await supabase
    .from('folders')
    .update(updates)
    .eq('id', folderId)

  if (error) throw error
}

export async function deleteFolder(folderId: string): Promise<void> {
  // Move images to uncategorized
  await supabase
    .from('images')
    .update({ folder_id: null })
    .eq('folder_id', folderId)

  const { error } = await supabase
    .from('folders')
    .delete()
    .eq('id', folderId)

  if (error) throw error
}

export async function moveImagesToFolder(
  imageIds: string[],
  folderId: string | null
): Promise<void> {
  const { error } = await supabase
    .from('images')
    .update({ folder_id: folderId })
    .in('id', imageIds)

  if (error) throw error
}

// ============================================
// Rating Operations
// ============================================

export async function updateImageRating(
  userId: string,
  imageId: string,
  updates: Partial<ImageRating>
): Promise<void> {
  const { data: existing } = await supabase
    .from('image_ratings')
    .select('image_id')
    .eq('image_id', imageId)
    .single()

  if (existing) {
    const { error } = await supabase
      .from('image_ratings')
      .update(updates)
      .eq('image_id', imageId)

    if (error) throw error
  } else {
    const { error } = await supabase
      .from('image_ratings')
      .insert({
        ...updates,
        user_id: userId,
        image_id: imageId,
      })

    if (error) throw error
  }
}
