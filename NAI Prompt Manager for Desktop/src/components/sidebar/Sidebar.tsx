import { useEffect, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { useAppStore } from '../../stores/appStore'
import { useFolderStore } from '../../stores/folderStore'
import { useTagStore } from '../../stores/tagStore'
import FolderTree from './FolderTree'
import TagFilter from './TagFilter'

export default function Sidebar() {
  const location = useLocation()
  const { filterOptions, setFolderId } = useAppStore()
  const { folderTree, loadFolders } = useFolderStore()
  const { tags, loadTags } = useTagStore()
  const [showNewFolderInput, setShowNewFolderInput] = useState(false)

  useEffect(() => {
    loadFolders()
    loadTags()
  }, [loadFolders, loadTags])

  return (
    <aside className="w-56 bg-nai-bg1 border-r border-nai-border flex flex-col overflow-hidden">
      {/* Navigation */}
      <nav className="p-2 border-b border-nai-border">
        <Link
          to="/gallery"
          className={`flex items-center gap-2 px-3 py-2 rounded-lg transition-colors ${
            location.pathname === '/gallery'
              ? 'bg-nai-accent/20 text-nai-accent'
              : 'text-nai-text-muted hover:bg-nai-bg2 hover:text-nai-text'
          }`}
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          <span className="text-sm font-medium">ギャラリー</span>
        </Link>
        <Link
          to="/settings"
          className={`flex items-center gap-2 px-3 py-2 rounded-lg transition-colors ${
            location.pathname === '/settings'
              ? 'bg-nai-accent/20 text-nai-accent'
              : 'text-nai-text-muted hover:bg-nai-bg2 hover:text-nai-text'
          }`}
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <span className="text-sm font-medium">設定</span>
        </Link>
      </nav>

      {/* Folders Section */}
      <div className="flex-1 overflow-y-auto scrollbar-thin">
        <div className="p-2">
          {/* Section Header */}
          <div className="flex items-center justify-between px-2 py-1">
            <span className="text-xs font-medium text-nai-text-muted uppercase tracking-wider">
              プロジェクト
            </span>
            <button
              onClick={() => setShowNewFolderInput(true)}
              className="p-1 hover:bg-nai-bg2 rounded transition-colors"
              title="新規プロジェクト"
            >
              <svg className="w-4 h-4 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
            </button>
          </div>

          {/* All Images */}
          <button
            onClick={() => setFolderId(null)}
            className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg transition-colors text-left ${
              filterOptions.folderId === null
                ? 'bg-nai-bg3 text-nai-text'
                : 'text-nai-text-muted hover:bg-nai-bg2 hover:text-nai-text'
            }`}
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
            <span className="text-sm">すべての画像</span>
          </button>

          {/* Uncategorized */}
          <button
            onClick={() => setFolderId('uncategorized')}
            className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg transition-colors text-left ${
              filterOptions.folderId === 'uncategorized'
                ? 'bg-nai-bg3 text-nai-text'
                : 'text-nai-text-muted hover:bg-nai-bg2 hover:text-nai-text'
            }`}
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
            </svg>
            <span className="text-sm">未分類</span>
          </button>

          {/* Folder Tree */}
          <FolderTree
            folders={folderTree}
            selectedFolderId={filterOptions.folderId}
            onSelectFolder={setFolderId}
            showNewFolderInput={showNewFolderInput}
            onCloseNewFolderInput={() => setShowNewFolderInput(false)}
          />
        </div>

        {/* Tags Section */}
        <div className="p-2 border-t border-nai-border">
          <div className="px-2 py-1">
            <span className="text-xs font-medium text-nai-text-muted uppercase tracking-wider">
              タグ
            </span>
          </div>
          <TagFilter tags={tags} />
        </div>
      </div>
    </aside>
  )
}
