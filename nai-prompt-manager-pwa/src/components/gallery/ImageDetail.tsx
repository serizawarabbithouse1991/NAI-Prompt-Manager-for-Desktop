import { useState } from 'react'
import { useImageStore } from '../../stores/imageStore'
import type { ImageWithDetails } from '../../types'

interface ImageDetailProps {
  image: ImageWithDetails
  onClose: () => void
}

export function ImageDetail({ image, onClose }: ImageDetailProps) {
  const [activeTab, setActiveTab] = useState<'info' | 'prompt'>('prompt')
  const [copying, setCopying] = useState(false)
  const { updateImageRating, deleteImage } = useImageStore()

  const handleCopyPrompt = async (text: string | null) => {
    if (!text) return
    try {
      await navigator.clipboard.writeText(text)
      setCopying(true)
      setTimeout(() => setCopying(false), 2000)
    } catch (e) {
      console.error('Failed to copy:', e)
    }
  }

  const handleToggleFavorite = async () => {
    await updateImageRating(image.id, !image.rating?.is_favorite)
  }

  const handleDelete = async () => {
    if (confirm('この画像を削除しますか？')) {
      await deleteImage(image.id)
      onClose()
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80" onClick={onClose}>
      <div 
        className="relative flex flex-col lg:flex-row w-full max-w-6xl max-h-[90vh] bg-dark-800 rounded-xl overflow-hidden"
        onClick={e => e.stopPropagation()}
      >
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 z-10 p-2 bg-dark-900/80 rounded-full text-white hover:bg-dark-700 transition-colors"
        >
          <CloseIcon className="w-5 h-5" />
        </button>

        {/* Image section */}
        <div className="flex-1 min-h-0 bg-dark-900 flex items-center justify-center p-4">
          <img
            src={image.image_url}
            alt={image.filename || 'Image'}
            className="max-w-full max-h-full object-contain"
          />
        </div>

        {/* Info panel */}
        <div className="w-full lg:w-96 flex flex-col bg-dark-800 border-t lg:border-t-0 lg:border-l border-dark-700">
          {/* Actions */}
          <div className="flex items-center justify-between p-4 border-b border-dark-700">
            <div className="flex items-center gap-2">
              <button
                onClick={handleToggleFavorite}
                className={`p-2 rounded-lg transition-colors ${
                  image.rating?.is_favorite
                    ? 'bg-red-500/20 text-red-500'
                    : 'bg-dark-700 text-dark-400 hover:text-white'
                }`}
              >
                <HeartIcon className="w-5 h-5" filled={image.rating?.is_favorite} />
              </button>
              <button
                onClick={handleDelete}
                className="p-2 bg-dark-700 text-dark-400 hover:text-red-500 rounded-lg transition-colors"
              >
                <TrashIcon className="w-5 h-5" />
              </button>
            </div>

            {/* Open in new tab */}
            {image.image_url && (
              <a
                href={image.image_url}
                target="_blank"
                rel="noopener noreferrer"
                className="p-2 bg-dark-700 text-dark-400 hover:text-white rounded-lg transition-colors"
              >
                <ExternalLinkIcon className="w-5 h-5" />
              </a>
            )}
          </div>

          {/* Tabs */}
          <div className="flex border-b border-dark-700">
            <button
              onClick={() => setActiveTab('prompt')}
              className={`flex-1 py-3 text-sm font-medium border-b-2 transition-colors ${
                activeTab === 'prompt'
                  ? 'text-primary-400 border-primary-400'
                  : 'text-dark-400 border-transparent hover:text-dark-300'
              }`}
            >
              プロンプト
            </button>
            <button
              onClick={() => setActiveTab('info')}
              className={`flex-1 py-3 text-sm font-medium border-b-2 transition-colors ${
                activeTab === 'info'
                  ? 'text-primary-400 border-primary-400'
                  : 'text-dark-400 border-transparent hover:text-dark-300'
              }`}
            >
              情報
            </button>
          </div>

          {/* Tab content */}
          <div className="flex-1 overflow-auto p-4">
            {activeTab === 'prompt' ? (
              <div className="space-y-4">
                {/* Positive prompt */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-sm text-dark-400">ポジティブ</label>
                    <button
                      onClick={() => handleCopyPrompt(image.prompt?.positive_prompt ?? null)}
                      className="text-xs text-primary-400 hover:text-primary-300"
                    >
                      {copying ? 'コピーしました！' : 'コピー'}
                    </button>
                  </div>
                  <div className="p-3 bg-dark-900 rounded-lg text-sm text-white whitespace-pre-wrap max-h-48 overflow-auto">
                    {image.prompt?.positive_prompt || '(なし)'}
                  </div>
                </div>

                {/* Negative prompt */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-sm text-dark-400">ネガティブ</label>
                    <button
                      onClick={() => handleCopyPrompt(image.prompt?.negative_prompt ?? null)}
                      className="text-xs text-primary-400 hover:text-primary-300"
                    >
                      コピー
                    </button>
                  </div>
                  <div className="p-3 bg-dark-900 rounded-lg text-sm text-dark-300 whitespace-pre-wrap max-h-32 overflow-auto">
                    {image.prompt?.negative_prompt || '(なし)'}
                  </div>
                </div>

                {/* Parameters */}
                {image.prompt && (
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div className="p-2 bg-dark-900 rounded">
                      <span className="text-dark-400">モデル: </span>
                      <span className="text-white">{image.prompt.model || '-'}</span>
                    </div>
                    <div className="p-2 bg-dark-900 rounded">
                      <span className="text-dark-400">サンプラー: </span>
                      <span className="text-white">{image.prompt.sampler || '-'}</span>
                    </div>
                    <div className="p-2 bg-dark-900 rounded">
                      <span className="text-dark-400">Steps: </span>
                      <span className="text-white">{image.prompt.steps ?? '-'}</span>
                    </div>
                    <div className="p-2 bg-dark-900 rounded">
                      <span className="text-dark-400">CFG: </span>
                      <span className="text-white">{image.prompt.cfg_scale ?? '-'}</span>
                    </div>
                    <div className="p-2 bg-dark-900 rounded col-span-2">
                      <span className="text-dark-400">Seed: </span>
                      <span className="text-white font-mono">{image.prompt.seed ?? '-'}</span>
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <div className="space-y-4">
                {/* File info */}
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-dark-400">ファイル名</span>
                    <span className="text-white truncate ml-4">{image.filename}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-dark-400">解像度</span>
                    <span className="text-white">
                      {image.width && image.height ? `${image.width} × ${image.height}` : '-'}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-dark-400">サイズ</span>
                    <span className="text-white">
                      {image.file_size ? formatFileSize(image.file_size) : '-'}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-dark-400">作成日時</span>
                    <span className="text-white">
                      {new Date(image.created_at).toLocaleString('ja-JP')}
                    </span>
                  </div>
                </div>

                {/* Tags */}
                {image.tags.length > 0 && (
                  <div>
                    <label className="text-sm text-dark-400 mb-2 block">タグ</label>
                    <div className="flex flex-wrap gap-2">
                      {image.tags.map(tag => (
                        <span
                          key={tag.id}
                          className="px-2 py-1 text-xs rounded-full"
                          style={{ backgroundColor: `${tag.color}20`, color: tag.color || '#a78bfa' }}
                        >
                          {tag.name}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

function CloseIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
    </svg>
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

function TrashIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
    </svg>
  )
}

function ExternalLinkIcon({ className }: { className?: string }) {
  return (
    <svg className={className} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
    </svg>
  )
}
