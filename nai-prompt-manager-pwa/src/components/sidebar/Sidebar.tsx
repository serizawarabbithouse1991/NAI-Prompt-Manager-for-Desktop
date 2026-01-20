import { useState } from 'react'
import type { Folder, Tag, FilterOptions } from '../../types'
import { useFolderStore } from '../../stores/folderStore'

interface SidebarProps {
  folders: Folder[]
  tags: Tag[]
  filterOptions: FilterOptions
  onFolderSelect: (folderId: string | null) => void
  onTagFilter: (tagIds: string[]) => void
  onFavoritesToggle: () => void
}

export function Sidebar({
  folders,
  tags,
  filterOptions,
  onFolderSelect,
  onTagFilter,
  onFavoritesToggle,
}: SidebarProps) {
  const [showNewFolderInput, setShowNewFolderInput] = useState(false)
  const [newFolderName, setNewFolderName] = useState('')
  const { createFolder } = useFolderStore()

  const handleCreateFolder = async () => {
    if (!newFolderName.trim()) return
    
    try {
      await createFolder(newFolderName.trim())
      setNewFolderName('')
      setShowNewFolderInput(false)
    } catch (error) {
      console.error('Failed to create folder:', error)
    }
  }

  const handleTagToggle = (tagId: string) => {
    const currentTags = filterOptions.tagIds
    if (currentTags.includes(tagId)) {
      onTagFilter(currentTags.filter(id => id !== tagId))
    } else {
      onTagFilter([...currentTags, tagId])
    }
  }

  return (
    <div className="h-full flex flex-col bg-dark-800 overflow-hidden">
      {/* Filters header */}
      <div className="p-4 border-b border-dark-700">
        <h2 className="text-sm font-semibold text-dark-300 uppercase tracking-wider">
          フィルター
        </h2>
      </div>

      <div className="flex-1 overflow-auto">
        {/* Favorites filter */}
        <div className="p-4 border-b border-dark-700">
          <button
            onClick={onFavoritesToggle}
            className={`
              flex items-center gap-2 w-full px-3 py-2 rounded-lg text-sm transition-colors
              ${filterOptions.favoritesOnly
                ? 'bg-red-500/20 text-red-400'
                : 'text-dark-300 hover:bg-dark-700 hover:text-white'
              }
            `}
          >
            <HeartIcon className="w-5 h-5" filled={filterOptions.favoritesOnly} />
            お気に入りのみ
          </button>
        </div>

        {/* Folders */}
        <div className="p-4 border-b border-dark-700">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-sm font-medium text-dark-300">フォルダ</h3>
            <button
              onClick={() => setShowNewFolderInput(true)}
              className="p-1 text-dark-400 hover:text-white transition-colors"
            >
              <PlusIcon className="w-4 h-4" />
            </button>
          </div>

          {/* New folder input */}
          {showNewFolderInput && (
            <div className="flex gap-2 mb-2">
              <input
                type="text"
                value={newFolderName}
                onChange={(e) => setNewFolderName(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleCreateFolder()}
                placeholder="フォルダ名"
                autoFocus
                className="flex-1 px-2 py-1 bg-dark-700 border border-dark-600 rounded text-sm text-white focus:outline-none focus:border-primary-500"
              />
              <button
                onClick={handleCreateFolder}
                className="px-2 py-1 bg-primary-600 text-white rounded text-sm hover:bg-primary-500"
              >
                追加
              </button>
              <button
                onClick={() => {
                  setShowNewFolderInput(false)
                  setNewFolderName('')
                }}
                className="px-2 py-1 text-dark-400 hover:text-white text-sm"
              >
                ×
              </button>
            </div>
          )}

          <div className="space-y-1">
            {/* All images */}
            <button
              onClick={() => onFolderSelect(null)}
              className={`
                flex items-center gap-2 w-full px-3 py-2 rounded-lg text-sm transition-colors
                ${filterOptions.folderId === null
                  ? 'bg-primary-500/20 text-primary-400'
                  : 'text-dark-300 hover:bg-dark-700 hover:text-white'
                }
              `}
            >
              <FolderIcon className="w-5 h-5" />
              すべての画像
            </button>

            {/* Folder list */}
            {folders.map(folder => (
              <button
                key={folder.id}
                onClick={() => onFolderSelect(folder.id)}
                className={`
                  flex items-center gap-2 w-full px-3 py-2 rounded-lg text-sm transition-colors
                  ${filterOptions.folderId === folder.id
                    ? 'bg-primary-500/20 text-primary-400'
                    : 'text-dark-300 hover:bg-dark-700 hover:text-white'
                  }
                `}
              >
                <FolderIcon 
                  className="w-5 h-5" 
                  style={{ color: folder.color || undefined }}
                />
                <span className="truncate">{folder.name}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Tags */}
        <div className="p-4">
          <h3 className="text-sm font-medium text-dark-300 mb-2">タグ</h3>
          
          {tags.length === 0 ? (
            <p className="text-xs text-dark-500">タグがありません</p>
          ) : (
            <div className="flex flex-wrap gap-2">
              {tags.map(tag => {
                const isSelected = filterOptions.tagIds.includes(tag.id)
                return (
                  <button
                    key={tag.id}
                    onClick={() => handleTagToggle(tag.id)}
                    className={`
                      px-2 py-1 text-xs rounded-full transition-colors
                      ${isSelected
                        ? 'ring-2 ring-white'
                        : 'hover:ring-1 hover:ring-white/50'
                      }
                    `}
                    style={{
                      backgroundColor: `${tag.color || '#a78bfa'}${isSelected ? '40' : '20'}`,
                      color: tag.color || '#a78bfa',
                    }}
                  >
                    {tag.name}
                  </button>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function HeartIcon({ className, filled }: { className?: string; filled?: boolean }) {
  return filled ? (
    <svg className={className} fill="currentColor" viewBox="0 0 20 20">
      <path fillRule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clipRule="evenodd" />
    </svg>
  ) : (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
    </svg>
  )
}

function FolderIcon({ className, style }: { className?: string; style?: React.CSSProperties }) {
  return (
    <svg className={className} style={style} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
    </svg>
  )
}

function PlusIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
    </svg>
  )
}
