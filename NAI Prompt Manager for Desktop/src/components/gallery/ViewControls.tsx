import { useState } from 'react'
import { useAppStore } from '../../stores/appStore'
import { useImageStore } from '../../stores/imageStore'
import { useFolderStore } from '../../stores/folderStore'
import { useTagStore } from '../../stores/tagStore'
import type { ImageWithDetails } from '../../types'
import { exportImageFilesToFolder } from '../../lib/export'
import { useI18n } from '../../lib/i18n'

interface ViewControlsProps {
  imageCount: number
  images: ImageWithDetails[]
  onUpload: () => void
  batchMode: boolean
  onToggleBatchMode: () => void
  selectedCount: number
  onSelectAll: () => void
  onClearSelection: () => void
}

export default function ViewControls({
  imageCount,
  images,
  onUpload,
  batchMode,
  onToggleBatchMode,
  selectedCount,
  onSelectAll,
  onClearSelection,
}: ViewControlsProps) {
  const {
    viewOptions,
    filterOptions,
    setViewMode,
    setThumbnailSize,
    setSortBy,
    setSortOrder,
    setSearchQuery,
    setFavoritesOnly,
    selectedImageIds,
    clearSelection,
  } = useAppStore()
  const { deleteImages, moveToFolder, addTagToImages } = useImageStore()
  const { folders } = useFolderStore()
  const { tags } = useTagStore()
  const [exporting, setExporting] = useState(false)
  const [exportMessage, setExportMessage] = useState<string | null>(null)
  const { t } = useI18n()

  const selectedIds = () => Array.from(selectedImageIds)
  const selectedImages = () => {
    const ids = new Set(selectedIds())
    return images.filter((image) => ids.has(image.id))
  }

  const handleBatchDelete = async () => {
    const ids = selectedIds()
    if (ids.length === 0) return
    if (!confirm(`選択した ${ids.length} 件の画像を削除しますか？`)) return
    try {
      await deleteImages(ids)
      clearSelection()
    } catch (err) {
      console.error('Batch delete failed:', err)
    }
  }

  const handleBatchMove = async (value: string) => {
    const ids = selectedIds()
    if (ids.length === 0) return
    try {
      await moveToFolder(ids, value === 'uncategorized' ? null : value)
      clearSelection()
    } catch (err) {
      console.error('Batch move failed:', err)
    }
  }

  const handleBatchTag = async (tagId: string) => {
    const ids = selectedIds()
    const tag = tags.find((t) => t.id === tagId)
    if (ids.length === 0 || !tag) return
    try {
      await addTagToImages(ids, tag)
    } catch (err) {
      console.error('Batch tag failed:', err)
    }
  }

  const handleExportImages = async (targets: ImageWithDetails[]) => {
    if (targets.length === 0) return
    setExporting(true)
    setExportMessage(t('exporting'))
    try {
      const result = await exportImageFilesToFolder(targets)
      if (!result.destination) {
        setExportMessage(null)
        return
      }
      setExportMessage(
        result.failed > 0
          ? t('exportDoneWithFailed', { count: result.exported, failed: result.failed })
          : t('exportDone', { count: result.exported })
      )
    } catch (err) {
      console.error('Batch image export failed:', err)
      setExportMessage(t('exportFailed'))
    } finally {
      setExporting(false)
    }
  }

  return (
    <div className="shrink-0 p-3 border-b border-nai-border bg-nai-bg1/50">
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            type="text"
            placeholder={t('search')}
            value={filterOptions.searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 bg-nai-bg0 border border-nai-border text-nai-text placeholder-nai-text-placeholder focus:outline-none focus:border-nai-accent rounded-lg text-sm"
          />
        </div>

        {/* Controls */}
        <div className="flex items-center gap-2">
          {/* Sort */}
          <select
            value={`${viewOptions.sortBy}-${viewOptions.sortOrder}`}
            onChange={(e) => {
              const [sortBy, sortOrder] = e.target.value.split('-') as ['date' | 'name' | 'size', 'asc' | 'desc']
              setSortBy(sortBy)
              setSortOrder(sortOrder)
            }}
            className="px-3 py-2 bg-nai-bg0 text-nai-text text-sm rounded-lg border border-nai-border focus:outline-none focus:border-nai-accent"
          >
            <option value="date-desc">{t('newest')}</option>
            <option value="date-asc">{t('oldest')}</option>
            <option value="name-asc">{t('nameAsc')}</option>
            <option value="name-desc">{t('nameDesc')}</option>
            <option value="size-desc">{t('sizeDesc')}</option>
            <option value="size-asc">{t('sizeAsc')}</option>
          </select>

          {/* Favorites filter */}
          <button
            className={`p-2 rounded-lg transition-colors ${
              filterOptions.favoritesOnly 
                ? 'bg-red-600 text-white' 
                : 'bg-nai-bg0 text-nai-text-muted hover:bg-nai-bg2 border border-nai-border'
            }`}
            onClick={() => setFavoritesOnly(!filterOptions.favoritesOnly)}
            title={t('favoritesOnly')}
          >
            <svg className={`w-4 h-4 ${filterOptions.favoritesOnly ? 'fill-current' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
            </svg>
          </button>

          {/* Divider */}
          <div className="w-px h-6 bg-nai-border" />

          {/* View mode toggle */}
          <div className="flex items-center bg-nai-bg0 border border-nai-border rounded-lg">
            <button
              className={`p-2 rounded-l-lg transition-colors ${
                viewOptions.mode === 'grid' 
                  ? 'bg-nai-accent text-nai-bg0' 
                  : 'text-nai-text-muted hover:bg-nai-bg2'
              }`}
              onClick={() => setViewMode('grid')}
              title={t('gridView')}
            >
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                <path d="M3 3h7v7H3V3zm0 11h7v7H3v-7zm11-11h7v7h-7V3zm0 11h7v7h-7v-7z" />
              </svg>
            </button>
            <button
              className={`p-2 rounded-r-lg transition-colors ${
                viewOptions.mode === 'list' 
                  ? 'bg-nai-accent text-nai-bg0' 
                  : 'text-nai-text-muted hover:bg-nai-bg2'
              }`}
              onClick={() => setViewMode('list')}
              title={t('listView')}
            >
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                <path d="M3 4h18v2H3V4zm0 7h18v2H3v-2zm0 7h18v2H3v-2z" />
              </svg>
            </button>
          </div>

          {/* Thumbnail size slider (grid mode only) */}
          {viewOptions.mode === 'grid' && (
            <div className="hidden sm:flex items-center gap-2 px-2">
              <svg className="w-3 h-3 text-nai-text-muted" fill="currentColor" viewBox="0 0 24 24">
                <path d="M3 3h7v7H3V3zm0 11h7v7H3v-7zm11-11h7v7h-7V3zm0 11h7v7h-7v-7z" />
              </svg>
              <input
                type="range"
                min="0"
                max="3"
                value={['small', 'medium', 'large', 'xlarge'].indexOf(viewOptions.thumbnailSize)}
                onChange={(e) => {
                  const sizes = ['small', 'medium', 'large', 'xlarge'] as const
                  setThumbnailSize(sizes[parseInt(e.target.value)])
                }}
                className="w-20 h-1.5 bg-nai-bg3 rounded-lg appearance-none cursor-pointer accent-nai-accent"
                title={`サイズ: ${viewOptions.thumbnailSize}`}
              />
              <svg className="w-5 h-5 text-nai-text-muted" fill="currentColor" viewBox="0 0 24 24">
                <path d="M3 3h7v7H3V3zm0 11h7v7H3v-7zm11-11h7v7h-7V3zm0 11h7v7h-7v-7z" />
              </svg>
            </div>
          )}

          {/* Divider */}
          <div className="w-px h-6 bg-nai-border" />

          {/* Export visible images */}
          <button
            onClick={() => handleExportImages(images)}
            disabled={exporting || images.length === 0}
            className="px-3 py-2 bg-nai-bg0 hover:bg-nai-bg2 disabled:opacity-50 text-nai-text-muted rounded-lg border border-nai-border transition-colors flex items-center gap-2 text-sm"
            title={t('exportVisible')}
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a2 2 0 002 2h12a2 2 0 002-2v-1M12 4v10m0 0l-4-4m4 4l4-4" />
            </svg>
            <span className="hidden lg:inline">{exporting ? t('exporting') : t('exportVisible')}</span>
          </button>

          {/* Batch mode */}
          <button
            className={`px-3 py-2 text-sm rounded-lg transition-colors flex items-center gap-2 ${
              batchMode 
                ? 'bg-orange-600 hover:bg-orange-700 text-white' 
                : 'bg-nai-bg0 hover:bg-nai-bg2 text-nai-text-muted border border-nai-border'
            }`}
            onClick={onToggleBatchMode}
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
            </svg>
            <span className="hidden lg:inline">{batchMode ? t('batchEnd') : t('batchStart')}</span>
          </button>

          {/* Upload button */}
          <button
            onClick={onUpload}
            className="px-4 py-2 bg-nai-accent hover:bg-nai-accent-hover text-nai-bg0 font-medium rounded-lg transition-colors flex items-center gap-2"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            <span className="hidden sm:inline">{t('upload')}</span>
          </button>
        </div>
      </div>

      {/* Batch actions */}
      {batchMode && selectedCount > 0 && (
        <div className="flex flex-wrap items-center gap-2 mt-3 p-3 bg-nai-bg2 rounded-lg">
          <span className="text-nai-text text-sm">{t('selectedCount', { count: selectedCount })}</span>

          {/* Add tag to selection */}
          {tags.length > 0 && (
            <select
              className="px-2 py-1.5 bg-nai-bg0 text-nai-text-muted rounded text-sm border border-nai-border focus:outline-none focus:border-nai-accent"
              onChange={(e) => {
                if (e.target.value) {
                  handleBatchTag(e.target.value)
                  e.target.value = ''
                }
              }}
              defaultValue=""
            >
              <option value="" disabled>{t('addTag')}</option>
              {tags.map((tag) => (
                <option key={tag.id} value={tag.id}>{tag.name}</option>
              ))}
            </select>
          )}

          {/* Move selection to folder */}
          <select
            className="px-2 py-1.5 bg-nai-bg0 text-nai-text-muted rounded text-sm border border-nai-border focus:outline-none focus:border-nai-accent"
            onChange={(e) => {
              if (e.target.value) {
                handleBatchMove(e.target.value)
                e.target.value = ''
              }
            }}
            defaultValue=""
          >
            <option value="" disabled>{t('moveToFolder')}</option>
            <option value="uncategorized">{t('uncategorized')}</option>
            {folders.map((folder) => (
              <option key={folder.id} value={folder.id}>{folder.name}</option>
            ))}
          </select>

          {/* Delete selection */}
          <button
            onClick={() => handleExportImages(selectedImages())}
            disabled={exporting}
            className="px-3 py-1.5 text-sm bg-nai-bg0 hover:bg-nai-bg3 disabled:opacity-50 text-nai-text rounded transition-colors border border-nai-border"
          >
            {exporting ? t('exporting') : t('export')}
          </button>

          <button
            onClick={handleBatchDelete}
            className="px-3 py-1.5 text-sm bg-red-900/50 hover:bg-red-900 text-red-300 rounded transition-colors"
          >
            {t('delete')}
          </button>

          <div className="flex-1" />
          <button
            onClick={onSelectAll}
            className="px-3 py-1.5 text-sm text-nai-text-muted hover:text-nai-text hover:bg-nai-bg3 rounded transition-colors"
          >
            {t('selectAll')}
          </button>
          <button
            onClick={onClearSelection}
            className="px-3 py-1.5 text-sm text-nai-text-muted hover:text-nai-text hover:bg-nai-bg3 rounded transition-colors"
          >
            {t('clearSelection')}
          </button>
        </div>
      )}

      {/* Image count */}
      <div className="mt-2 text-xs text-nai-text-muted">
        {t('imageCount', { count: imageCount })}
        {exportMessage && <span className="ml-3 text-nai-accent">{exportMessage}</span>}
      </div>
    </div>
  )
}
