import { join } from '@tauri-apps/api/path'
import { getOrCreateDeviceId } from './device'
import { ensureSyncDirs, writeJsonFile } from './io'
import type { SyncAction, SyncChangeRecord, SyncEntityType } from './types'
import { SYNC_PROTOCOL_VERSION } from './types'

export async function writeChangeLog(
  syncPath: string,
  entityType: SyncEntityType,
  entityId: string,
  action: SyncAction
): Promise<SyncChangeRecord> {
  const dirs = await ensureSyncDirs(syncPath)
  const timestamp = new Date().toISOString()
  const deviceId = getOrCreateDeviceId()
  const changeId = crypto.randomUUID()
  const fileName = `${timestamp.replace(/[:.]/g, '-')}_${deviceId.slice(0, 8)}_${changeId}.json`

  const record: SyncChangeRecord = {
    version: SYNC_PROTOCOL_VERSION,
    timestamp,
    deviceId,
    entityType,
    entityId,
    action,
    updatedAt: timestamp,
  }

  await writeJsonFile(await join(dirs.changes, fileName), record)
  return record
}
