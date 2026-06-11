import { useAppStore } from '../../stores/appStore'
import type { SyncDeviceInfo } from './types'

function detectPlatform(): string {
  if (typeof navigator !== 'undefined' && navigator.userAgent.includes('Windows')) {
    return 'windows'
  }
  return 'desktop'
}

export function getOrCreateDeviceId(): string {
  const { settings, updateSettings } = useAppStore.getState()
  if (settings.icloudSyncDeviceId) {
    return settings.icloudSyncDeviceId
  }
  const deviceId = crypto.randomUUID()
  updateSettings({ icloudSyncDeviceId: deviceId })
  return deviceId
}

export function getDeviceInfo(lastSyncedAt: string | null = null): SyncDeviceInfo {
  return {
    deviceId: getOrCreateDeviceId(),
    deviceName: 'NAI Prompt Manager Desktop',
    platform: detectPlatform(),
    lastSyncedAt,
  }
}
