import { useState } from 'react'
import type { Tag } from '../../types'
import { useAppStore } from '../../stores/appStore'
import { useTagStore } from '../../stores/tagStore'
import { useI18n } from '../../lib/i18n'

interface TagFilterProps {
  tags: Tag[]
}

export default function TagFilter({ tags }: TagFilterProps) {
  const { filterOptions, toggleTagId } = useAppStore()
  const { createTag, deleteTag } = useTagStore()
  const [showNewTagInput, setShowNewTagInput] = useState(false)
  const [newTagName, setNewTagName] = useState('')
  const [newTagColor, setNewTagColor] = useState('#a78bfa')
  const [tagQuery, setTagQuery] = useState('')
  const { t } = useI18n()

  // Sidebars with hundreds of tags get unwieldy: filter by query, keep selected
  // tags pinned to the top, and cap the unfiltered list so the DOM stays light.
  const TAG_DISPLAY_LIMIT = 100
  const q = tagQuery.trim().toLowerCase()
  const selectedIds = filterOptions.tagIds
  const filteredTags = tags
    .filter((t) => !q || t.name.toLowerCase().includes(q))
    .sort((a, b) => {
      const aSel = selectedIds.includes(a.id) ? 0 : 1
      const bSel = selectedIds.includes(b.id) ? 0 : 1
      if (aSel !== bSel) return aSel - bSel
      return a.name.localeCompare(b.name)
    })
  const visibleTags = q ? filteredTags : filteredTags.slice(0, TAG_DISPLAY_LIMIT)
  const hiddenCount = filteredTags.length - visibleTags.length

  const handleCreateTag = async () => {
    if (!newTagName.trim()) return
    try {
      await createTag(newTagName.trim(), newTagColor)
      setNewTagName('')
      setShowNewTagInput(false)
    } catch (err) {
      console.error('Failed to create tag:', err)
    }
  }

  const handleDeleteTag = async (tagId: string, tagName: string, e: React.MouseEvent) => {
    e.stopPropagation()
    if (!confirm(`タグ「${tagName}」を削除しますか？`)) return
    try {
      await deleteTag(tagId)
    } catch (err) {
      console.error('Failed to delete tag:', err)
    }
  }

  return (
    <div className="space-y-1">
      {/* Tag search (shown once the list is long enough to warrant it) */}
      {tags.length > 10 && (
        <input
          type="text"
          value={tagQuery}
          onChange={(e) => setTagQuery(e.target.value)}
          placeholder={t('searchTags')}
          className="w-full bg-nai-bg0 text-nai-text text-sm px-3 py-1.5 mb-1 rounded border border-nai-border focus:outline-none focus:border-nai-accent"
        />
      )}

      {/* Add Tag Button */}
      {!showNewTagInput && (
        <button
          onClick={() => setShowNewTagInput(true)}
          className="w-full flex items-center gap-2 px-3 py-2 text-nai-text-muted hover:bg-nai-bg2 hover:text-nai-text rounded-lg transition-colors text-left"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          <span className="text-sm">{t('addTagButton')}</span>
        </button>
      )}

      {/* New Tag Input */}
      {showNewTagInput && (
        <div className="p-2 bg-nai-bg2 rounded-lg space-y-2">
          <input
            type="text"
            value={newTagName}
            onChange={(e) => setNewTagName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleCreateTag()
              if (e.key === 'Escape') setShowNewTagInput(false)
            }}
            placeholder={t('tagName')}
            className="w-full bg-nai-bg0 text-nai-text text-sm px-2 py-1.5 rounded border border-nai-border focus:outline-none focus:border-nai-accent"
            autoFocus
          />
          <div className="flex items-center gap-2">
            <input
              type="color"
              value={newTagColor}
              onChange={(e) => setNewTagColor(e.target.value)}
              className="w-8 h-8 rounded cursor-pointer border-0"
            />
            <button
              onClick={handleCreateTag}
              className="flex-1 px-3 py-1.5 bg-nai-accent hover:bg-nai-accent-hover text-nai-bg0 text-sm font-medium rounded transition-colors"
            >
              {t('create')}
            </button>
            <button
              onClick={() => setShowNewTagInput(false)}
              className="px-3 py-1.5 bg-nai-bg3 hover:bg-nai-border text-nai-text-muted text-sm rounded transition-colors"
            >
              {t('cancel')}
            </button>
          </div>
        </div>
      )}

      {/* Tag List */}
      {visibleTags.map((tag) => (
        <div
          key={tag.id}
          onClick={() => toggleTagId(tag.id)}
          className={`group flex items-center gap-2 px-3 py-1.5 rounded-lg cursor-pointer transition-colors ${
            filterOptions.tagIds.includes(tag.id)
              ? 'bg-nai-bg3 text-nai-text'
              : 'text-nai-text-muted hover:bg-nai-bg2 hover:text-nai-text'
          }`}
        >
          {/* Tag Color Dot */}
          <span
            className="w-3 h-3 rounded-full shrink-0"
            style={{ backgroundColor: tag.color || '#a78bfa' }}
          />

          {/* Tag Name */}
          <span className="flex-1 text-sm truncate">{tag.name}</span>

          {/* Checkbox Indicator */}
          {filterOptions.tagIds.includes(tag.id) && (
            <svg className="w-4 h-4 text-nai-accent shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          )}

          {/* Delete Button */}
          <button
            onClick={(e) => handleDeleteTag(tag.id, tag.name, e)}
            className="hidden group-hover:block p-1 hover:bg-red-900/50 rounded text-red-400"
            title={t('delete')}
          >
            <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      ))}

      {/* Hidden-count hint when the unfiltered list is truncated */}
      {hiddenCount > 0 && (
        <p className="text-xs text-nai-text-placeholder px-3 py-1.5">
          他 {hiddenCount} 件（検索で絞り込み）
        </p>
      )}

      {/* No results for the current query */}
      {q && filteredTags.length === 0 && (
        <p className="text-xs text-nai-text-placeholder px-3 py-2">
          「{tagQuery}」に一致するタグはありません
        </p>
      )}

      {tags.length === 0 && !showNewTagInput && (
        <p className="text-xs text-nai-text-placeholder px-3 py-2">
          {t('noTags')}
        </p>
      )}
    </div>
  )
}
