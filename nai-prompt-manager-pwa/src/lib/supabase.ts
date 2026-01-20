import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables. Please check .env file.')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
})

// Storage helpers
export const STORAGE_BUCKETS = {
  IMAGES: 'images',
  THUMBNAILS: 'thumbnails',
} as const

export function getStorageUrl(bucket: string, path: string): string {
  const { data } = supabase.storage.from(bucket).getPublicUrl(path)
  return data.publicUrl
}

export async function getSignedUrl(bucket: string, path: string, expiresIn = 3600): Promise<string | null> {
  const { data, error } = await supabase.storage
    .from(bucket)
    .createSignedUrl(path, expiresIn)
  
  if (error) {
    console.error('Failed to get signed URL:', error)
    return null
  }
  
  return data.signedUrl
}

export async function uploadFile(
  bucket: string,
  path: string,
  file: File | Blob,
  options?: { contentType?: string; upsert?: boolean }
): Promise<{ path: string } | null> {
  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(path, file, {
      contentType: options?.contentType,
      upsert: options?.upsert ?? false,
    })
  
  if (error) {
    console.error('Failed to upload file:', error)
    return null
  }
  
  return data
}

export async function deleteFile(bucket: string, paths: string[]): Promise<boolean> {
  const { error } = await supabase.storage
    .from(bucket)
    .remove(paths)
  
  if (error) {
    console.error('Failed to delete file:', error)
    return false
  }
  
  return true
}
