import { create } from 'zustand'
import { supabase } from '../lib/supabase'
import type { User as SupabaseUser } from '@supabase/supabase-js'

interface User {
  id: string
  email: string | null
}

interface AuthState {
  user: User | null
  loading: boolean
  error: string | null
  
  initialize: () => Promise<void>
  signIn: (email: string, password: string) => Promise<boolean>
  signUp: (email: string, password: string) => Promise<boolean>
  signInWithMagicLink: (email: string) => Promise<boolean>
  signOut: () => Promise<void>
  clearError: () => void
}

function mapUser(supabaseUser: SupabaseUser | null): User | null {
  if (!supabaseUser) return null
  return {
    id: supabaseUser.id,
    email: supabaseUser.email ?? null,
  }
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  loading: true,
  error: null,

  initialize: async () => {
    try {
      // Get current session
      const { data: { session } } = await supabase.auth.getSession()
      set({ user: mapUser(session?.user ?? null), loading: false })

      // Listen for auth changes
      supabase.auth.onAuthStateChange((_event, session) => {
        set({ user: mapUser(session?.user ?? null) })
      })
    } catch (error) {
      console.error('Auth initialization error:', error)
      set({ loading: false, error: '認証の初期化に失敗しました' })
    }
  },

  signIn: async (email: string, password: string) => {
    set({ loading: true, error: null })
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error) {
        set({ error: error.message, loading: false })
        return false
      }

      set({ user: mapUser(data.user), loading: false })
      return true
    } catch (error) {
      set({ error: 'ログインに失敗しました', loading: false })
      return false
    }
  },

  signUp: async (email: string, password: string) => {
    set({ loading: true, error: null })
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      })

      if (error) {
        set({ error: error.message, loading: false })
        return false
      }

      // If email confirmation is required
      if (!data.user?.confirmed_at) {
        set({ 
          error: null, 
          loading: false 
        })
        return true // Return true but user won't be set until confirmed
      }

      set({ user: mapUser(data.user), loading: false })
      return true
    } catch (error) {
      set({ error: 'アカウント作成に失敗しました', loading: false })
      return false
    }
  },

  signInWithMagicLink: async (email: string) => {
    set({ loading: true, error: null })
    try {
      const { error } = await supabase.auth.signInWithOtp({
        email,
        options: {
          emailRedirectTo: window.location.origin,
        },
      })

      if (error) {
        set({ error: error.message, loading: false })
        return false
      }

      set({ loading: false })
      return true
    } catch (error) {
      set({ error: 'マジックリンクの送信に失敗しました', loading: false })
      return false
    }
  },

  signOut: async () => {
    set({ loading: true })
    try {
      await supabase.auth.signOut()
      set({ user: null, loading: false })
    } catch (error) {
      console.error('Sign out error:', error)
      set({ loading: false })
    }
  },

  clearError: () => set({ error: null }),
}))
