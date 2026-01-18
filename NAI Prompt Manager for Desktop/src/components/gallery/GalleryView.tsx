import { useEffect, useMemo, useState, useCallback } from 'react'
import { useImageStore } from '../../stores/imageStore'
import { useAppStore } from '../../stores/appStore'
import { useTagStore } from '../../stores/tagStore'
import ImageCard from './ImageCard'
import ImageDetail from './ImageDetail'
import UploadModal from '../upload/UploadModal'
import ViewControls from './ViewControls'
import type { ImageWithDetails } from '../../types'

export default function GalleryView() {
  const { images, loading, loadImages } = useImageStore()
  const { tags, loadTags } = useTagStore()
  const { 
    viewOptions, 
    filterOptions, 
    batchMode, 
    setBatchMode,
    selectedImageIds,
    clearSelection,
    selectAll,
  } = useAppStore()
  const [uploadModalOpen, setUploadModalOpen] = useState(false)
  const [selectedImage, setSelectedImage] = useState<ImageWithDetails | null>(null)
  const [isDraggingOver, setIsDraggingOver] = useState(false)

  useEffect(() => {
    loadImages()
    loadTags()
  }, [loadImages, loadTags])

  // Filter and sort images
  const filteredImages = useMemo(() => {
    let result = images.filter((image) => {
      // Deleted filter
      if (image.deleted_at) return false

      // Folder filter
      if (filterOptions.folderId !== null) {
        if (filterOptions.folderId === 'uncategorized') {
          if (image.folder_id !== null) return false
        } else if (image.folder_id !== filterOptions.folderId) {
          return false
        }
      }

      // Search filter
      if (filterOptions.searchQuery) {
        const query = filterOptions.searchQuery.toLowerCase()
        const matchesFilename = image.filename?.toLowerCase().includes(query)
        const matchesPrompt = image.prompt?.positive_prompt?.toLowerCase().includes(query)
        const matchesNegative = image.prompt?.negative_prompt?.toLowerCase().includes(query)
        if (!matchesFilename && !matchesPrompt && !matchesNegative) {
          return false
        }
      }

      // Favorites filter
      if (filterOptions.favoritesOnly) {
        if (!image.rating?.is_favorite) return false
      }

      // Tags filter
      if (filterOptions.tagIds.length > 0) {
        const imageTags = image.tags.map((t) => t.id)
        const hasAllTags = filterOptions.tagIds.every((tagId) => imageTags.includes(tagId))
        if (!hasAllTags) return false
      }

      return true
    })

    // Sort
    result.sort((a, b) => {
      let comparison = 0
      switch (viewOptions.sortBy) {
        case 'date':
          comparison = new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
          break
        case 'name':
          comparison = (a.filename || '').localeCompare(b.filename || '')
          break
        case 'size':
          comparison = (a.file_size || 0) - (b.file_size || 0)
          break
      }
      return viewOptions.sortOrder === 'asc' ? comparison : -comparison
    })

    return result
  }, [images, filterOptions, viewOptions.sortBy, viewOptions.sortOrder])

  // Drag and drop handlers
  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    if (e.dataTransfer.types.includes('Files')) {
      setIsDraggingOver(true)
    }
  }, [])

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setIsDraggingOver(false)
  }, [])

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setIsDraggingOver(false)
    
    const files = Array.from(e.dataTransfer.files)
    if (files.length > 0) {
      // Open upload modal with dropped files
      setUploadModalOpen(true)
      // TODO: Pass files to upload modal
    }
  }, [])

  // Thumbnail size configurations
  const thumbnailSizes = {
    small: { gridCols: 'grid-cols-4 sm:grid-cols-6 md:grid-cols-8 lg:grid-cols-10', size: 80 },
    medium: { gridCols: 'grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6', size: 160 },
    large: { gridCols: 'grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5', size: 240 },
    xlarge: { gridCols: 'grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4', size: 320 },
  }

  const handleSelectAll = () => {
    selectAll(filteredImages.map((img) => img.id))
  }

  return (
    <div 
      className="h-full flex flex-col overflow-hidden"
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      {/* Drag Overlay */}
      {isDraggingOver && (
        <div className="drag-overlay">
          <div className="text-center">
            <svg className="w-16 h-16 text-nai-accent mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
            </svg>
            <p className="text-xl font-medium text-nai-text">画像をドロップしてアップロード</p>
          </div>
        </div>
      )}

      {/* Toolbar */}
      <ViewControls
        imageCount={filteredImages.length}
        onUpload={() => setUploadModalOpen(true)}
        batchMode={batchMode}
        onToggleBatchMode={() => {
          setBatchMode(!batchMode)
          clearSelection()
        }}
        selectedCount={selectedImageIds.size}
        onSelectAll={handleSelectAll}
        onClearSelection={clearSelection}
      />

      {/* Gallery Content */}
      <div className="flex-1 overflow-y-auto scrollbar-thin p-4">
        {loading ? (
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <div className="w-12 h-12 border-4 border-nai-accent border-t-transparent rounded-full animate-spin mx-auto mb-4" />
              <p className="text-nai-text-muted">読み込み中...</p>
            </div>
          </div>
        ) : filteredImages.length === 0 ? (
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <div className="w-20 h-20 bg-nai-bg2 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-10 h-10 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
              <h3 className="text-xl font-medium text-nai-text mb-2">画像がありません</h3>
              <p className="text-nai-text-muted mb-6">
                画像をドラッグ&ドロップするか、アップロードボタンを押してください
              </p>
              <button
                onClick={() => setUploadModalOpen(true)}
                className="px-6 py-3 bg-nai-accent hover:bg-nai-accent-hover text-nai-bg0 font-medium rounded-lg transition-colors"
              >
                画像をアップロード
              </button>
            </div>
          </div>
        ) : viewOptions.mode === 'list' ? (
          /* List View */
          <div className="space-y-1">
            {/* List Header */}
            <div className="flex items-center gap-4 px-4 py-2 bg-nai-bg1 rounded text-xs text-nai-text-muted font-medium border-b border-nai-border">
              <div className="w-12" />
              <div className="flex-1">ファイル名</div>
              <div className="w-32 hidden sm:block">サイズ</div>
              <div className="w-40 hidden md:block">作成日</div>
              <div className="w-24">タグ</div>
            </div>
            {filteredImages.map((image) => (
              <ImageCard
                key={image.id}
                image={image}
                viewMode="list"
                onClick={() => setSelectedImage(image)}
              />
            ))}
          </div>
        ) : (
          /* Grid View */
          <div className={`grid ${thumbnailSizes[viewOptions.thumbnailSize].gridCols} gap-3`}>
            {filteredImages.map((image) => (
              <ImageCard
                key={image.id}
                image={image}
                viewMode="grid"
                thumbnailSize={viewOptions.thumbnailSize}
                onClick={() => setSelectedImage(image)}
              />
            ))}
          </div>
        )}
      </div>

      {/* Upload Modal */}
      <UploadModal 
        isOpen={uploadModalOpen} 
        onClose={() => setUploadModalOpen(false)} 
      />

      {/* Image Detail Modal */}
      {selectedImage && (
        <ImageDetail
          image={selectedImage}
          tags={tags}
          onClose={() => setSelectedImage(null)}
          onUpdate={(updated) => setSelectedImage(updated)}
        />
      )}
    </div>
  )
}
