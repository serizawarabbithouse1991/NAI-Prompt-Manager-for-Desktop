import { useAuthStore } from '../stores/authStore'

export function SettingsPage() {
  const { user, signOut } = useAuthStore()

  return (
    <div className="p-6 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold text-white mb-6">設定</h1>

      {/* Account section */}
      <section className="bg-dark-800 rounded-xl p-6 mb-6">
        <h2 className="text-lg font-semibold text-white mb-4">アカウント</h2>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm text-dark-400 mb-1">メールアドレス</label>
            <p className="text-white">{user?.email ?? '-'}</p>
          </div>

          <div>
            <label className="block text-sm text-dark-400 mb-1">ユーザーID</label>
            <p className="text-white font-mono text-sm">{user?.id ?? '-'}</p>
          </div>
        </div>
      </section>

      {/* Storage section */}
      <section className="bg-dark-800 rounded-xl p-6 mb-6">
        <h2 className="text-lg font-semibold text-white mb-4">ストレージ</h2>
        
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-white">キャッシュをクリア</p>
              <p className="text-sm text-dark-400">ローカルにキャッシュされた画像を削除します</p>
            </div>
            <button
              onClick={() => {
                // Clear cache
                if ('caches' in window) {
                  caches.keys().then(names => {
                    names.forEach(name => caches.delete(name))
                  })
                  alert('キャッシュをクリアしました')
                }
              }}
              className="px-4 py-2 bg-dark-700 hover:bg-dark-600 text-white rounded-lg transition-colors"
            >
              クリア
            </button>
          </div>
        </div>
      </section>

      {/* About section */}
      <section className="bg-dark-800 rounded-xl p-6 mb-6">
        <h2 className="text-lg font-semibold text-white mb-4">アプリ情報</h2>
        
        <div className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-dark-400">バージョン</span>
            <span className="text-white">1.0.0</span>
          </div>
          <div className="flex justify-between">
            <span className="text-dark-400">ビルド</span>
            <span className="text-white">PWA</span>
          </div>
        </div>
      </section>

      {/* Logout button */}
      <button
        onClick={signOut}
        className="w-full py-3 bg-red-600 hover:bg-red-500 text-white font-medium rounded-lg transition-colors"
      >
        ログアウト
      </button>
    </div>
  )
}
