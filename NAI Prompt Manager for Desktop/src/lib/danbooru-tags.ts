import { invoke } from '@tauri-apps/api/core'
import type { DanbooruDbStats, DanbooruTagMatch, Prompt, Tag } from '../types'
import * as db from './database'

type TagSeed = {
  name: string
  color: string
}

export interface DanbooruAutoTagResult {
  matched: DanbooruTagMatch[]
  tags: Tag[]
}

export interface DanbooruAutoTagOptions {
  allowedTagTypes?: number[]
  maxTagsPerImage?: number
  minPopularity?: number
}

const TAG_COLORS_BY_TYPE: Record<number, string> = {
  0: '#60a5fa',
  1: '#f59e0b',
  3: '#a78bfa',
  4: '#f472b6',
  5: '#34d399',
}

function normalizeTagCandidate(value: string): string | null {
  let tag = value
    .trim()
    .toLowerCase()
    .replace(/\\([()[\]{}])/g, '$1')
    .replace(/^[([{]+/, '')
    .replace(/[)\]}]+$/, '')
    .replace(/^["']+|["']+$/g, '')
    .trim()

  tag = tag.replace(/:[+-]?\d+(?:\.\d+)?$/, '').trim()
  tag = tag.replace(/\s+/g, '_')
  tag = tag.replace(/_+/g, '_')

  if (!tag || tag.length > 160) return null
  if (/^-+$/.test(tag)) return null
  return tag
}

export function extractDanbooruTagCandidates(prompt: string | null | undefined): string[] {
  if (!prompt) return []

  const seen = new Set<string>()
  const candidates: string[] = []
  for (const part of prompt.split(/[,\n]/)) {
    const normalized = normalizeTagCandidate(part)
    if (normalized && !seen.has(normalized)) {
      seen.add(normalized)
      candidates.push(normalized)
    }
  }
  return candidates
}

export async function findDanbooruTags(
  dbPath: string,
  prompt: string | null | undefined,
  options: DanbooruAutoTagOptions = {}
): Promise<DanbooruTagMatch[]> {
  const candidates = extractDanbooruTagCandidates(prompt)
  if (!dbPath || candidates.length === 0) return []

  const matches = await invoke<DanbooruTagMatch[]>('find_danbooru_tags', {
    dbPath,
    names: candidates,
  })
  const allowedTypes = options.allowedTagTypes?.length
    ? new Set(options.allowedTagTypes)
    : null
  const minPopularity = options.minPopularity ?? 0
  const maxTags = options.maxTagsPerImage ?? 0

  const filtered = matches
    .filter((match) => !allowedTypes || allowedTypes.has(match.tag_type))
    .filter((match) => match.popularity >= minPopularity)
    .sort((a, b) => b.popularity - a.popularity)

  return maxTags > 0 ? filtered.slice(0, maxTags) : filtered
}

export async function getDanbooruDbStats(dbPath: string): Promise<DanbooruDbStats> {
  return invoke<DanbooruDbStats>('get_danbooru_db_stats', { dbPath })
}

function toTagSeed(match: DanbooruTagMatch): TagSeed {
  return {
    name: match.name,
    color: TAG_COLORS_BY_TYPE[match.tag_type] || TAG_COLORS_BY_TYPE[0],
  }
}

export async function autoTagImageFromPrompt(
  imageId: string,
  prompt: Pick<Prompt, 'positive_prompt'> | null | undefined,
  dbPath: string,
  options: DanbooruAutoTagOptions = {}
): Promise<DanbooruAutoTagResult> {
  const matched = await findDanbooruTags(dbPath, prompt?.positive_prompt, options)
  if (matched.length === 0) return { matched, tags: [] }

  const seeds = matched.map(toTagSeed)
  const tags = await db.getOrCreateTags(seeds)
  await db.addTagsToImage(imageId, tags.map((tag) => tag.id))
  return { matched, tags }
}
