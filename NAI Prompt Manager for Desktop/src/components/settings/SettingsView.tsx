import { open } from '@tauri-apps/plugin-dialog'
import { useAppStore } from '../../stores/appStore'

export default function SettingsView() {
  const { settings, updateSettings } = useAppStore()

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

  const handleSelectBackupPath = async () => {
    try {
      const selected = await open({
        directory: true,
        title: 'バックアップフォルダを選択',
      })
      if (selected) {
        updateSettings({ backupPath: selected as string })
      }
    } catch (err) {
      console.error('Failed to select directory:', err)
    }
  }

  return (
    <div className="h-full overflow-y-auto scrollbar-thin">
      <div className="max-w-2xl mx-auto p-6">
        <h1 className="text-2xl font-bold text-nai-text mb-6">設定</h1>

        <div className="space-y-8">
          {/* Storage Settings */}
          <section className="bg-nai-bg1 rounded-xl p-6 border border-nai-border">
            <h2 className="text-lg font-semibold text-nai-text mb-4 flex items-center gap-2">
              <svg className="w-5 h-5 text-nai-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
              </svg>
              ストレージ
            </h2>

            <div className="space-y-4">
              <div>
                <label className="block text-sm text-nai-text-muted mb-2">
                  画像保存フォルダ
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={settings.imageStoragePath || 'デフォルト (アプリデータフォルダ)'}
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
            </div>
          </section>

          {/* Backup Settings */}
          <section className="bg-nai-bg1 rounded-xl p-6 border border-nai-border">
            <h2 className="text-lg font-semibold text-nai-text mb-4 flex items-center gap-2">
              <svg className="w-5 h-5 text-nai-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
              </svg>
              バックアップ
            </h2>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <label className="text-sm text-nai-text">自動バックアップ</label>
                  <p className="text-xs text-nai-text-placeholder">
                    データベースを定期的にバックアップします
                  </p>
                </div>
                <button
                  onClick={() => updateSettings({ autoBackupEnabled: !settings.autoBackupEnabled })}
                  className={`relative w-12 h-6 rounded-full transition-colors ${
                    settings.autoBackupEnabled ? 'bg-nai-accent' : 'bg-nai-bg3'
                  }`}
                >
                  <span
                    className={`absolute top-1 w-4 h-4 bg-white rounded-full transition-transform ${
                      settings.autoBackupEnabled ? 'translate-x-7' : 'translate-x-1'
                    }`}
                  />
                </button>
              </div>

              {settings.autoBackupEnabled && (
                <div>
                  <label className="block text-sm text-nai-text-muted mb-2">
                    バックアップフォルダ
                  </label>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={settings.backupPath || '未設定'}
                      readOnly
                      className="flex-1 px-3 py-2 bg-nai-bg0 border border-nai-border rounded-lg text-nai-text text-sm"
                    />
                    <button
                      onClick={handleSelectBackupPath}
                      className="px-4 py-2 bg-nai-bg2 hover:bg-nai-bg3 text-nai-text rounded-lg transition-colors text-sm"
                    >
                      選択
                    </button>
                  </div>
                </div>
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
