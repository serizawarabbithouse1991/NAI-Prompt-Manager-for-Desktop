import { getOrCreateDeviceId } from './device'
import { readJsonFile, writeJsonFile } from './io'
import { getSyncDirs } from './paths'
import type { SyncManifest } from './types'
import { SYNC_PROTOCOL_VERSION } from './types'

export function createEmptyManifest(): SyncManifest {
  return {
    version: SYNC_PROTOCOL_VERSION,
    updatedAt: new Date().toISOString(),
    deviceId: getOrCreateDeviceId(),
    images: {},
    tags: {},
    folders: {},
  }
}

export async function readManifest(syncPath: string): Promise<SyncManifest> {
  const { manifestFile } = await getSyncDirs(syncPath)
  const existing = await readJsonFile<SyncManifest>(manifestFile)
  return existing ?? createEmptyManifest()
}

export async function writeManifest(syncPath: string, manifest: SyncManifest): Promise<void> {
  const { manifestFile } = await getSyncDirs(syncPath)
  manifest.updatedAt = new Date().toISOString()
  manifest.deviceId = getOrCreateDeviceId()
  await writeJsonFile(manifestFile, manifest)
}

export async function updateManifestTimestamp(syncPath: string): Promise<SyncManifest> {
  const manifest = await readManifest(syncPath)
  await writeManifest(syncPath, manifest)
  return manifest
}
