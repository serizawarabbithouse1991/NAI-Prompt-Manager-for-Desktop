import { supabase } from './supabase'
import type { RealtimeChannel } from '@supabase/supabase-js'

type TableName = 'images' | 'folders' | 'tags' | 'prompts' | 'image_ratings' | 'image_tags'

interface SubscriptionCallbacks {
  onInsert?: (payload: Record<string, unknown>) => void
  onUpdate?: (payload: Record<string, unknown>) => void
  onDelete?: (payload: Record<string, unknown>) => void
}

const channels: Map<string, RealtimeChannel> = new Map()

/**
 * Subscribe to realtime changes on a table
 */
export function subscribeToTable(
  userId: string,
  table: TableName,
  callbacks: SubscriptionCallbacks
): () => void {
  const channelKey = `${table}:${userId}`
  
  // Unsubscribe from existing channel if any
  const existingChannel = channels.get(channelKey)
  if (existingChannel) {
    existingChannel.unsubscribe()
  }

  const channel = supabase
    .channel(channelKey)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: table,
        filter: `user_id=eq.${userId}`,
      },
      (payload) => {
        switch (payload.eventType) {
          case 'INSERT':
            callbacks.onInsert?.(payload.new as Record<string, unknown>)
            break
          case 'UPDATE':
            callbacks.onUpdate?.(payload.new as Record<string, unknown>)
            break
          case 'DELETE':
            callbacks.onDelete?.(payload.old as Record<string, unknown>)
            break
        }
      }
    )
    .subscribe()

  channels.set(channelKey, channel)

  // Return unsubscribe function
  return () => {
    channel.unsubscribe()
    channels.delete(channelKey)
  }
}

/**
 * Subscribe to all relevant tables for the app
 */
export function subscribeToAllTables(
  userId: string,
  callbacks: {
    onImageChange?: () => void
    onFolderChange?: () => void
    onTagChange?: () => void
  }
): () => void {
  const unsubscribers: (() => void)[] = []

  // Images
  unsubscribers.push(
    subscribeToTable(userId, 'images', {
      onInsert: callbacks.onImageChange,
      onUpdate: callbacks.onImageChange,
      onDelete: callbacks.onImageChange,
    })
  )

  // Folders
  unsubscribers.push(
    subscribeToTable(userId, 'folders', {
      onInsert: callbacks.onFolderChange,
      onUpdate: callbacks.onFolderChange,
      onDelete: callbacks.onFolderChange,
    })
  )

  // Tags
  unsubscribers.push(
    subscribeToTable(userId, 'tags', {
      onInsert: callbacks.onTagChange,
      onUpdate: callbacks.onTagChange,
      onDelete: callbacks.onTagChange,
    })
  )

  // Image tags (affects images)
  unsubscribers.push(
    subscribeToTable(userId, 'image_tags', {
      onInsert: callbacks.onImageChange,
      onDelete: callbacks.onImageChange,
    })
  )

  // Image ratings (affects images)
  unsubscribers.push(
    subscribeToTable(userId, 'image_ratings', {
      onInsert: callbacks.onImageChange,
      onUpdate: callbacks.onImageChange,
    })
  )

  // Return combined unsubscribe function
  return () => {
    unsubscribers.forEach(unsub => unsub())
  }
}

/**
 * Unsubscribe from all channels
 */
export function unsubscribeAll(): void {
  channels.forEach(channel => channel.unsubscribe())
  channels.clear()
}
