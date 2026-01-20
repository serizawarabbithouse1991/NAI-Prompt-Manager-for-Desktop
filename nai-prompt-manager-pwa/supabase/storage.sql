-- ============================================
-- NAI Prompt Manager - Supabase Storage Setup
-- ============================================
-- このファイルをSupabaseダッシュボードのSQL Editorで実行してください
-- schema.sql を実行した後に実行してください

-- ============================================
-- Create Storage Bucket for Images
-- ============================================
-- Note: バケットの作成はダッシュボードからも可能です
-- Storage > New bucket > "images" (public: false)

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'images',
  'images',
  false,
  52428800, -- 50MB limit
  array['image/png', 'image/jpeg', 'image/gif', 'image/webp']
)
on conflict (id) do nothing;

-- ============================================
-- Create Storage Bucket for Thumbnails
-- ============================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'thumbnails',
  'thumbnails',
  false,
  5242880, -- 5MB limit
  array['image/png', 'image/jpeg', 'image/webp']
)
on conflict (id) do nothing;

-- ============================================
-- Storage RLS Policies
-- ============================================

-- Images bucket policies
create policy "Users can upload own images"
  on storage.objects for insert
  with check (
    bucket_id = 'images' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can view own images"
  on storage.objects for select
  using (
    bucket_id = 'images' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update own images"
  on storage.objects for update
  using (
    bucket_id = 'images' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete own images"
  on storage.objects for delete
  using (
    bucket_id = 'images' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Thumbnails bucket policies
create policy "Users can upload own thumbnails"
  on storage.objects for insert
  with check (
    bucket_id = 'thumbnails' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can view own thumbnails"
  on storage.objects for select
  using (
    bucket_id = 'thumbnails' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update own thumbnails"
  on storage.objects for update
  using (
    bucket_id = 'thumbnails' and
    auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete own thumbnails"
  on storage.objects for delete
  using (
    bucket_id = 'thumbnails' and
    auth.uid()::text = (storage.foldername(name))[1]
  );
