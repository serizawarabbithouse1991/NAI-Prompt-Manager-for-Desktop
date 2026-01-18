import { useState } from 'react'
import type { FolderWithChildren } from '../../types'
import { useFolderStore } from '../../stores/folderStore'

interface FolderTreeProps {
  folders: FolderWithChildren[]
  selectedFolderId: string | null
  onSelectFolder: (id: string | null) => void
  showNewFolderInput?: boolean
  onCloseNewFolderInput?: () => void
  parentId?: string | null
  level?: number
}

export default function FolderTree({
  folders,
  selectedFolderId,
  onSelectFolder,
  showNewFolderInput,
  onCloseNewFolderInput,
  parentId = null,
  level = 0,
}: FolderTreeProps) {
  const [expandedFolders, setExpandedFolders] = useState<Set<string>>(new Set())
  const [newFolderName, setNewFolderName] = useState('')
  const [editingFolderId, setEditingFolderId] = useState<string | null>(null)
  const [editingName, setEditingName] = useState('')
  const { createFolder, updateFolder, deleteFolder } = useFolderStore()

  const toggleExpand = (folderId: string) => {
    setExpandedFolders((prev) => {
      const newSet = new Set(prev)
      if (newSet.has(folderId)) {
        newSet.delete(folderId)
      } else {
        newSet.add(folderId)
      }
      return newSet
    })
  }

  const handleCreateFolder = async () => {
    if (!newFolderName.trim()) return
    try {
      await createFolder(newFolderName.trim(), parentId)
      setNewFolderName('')
      onCloseNewFolderInput?.()
    } catch (err) {
      console.error('Failed to create folder:', err)
    }
  }

  const handleRename = async (folderId: string) => {
    if (!editingName.trim()) {
      setEditingFolderId(null)
      return
    }
    try {
      await updateFolder(folderId, { name: editingName.trim() })
      setEditingFolderId(null)
    } catch (err) {
      console.error('Failed to rename folder:', err)
    }
  }

  const handleDelete = async (folderId: string, name: string) => {
    if (!confirm(`「${name}」を削除しますか？\n※フォルダ内の画像は未分類に移動されます`)) {
      return
    }
    try {
      await deleteFolder(folderId)
      if (selectedFolderId === folderId) {
        onSelectFolder(null)
      }
    } catch (err) {
      console.error('Failed to delete folder:', err)
    }
  }

  return (
    <div className="space-y-0.5">
      {/* New Folder Input */}
      {showNewFolderInput && level === 0 && (
        <div className="flex items-center gap-1 px-2 py-1">
          <svg className="w-4 h-4 text-nai-accent shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
          </svg>
          <input
            type="text"
            value={newFolderName}
            onChange={(e) => setNewFolderName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleCreateFolder()
              if (e.key === 'Escape') onCloseNewFolderInput?.()
            }}
            onBlur={() => {
              if (!newFolderName.trim()) onCloseNewFolderInput?.()
            }}
            placeholder="新規プロジェクト"
            className="flex-1 bg-nai-bg0 text-nai-text text-sm px-2 py-1 rounded border border-nai-border focus:outline-none focus:border-nai-accent"
            autoFocus
          />
        </div>
      )}

      {folders.map((folder) => (
        <div key={folder.id}>
          <div
            className={`group flex items-center gap-1 px-2 py-1.5 rounded-lg cursor-pointer transition-colors ${
              selectedFolderId === folder.id
                ? 'bg-nai-bg3 text-nai-text'
                : 'text-nai-text-muted hover:bg-nai-bg2 hover:text-nai-text'
            }`}
            style={{ paddingLeft: `${8 + level * 12}px` }}
            onClick={() => onSelectFolder(folder.id)}
          >
            {/* Expand Arrow */}
            {folder.children.length > 0 ? (
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  toggleExpand(folder.id)
                }}
                className="p-0.5 hover:bg-nai-bg3 rounded"
              >
                <svg
                  className={`w-3 h-3 transition-transform ${
                    expandedFolders.has(folder.id) ? 'rotate-90' : ''
                  }`}
                  fill="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path d="M10 6l6 6-6 6V6z" />
                </svg>
              </button>
            ) : (
              <span className="w-4" />
            )}

            {/* Folder Icon */}
            <svg
              className="w-4 h-4 shrink-0"
              fill={folder.color || '#a78bfa'}
              stroke="none"
              viewBox="0 0 24 24"
            >
              <path d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
            </svg>

            {/* Folder Name */}
            {editingFolderId === folder.id ? (
              <input
                type="text"
                value={editingName}
                onChange={(e) => setEditingName(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') handleRename(folder.id)
                  if (e.key === 'Escape') setEditingFolderId(null)
                }}
                onBlur={() => handleRename(folder.id)}
                onClick={(e) => e.stopPropagation()}
                className="flex-1 bg-nai-bg0 text-nai-text text-sm px-1 rounded border border-nai-border focus:outline-none focus:border-nai-accent"
                autoFocus
              />
            ) : (
              <span className="flex-1 text-sm truncate">{folder.name}</span>
            )}

            {/* Actions */}
            <div className="hidden group-hover:flex items-center gap-1">
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  setEditingFolderId(folder.id)
                  setEditingName(folder.name)
                }}
                className="p-1 hover:bg-nai-bg3 rounded"
                title="名前を変更"
              >
                <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  handleDelete(folder.id, folder.name)
                }}
                className="p-1 hover:bg-red-900/50 rounded text-red-400"
                title="削除"
              >
                <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </button>
            </div>
          </div>

          {/* Children */}
          {folder.children.length > 0 && expandedFolders.has(folder.id) && (
            <FolderTree
              folders={folder.children}
              selectedFolderId={selectedFolderId}
              onSelectFolder={onSelectFolder}
              parentId={folder.id}
              level={level + 1}
            />
          )}
        </div>
      ))}
    </div>
  )
}
