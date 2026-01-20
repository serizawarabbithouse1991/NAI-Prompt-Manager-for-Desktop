import type { ImageWithDetails, ViewOptions } from '../../types'

interface ImageGridProps {
  images: ImageWithDetails[]
  viewOptions: ViewOptions
  onImageClick: (image: ImageWithDetails) => void
}

const THUMBNAIL_SIZES = {
  small: 'w-32 h-32',
  medium: 'w-48 h-48',
  large: 'w-64 h-64',
  xlarge: 'w-80 h-80',
}

const GRID_COLS = {
  small: 'grid-cols-3 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 xl:grid-cols-10',
  medium: 'grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6',
  large: 'grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5',
  xlarge: 'grid-cols-1 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4',
}

export function ImageGrid({ images, viewOptions, onImageClick }: ImageGridProps) {
  const thumbnailSizeClass = THUMBNAIL_SIZES[viewOptions.thumbnailSize]
  const gridColsClass = GRID_COLS[viewOptions.thumbnailSize]

  return (
    <div className={`grid gap-4 ${gridColsClass}`}>
      {images.map((image) => (
        <ImageCard
          key={image.id}
          image={image}
          sizeClass={thumbnailSizeClass}
          onClick={() => onImageClick(image)}
        />
      ))}
    </div>
  )
}

interface ImageCardProps {
  image: ImageWithDetails
  sizeClass: string
  onClick: () => void
}

function ImageCard({ image, sizeClass, onClick }: ImageCardProps) {
  return (
    <button
      onClick={onClick}
      className={`
        relative ${sizeClass} rounded-lg overflow-hidden bg-dark-800
        hover:ring-2 hover:ring-primary-500 transition-all duration-200
        focus:outline-none focus:ring-2 focus:ring-primary-500
        image-card group
      `}
    >
      {/* Image */}
      <img
        src={image.thumbnail_url || image.image_url}
        alt={image.filename || 'Image'}
        className="absolute inset-0 w-full h-full object-cover"
        loading="lazy"
      />

      {/* Overlay on hover */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
        <div className="absolute bottom-0 left-0 right-0 p-2">
          <p className="text-xs text-white truncate">
            {image.filename}
          </p>
        </div>
      </div>

      {/* Favorite indicator */}
      {image.rating?.is_favorite && (
        <div className="absolute top-2 right-2">
          <HeartIcon className="w-5 h-5 text-red-500 drop-shadow-lg" />
        </div>
      )}

      {/* Tags indicator */}
      {image.tags.length > 0 && (
        <div className="absolute top-2 left-2 flex gap-1">
          <div className="w-2 h-2 rounded-full bg-primary-500" />
        </div>
      )}
    </button>
  )
}

function HeartIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="currentColor" viewBox="0 0 20 20">
      <path fillRule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clipRule="evenodd" />
    </svg>
  )
}
