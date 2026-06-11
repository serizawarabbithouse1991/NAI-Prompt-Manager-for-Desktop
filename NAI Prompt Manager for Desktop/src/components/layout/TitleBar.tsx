import { getCurrentWindow } from '@tauri-apps/api/window'
import { useAppStore } from '../../stores/appStore'

export default function TitleBar() {
  const { toggleSidebar, sidebarOpen } = useAppStore()

  const handleMinimize = () => getCurrentWindow().minimize()
  const handleMaximize = () => getCurrentWindow().toggleMaximize()
  const handleClose = () => getCurrentWindow().close()

  return (
    <header className="app-titlebar bg-nai-bg1 border-b border-nai-border flex items-center justify-between select-none">
      {/* Left: Menu & Title */}
      <div className="flex items-center">
        {/* Sidebar Toggle */}
        <button
          onClick={toggleSidebar}
          className="titlebar-no-drag h-10 w-10 flex items-center justify-center hover:bg-nai-bg2 transition-colors"
          title={sidebarOpen ? 'サイドバーを閉じる' : 'サイドバーを開く'}
        >
          <svg className="w-4 h-4 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h7" />
          </svg>
        </button>

        {/* App Title - Draggable */}
        <div className="titlebar-drag flex items-center px-3 h-10">
          <span className="text-sm font-semibold text-nai-accent">NAI Prompt Manager</span>
        </div>
      </div>

      {/* Center: Drag Region */}
      <div className="flex-1 titlebar-drag h-full" />

      {/* Right: Window Controls */}
      <div className="desktop-window-controls flex items-center titlebar-no-drag">
        {/* Minimize */}
        <button
          onClick={handleMinimize}
          className="h-10 w-12 flex items-center justify-center hover:bg-nai-bg2 transition-colors"
          title="最小化"
        >
          <svg className="w-4 h-4 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 12H4" />
          </svg>
        </button>

        {/* Maximize */}
        <button
          onClick={handleMaximize}
          className="h-10 w-12 flex items-center justify-center hover:bg-nai-bg2 transition-colors"
          title="最大化"
        >
          <svg className="w-3.5 h-3.5 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <rect x="4" y="4" width="16" height="16" rx="1" strokeWidth={2} />
          </svg>
        </button>

        {/* Close */}
        <button
          onClick={handleClose}
          className="h-10 w-12 flex items-center justify-center hover:bg-red-600 transition-colors"
          title="閉じる"
        >
          <svg className="w-4 h-4 text-nai-text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </header>
  )
}
