import Database from '@tauri-apps/plugin-sql'
import type { 
  Image, 
  ImageWithDetails, 
  Prompt, 
  Tag, 
  Folder, 
  ImageRating 
} from '../../types'
import { MIGRATIONS } from './migrations'

let db: Database | null = null

export async function getDatabase(): Promise<Database> {
  if (!db) {
    db = await Database.load('sqlite:nai_prompt_manager.db')
  }
  return db
}

export async function initDatabase(): Promise<void> {
  const database = await getDatabase()
  
  // Run migrations
  for (const migration of MIGRATIONS) {
    await database.execute(migration)
  }
  
  console.log('Database initialized successfully')
}

// ============================================
// Image Operations
// ============================================

export async function getAllImages(): Promise<ImageWithDetails[]> {
  const database = await getDatabase()
  
  // Get all images
  const images = await database.select<Image[]>(`
    SELECT * FROM images 
    WHERE deleted_at IS NULL 
    ORDER BY created_at DESC
  `)

  // Get all prompts.
  // NOTE: We deliberately exclude `raw_metadata` here. It is a large JSON blob
  // (the original NovelAI PNG metadata) that is never displayed in the gallery,
  // and selecting it for every row makes the tauri-plugin-sql IPC payload huge.
  // Worse, legacy rows can contain control/NULL bytes that stall JSON
  // serialization, which is why this query (and the gallery) appeared to hang
  // forever on "読み込み中...". Fetch only the columns the UI actually uses.
  const prompts = await database.select<Prompt[]>(`
    SELECT id, image_id, positive_prompt, negative_prompt, model, sampler, steps,
           cfg_scale, seed, resolution_width, resolution_height, noise_schedule,
           prompt_guidance_rescale, notes, created_at
    FROM prompts
  `)
  const promptMap = new Map(prompts.map(p => [p.image_id, p]))

  // Get all image tags with tag details
  const imageTags = await database.select<{ image_id: string; tag_id: string; name: string; color: string | null; created_at: string }[]>(`
    SELECT it.image_id, it.tag_id, t.name, t.color, t.created_at
    FROM image_tags it
    JOIN tags t ON it.tag_id = t.id
  `)
  const imageTagsMap = new Map<string, Tag[]>()
  for (const it of imageTags) {
    const tags = imageTagsMap.get(it.image_id) || []
    tags.push({ id: it.tag_id, name: it.name, color: it.color, created_at: it.created_at })
    imageTagsMap.set(it.image_id, tags)
  }

  // Get all ratings
  const ratings = await database.select<ImageRating[]>(`SELECT * FROM image_ratings`)
  const ratingMap = new Map(ratings.map(r => [r.image_id, r]))

  // Combine data
  return images.map(img => ({
    ...img,
    prompt: promptMap.get(img.id) || null,
    tags: imageTagsMap.get(img.id) || [],
    rating: ratingMap.get(img.id) || null,
  }))
}

export async function findImageByHash(fileHash: string): Promise<boolean> {
  if (!fileHash) return false
  const database = await getDatabase()
  const rows = await database.select<{ id: string }[]>(
    `SELECT id FROM images WHERE file_hash = $1 AND deleted_at IS NULL LIMIT 1`,
    [fileHash]
  )
  return rows.length > 0
}

export async function createImage(
  image: Omit<Image, 'id' | 'created_at' | 'deleted_at'>,
  prompt?: Omit<Prompt, 'id' | 'image_id' | 'created_at'> | null
): Promise<Image> {
  const database = await getDatabase()
  const id = crypto.randomUUID()
  
  await database.execute(`
    INSERT INTO images (id, folder_id, file_path, thumbnail_path, filename, width, height, file_size, file_hash)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
  `, [id, image.folder_id, image.file_path, image.thumbnail_path, image.filename, image.width, image.height, image.file_size, image.file_hash])

  if (prompt) {
    const promptId = crypto.randomUUID()
    await database.execute(`
      INSERT INTO prompts (id, image_id, positive_prompt, negative_prompt, model, sampler, steps, cfg_scale, seed, resolution_width, resolution_height, noise_schedule, notes, raw_metadata)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
    `, [
      promptId, id, prompt.positive_prompt, prompt.negative_prompt, prompt.model, 
      prompt.sampler, prompt.steps, prompt.cfg_scale, prompt.seed,
      prompt.resolution_width, prompt.resolution_height, prompt.noise_schedule,
      prompt.notes, prompt.raw_metadata
    ])
  }

  const [created] = await database.select<Image[]>(`SELECT * FROM images WHERE id = $1`, [id])
  return created
}

export async function updateImage(id: string, updates: Partial<Image>): Promise<void> {
  const database = await getDatabase()
  const fields: string[] = []
  const values: unknown[] = []
  let paramIndex = 1

  for (const [key, value] of Object.entries(updates)) {
    if (key !== 'id' && key !== 'created_at') {
      fields.push(`${key} = $${paramIndex}`)
      values.push(value)
      paramIndex++
    }
  }

  if (fields.length > 0) {
    values.push(id)
    await database.execute(
      `UPDATE images SET ${fields.join(', ')} WHERE id = $${paramIndex}`,
      values
    )
  }
}

export async function deleteImage(id: string): Promise<void> {
  const database = await getDatabase()
  // Soft delete
  await database.execute(`UPDATE images SET deleted_at = datetime('now') WHERE id = $1`, [id])
}

export async function deleteImages(ids: string[]): Promise<void> {
  const database = await getDatabase()
  const placeholders = ids.map((_, i) => `$${i + 1}`).join(', ')
  await database.execute(
    `UPDATE images SET deleted_at = datetime('now') WHERE id IN (${placeholders})`,
    ids
  )
}

export async function permanentlyDeleteImage(id: string): Promise<void> {
  const database = await getDatabase()
  await database.execute(`DELETE FROM images WHERE id = $1`, [id])
}

// ============================================
// Prompt Operations
// ============================================

export async function updatePrompt(imageId: string, updates: Partial<Prompt>): Promise<void> {
  const database = await getDatabase()
  
  // Check if prompt exists
  const [existing] = await database.select<Prompt[]>(
    `SELECT id FROM prompts WHERE image_id = $1`,
    [imageId]
  )

  if (existing) {
    const fields: string[] = []
    const values: unknown[] = []
    let paramIndex = 1

    for (const [key, value] of Object.entries(updates)) {
      if (key !== 'id' && key !== 'image_id' && key !== 'created_at') {
        fields.push(`${key} = $${paramIndex}`)
        values.push(value)
        paramIndex++
      }
    }

    if (fields.length > 0) {
      values.push(imageId)
      await database.execute(
        `UPDATE prompts SET ${fields.join(', ')} WHERE image_id = $${paramIndex}`,
        values
      )
    }
  } else {
    // Create new prompt
    const id = crypto.randomUUID()
    await database.execute(`
      INSERT INTO prompts (id, image_id, positive_prompt, negative_prompt, model, sampler, steps, cfg_scale, seed, resolution_width, resolution_height, noise_schedule, notes, raw_metadata)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
    `, [
      id, imageId, 
      updates.positive_prompt ?? null, 
      updates.negative_prompt ?? null,
      updates.model ?? null,
      updates.sampler ?? null,
      updates.steps ?? null,
      updates.cfg_scale ?? null,
      updates.seed ?? null,
      updates.resolution_width ?? null,
      updates.resolution_height ?? null,
      updates.noise_schedule ?? null,
      updates.notes ?? null,
      updates.raw_metadata ?? null
    ])
  }
}

// ============================================
// Tag Operations
// ============================================

export async function getAllTags(): Promise<Tag[]> {
  const database = await getDatabase()
  return database.select<Tag[]>(`SELECT * FROM tags ORDER BY name`)
}

export async function createTag(name: string, color?: string): Promise<Tag> {
  const database = await getDatabase()
  const id = crypto.randomUUID()
  
  await database.execute(`
    INSERT INTO tags (id, name, color) VALUES ($1, $2, $3)
  `, [id, name, color || '#a78bfa'])

  const [tag] = await database.select<Tag[]>(`SELECT * FROM tags WHERE id = $1`, [id])
  return tag
}

export async function getOrCreateTags(
  tagSeeds: { name: string; color?: string | null }[]
): Promise<Tag[]> {
  const database = await getDatabase()
  const uniqueSeeds = new Map<string, { name: string; color?: string | null }>()
  for (const seed of tagSeeds) {
    const name = seed.name.trim()
    if (name && !uniqueSeeds.has(name)) uniqueSeeds.set(name, { ...seed, name })
  }
  const seeds = [...uniqueSeeds.values()]
  if (seeds.length === 0) return []

  const existing = new Map<string, Tag>()
  for (let i = 0; i < seeds.length; i += 500) {
    const chunk = seeds.slice(i, i + 500)
    const placeholders = chunk.map((_, index) => `$${index + 1}`).join(', ')
    const rows = await database.select<Tag[]>(
      `SELECT * FROM tags WHERE name IN (${placeholders})`,
      chunk.map((seed) => seed.name)
    )
    for (const tag of rows) existing.set(tag.name, tag)
  }

  for (const seed of seeds) {
    if (existing.has(seed.name)) continue
    const id = crypto.randomUUID()
    await database.execute(
      `INSERT OR IGNORE INTO tags (id, name, color) VALUES ($1, $2, $3)`,
      [id, seed.name, seed.color || '#a78bfa']
    )
    const [tag] = await database.select<Tag[]>(`SELECT * FROM tags WHERE name = $1`, [seed.name])
    if (tag) existing.set(tag.name, tag)
  }

  return seeds
    .map((seed) => existing.get(seed.name))
    .filter((tag): tag is Tag => Boolean(tag))
}

export async function updateTag(id: string, updates: Partial<Tag>): Promise<void> {
  const database = await getDatabase()
  const fields: string[] = []
  const values: unknown[] = []
  let paramIndex = 1

  for (const [key, value] of Object.entries(updates)) {
    if (key !== 'id' && key !== 'created_at') {
      fields.push(`${key} = $${paramIndex}`)
      values.push(value)
      paramIndex++
    }
  }

  if (fields.length > 0) {
    values.push(id)
    await database.execute(
      `UPDATE tags SET ${fields.join(', ')} WHERE id = $${paramIndex}`,
      values
    )
  }
}

export async function deleteTag(id: string): Promise<void> {
  const database = await getDatabase()
  await database.execute(`DELETE FROM tags WHERE id = $1`, [id])
}

export async function addTagToImage(imageId: string, tagId: string): Promise<void> {
  const database = await getDatabase()
  await database.execute(`
    INSERT OR IGNORE INTO image_tags (image_id, tag_id) VALUES ($1, $2)
  `, [imageId, tagId])
}

export async function addTagsToImage(imageId: string, tagIds: string[]): Promise<void> {
  if (tagIds.length === 0) return
  const database = await getDatabase()
  for (const tagId of tagIds) {
    await database.execute(
      `INSERT OR IGNORE INTO image_tags (image_id, tag_id) VALUES ($1, $2)`,
      [imageId, tagId]
    )
  }
}

export async function addTagToImages(imageIds: string[], tagId: string): Promise<void> {
  if (imageIds.length === 0) return
  const database = await getDatabase()
  for (const imageId of imageIds) {
    await database.execute(
      `INSERT OR IGNORE INTO image_tags (image_id, tag_id) VALUES ($1, $2)`,
      [imageId, tagId]
    )
  }
}

export async function removeTagFromImage(imageId: string, tagId: string): Promise<void> {
  const database = await getDatabase()
  await database.execute(`
    DELETE FROM image_tags WHERE image_id = $1 AND tag_id = $2
  `, [imageId, tagId])
}

// ============================================
// Folder Operations
// ============================================

export async function getAllFolders(): Promise<Folder[]> {
  const database = await getDatabase()
  return database.select<Folder[]>(`SELECT * FROM folders ORDER BY sort_order, name`)
}

export async function createFolder(
  name: string,
  parentId: string | null = null,
  color?: string
): Promise<Folder> {
  const database = await getDatabase()
  const id = crypto.randomUUID()
  
  // Get max sort_order
  const [result] = await database.select<{ max_order: number | null }[]>(
    `SELECT MAX(sort_order) as max_order FROM folders WHERE parent_id IS $1`,
    [parentId]
  )
  const sortOrder = (result?.max_order ?? -1) + 1

  await database.execute(`
    INSERT INTO folders (id, parent_id, name, color, sort_order) VALUES ($1, $2, $3, $4, $5)
  `, [id, parentId, name, color, sortOrder])

  const [folder] = await database.select<Folder[]>(`SELECT * FROM folders WHERE id = $1`, [id])
  return folder
}

export async function updateFolder(id: string, updates: Partial<Folder>): Promise<void> {
  const database = await getDatabase()
  const fields: string[] = []
  const values: unknown[] = []
  let paramIndex = 1

  for (const [key, value] of Object.entries(updates)) {
    if (key !== 'id' && key !== 'created_at') {
      fields.push(`${key} = $${paramIndex}`)
      values.push(value)
      paramIndex++
    }
  }

  if (fields.length > 0) {
    values.push(id)
    await database.execute(
      `UPDATE folders SET ${fields.join(', ')} WHERE id = $${paramIndex}`,
      values
    )
  }
}

export async function deleteFolder(id: string): Promise<void> {
  const database = await getDatabase()
  // Move images to uncategorized
  await database.execute(`UPDATE images SET folder_id = NULL WHERE folder_id = $1`, [id])
  // Delete folder
  await database.execute(`DELETE FROM folders WHERE id = $1`, [id])
}

export async function moveImagesToFolder(imageIds: string[], folderId: string | null): Promise<void> {
  const database = await getDatabase()
  const placeholders = imageIds.map((_, i) => `$${i + 2}`).join(', ')
  await database.execute(
    `UPDATE images SET folder_id = $1 WHERE id IN (${placeholders})`,
    [folderId, ...imageIds]
  )
}

// ============================================
// Rating Operations
// ============================================

export async function updateImageRating(
  imageId: string,
  updates: Partial<ImageRating>
): Promise<void> {
  const database = await getDatabase()
  
  // Check if rating exists
  const [existing] = await database.select<ImageRating[]>(
    `SELECT * FROM image_ratings WHERE image_id = $1`,
    [imageId]
  )

  if (existing) {
    const fields: string[] = []
    const values: unknown[] = []
    let paramIndex = 1

    for (const [key, value] of Object.entries(updates)) {
      if (key !== 'image_id') {
        fields.push(`${key} = $${paramIndex}`)
        values.push(value)
        paramIndex++
      }
    }

    if (fields.length > 0) {
      values.push(imageId)
      await database.execute(
        `UPDATE image_ratings SET ${fields.join(', ')} WHERE image_id = $${paramIndex}`,
        values
      )
    }
  } else {
    await database.execute(`
      INSERT INTO image_ratings (image_id, is_favorite, rating)
      VALUES ($1, $2, $3)
    `, [imageId, updates.is_favorite ?? false, updates.rating ?? null])
  }
}

// ============================================
// Search Operations
// ============================================

export async function searchImages(
  query: string,
  folderId?: string | null,
  tagIds?: string[],
  favoritesOnly?: boolean
): Promise<ImageWithDetails[]> {
  const database = await getDatabase()
  
  let sql = `
    SELECT DISTINCT i.* FROM images i
    LEFT JOIN prompts p ON i.id = p.image_id
    LEFT JOIN image_ratings r ON i.id = r.image_id
  `
  const params: unknown[] = []
  const conditions: string[] = ['i.deleted_at IS NULL']
  let paramIndex = 1

  if (query) {
    const searchPattern = `%${query}%`
    conditions.push(`(
      i.filename LIKE $${paramIndex} OR
      p.positive_prompt LIKE $${paramIndex + 1} OR
      p.negative_prompt LIKE $${paramIndex + 2}
    )`)
    params.push(searchPattern, searchPattern, searchPattern)
    paramIndex += 3
  }

  if (folderId !== undefined) {
    if (folderId === null) {
      conditions.push(`i.folder_id IS NULL`)
    } else {
      conditions.push(`i.folder_id = $${paramIndex}`)
      params.push(folderId)
      paramIndex++
    }
  }

  if (tagIds && tagIds.length > 0) {
    const tagPlaceholders = tagIds.map((_, i) => `$${paramIndex + i}`).join(', ')
    sql += ` JOIN image_tags it ON i.id = it.image_id AND it.tag_id IN (${tagPlaceholders})`
    params.push(...tagIds)
    paramIndex += tagIds.length
  }

  if (favoritesOnly) {
    conditions.push(`r.is_favorite = 1`)
  }

  sql += ` WHERE ${conditions.join(' AND ')} ORDER BY i.created_at DESC`

  const images = await database.select<Image[]>(sql, params)
  
  // Get additional details (same as getAllImages)
  const imageIds = images.map(i => i.id)
  if (imageIds.length === 0) return []

  const idPlaceholders = imageIds.map((_, i) => `$${i + 1}`).join(', ')
  
  // Exclude `raw_metadata` (large, unused in UI) — see note in getAllImages.
  const prompts = await database.select<Prompt[]>(
    `SELECT id, image_id, positive_prompt, negative_prompt, model, sampler, steps,
            cfg_scale, seed, resolution_width, resolution_height, noise_schedule,
            prompt_guidance_rescale, notes, created_at
     FROM prompts WHERE image_id IN (${idPlaceholders})`,
    imageIds
  )
  const promptMap = new Map(prompts.map(p => [p.image_id, p]))

  const imageTags = await database.select<{ image_id: string; tag_id: string; name: string; color: string | null; created_at: string }[]>(
    `SELECT it.image_id, it.tag_id, t.name, t.color, t.created_at
     FROM image_tags it
     JOIN tags t ON it.tag_id = t.id
     WHERE it.image_id IN (${idPlaceholders})`,
    imageIds
  )
  const imageTagsMap = new Map<string, Tag[]>()
  for (const it of imageTags) {
    const tags = imageTagsMap.get(it.image_id) || []
    tags.push({ id: it.tag_id, name: it.name, color: it.color, created_at: it.created_at })
    imageTagsMap.set(it.image_id, tags)
  }

  const ratings = await database.select<ImageRating[]>(
    `SELECT * FROM image_ratings WHERE image_id IN (${idPlaceholders})`,
    imageIds
  )
  const ratingMap = new Map(ratings.map(r => [r.image_id, r]))

  return images.map(img => ({
    ...img,
    prompt: promptMap.get(img.id) || null,
    tags: imageTagsMap.get(img.id) || [],
    rating: ratingMap.get(img.id) || null,
  }))
}
