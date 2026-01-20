import { useState, useEffect } from 'react'
import { useImageStore } from '../stores/imageStore'
import { useFolderStore } from '../stores/folderStore'
import { useTagStore } from '../stores/tagStore'
import { ImageGrid } from '../components/gallery/ImageGrid'
import { ImageDetail } from '../components/gallery/ImageDetail'
import { Sidebar } from '../components/sidebar/Sidebar'
import { UploadModal } from '../components/gallery/UploadModal'
import type { ImageWithDetails, ViewOptions, FilterOptions } from '../types'

export function GalleryPage() {
  const [selectedImage, setSelectedImage] = useState<ImageWithDetails | null>(null)
  const [showUploadModal, setShowUploadModal] = useState(false)
  const [viewOptions, setViewOptions] = useState<ViewOptions>({
    mode: 'grid',
    thumbnailSize: 'medium',
    sortBy: 'date',
    sortOrder: 'desc',
  })
  const [filterOptions, setFilterOptions] = useState<FilterOptions>({
    searchQuery: '',
    folderId: null,
    tagIds: [],
    favoritesOnly: false,
  })

  const { images, loading, error, fetchImages } = useImageStore()
  const { folders, fetchFolders } = useFolderStore()
  const { tags, fetchTags } = useTagStore()

  useEffect(() => {
    fetchImages(filterOptions)
    fetchFolders()
    fetchTags()
  }, [fetchImages, fetchFolders, fetchTags, filterOptions])

  const handleSearch = (query: string) => {
    setFilterOptions(prev => ({ ...prev, searchQuery: query }))
  }

  const handleFolderSelect = (folderId: string | null) => {
    setFilterOptions(prev => ({ ...prev, folderId }))
  }

  const handleTagFilter = (tagIds: string[]) => {
    setFilterOptions(prev => ({ ...prev, tagIds }))
  }

  const handleFavoritesToggle = () => {
    setFilterOptions(prev => ({ ...prev, favoritesOnly: !prev.favoritesOnly }))
  }

  return (
    <div className="flex h-full">
      {/* Sidebar - hidden on mobile, shown on lg+ */}
      <div className="hidden lg:block w-64 border-r border-dark-700">
        <Sidebar
          folders={folders}
          tags={tags}
          filterOptions={filterOptions}
          onFolderSelect={handleFolderSelect}
          onTagFilter={handleTagFilter}
          onFavoritesToggle={handleFavoritesToggle}
        />
      </div>

      {/* Main content */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Toolbar */}
        <div className="flex items-center justify-between gap-4 p-4 border-b border-dark-700">
          {/* Search */}
          <div className="flex-1 max-w-md">
            <div className="relative">
              <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-dark-400" />
              <input
                type="text"
                placeholder="プロンプトを検索..."
                value={filterOptions.searchQuery}
                onChange={(e) => handleSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-dark-800 border border-dark-700 rounded-lg text-white placeholder-dark-400 focus:outline-none focus:border-primary-500"
              />
            </div>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-2">
            {/* View options */}
            <div className="hidden sm:flex items-center gap-1 bg-dark-800 rounded-lg p-1">
              <button
                onClick={() => setViewOptions(prev => ({ ...prev, thumbnailSize: 'small' }))}
                className={`p-2 rounded ${viewOptions.thumbnailSize === 'small' ? 'bg-dark-700 text-white' : 'text-dark-400 hover:text-white'}`}
              >
                <GridSmallIcon className="w-5 h-5" />
              </button>
              <button
                onClick={() => setViewOptions(prev => ({ ...prev, thumbnailSize: 'medium' }))}
                className={`p-2 rounded ${viewOptions.thumbnailSize === 'medium' ? 'bg-dark-700 text-white' : 'text-dark-400 hover:text-white'}`}
              >
                <GridMediumIcon className="w-5 h-5" />
              </button>
              <button
                onClick={() => setViewOptions(prev => ({ ...prev, thumbnailSize: 'large' }))}
                className={`p-2 rounded ${viewOptions.thumbnailSize === 'large' ? 'bg-dark-700 text-white' : 'text-dark-400 hover:text-white'}`}
              >
                <GridLargeIcon className="w-5 h-5" />
              </button>
            </div>

            {/* Upload button */}
            <button
              onClick={() => setShowUploadModal(true)}
              className="flex items-center gap-2 px-4 py-2 bg-primary-600 hover:bg-primary-500 text-white rounded-lg transition-colors"
            >
              <UploadIcon className="w-5 h-5" />
              <span className="hidden sm:inline">アップロード</span>
            </button>
          </div>
        </div>

        {/* Image grid */}
        <div className="flex-1 overflow-auto p-4">
          {loading ? (
            <div className="flex items-center justify-center h-64">
              <div className="w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full spinner" />
            </div>
          ) : error ? (
            <div className="flex items-center justify-center h-64 text-red-400">
              {error}
            </div>
          ) : images.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-64 text-dark-400">
              <ImageIcon className="w-16 h-16 mb-4" />
              <p>画像がありません</p>
              <button
                onClick={() => setShowUploadModal(true)}
                className="mt-4 text-primary-400 hover:text-primary-300"
              >
                画像をアップロード
              </button>
            </div>
          ) : (
            <ImageGrid
              images={images}
              viewOptions={viewOptions}
              onImageClick={setSelectedImage}
            />
          )}
        </div>
      </div>

      {/* Image detail modal */}
      {selectedImage && (
        <ImageDetail
          image={selectedImage}
          onClose={() => setSelectedImage(null)}
        />
      )}

      {/* Upload modal */}
      {showUploadModal && (
        <UploadModal
          onClose={() => setShowUploadModal(false)}
          onUploadComplete={() => {
            setShowUploadModal(false)
            fetchImages(filterOptions)
          }}
        />
      )}
    </div>
  )
}

// Icons
function SearchIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
    </svg>
  )
}

function UploadIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
    </svg>
  )
}

function ImageIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
    </svg>
  )
}

function GridSmallIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="currentColor" viewBox="0 0 20 20">
      <path d="M5 3a2 2 0 00-2 2v2a2 2 0 002 2h2a2 2 0 002-2V5a2 2 0 00-2-2H5zM5 11a2 2 0 00-2 2v2a2 2 0 002 2h2a2 2 0 002-2v-2a2 2 0 00-2-2H5zM11 5a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V5zM11 13a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
    </svg>
  )
}

function GridMediumIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="currentColor" viewBox="0 0 20 20">
      <path d="M5 3a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2V5a2 2 0 00-2-2H5zm0 2h4v4H5V5zm6 0h4v4h-4V5zM5 11h4v4H5v-4zm6 0h4v4h-4v-4z" />
    </svg>
  )
}

function GridLargeIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="currentColor" viewBox="0 0 20 20">
      <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v12a1 1 0 01-1 1H4a1 1 0 01-1-1V4z" />
    </svg>
  )
}
