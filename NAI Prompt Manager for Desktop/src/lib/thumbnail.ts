/**
 * Thumbnail generation utilities.
 *
 * Runs entirely in the WebView (WebView2 / Chromium) using `createImageBitmap`
 * + `OffscreenCanvas`, so no Rust-side image processing is required. Used both
 * at upload time and by the background backfill for legacy images that were
 * imported before thumbnails existed.
 */

// Default longest edge of generated thumbnails, in pixels.
export const DEFAULT_THUMBNAIL_MAX_EDGE = 400

function extToMime(ext: string): string {
  switch (ext.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg'
    case 'webp':
      return 'image/webp'
    case 'gif':
      return 'image/gif'
    case 'png':
    default:
      return 'image/png'
  }
}

/**
 * Decode the image bytes and produce a downscaled WebP thumbnail.
 * Returns the encoded thumbnail bytes, or null if the browser engine can't
 * decode/encode this image (caller then falls back to the full-size file).
 */
export async function generateThumbnailBytes(
  bytes: Uint8Array,
  ext: string,
  maxEdge: number = DEFAULT_THUMBNAIL_MAX_EDGE
): Promise<Uint8Array | null> {
  try {
    const blob = new Blob([bytes as BlobPart], { type: extToMime(ext) })
    const bitmap = await createImageBitmap(blob)
    try {
      const { width, height } = bitmap
      if (!width || !height) return null
      const scale = Math.min(1, maxEdge / Math.max(width, height))
      const w = Math.max(1, Math.round(width * scale))
      const h = Math.max(1, Math.round(height * scale))
      const canvas = new OffscreenCanvas(w, h)
      const ctx = canvas.getContext('2d')
      if (!ctx) return null
      ctx.drawImage(bitmap, 0, 0, w, h)
      const outBlob = await canvas.convertToBlob({ type: 'image/webp', quality: 0.8 })
      return new Uint8Array(await outBlob.arrayBuffer())
    } finally {
      bitmap.close()
    }
  } catch (err) {
    console.error('Thumbnail generation failed:', err)
    return null
  }
}
