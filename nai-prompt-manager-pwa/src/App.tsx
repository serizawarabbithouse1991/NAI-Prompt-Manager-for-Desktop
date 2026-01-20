import { useEffect } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from './stores/authStore'
import { useImageStore } from './stores/imageStore'
import { useFolderStore } from './stores/folderStore'
import { useTagStore } from './stores/tagStore'
import { subscribeToAllTables, unsubscribeAll } from './lib/realtime'
import { Layout } from './components/layout/Layout'
import { LoginPage } from './pages/LoginPage'
import { GalleryPage } from './pages/GalleryPage'
import { SettingsPage } from './pages/SettingsPage'

function App() {
  const { user, loading, initialize } = useAuthStore()
  const { fetchImages } = useImageStore()
  const { fetchFolders } = useFolderStore()
  const { fetchTags } = useTagStore()

  useEffect(() => {
    initialize()
  }, [initialize])

  // Set up realtime subscriptions when user is authenticated
  useEffect(() => {
    if (!user) {
      unsubscribeAll()
      return
    }

    const unsubscribe = subscribeToAllTables(user.id, {
      onImageChange: () => fetchImages(),
      onFolderChange: () => fetchFolders(),
      onTagChange: () => fetchTags(),
    })

    return () => {
      unsubscribe()
    }
  }, [user, fetchImages, fetchFolders, fetchTags])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-dark-900">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-primary-500 border-t-transparent rounded-full spinner" />
          <p className="text-dark-400">読み込み中...</p>
        </div>
      </div>
    )
  }

  if (!user) {
    return <LoginPage />
  }

  return (
    <Layout>
      <Routes>
        <Route path="/" element={<GalleryPage />} />
        <Route path="/settings" element={<SettingsPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Layout>
  )
}

export default App
