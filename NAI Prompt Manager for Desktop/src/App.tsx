import { useEffect, useState } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { useAppStore } from './stores/appStore'
import { initDatabase } from './lib/database'
import GalleryView from './components/gallery/GalleryView'
import SettingsView from './components/settings/SettingsView'
import Sidebar from './components/sidebar/Sidebar'
import TitleBar from './components/layout/TitleBar'
import { translate, useI18n } from './lib/i18n'

export default function App() {
  const [initialized, setInitialized] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const { sidebarOpen } = useAppStore()
  const { t, language } = useI18n()

  useEffect(() => {
    const init = async () => {
      try {
        await initDatabase()
        setInitialized(true)
      } catch (err) {
        console.error('Failed to initialize database:', err)
        setError(err instanceof Error ? err.message : translate(language, 'appErrorTitle'))
      }
    }
    init()
  }, [])

  if (error) {
    return (
      <div className="h-screen flex items-center justify-center bg-nai-bg0">
        <div className="text-center p-8">
          <div className="w-16 h-16 bg-red-900/30 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <h2 className="text-xl font-bold text-white mb-2">{t('appErrorTitle')}</h2>
          <p className="text-zinc-400">{error}</p>
        </div>
      </div>
    )
  }

  if (!initialized) {
    return (
      <div className="h-screen flex items-center justify-center bg-nai-bg0">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-nai-accent border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-zinc-400">{t('initializing')}</p>
        </div>
      </div>
    )
  }

  return (
    <div className="h-screen flex flex-col bg-nai-bg0 overflow-hidden">
      {/* Custom Title Bar */}
      <TitleBar />

      {/* Main Content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Sidebar */}
        {sidebarOpen && <Sidebar />}

        {/* Main Area */}
        <main className="flex-1 overflow-hidden">
          <Routes>
            <Route path="/" element={<Navigate to="/gallery" replace />} />
            <Route path="/gallery" element={<GalleryView />} />
            <Route path="/settings" element={<SettingsView />} />
          </Routes>
        </main>
      </div>
    </div>
  )
}
