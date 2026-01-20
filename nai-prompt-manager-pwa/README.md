# NAI Prompt Manager PWA

AI画像生成のプロンプト管理ツール - Progressive Web App版

## 機能

- 画像のアップロード・管理
- NovelAI画像のメタデータ（プロンプト）自動抽出
- フォルダ・タグによる整理
- お気に入り機能
- 複数デバイス間のリアルタイム同期
- オフライン対応（PWA）

## セットアップ

### 1. Supabaseプロジェクトの作成

詳細は `supabase/README.md` を参照してください。

1. https://supabase.com でプロジェクトを作成
2. `supabase/schema.sql` をSQL Editorで実行
3. `supabase/storage.sql` をSQL Editorで実行
4. Project Settings > API からURLとキーを取得

### 2. 環境変数の設定

プロジェクトルートに `.env` ファイルを作成:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 3. 開発サーバーの起動

```bash
npm install
npm run dev
```

### 4. ビルド

```bash
npm run build
```

## デプロイ

### Vercel

```bash
npm install -g vercel
vercel
```

### Netlify

```bash
npm install -g netlify-cli
netlify deploy --prod --dir=dist
```

## 技術スタック

- **フロントエンド**: React + TypeScript + Tailwind CSS
- **状態管理**: Zustand
- **バックエンド**: Supabase (PostgreSQL + Auth + Storage)
- **PWA**: vite-plugin-pwa + Workbox
- **ビルドツール**: Vite

## iPhoneでの利用方法

1. SafariでアプリのURLにアクセス
2. 共有ボタン（□↑）をタップ
3. 「ホーム画面に追加」を選択
4. アプリがホーム画面に追加されます

## ライセンス

MIT
