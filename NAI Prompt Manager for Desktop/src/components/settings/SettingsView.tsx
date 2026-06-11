import { useRef, useState } from 'react'
import { open } from '@tauri-apps/plugin-dialog'
import { useAppStore } from '../../stores/appStore'
import { useImageStore } from '../../stores/imageStore'
import { useFolderStore } from '../../stores/folderStore'
import { useTagStore } from '../../stores/tagStore'
import { exportAsJson, exportWithFiles, importFromJson } from '../../lib/export'
import { autoTagImageFromPrompt, getDanbooruDbStats } from '../../lib/danbooru-tags'
import { exportAllToICloud, setupICloudSync, type FullExportProgress } from '../../lib/icloud-sync'
import { useI18n } from '../../lib/i18n'

const DANBOORU_TAG_TYPES = [
  { id: 0, label: '一般' },
  { id: 1, label: '作者' },
  { id: 3, label: '版権' },
  { id: 4, label: 'キャラ' },
  { id: 5, label: 'メタ' },
]

export default function SettingsView() {
  const { settings, updateSettings } = useAppStore()
  const { images, loadImages } = useImageStore()
  const { folders, loadFolders } = useFolderStore()
  const { tags, loadTags } = useTagStore()
  const [busy, setBusy] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [syncProgress, setSyncProgress] = useState<FullExportProgress | null>(null)
  const retagCancelRef = useRef(false)
  const { t } = useI18n()

  const handleExportJson = async () => {
    setBusy('export-json')
    setMessage(null)
    try {
      const ok = await exportAsJson(images, folders, tags)
      setMessage(ok ? 'JSONエクスポートが完了しました' : null)
    } catch (err) {
      console.error('Export failed:', err)
      setMessage('エクスポートに失敗しました')
    } finally {
      setBusy(null)
    }
  }

  const handleExportWithFiles = async () => {
    setBusy('export-files')
    setMessage(null)
    try {
      const ok = await exportWithFiles(images, folders, tags)
      setMessage(ok ? '画像付きエクスポートが完了しました' : null)
    } catch (err) {
      console.error('Export with files failed:', err)
      setMessage('エクスポートに失敗しました')
    } finally {
      setBusy(null)
    }
  }

  const handleImport = async () => {
    setBusy('import')
    setMessage(null)
    try {
      const selected = await open({
        multiple: false,
        filters: [{ name: 'JSON', extensions: ['json'] }],
        title: 'インポートするJSONを選択',
      })
      if (!selected) return
      const result = await importFromJson(selected as string)
      if (result.success) {
        await Promise.all([loadFolders(), loadTags(), loadImages()])
        setMessage(`インポート完了: タグ/フォルダを復元しました（画像メタ ${result.imported} 件は対象外）`)
      } else {
        setMessage(`インポートに失敗しました: ${result.errors.join(', ')}`)
      }
    } catch (err) {
      console.error('Import failed:', err)
      setMessage('インポートに失敗しました')
    } finally {
      setBusy(null)
    }
  }

  const handleSelectStoragePath = async () => {
    try {
      const selected = await open({
        directory: true,
        title: '画像保存フォルダを選択',
      })
      if (selected) {
        updateSettings({ imageStoragePath: selected as string })
      }
    } catch (err) {
      console.error('Failed to select directory:', err)
    }
  }

  const handleSelectIcloudSyncPath = async () => {
    try {
      const selected = await open({
        directory: true,
        title: 'iCloud同期フォルダを選択',
      })
      if (selected) {
        updateSettings({ icloudSyncPath: selected as string })
      }
    } catch (err) {
      console.error('Failed to select iCloud sync directory:', err)
    }
  }

  const handleEnableIcloudSync = async (enabled: boolean) => {
    updateSettings({ icloudSyncEnabled: enabled })
    if (enabled && settings.icloudSyncPath) {
      try {
        await setupICloudSync(settings.icloudSyncPath)
      } catch (err) {
        console.error('Failed to initialize iCloud sync folder:', err)
        setMessage('iCloud同期フォルダの初期化に失敗しました')
      }
    }
  }

  const handleFullIcloudExport = async () => {
    if (!settings.icloudSyncPath) {
      setMessage('iCloud同期フォルダを選択してください')
      return
    }

    setBusy('icloud-export')
    setSyncProgress(null)
    setMessage(null)
    try {
      if (!settings.icloudSyncEnabled) {
        updateSettings({ icloudSyncEnabled: true })
      }
      await setupICloudSync(settings.icloudSyncPath)
      const result = await exportAllToICloud((progress) => setSyncProgress(progress))
      if (result.success) {
        setMessage(
          `iCloud初回エクスポート完了: 画像 ${result.exportedImages} 件 / タグ ${result.exportedTags} 件 / フォルダ ${result.exportedFolders} 件`
        )
      } else {
        setMessage(
          `iCloudエクスポート完了（一部失敗）: 画像 ${result.exportedImages} 件 / 失敗 ${result.failedImages} 件${result.errors.length > 0 ? ` — ${result.errors[0]}` : ''}`
        )
      }
    } catch (err) {
      console.error('iCloud full export failed:', err)
      setMessage('iCloudエクスポートに失敗しました')
    } finally {
      setBusy(null)
      setSyncProgress(null)
    }
  }

  const handleSelectImportMirrorPath = async () => {
    try {
      const selected = await open({
        directory: true,
        title: 'インポート画像の自動コピー先を選択',
      })
      if (selected) {
        updateSettings({ importMirrorPath: selected as string })
      }
    } catch (err) {
      console.error('Failed to select mirror directory:', err)
    }
  }

  const handleSelectDanbooruDbPath = async () => {
    try {
      const selected = await open({
        multiple: false,
        filters: [{ name: 'SQLite DB', extensions: ['db', 'sqlite', 'sqlite3'] }],
        title: 'DanbooruタグDBを選択',
      })
      if (selected) {
        updateSettings({ danbooruDbPath: selected as string })
      }
    } catch (err) {
      console.error('Failed to select Danbooru DB:', err)
    }
  }

  const handleTestDanbooruDb = async () => {
    if (!settings.danbooruDbPath) {
      setMessage('DanbooruタグDBを選択してください')
      return
    }

    setBusy('danbooru-test')
    setMessage('DanbooruタグDBを確認中...')
    try {
      const stats = await getDanbooruDbStats(settings.danbooruDbPath)
      const typeSummary = DANBOORU_TAG_TYPES
        .map((type) => `${type.label}: ${stats.type_counts[String(type.id)] ?? 0}`)
        .join(' / ')
      setMessage(`DanbooruタグDB OK: 総タグ ${stats.total_tags.toLocaleString()} 件（${typeSummary}）`)
    } catch (err) {
      console.error('Danbooru DB test failed:', err)
      setMessage(err instanceof Error ? err.message : 'DanbooruタグDBの確認に失敗しました')
    } finally {
      setBusy(null)
    }
  }

  const toggleDanbooruTagType = (typeId: number) => {
    const current = settings.danbooruAllowedTagTypes ?? []
    const next = current.includes(typeId)
      ? current.filter((id) => id !== typeId)
      : [...current, typeId].sort((a, b) => a - b)
    updateSettings({ danbooruAllowedTagTypes: next })
  }

  const cancelRetagExistingImages = () => {
    retagCancelRef.current = true
    setMessage(`${t('retagging')} ${t('stop')}`)
  }

  const handleRetagExistingImages = async () => {
    if (!settings.danbooruDbPath) {
      setMessage('DanbooruタグDBを選択してください')
      return
    }

    retagCancelRef.current = false
    setBusy('danbooru-retag')
    setMessage('既存画像のタグ付けを準備中...')
    let processed = 0
    let tagged = 0
    let matched = 0
    let failed = 0

    try {
      await loadImages()
      const targets = useImageStore
        .getState()
        .images
        .filter((image) => image.prompt?.positive_prompt)

      for (const image of targets) {
        if (retagCancelRef.current) break
        try {
          const result = await autoTagImageFromPrompt(image.id, image.prompt, settings.danbooruDbPath, {
            allowedTagTypes: settings.danbooruAllowedTagTypes,
            maxTagsPerImage: settings.danbooruMaxTagsPerImage,
            minPopularity: settings.danbooruMinPopularity,
          })
          processed++
          if (result.matched.length > 0) {
            tagged++
            matched += result.matched.length
          }
        } catch (err) {
          failed++
          console.error(`Danbooru retag failed for ${image.id}:`, err)
        }

        if (processed % 10 === 0) {
          setMessage(`既存画像をタグ付け中... ${processed}/${targets.length} 件`)
          await new Promise((resolve) => setTimeout(resolve, 0))
        }
      }

      await Promise.all([loadTags(), loadImages()])
      const prefix = retagCancelRef.current ? '既存画像のタグ付けを中止しました' : '既存画像のタグ付け完了'
      setMessage(`${prefix}: 処理 ${processed}/${targets.length} 件 / 一致 ${tagged} 件 / タグ候補 ${matched} 件${failed > 0 ? ` / 失敗 ${failed} 件` : ''}`)
    } catch (err) {
      console.error('Danbooru retag failed:', err)
      setMessage('既存画像のタグ付けに失敗しました')
    } finally {
      setBusy(null)
    }
  }

  return (
    <div className="h-full overflow-y-auto scrollbar-thin">
      <div className="max-w-2xl mx-auto p-6">
        <h1 className="text-2xl font-bold text-nai-text mb-6">{t('settings')}</h1>

        <div className="space-y-8">
          {/* Storage Settings */}
          <section className="bg-nai-bg1 rounded-xl p-6 border border-nai-border">
            <h2 className="text-lg font-semibold text-nai-text mb-4 flex items-center gap-2">
              <svg className="w-5 h-5 text-nai-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
              </svg>
              {t('storage')}
            </h2>

            <div className="space-y-4">
              <div>
                <label className="block text-sm text-nai-text-muted mb-2">
                  {t('imageStorageFolder')}
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={settings.imageStoragePath || t('defaultAppData')}
                    readOnly
                    className="flex-1 px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm"
                  />
                  <button
                    onClick={handleSelectStoragePath}
                    className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 text-nai-text rounded-lg transition-colors text-sm"
                  >
                    選択
                  </button>
                </div>
                <p className="mt-1 text-xs text-nai-text-placeholder">
                  インポートした画像がコピーされるフォルダです
                </p>
              </div>

              <div>
                <label className="block text-sm text-nai-text-muted mb-2">
                  サムネイルサイズ
                </label>
                <select
                  value={settings.thumbnailSize}
                  onChange={(e) => updateSettings({ thumbnailSize: parseInt(e.target.value) })}
                  className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm focus:outline-none focus:border-nai-accent"
                >
                  <option value={128}>128px (小)</option>
                  <option value={256}>256px (中)</option>
                  <option value={512}>512px (大)</option>
                </select>
              </div>

              <div className="pt-4 border-t border-nai-border">
                <label className="flex items-center gap-3 text-sm text-nai-text mb-3">
                  <input
                    type="checkbox"
                    checked={settings.importMirrorEnabled}
                    onChange={(e) => updateSettings({ importMirrorEnabled: e.target.checked })}
                    className="w-4 h-4 accent-nai-accent"
                  />
                  インポートした画像を自動コピーする
                </label>
                <label className="block text-sm text-nai-text-muted mb-2">
                  自動コピー先
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={settings.importMirrorPath || '未設定'}
                    readOnly
                    className="flex-1 px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm"
                  />
                  <button
                    onClick={handleSelectImportMirrorPath}
                    className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 text-nai-text rounded-lg transition-colors text-sm"
                  >
                    {t('choose')}
                  </button>
                </div>
                <p className="mt-1 text-xs text-nai-text-placeholder">
                  初期値: C:\Users\rt032\iCloudDrive\NovelAI
                </p>
              </div>
            </div>
          </section>

          {/* iCloud Sync */}
          <section className="bg-nai-bg1 rounded-xl p-6 border border-nai-border">
            <h2 className="text-lg font-semibold text-nai-text mb-4 flex items-center gap-2">
              <svg className="w-5 h-5 text-nai-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z" />
              </svg>
              iCloud Drive 同期
            </h2>

            <div className="space-y-4">
              <label className="flex items-center gap-3 text-sm text-nai-text">
                <input
                  type="checkbox"
                  checked={settings.icloudSyncEnabled}
                  onChange={(e) => handleEnableIcloudSync(e.target.checked)}
                  disabled={busy !== null}
                  className="w-4 h-4 accent-nai-accent"
                />
                iCloud Drive 同期を有効にする
              </label>

              <div>
                <label className="block text-sm text-nai-text-muted mb-2">
                  同期フォルダ
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={settings.icloudSyncPath || t('unset')}
                    readOnly
                    className="flex-1 px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm"
                  />
                  <button
                    onClick={handleSelectIcloudSyncPath}
                    disabled={busy !== null}
                    className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 disabled:opacity-50 text-nai-text rounded-lg transition-colors text-sm"
                  >
                    {t('choose')}
                  </button>
                </div>
                <p className="mt-1 text-xs text-nai-text-placeholder">
                  推奨: iCloudDrive\NAI-Prompt-Manager（iPhoneの「ファイル」アプリから同じフォルダにアクセスできます）
                </p>
              </div>

              {settings.icloudSyncLastSyncedAt && (
                <p className="text-xs text-nai-text-muted">
                  最終同期: {new Date(settings.icloudSyncLastSyncedAt).toLocaleString()}
                </p>
              )}

              <div className="grid sm:grid-cols-2 gap-2">
                <button
                  onClick={handleFullIcloudExport}
                  disabled={busy !== null || !settings.icloudSyncPath}
                  className="px-4 py-2 bg-nai-accent hover:bg-nai-accent-hover disabled:bg-nai-accent/50 text-nai-bg0 font-medium rounded-lg transition-colors text-sm"
                >
                  {busy === 'icloud-export' ? 'エクスポート中...' : '初回フルエクスポート'}
                </button>
              </div>

              {syncProgress && (
                <div className="space-y-2">
                  <div className="flex justify-between text-xs text-nai-text-muted">
                    <span>{syncProgress.message}</span>
                    <span>
                      {syncProgress.total > 0
                        ? `${Math.min(syncProgress.current, syncProgress.total)} / ${syncProgress.total}`
                        : ''}
                    </span>
                  </div>
                  <div className="h-2 bg-nai-bg0 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-nai-accent transition-all duration-300"
                      style={{
                        width:
                          syncProgress.total > 0
                            ? `${Math.min(100, (syncProgress.current / syncProgress.total) * 100)}%`
                            : '0%',
                      }}
                    />
                  </div>
                </div>
              )}

              <p className="text-xs text-nai-text-placeholder">
                有効化後、タグ・フォルダ・画像の変更は自動的に同期フォルダへ書き出されます。
                初回は「フルエクスポート」で既存データ（約20GB）をiCloudへコピーしてください。Wi-Fi接続を推奨します。
              </p>

              {message && (busy === 'icloud-export' || message.includes('iCloud')) && (
                <p className="text-sm text-nai-accent">{message}</p>
              )}
            </div>
          </section>

          {/* Danbooru Tag Settings */}
          <section className="bg-nai-bg1 rounded-xl p-6 border border-nai-border">
            <h2 className="text-lg font-semibold text-nai-text mb-4 flex items-center gap-2">
              <svg className="w-5 h-5 text-nai-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A2 2 0 013 12V7a4 4 0 014-4z" />
              </svg>
              Danbooruタグ連携
            </h2>

            <div className="space-y-4">
              <div>
                <label className="block text-sm text-nai-text-muted mb-2">
                  DanbooruタグDB
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={settings.danbooruDbPath || '未設定'}
                    readOnly
                    className="flex-1 px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm"
                  />
                  <button
                    onClick={handleSelectDanbooruDbPath}
                    disabled={busy !== null}
                    className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 disabled:opacity-50 text-nai-text rounded-lg transition-colors text-sm"
                  >
                    選択
                  </button>
                  <button
                    onClick={handleTestDanbooruDb}
                    disabled={busy !== null || !settings.danbooruDbPath}
                    className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 disabled:opacity-50 text-nai-text rounded-lg transition-colors text-sm"
                  >
                    {busy === 'danbooru-test' ? '確認中...' : '確認'}
                  </button>
                </div>
                <p className="mt-1 text-xs text-nai-text-placeholder">
                  画像のポジティブプロンプトに含まれる語句を tag.name と照合します
                </p>
              </div>

              <label className="flex items-center gap-3 text-sm text-nai-text">
                <input
                  type="checkbox"
                  checked={settings.danbooruAutoTagEnabled}
                  onChange={(e) => updateSettings({ danbooruAutoTagEnabled: e.target.checked })}
                  className="w-4 h-4 accent-nai-accent"
                />
                アップロード時に自動でタグ付けする
              </label>

              <div>
                <label className="block text-sm text-nai-text-muted mb-2">
                  対象タグ種別
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-5 gap-2">
                  {DANBOORU_TAG_TYPES.map((type) => (
                    <label
                      key={type.id}
                      className={`flex items-center justify-center gap-2 px-3 py-2 rounded-lg border text-sm transition-colors ${
                        settings.danbooruAllowedTagTypes?.includes(type.id)
                          ? 'bg-nai-accent/20 border-nai-accent text-nai-text'
                          : 'bg-nai-bg0 border-nai-border text-nai-text-muted'
                      }`}
                    >
                      <input
                        type="checkbox"
                        checked={settings.danbooruAllowedTagTypes?.includes(type.id) ?? false}
                        onChange={() => toggleDanbooruTagType(type.id)}
                        className="w-4 h-4 accent-nai-accent"
                      />
                      {type.label}
                    </label>
                  ))}
                </div>
              </div>

              <div className="grid sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm text-nai-text-muted mb-2">
                    1画像あたりの最大タグ数
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={300}
                    value={settings.danbooruMaxTagsPerImage}
                    onChange={(e) =>
                      updateSettings({
                        danbooruMaxTagsPerImage: Math.max(1, Math.min(300, parseInt(e.target.value) || 1)),
                      })
                    }
                    className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm focus:outline-none focus:border-nai-accent"
                  />
                </div>
                <div>
                  <label className="block text-sm text-nai-text-muted mb-2">
                    人気度下限
                  </label>
                  <input
                    type="number"
                    min={0}
                    value={settings.danbooruMinPopularity}
                    onChange={(e) =>
                      updateSettings({
                        danbooruMinPopularity: Math.max(0, parseInt(e.target.value) || 0),
                      })
                    }
                    className="w-full px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm focus:outline-none focus:border-nai-accent"
                  />
                </div>
              </div>

              <div className="grid sm:grid-cols-2 gap-2">
                <button
                  onClick={handleRetagExistingImages}
                  disabled={busy !== null || !settings.danbooruDbPath || settings.danbooruAllowedTagTypes.length === 0}
                  className="px-4 py-2 bg-nai-accent hover:bg-nai-accent-hover disabled:bg-nai-accent/50 text-nai-bg0 font-medium rounded-lg transition-colors text-sm"
                >
                  {busy === 'danbooru-retag' ? 'タグ付け中...' : '既存画像を再タグ付け'}
                </button>
                <button
                  onClick={cancelRetagExistingImages}
                  disabled={busy !== 'danbooru-retag'}
                  className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 disabled:opacity-50 text-nai-text rounded-lg transition-colors text-sm"
                >
                  中止
                </button>
              </div>

              {message && (busy === 'danbooru-retag' || message.includes('Danbooru') || message.includes('既存画像')) && (
                <p className="text-sm text-nai-accent">{message}</p>
              )}
            </div>
          </section>

          {/* Data Management */}
          <section className="bg-nai-bg1 rounded-xl p-6 border border-nai-border">
            <h2 className="text-lg font-semibold text-nai-text mb-4 flex items-center gap-2">
              <svg className="w-5 h-5 text-nai-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
              </svg>
              データ管理（エクスポート / バックアップ）
            </h2>

            <div className="space-y-4">
              <div className="grid sm:grid-cols-3 gap-2">
                <button
                  onClick={handleExportJson}
                  disabled={busy !== null}
                  className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 disabled:opacity-50 text-nai-text rounded-lg transition-colors text-sm"
                >
                  {busy === 'export-json' ? '処理中...' : 'JSONバックアップ'}
                </button>
                <button
                  onClick={handleExportWithFiles}
                  disabled={busy !== null}
                  className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 disabled:opacity-50 text-nai-text rounded-lg transition-colors text-sm"
                >
                  {busy === 'export-files' ? '処理中...' : '画像付きエクスポート'}
                </button>
                <button
                  onClick={handleImport}
                  disabled={busy !== null}
                  className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 disabled:opacity-50 text-nai-text rounded-lg transition-colors text-sm"
                >
                  {busy === 'import' ? '処理中...' : 'JSONインポート'}
                </button>
              </div>

              <p className="text-xs text-nai-text-placeholder">
                JSONバックアップはプロンプト・タグ・フォルダ情報を書き出します。画像ファイルも含めて保存するには「画像付きエクスポート」を使用してください。
                インポートはタグ・フォルダを復元します（画像ファイルの取り込みは未対応）。
              </p>

              {message && (
                <p className="text-sm text-nai-accent">{message}</p>
              )}
            </div>
          </section>

          {/* Appearance Settings */}
          <section className="bg-nai-bg1 rounded-xl p-6 border border-nai-border">
            <h2 className="text-lg font-semibold text-nai-text mb-4 flex items-center gap-2">
              <svg className="w-5 h-5 text-nai-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
              </svg>
              外観
            </h2>

            <div className="space-y-4">
              <div>
                <label className="block text-sm text-nai-text-muted mb-2">
                  テーマ
                </label>
                <div className="flex gap-2">
                  <button
                    onClick={() => updateSettings({ theme: 'dark' })}
                    className={`flex-1 px-4 py-3 rounded-lg border transition-colors ${
                      settings.theme === 'dark'
                        ? 'bg-nai-accent/20 border-nai-accent text-nai-text'
                        : 'bg-nai-bg0 border-nai-border text-nai-text-muted hover:border-nai-text-muted'
                    }`}
                  >
                    <svg className="w-5 h-5 mx-auto mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                    </svg>
                    <span className="text-sm">ダーク</span>
                  </button>
                  <button
                    onClick={() => updateSettings({ theme: 'light' })}
                    className={`flex-1 px-4 py-3 rounded-lg border transition-colors ${
                      settings.theme === 'light'
                        ? 'bg-nai-accent/20 border-nai-accent text-nai-text'
                        : 'bg-nai-bg0 border-nai-border text-nai-text-muted hover:border-nai-text-muted'
                    }`}
                  >
                    <svg className="w-5 h-5 mx-auto mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
                    </svg>
                    <span className="text-sm">ライト</span>
                  </button>
                </div>
                <p className="mt-2 text-xs text-nai-text-placeholder">
                  ※ ライトテーマは現在準備中です
                </p>
              </div>
            </div>
          </section>

          {/* About */}
          <section className="bg-nai-bg1 rounded-xl p-6 border border-nai-border">
            <h2 className="text-lg font-semibold text-nai-text mb-4 flex items-center gap-2">
              <svg className="w-5 h-5 text-nai-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              このアプリについて
            </h2>

            <div className="space-y-2 text-sm">
              <p className="text-nai-text">
                <span className="text-nai-text-muted">アプリ名:</span> NAI Prompt Manager
              </p>
              <p className="text-nai-text">
                <span className="text-nai-text-muted">バージョン:</span> 1.0.0
              </p>
              <p className="text-nai-text-muted mt-4">
                NovelAI等のAI生成画像を管理するためのデスクトップアプリケーションです。
                画像のプロンプト情報を自動抽出し、タグ付けやフォルダ管理ができます。
              </p>
            </div>
          </section>
        </div>

      </div>
    </div>
  )
}
