/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'nai-bg0': '#0e0e10',
        'nai-bg1': '#18181b',
        'nai-bg2': '#1f1f23',
        'nai-bg3': '#27272a',
        'nai-accent': '#a78bfa',
        'nai-accent-hover': '#8b5cf6',
        'nai-text': '#fafafa',
        'nai-text-muted': '#a1a1aa',
        'nai-text-placeholder': '#52525b',
        'nai-border': '#3f3f46',
      },
      fontFamily: {
        sans: ['Inter', 'Noto Sans JP', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
