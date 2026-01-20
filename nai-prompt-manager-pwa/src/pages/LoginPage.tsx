import { useState } from 'react'
import { useAuthStore } from '../stores/authStore'

type AuthMode = 'signin' | 'signup' | 'magic-link'

export function LoginPage() {
  const [mode, setMode] = useState<AuthMode>('signin')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [magicLinkSent, setMagicLinkSent] = useState(false)
  
  const { loading, error, signIn, signUp, signInWithMagicLink, clearError } = useAuthStore()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    clearError()

    if (mode === 'magic-link') {
      const success = await signInWithMagicLink(email)
      if (success) {
        setMagicLinkSent(true)
      }
      return
    }

    if (mode === 'signin') {
      await signIn(email, password)
    } else {
      const success = await signUp(email, password)
      if (success) {
        // Show success message for signup
        alert('確認メールを送信しました。メールをご確認ください。')
      }
    }
  }

  const switchMode = (newMode: AuthMode) => {
    setMode(newMode)
    clearError()
    setMagicLinkSent(false)
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-dark-900 p-4">
      <div className="w-full max-w-md">
        {/* Logo/Header */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">
            NAI Prompt Manager
          </h1>
          <p className="text-dark-400">
            AI画像生成のプロンプト管理ツール
          </p>
        </div>

        {/* Auth Card */}
        <div className="bg-dark-800 rounded-xl p-6 shadow-xl">
          {magicLinkSent ? (
            <div className="text-center py-8">
              <div className="w-16 h-16 bg-primary-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-8 h-8 text-primary-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
              </div>
              <h2 className="text-xl font-semibold text-white mb-2">
                メールを確認してください
              </h2>
              <p className="text-dark-400 mb-4">
                {email} にログインリンクを送信しました
              </p>
              <button
                onClick={() => setMagicLinkSent(false)}
                className="text-primary-400 hover:text-primary-300"
              >
                別のメールアドレスを使用
              </button>
            </div>
          ) : (
            <>
              {/* Mode Tabs */}
              <div className="flex border-b border-dark-700 mb-6">
                <button
                  onClick={() => switchMode('signin')}
                  className={`flex-1 py-3 text-sm font-medium border-b-2 transition-colors ${
                    mode === 'signin'
                      ? 'text-primary-400 border-primary-400'
                      : 'text-dark-400 border-transparent hover:text-dark-300'
                  }`}
                >
                  ログイン
                </button>
                <button
                  onClick={() => switchMode('signup')}
                  className={`flex-1 py-3 text-sm font-medium border-b-2 transition-colors ${
                    mode === 'signup'
                      ? 'text-primary-400 border-primary-400'
                      : 'text-dark-400 border-transparent hover:text-dark-300'
                  }`}
                >
                  新規登録
                </button>
              </div>

              {/* Error Message */}
              {error && (
                <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded-lg text-red-400 text-sm">
                  {error}
                </div>
              )}

              {/* Form */}
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-dark-300 mb-1">
                    メールアドレス
                  </label>
                  <input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="w-full px-4 py-3 bg-dark-700 border border-dark-600 rounded-lg text-white placeholder-dark-400 focus:outline-none focus:border-primary-500 focus:ring-1 focus:ring-primary-500"
                    placeholder="your@email.com"
                  />
                </div>

                {mode !== 'magic-link' && (
                  <div>
                    <label htmlFor="password" className="block text-sm font-medium text-dark-300 mb-1">
                      パスワード
                    </label>
                    <input
                      id="password"
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                      minLength={6}
                      className="w-full px-4 py-3 bg-dark-700 border border-dark-600 rounded-lg text-white placeholder-dark-400 focus:outline-none focus:border-primary-500 focus:ring-1 focus:ring-primary-500"
                      placeholder="6文字以上"
                    />
                  </div>
                )}

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3 bg-primary-600 hover:bg-primary-500 disabled:bg-primary-800 disabled:cursor-not-allowed text-white font-medium rounded-lg transition-colors flex items-center justify-center gap-2"
                >
                  {loading && (
                    <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full spinner" />
                  )}
                  {mode === 'signin' ? 'ログイン' : mode === 'signup' ? 'アカウント作成' : 'リンクを送信'}
                </button>
              </form>

              {/* Magic Link Option */}
              {mode !== 'magic-link' && (
                <div className="mt-4 text-center">
                  <button
                    onClick={() => switchMode('magic-link')}
                    className="text-sm text-dark-400 hover:text-primary-400 transition-colors"
                  >
                    パスワードなしでログイン（マジックリンク）
                  </button>
                </div>
              )}

              {mode === 'magic-link' && (
                <div className="mt-4 text-center">
                  <button
                    onClick={() => switchMode('signin')}
                    className="text-sm text-dark-400 hover:text-primary-400 transition-colors"
                  >
                    パスワードでログイン
                  </button>
                </div>
              )}
            </>
          )}
        </div>

        {/* Footer */}
        <p className="text-center text-dark-500 text-sm mt-6">
          データはSupabaseで安全に管理されます
        </p>
      </div>
    </div>
  )
}
