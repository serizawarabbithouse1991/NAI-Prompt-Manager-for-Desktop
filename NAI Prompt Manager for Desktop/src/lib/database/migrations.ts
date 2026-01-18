export const MIGRATIONS = [
  // Create folders table
  `CREATE TABLE IF NOT EXISTS folders (
    id TEXT PRIMARY KEY,
    parent_id TEXT REFERENCES folders(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    color TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now'))
  )`,

  // Create images table
  `CREATE TABLE IF NOT EXISTS images (
    id TEXT PRIMARY KEY,
    folder_id TEXT REFERENCES folders(id) ON DELETE SET NULL,
    file_path TEXT NOT NULL UNIQUE,
    thumbnail_path TEXT,
    filename TEXT,
    width INTEGER,
    height INTEGER,
    file_size INTEGER,
    file_hash TEXT,
    deleted_at TEXT,
    created_at TEXT DEFAULT (datetime('now'))
  )`,

  // Create prompts table
  `CREATE TABLE IF NOT EXISTS prompts (
    id TEXT PRIMARY KEY,
    image_id TEXT NOT NULL REFERENCES images(id) ON DELETE CASCADE,
    positive_prompt TEXT,
    negative_prompt TEXT,
    model TEXT,
    sampler TEXT,
    steps INTEGER,
    cfg_scale REAL,
    seed INTEGER,
    resolution_width INTEGER,
    resolution_height INTEGER,
    noise_schedule TEXT,
    prompt_guidance_rescale REAL,
    notes TEXT,
    raw_metadata TEXT,
    created_at TEXT DEFAULT (datetime('now'))
  )`,

  // Create tags table
  `CREATE TABLE IF NOT EXISTS tags (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    color TEXT,
    created_at TEXT DEFAULT (datetime('now'))
  )`,

  // Create image_tags table
  `CREATE TABLE IF NOT EXISTS image_tags (
    image_id TEXT REFERENCES images(id) ON DELETE CASCADE,
    tag_id TEXT REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (image_id, tag_id)
  )`,

  // Create image_ratings table
  `CREATE TABLE IF NOT EXISTS image_ratings (
    image_id TEXT PRIMARY KEY REFERENCES images(id) ON DELETE CASCADE,
    is_favorite INTEGER DEFAULT 0,
    rating INTEGER
  )`,

  // Create settings table
  `CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT
  )`,

  // Create indexes
  `CREATE INDEX IF NOT EXISTS idx_images_folder ON images(folder_id)`,
  `CREATE INDEX IF NOT EXISTS idx_images_created ON images(created_at)`,
  `CREATE INDEX IF NOT EXISTS idx_images_deleted ON images(deleted_at)`,
  `CREATE INDEX IF NOT EXISTS idx_images_hash ON images(file_hash)`,
  `CREATE INDEX IF NOT EXISTS idx_prompts_image ON prompts(image_id)`,
  `CREATE INDEX IF NOT EXISTS idx_image_tags_image ON image_tags(image_id)`,
  `CREATE INDEX IF NOT EXISTS idx_image_tags_tag ON image_tags(tag_id)`,
]
