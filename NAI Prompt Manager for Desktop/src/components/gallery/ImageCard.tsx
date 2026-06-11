import { useState } from 'react'
import type { ImageWithDetails, ThumbnailSize } from '../../types'
import { useAppStore } from '../../stores/appStore'
import { pathToAssetUrl, formatFileSize, formatDate } from '../../lib/utils'

interface ImageCardProps {
  image: ImageWithDetails
  viewMode: 'grid' | 'list'
  thumbnailSize?: ThumbnailSize
  onClick: () => void
}

export default function ImageCard({ image, viewMode, thumbnailSize = 'medium', onClick }: ImageCardProps) {
  const { batchMode, selectedImageIds, toggleImageSelection } = useAppStore()
  // Staged loading: try the thumbnail first, fall back to the full-size file if
  // the thumbnail is missing/corrupt, and only show a placeholder if both fail.
  const [stage, setStage] = useState<'thumb' | 'full' | 'error'>(
    image.thumbnail_path ? 'thumb' : 'full'
  )
  const isSelected = selectedImageIds.has(image.id)

  const handleClick = (e: React.MouseEvent) => {
    if (batchMode) {
      e.stopPropagation()
      toggleImageSelection(image.id)
    } else {
      onClick()
    }
  }

  const handleImageError = () =>
    setStage((prev) => (prev === 'thumb' ? 'full' : 'error'))

  // Get image URL (for local files, use Tauri asset protocol)
  const imageError = stage === 'error'
  const imageUrl = imageError
    ? ''
    : stage === 'thumb' && image.thumbnail_path
      ? pathToAssetUrl(image.thumbnail_path)
      : pathToAssetUrl(image.file_path)

  if (viewMode === 'list') {
    return (
      <div
        className={`group flex items-center gap-4 px-4 py-2 rounded cursor-pointer transition-all ${
          batchMode && isSelected
            ? 'bg-nai-accent/20 ring-1 ring-nai-accent'
            : 'hover:bg-nai-bg1'
        }`}
        onClick={handleClick}
      >
        {/* Batch checkbox / Thumbnail */}
        <div className="w-12 h-12 relative shrink-0 bg-nai-bg2 rounded overflow-hidden">
          {batchMode && (
            <div className={`absolute inset-0 z-10 flex items-center justify-center ${
              isSelected ? 'bg-nai-accent' : 'bg-black/50'
            }`}>
              {isSelected && (
                <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                </svg>
              )}
            </div>
          )}
          {imageUrl && !imageError ? (
            <img
              src={imageUrl}
              alt={image.filename || 'Image'}
              className="w-full h-full object-cover"
              onError={handleImageError}
            />
          ) : (
            <div className="absolute inset-0 flex items-center justify-center">
              <svg className="w-5 h-5 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
          )}
        </div>

        {/* Filename */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            {image.rating?.is_favorite && (
              <svg className="w-4 h-4 text-red-500 fill-current shrink-0" viewBox="0 0 24 24">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
              </svg>
            )}
            <span className="text-nai-text text-sm truncate">{image.filename || 'Untitled'}</span>
          </div>
          {image.prompt?.positive_prompt && (
            <p className="text-nai-text-muted text-xs truncate mt-0.5 hidden lg:block">
              {image.prompt.positive_prompt}
            </p>
          )}
        </div>

        {/* Size */}
        <div className="w-32 text-xs text-nai-text-muted hidden sm:block">
          {image.width && image.height ? `${image.width}×${image.height}` : '-'}
          {image.file_size && (
            <span className="ml-2">({formatFileSize(image.file_size)})</span>
          )}
        </div>

        {/* Date */}
        <div className="w-40 text-xs text-nai-text-muted hidden md:block">
          {formatDate(image.created_at)}
        </div>

        {/* Tags */}
        <div className="w-24 flex flex-wrap gap-1">
          {image.tags.slice(0, 2).map((tag) => (
            <span
              key={tag.id}
              className="px-1.5 py-0.5 rounded text-[10px] text-white"
              style={{ backgroundColor: tag.color || '#a78bfa' }}
            >
              {tag.name}
            </span>
          ))}
          {image.tags.length > 2 && (
            <span className="text-nai-text-muted text-[10px]">+{image.tags.length - 2}</span>
          )}
        </div>
      </div>
    )
  }

  // Grid View
  return (
    <div
      className={`group relative aspect-square bg-nai-bg2 rounded-lg overflow-hidden cursor-pointer transition-all ${
        batchMode && isSelected
          ? 'ring-2 ring-nai-accent'
          : 'hover:ring-2 hover:ring-nai-accent/50'
      }`}
      onClick={handleClick}
    >
      {/* Batch selection checkbox */}
      {batchMode && (
        <div className={`absolute top-2 left-2 z-10 w-6 h-6 rounded-full border-2 flex items-center justify-center ${
          isSelected
            ? 'bg-nai-accent border-nai-accent'
            : 'border-white bg-black/50'
        }`}>
          {isSelected && (
            <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
            </svg>
          )}
        </div>
      )}

      {/* Image */}
      {imageUrl && !imageError ? (
        <img
          src={imageUrl}
          alt={image.filename || 'Image'}
          className="w-full h-full object-cover"
          onError={handleImageError}
          loading="lazy"
        />
      ) : (
        <div className="absolute inset-0 flex items-center justify-center text-nai-text-muted">
          <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
        </div>
      )}

      {/* Overlay on hover */}
      {thumbnailSize !== 'small' && (
        <div className="absolute inset-0 bg-nai-bg0/80 opacity-0 group-hover:opacity-100 transition-opacity flex items-end">
          <div className="p-2 w-full">
            <p className="text-nai-text text-xs truncate">
              {image.filename || 'Untitled'}
            </p>
            {thumbnailSize !== 'medium' && image.prompt?.positive_prompt && (
              <p className="text-nai-text-muted text-[10px] truncate mt-0.5">
                {image.prompt.positive_prompt}
              </p>
            )}
            {image.tags.length > 0 && (
              <div className="flex flex-wrap gap-0.5 mt-1">
                {image.tags.slice(0, thumbnailSize === 'xlarge' ? 4 : 2).map((tag) => (
                  <span
                    key={tag.id}
                    className="px-1 py-0.5 rounded text-[9px] text-white"
                    style={{ backgroundColor: tag.color || '#a78bfa' }}
                  >
                    {tag.name}
                  </span>
                ))}
                {image.tags.length > (thumbnailSize === 'xlarge' ? 4 : 2) && (
                  <span className="text-nai-text-muted text-[9px]">
                    +{image.tags.length - (thumbnailSize === 'xlarge' ? 4 : 2)}
                  </span>
                )}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Favorite indicator */}
      {image.rating?.is_favorite && (
        <div className={`absolute ${thumbnailSize === 'small' ? 'top-1 right-1' : 'top-2 right-2'}`}>
          <svg 
            className={`${thumbnailSize === 'small' ? 'w-3 h-3' : 'w-5 h-5'} text-red-500 fill-current`} 
            viewBox="0 0 24 24"
          >
            <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
          </svg>
        </div>
      )}
    </div>
  )
}
