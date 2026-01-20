-- ============================================
-- NAI Prompt Manager - Supabase Schema
-- ============================================
-- このファイルをSupabaseダッシュボードのSQL Editorで実行してください
-- https://supabase.com/dashboard/project/YOUR_PROJECT/sql

-- ============================================
-- Enable UUID extension (if not already enabled)
-- ============================================
create extension if not exists "uuid-ossp";

-- ============================================
-- Folders Table
-- ============================================
create table if not exists public.folders (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  parent_id uuid references public.folders(id) on delete set null,
  name text not null,
  color text,
  sort_order int default 0,
  created_at timestamptz default now() not null
);

-- Indexes
create index if not exists idx_folders_user_id on public.folders(user_id);
create index if not exists idx_folders_parent_id on public.folders(parent_id);

-- ============================================
-- Images Table
-- ============================================
create table if not exists public.images (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  folder_id uuid references public.folders(id) on delete set null,
  storage_path text not null,
  thumbnail_path text,
  filename text,
  width int,
  height int,
  file_size int,
  file_hash text,
  is_nsfw boolean default false,
  nsfw_score real,
  nsfw_category text,
  deleted_at timestamptz,
  created_at timestamptz default now() not null
);

-- Indexes
create index if not exists idx_images_user_id on public.images(user_id);
create index if not exists idx_images_folder_id on public.images(folder_id);
create index if not exists idx_images_created_at on public.images(created_at desc);
create index if not exists idx_images_deleted_at on public.images(deleted_at);
create index if not exists idx_images_file_hash on public.images(file_hash);

-- ============================================
-- Prompts Table
-- ============================================
create table if not exists public.prompts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  image_id uuid references public.images(id) on delete cascade not null unique,
  positive_prompt text,
  negative_prompt text,
  model text,
  sampler text,
  steps int,
  cfg_scale real,
  seed bigint,
  resolution_width int,
  resolution_height int,
  noise_schedule text,
  prompt_guidance_rescale real,
  notes text,
  raw_metadata jsonb,
  source_type text default 'unknown',
  workflow_json jsonb,
  created_at timestamptz default now() not null
);

-- Indexes
create index if not exists idx_prompts_user_id on public.prompts(user_id);
create index if not exists idx_prompts_image_id on public.prompts(image_id);
create index if not exists idx_prompts_source_type on public.prompts(source_type);

-- Full-text search index for prompts
create index if not exists idx_prompts_positive_fts on public.prompts using gin(to_tsvector('english', coalesce(positive_prompt, '')));
create index if not exists idx_prompts_negative_fts on public.prompts using gin(to_tsvector('english', coalesce(negative_prompt, '')));

-- ============================================
-- Tags Table
-- ============================================
create table if not exists public.tags (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  color text default '#a78bfa',
  created_at timestamptz default now() not null,
  unique(user_id, name)
);

-- Indexes
create index if not exists idx_tags_user_id on public.tags(user_id);
create index if not exists idx_tags_name on public.tags(name);

-- ============================================
-- Image Tags Junction Table
-- ============================================
create table if not exists public.image_tags (
  image_id uuid references public.images(id) on delete cascade not null,
  tag_id uuid references public.tags(id) on delete cascade not null,
  primary key (image_id, tag_id)
);

-- Indexes
create index if not exists idx_image_tags_image_id on public.image_tags(image_id);
create index if not exists idx_image_tags_tag_id on public.image_tags(tag_id);

-- ============================================
-- Image Ratings Table
-- ============================================
create table if not exists public.image_ratings (
  image_id uuid references public.images(id) on delete cascade not null primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  is_favorite boolean default false,
  rating int check (rating >= 1 and rating <= 5)
);

-- Indexes
create index if not exists idx_image_ratings_user_id on public.image_ratings(user_id);
create index if not exists idx_image_ratings_is_favorite on public.image_ratings(is_favorite) where is_favorite = true;

-- ============================================
-- Settings Table
-- ============================================
create table if not exists public.settings (
  user_id uuid references auth.users(id) on delete cascade not null,
  key text not null,
  value text,
  primary key (user_id, key)
);

-- ============================================
-- Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on all tables
alter table public.folders enable row level security;
alter table public.images enable row level security;
alter table public.prompts enable row level security;
alter table public.tags enable row level security;
alter table public.image_tags enable row level security;
alter table public.image_ratings enable row level security;
alter table public.settings enable row level security;

-- Folders policies
create policy "Users can view own folders"
  on public.folders for select
  using (auth.uid() = user_id);

create policy "Users can insert own folders"
  on public.folders for insert
  with check (auth.uid() = user_id);

create policy "Users can update own folders"
  on public.folders for update
  using (auth.uid() = user_id);

create policy "Users can delete own folders"
  on public.folders for delete
  using (auth.uid() = user_id);

-- Images policies
create policy "Users can view own images"
  on public.images for select
  using (auth.uid() = user_id);

create policy "Users can insert own images"
  on public.images for insert
  with check (auth.uid() = user_id);

create policy "Users can update own images"
  on public.images for update
  using (auth.uid() = user_id);

create policy "Users can delete own images"
  on public.images for delete
  using (auth.uid() = user_id);

-- Prompts policies
create policy "Users can view own prompts"
  on public.prompts for select
  using (auth.uid() = user_id);

create policy "Users can insert own prompts"
  on public.prompts for insert
  with check (auth.uid() = user_id);

create policy "Users can update own prompts"
  on public.prompts for update
  using (auth.uid() = user_id);

create policy "Users can delete own prompts"
  on public.prompts for delete
  using (auth.uid() = user_id);

-- Tags policies
create policy "Users can view own tags"
  on public.tags for select
  using (auth.uid() = user_id);

create policy "Users can insert own tags"
  on public.tags for insert
  with check (auth.uid() = user_id);

create policy "Users can update own tags"
  on public.tags for update
  using (auth.uid() = user_id);

create policy "Users can delete own tags"
  on public.tags for delete
  using (auth.uid() = user_id);

-- Image Tags policies
create policy "Users can view own image_tags"
  on public.image_tags for select
  using (
    exists (
      select 1 from public.images
      where images.id = image_tags.image_id
      and images.user_id = auth.uid()
    )
  );

create policy "Users can insert own image_tags"
  on public.image_tags for insert
  with check (
    exists (
      select 1 from public.images
      where images.id = image_tags.image_id
      and images.user_id = auth.uid()
    )
  );

create policy "Users can delete own image_tags"
  on public.image_tags for delete
  using (
    exists (
      select 1 from public.images
      where images.id = image_tags.image_id
      and images.user_id = auth.uid()
    )
  );

-- Image Ratings policies
create policy "Users can view own ratings"
  on public.image_ratings for select
  using (auth.uid() = user_id);

create policy "Users can insert own ratings"
  on public.image_ratings for insert
  with check (auth.uid() = user_id);

create policy "Users can update own ratings"
  on public.image_ratings for update
  using (auth.uid() = user_id);

create policy "Users can delete own ratings"
  on public.image_ratings for delete
  using (auth.uid() = user_id);

-- Settings policies
create policy "Users can view own settings"
  on public.settings for select
  using (auth.uid() = user_id);

create policy "Users can insert own settings"
  on public.settings for insert
  with check (auth.uid() = user_id);

create policy "Users can update own settings"
  on public.settings for update
  using (auth.uid() = user_id);

create policy "Users can delete own settings"
  on public.settings for delete
  using (auth.uid() = user_id);
