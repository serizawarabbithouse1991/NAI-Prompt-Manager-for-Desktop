import { copyFile, exists, mkdir, readFile, writeTextFile } from '@tauri-apps/plugin-fs'
import { getSyncDirs } from './paths'

export async function ensureSyncDirs(syncPath: string): Promise<Awaited<ReturnType<typeof getSyncDirs>>> {
  const dirs = await getSyncDirs(syncPath)
  for (const dir of [dirs.root, dirs.sync, dirs.changes, dirs.images, dirs.thumbnails, dirs.meta, dirs.tags, dirs.folders]) {
    if (!(await exists(dir))) {
      await mkdir(dir, { recursive: true })
    }
  }
  return dirs
}

export async function writeJsonFile(path: string, data: unknown): Promise<void> {
  await writeTextFile(path, JSON.stringify(data, null, 2))
}

export async function readJsonFile<T>(path: string): Promise<T | null> {
  if (!(await exists(path))) return null
  const bytes = await readFile(path)
  const text = new TextDecoder().decode(bytes)
  return JSON.parse(text) as T
}

export async function copyFileIfNeeded(source: string, dest: string): Promise<boolean> {
  if (await exists(dest)) return false
  await copyFile(source, dest)
  return true
}

export async function copyFileAlways(source: string, dest: string): Promise<void> {
  await copyFile(source, dest)
}
