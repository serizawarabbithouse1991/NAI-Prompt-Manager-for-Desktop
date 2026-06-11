import { useState, useEffect } from 'react'
import type { ImageWithDetails, Tag } from '../../types'
import { useImageStore } from '../../stores/imageStore'
import { useAppStore } from '../../stores/appStore'
import { useTagStore } from '../../stores/tagStore'
import { pathToAssetUrl, formatFileSize, formatDate } from '../../lib/utils'
import { autoTagImageFromPrompt } from '../../lib/danbooru-tags'
import { exportImageFile } from '../../lib/export'
import { useI18n } from '../../lib/i18n'

interface ImageDetailProps {
  image: ImageWithDetails
  tags: Tag[]
  onClose: () => void
  onUpdate: (image: ImageWithDetails) => void
}

export default function ImageDetail({ image, tags, onClose, onUpdate }: ImageDetailProps) {
  const { toggleFavorite, addTagToImage, removeTagFromImage, updatePrompt, deleteImage } = useImageStore()
  const { settings } = useAppStore()
  const { loadTags } = useTagStore()
  const [editMode, setEditMode] = useState(false)
  const [saving, setSaving] = useState(false)
  const [retagging, setRetagging] = useState(false)
  const [tagMessage, setTagMessage] = useState<string | null>(null)
  const [exporting, setExporting] = useState(false)
  const [exportMessage, setExportMessage] = useState<string | null>(null)
  const [imageError, setImageError] = useState(false)
  const { t } = useI18n()
  const [formData, setFormData] = useState({
    positive_prompt: image.prompt?.positive_prompt || '',
    negative_prompt: image.prompt?.negative_prompt || '',
    model: image.prompt?.model || '',
    sampler: image.prompt?.sampler || '',
    steps: image.prompt?.steps?.toString() || '',
    cfg_scale: image.prompt?.cfg_scale?.toString() || '',
    seed: image.prompt?.seed?.toString() || '',
    notes: image.prompt?.notes || '',
  })

  useEffect(() => {
    // Handle escape key
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [onClose])

  const handleToggleFavorite = async () => {
    try {
      await toggleFavorite(image.id)
      onUpdate({
        ...image,
        rating: {
          image_id: image.id,
          is_favorite: !image.rating?.is_favorite,
          rating: image.rating?.rating ?? null,
        },
      })
    } catch (err) {
      console.error('Failed to toggle favorite:', err)
    }
  }

  const handleAddTag = async (tagId: string) => {
    const tag = tags.find((t) => t.id === tagId)
    if (!tag) return
    try {
      await addTagToImage(image.id, tag)
      onUpdate({ ...image, tags: [...image.tags, tag] })
    } catch (err) {
      console.error('Failed to add tag:', err)
    }
  }

  const handleRemoveTag = async (tagId: string) => {
    try {
      await removeTagFromImage(image.id, tagId)
      onUpdate({ ...image, tags: image.tags.filter((t) => t.id !== tagId) })
    } catch (err) {
      console.error('Failed to remove tag:', err)
    }
  }

  const handleDanbooruRetag = async () => {
    if (!settings.danbooruDbPath) {
      setTagMessage(t('danbooruDbMissing'))
      return
    }
    if (!image.prompt?.positive_prompt) {
      setTagMessage(t('promptMissing'))
      return
    }

    setRetagging(true)
    setTagMessage(t('danbooruChecking'))
    try {
      const result = await autoTagImageFromPrompt(image.id, image.prompt, settings.danbooruDbPath, {
        allowedTagTypes: settings.danbooruAllowedTagTypes,
        maxTagsPerImage: settings.danbooruMaxTagsPerImage,
        minPopularity: settings.danbooruMinPopularity,
      })
      const mergedTags = [...image.tags]
      for (const tag of result.tags) {
        if (!mergedTags.some((existing) => existing.id === tag.id)) {
          mergedTags.push(tag)
        }
      }
      onUpdate({ ...image, tags: mergedTags })
      await loadTags()
      setTagMessage(t('danbooruApplied', { count: result.matched.length }))
    } catch (err) {
      console.error('Danbooru retag failed:', err)
      setTagMessage(t('exportFailed'))
    } finally {
      setRetagging(false)
    }
  }

  const handleSave = async () => {
    setSaving(true)
    try {
      await updatePrompt(image.id, {
        positive_prompt: formData.positive_prompt || null,
        negative_prompt: formData.negative_prompt || null,
        model: formData.model || null,
        sampler: formData.sampler || null,
        steps: formData.steps ? parseInt(formData.steps) : null,
        cfg_scale: formData.cfg_scale ? parseFloat(formData.cfg_scale) : null,
        seed: formData.seed ? parseInt(formData.seed) : null,
        notes: formData.notes || null,
      })
      setEditMode(false)
      onUpdate({
        ...image,
        prompt: {
          ...image.prompt!,
          positive_prompt: formData.positive_prompt || null,
          negative_prompt: formData.negative_prompt || null,
          model: formData.model || null,
          sampler: formData.sampler || null,
          steps: formData.steps ? parseInt(formData.steps) : null,
          cfg_scale: formData.cfg_scale ? parseFloat(formData.cfg_scale) : null,
          seed: formData.seed ? parseInt(formData.seed) : null,
          notes: formData.notes || null,
        } as typeof image.prompt,
      })
    } catch (err) {
      console.error('Failed to save:', err)
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!confirm(t('deleteImageConfirm'))) return
    try {
      await deleteImage(image.id)
      onClose()
    } catch (err) {
      console.error('Failed to delete:', err)
    }
  }

  const handleExport = async () => {
    setExporting(true)
    setExportMessage(null)
    try {
      const ok = await exportImageFile(image)
      if (ok) setExportMessage(t('exportImageDone'))
    } catch (err) {
      console.error('Image export failed:', err)
      setExportMessage(t('exportImageFailed'))
    } finally {
      setExporting(false)
    }
  }

  const imageUrl = imageError ? '' : pathToAssetUrl(image.file_path)
  const availableTags = tags.filter((t) => !image.tags.some((it) => it.id === t.id))

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-nai-bg0/95" onClick={onClose} />

      {/* Modal */}
      <div className="relative bg-nai-bg1 max-w-5xl w-full mx-4 max-h-[90vh] overflow-hidden border border-nai-border rounded-lg flex animate-slide-up">
        {/* Image */}
        <div className="flex-1 relative min-h-[400px] bg-nai-bg0">
          {imageUrl && !imageError ? (
            <img
              src={imageUrl}
              alt={image.filename || 'Image'}
              className="w-full h-full object-contain"
              onError={() => setImageError(true)}
            />
          ) : (
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="w-8 h-8 border-2 border-nai-accent border-t-transparent rounded-full animate-spin" />
            </div>
          )}
        </div>

        {/* Details Panel */}
        <div className="w-96 p-6 overflow-y-auto border-l border-nai-border scrollbar-thin">
          {/* Header */}
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-nai-text">{t('detail')}</h3>
            <div className="flex items-center gap-2">
              {/* Edit button */}
              {!editMode && (
                <button
                  onClick={() => setEditMode(true)}
                  className="p-2 bg-nai-bg2 text-nai-text-muted hover:bg-nai-bg3 rounded-lg transition-colors"
                  title={t('edit')}
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </button>
              )}
              {/* Favorite button */}
              <button
                onClick={handleToggleFavorite}
                className={`p-2 rounded-lg transition-colors ${
                  image.rating?.is_favorite
                    ? 'bg-red-600 text-white'
                    : 'bg-nai-bg2 text-nai-text-muted hover:bg-nai-bg3'
                }`}
              >
                <svg className={`w-5 h-5 ${image.rating?.is_favorite ? 'fill-current' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                </svg>
              </button>
              {/* Close button */}
              <button
                onClick={onClose}
                className="p-2 hover:bg-nai-bg2 rounded-lg transition-colors"
              >
                <svg className="w-5 h-5 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>

          <div className="space-y-4">
            {/* Tags */}
            <div>
              <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('tags')}</label>
              <div className="mt-2 flex flex-wrap gap-2">
                {image.tags.map((tag) => (
                  <span
                    key={tag.id}
                    className="px-2 py-1 rounded-full text-xs text-white flex items-center gap-1"
                    style={{ backgroundColor: tag.color || '#a78bfa' }}
                  >
                    {tag.name}
                    <button
                      onClick={() => handleRemoveTag(tag.id)}
                      className="hover:bg-white/20 rounded-full p-0.5"
                    >
                      <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </span>
                ))}
                {availableTags.length > 0 && (
                  <select
                    className="px-2 py-1 bg-nai-bg0 text-nai-text-muted rounded-full text-xs border border-nai-border focus:outline-none focus:border-nai-accent"
                    onChange={(e) => {
                      if (e.target.value) {
                        handleAddTag(e.target.value)
                        e.target.value = ''
                      }
                    }}
                    defaultValue=""
                  >
                    <option value="" disabled>+ {t('addTagButton')}</option>
                    {availableTags.map((tag) => (
                      <option key={tag.id} value={tag.id}>{tag.name}</option>
                    ))}
                  </select>
                )}
              </div>
              <div className="mt-2 grid grid-cols-1 gap-2">
                <button
                  onClick={handleDanbooruRetag}
                  disabled={retagging || !settings.danbooruDbPath || !image.prompt?.positive_prompt}
                  className="px-3 py-2 bg-nai-bg2 hover:bg-nai-bg3 disabled:opacity-50 text-nai-text rounded-lg transition-colors text-sm"
                >
                  {retagging ? t('danbooruApplying') : t('danbooruApply')}
                </button>
                {tagMessage && (
                  <p className="text-xs text-nai-accent">{tagMessage}</p>
                )}
              </div>
            </div>

            {/* Filename */}
            <div>
              <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('filename')}</label>
              <p className="text-nai-text mt-1">{image.filename || 'Untitled'}</p>
            </div>

            {editMode ? (
              /* Edit Mode */
              <div className="space-y-4">
                <div>
                  <label className="text-xs text-nai-text-muted uppercase tracking-wide mb-2 block">{t('prompt')}</label>
                  <textarea
                    value={formData.positive_prompt}
                    onChange={(e) => setFormData({ ...formData, positive_prompt: e.target.value })}
                    className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm focus:outline-none focus:border-nai-accent resize-none"
                    rows={4}
                  />
                </div>
                <div>
                  <label className="text-xs text-nai-text-muted uppercase tracking-wide mb-2 block">{t('negativePrompt')}</label>
                  <textarea
                    value={formData.negative_prompt}
                    onChange={(e) => setFormData({ ...formData, negative_prompt: e.target.value })}
                    className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm focus:outline-none focus:border-nai-accent resize-none"
                    rows={3}
                  />
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs text-nai-text-muted uppercase tracking-wide mb-1 block">{t('model')}</label>
                    <input
                      type="text"
                      value={formData.model}
                      onChange={(e) => setFormData({ ...formData, model: e.target.value })}
                      className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded text-nai-text text-sm focus:outline-none focus:border-nai-accent"
                    />
                  </div>
                  <div>
                    <label className="text-xs text-nai-text-muted uppercase tracking-wide mb-1 block">{t('sampler')}</label>
                    <input
                      type="text"
                      value={formData.sampler}
                      onChange={(e) => setFormData({ ...formData, sampler: e.target.value })}
                      className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded text-nai-text text-sm focus:outline-none focus:border-nai-accent"
                    />
                  </div>
                  <div>
                    <label className="text-xs text-nai-text-muted uppercase tracking-wide mb-1 block">{t('steps')}</label>
                    <input
                      type="number"
                      value={formData.steps}
                      onChange={(e) => setFormData({ ...formData, steps: e.target.value })}
                      className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded text-nai-text text-sm focus:outline-none focus:border-nai-accent"
                    />
                  </div>
                  <div>
                    <label className="text-xs text-nai-text-muted uppercase tracking-wide mb-1 block">CFG Scale</label>
                    <input
                      type="number"
                      step="0.1"
                      value={formData.cfg_scale}
                      onChange={(e) => setFormData({ ...formData, cfg_scale: e.target.value })}
                      className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded text-nai-text text-sm focus:outline-none focus:border-nai-accent"
                    />
                  </div>
                  <div className="col-span-2">
                    <label className="text-xs text-nai-text-muted uppercase tracking-wide mb-1 block">{t('seed')}</label>
                    <input
                      type="text"
                      value={formData.seed}
                      onChange={(e) => setFormData({ ...formData, seed: e.target.value })}
                      className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded text-nai-text text-sm font-mono focus:outline-none focus:border-nai-accent"
                    />
                  </div>
                </div>
                <div>
                  <label className="text-xs text-nai-text-muted uppercase tracking-wide mb-2 block">{t('notes')}</label>
                  <textarea
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm focus:outline-none focus:border-nai-accent resize-none"
                    rows={2}
                  />
                </div>
                <div className="flex gap-2 pt-4 border-t border-nai-border">
                  <button
                    onClick={handleSave}
                    disabled={saving}
                    className="flex-1 px-4 py-2 bg-nai-accent hover:bg-nai-accent-hover disabled:bg-nai-accent/50 text-nai-bg0 font-medium rounded-lg transition-colors text-sm"
                  >
                    {saving ? t('saving') : t('save')}
                  </button>
                  <button
                    onClick={() => setEditMode(false)}
                    disabled={saving}
                    className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 text-nai-text rounded-lg transition-colors text-sm"
                  >
                    {t('cancel')}
                  </button>
                </div>
              </div>
            ) : (
              /* Display Mode */
              <>
                {image.prompt?.positive_prompt && (
                  <div>
                    <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('prompt')}</label>
                    <p className="text-nai-text mt-1 text-sm leading-relaxed whitespace-pre-wrap">
                      {image.prompt.positive_prompt}
                    </p>
                  </div>
                )}
                {image.prompt?.negative_prompt && (
                  <div>
                    <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('negativePrompt')}</label>
                    <p className="text-nai-text-muted mt-1 text-sm leading-relaxed whitespace-pre-wrap">
                      {image.prompt.negative_prompt}
                    </p>
                  </div>
                )}
                {image.prompt && (
                  <div className="grid grid-cols-2 gap-3">
                    {image.prompt.model && (
                      <div>
                        <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('model')}</label>
                        <p className="text-nai-text mt-1 text-sm">{image.prompt.model}</p>
                      </div>
                    )}
                    {image.prompt.sampler && (
                      <div>
                        <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('sampler')}</label>
                        <p className="text-nai-text mt-1 text-sm">{image.prompt.sampler}</p>
                      </div>
                    )}
                    {image.prompt.steps && (
                      <div>
                        <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('steps')}</label>
                        <p className="text-nai-text mt-1 text-sm">{image.prompt.steps}</p>
                      </div>
                    )}
                    {image.prompt.cfg_scale && (
                      <div>
                        <label className="text-xs text-nai-text-muted uppercase tracking-wide">CFG Scale</label>
                        <p className="text-nai-text mt-1 text-sm">{image.prompt.cfg_scale}</p>
                      </div>
                    )}
                    {image.prompt.seed != null && (
                      <div className="col-span-2">
                        <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('seed')}</label>
                        <p className="text-nai-text mt-1 text-sm font-mono">{image.prompt.seed}</p>
                      </div>
                    )}
                  </div>
                )}
              </>
            )}

            {/* File Info */}
            {(image.width || image.height) && (
              <div>
                <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('resolution')}</label>
                <p className="text-nai-text mt-1 text-sm">
                  {image.width} × {image.height}
                </p>
              </div>
            )}
            {image.file_size && (
              <div>
                <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('fileSize')}</label>
                <p className="text-nai-text mt-1 text-sm">{formatFileSize(image.file_size)}</p>
              </div>
            )}
            <div>
              <label className="text-xs text-nai-text-muted uppercase tracking-wide">{t('createdAt')}</label>
              <p className="text-nai-text mt-1 text-sm">{formatDate(image.created_at)}</p>
            </div>

            {/* Delete button */}
            <div className="pt-4 border-t border-nai-border">
              <button
                onClick={handleExport}
                disabled={exporting}
                className="w-full px-4 py-2 mb-2 bg-nai-bg2 hover:bg-nai-bg3 disabled:opacity-50 text-nai-text rounded-lg transition-colors text-sm"
              >
                {exporting ? t('exporting') : t('exportImage')}
              </button>
              {exportMessage && (
                <p className="text-xs text-nai-accent mb-2">{exportMessage}</p>
              )}
              <button
                onClick={handleDelete}
                className="w-full px-4 py-2 bg-red-900/50 hover:bg-red-900 text-red-300 rounded-lg transition-colors text-sm"
              >
                {t('deleteImage')}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
