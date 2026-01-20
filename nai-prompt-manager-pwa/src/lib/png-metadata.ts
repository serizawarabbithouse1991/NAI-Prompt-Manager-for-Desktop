/**
 * PNG Metadata Extractor for NovelAI images
 * Parses tEXt and iTXt chunks from PNG files to extract generation parameters
 */

import type { ParsedPromptData, NovelAIComment } from '../types'

// PNG signature bytes
const PNG_SIGNATURE = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]

/**
 * Check if buffer is a valid PNG file
 */
function isPNG(buffer: Uint8Array): boolean {
  if (buffer.length < 8) return false
  for (let i = 0; i < 8; i++) {
    if (buffer[i] !== PNG_SIGNATURE[i]) return false
  }
  return true
}

/**
 * Read a 4-byte big-endian unsigned integer
 */
function readUInt32BE(buffer: Uint8Array, offset: number): number {
  return (
    (buffer[offset] << 24) |
    (buffer[offset + 1] << 16) |
    (buffer[offset + 2] << 8) |
    buffer[offset + 3]
  ) >>> 0
}

/**
 * Extract text chunks (tEXt and iTXt) from PNG buffer
 */
function extractPNGTextChunks(buffer: Uint8Array): Map<string, string> {
  const textData = new Map<string, string>()

  if (!isPNG(buffer)) {
    console.warn('Not a valid PNG file')
    return textData
  }

  let offset = 8 // Skip PNG signature
  const decoder = new TextDecoder('utf-8')
  const latin1Decoder = new TextDecoder('latin1')

  while (offset < buffer.length - 12) {
    const length = readUInt32BE(buffer, offset)
    const chunkType = latin1Decoder.decode(buffer.slice(offset + 4, offset + 8))

    if (chunkType === 'tEXt') {
      // tEXt chunk format: keyword\0text
      const chunkData = buffer.slice(offset + 8, offset + 8 + length)
      const nullIndex = chunkData.indexOf(0)

      if (nullIndex > 0) {
        const keyword = latin1Decoder.decode(chunkData.slice(0, nullIndex))
        const text = latin1Decoder.decode(chunkData.slice(nullIndex + 1))
        textData.set(keyword, text)
      }
    } else if (chunkType === 'iTXt') {
      // iTXt chunk format: keyword\0compression_flag\0compression_method\0language_tag\0translated_keyword\0text
      const chunkData = buffer.slice(offset + 8, offset + 8 + length)
      const nullIndex = chunkData.indexOf(0)

      if (nullIndex > 0) {
        const keyword = decoder.decode(chunkData.slice(0, nullIndex))
        const compressionFlag = chunkData[nullIndex + 1]

        if (compressionFlag === 0) {
          // Uncompressed
          // Find the text after language tag and translated keyword
          let textStart = nullIndex + 3 // Skip null, compression flag, compression method

          // Skip language tag (null-terminated)
          while (textStart < chunkData.length && chunkData[textStart] !== 0) {
            textStart++
          }
          textStart++ // Skip null

          // Skip translated keyword (null-terminated)
          while (textStart < chunkData.length && chunkData[textStart] !== 0) {
            textStart++
          }
          textStart++ // Skip null

          if (textStart < chunkData.length) {
            const text = decoder.decode(chunkData.slice(textStart))
            textData.set(keyword, text)
          }
        }
      }
    } else if (chunkType === 'IEND') {
      break
    }

    // Move to next chunk (length + type + data + CRC)
    offset += 12 + length
  }

  return textData
}

/**
 * Parse NovelAI Comment JSON
 */
function parseNovelAIComment(commentStr: string): NovelAIComment | null {
  try {
    return JSON.parse(commentStr) as NovelAIComment
  } catch {
    console.warn('Failed to parse NovelAI comment JSON')
    return null
  }
}

/**
 * Extract model name from Source string
 * Example: "Stable Diffusion XL C1E1DE52" -> "Stable Diffusion XL"
 */
function extractModelName(source: string): string {
  // NovelAI format: "Stable Diffusion XL C1E1DE52" or similar
  // Remove the hash at the end if present
  const match = source.match(/^(.+?)\s+[A-F0-9]{8}$/i)
  return match ? match[1] : source
}

interface NovelAIMetadata {
  title?: string
  description?: string
  source?: string
  comment?: NovelAIComment
  software?: string
  rawMetadata: Record<string, string>
}

/**
 * Main function to extract NovelAI metadata from PNG buffer
 */
export function extractNovelAIMetadata(buffer: Uint8Array): NovelAIMetadata | null {
  const textChunks = extractPNGTextChunks(buffer)

  if (textChunks.size === 0) {
    return null
  }

  const rawMetadata: Record<string, string> = {}
  textChunks.forEach((value, key) => {
    rawMetadata[key] = value
  })

  const metadata: NovelAIMetadata = {
    rawMetadata,
  }

  // Extract known fields
  if (textChunks.has('Title')) {
    metadata.title = textChunks.get('Title')
  }
  if (textChunks.has('Description')) {
    metadata.description = textChunks.get('Description')
  }
  if (textChunks.has('Source')) {
    metadata.source = textChunks.get('Source')
  }
  if (textChunks.has('Software')) {
    metadata.software = textChunks.get('Software')
  }
  if (textChunks.has('Comment')) {
    const parsed = parseNovelAIComment(textChunks.get('Comment')!)
    if (parsed) {
      metadata.comment = parsed
    }
  }

  return metadata
}

/**
 * Convert extracted metadata to prompt data format for database
 */
export function convertToPromptData(metadata: NovelAIMetadata): ParsedPromptData {
  const comment = metadata.comment

  // Positive prompt: Description field contains the main prompt
  let positivePrompt = metadata.description || null

  // If Comment has a prompt field, prefer that (more accurate)
  if (comment?.prompt) {
    positivePrompt = comment.prompt
  }

  // Negative prompt: can be in 'uc' or 'uncond' field of Comment
  let negativePrompt: string | null = null
  if (comment?.uc) {
    negativePrompt = comment.uc
  } else if (comment?.uncond) {
    negativePrompt = comment.uncond
  }

  // Model from Source field
  const model = metadata.source ? extractModelName(metadata.source) : null

  // Other parameters from Comment
  const sampler = comment?.sampler || null
  const steps = comment?.steps ?? null
  const cfgScale = comment?.scale ?? null
  const seed = comment?.seed ?? null
  const width = comment?.width ?? null
  const height = comment?.height ?? null
  const noiseSchedule = comment?.noise_schedule ?? null

  return {
    positivePrompt,
    negativePrompt,
    model,
    sampler,
    steps,
    cfgScale,
    seed,
    width,
    height,
    noiseSchedule,
    rawMetadata: metadata.rawMetadata,
  }
}

/**
 * Extract and convert PNG metadata in one step (from buffer)
 */
export function extractPromptDataFromPNG(buffer: Uint8Array): ParsedPromptData | null {
  const metadata = extractNovelAIMetadata(buffer)
  if (!metadata) {
    return null
  }
  return convertToPromptData(metadata)
}

/**
 * Parse PNG metadata from File object
 */
export async function parsePngMetadata(file: File): Promise<ParsedPromptData | null> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    
    reader.onload = () => {
      try {
        const buffer = new Uint8Array(reader.result as ArrayBuffer)
        const data = extractPromptDataFromPNG(buffer)
        resolve(data)
      } catch (error) {
        reject(error)
      }
    }
    
    reader.onerror = () => {
      reject(new Error('Failed to read file'))
    }
    
    reader.readAsArrayBuffer(file)
  })
}

/**
 * Calculate file hash for duplicate detection
 */
export async function calculateFileHash(buffer: Uint8Array): Promise<string> {
  // Create a new ArrayBuffer copy to avoid SharedArrayBuffer issues
  const arrayBuffer = new ArrayBuffer(buffer.length)
  new Uint8Array(arrayBuffer).set(buffer)
  const hashBuffer = await crypto.subtle.digest('SHA-256', arrayBuffer)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}
