# NAI Prompt Manager - Desktop Version

NovelAI/Stable Diffusion等のAI生成画像を管理するデスクトップアプリケーション。
画像のアップロード、プロンプト情報の自動抽出・保存、タグ付け、お気に入り管理機能を提供。

## 特徴

- **オフラインファースト**: すべてローカルで動作、インターネット接続不要
- **PNGメタデータ自動抽出**: NovelAI形式のプロンプト情報を自動解析
- **専用フォルダ管理**: 画像をアプリ専用フォルダにコピーして一元管理
- **高速検索**: SQLiteによる高速なローカルデータベース
- **軽量**: Tauri v2による軽量なネイティブアプリ

## Tech Stack

- **Framework**: Tauri v2 (Rust backend)
- **Frontend**: React 18 + Vite
- **State**: Zustand
- **Database**: SQLite (via @tauri-apps/plugin-sql)
- **Styling**: Tailwind CSS 3
- **Language**: TypeScript

## 必要環境

### 開発環境

- Node.js 18+
- Rust (最新stable)
- Windows 10/11

### Rust / Tauri のセットアップ (Windows)

```bash
# Rust のインストール
# https://www.rust-lang.org/tools/install からダウンロード

# Visual Studio Build Tools が必要
# https://visualstudio.microsoft.com/visual-cpp-build-tools/
```

## 開発

### インストール

```bash
cd "NAI Prompt Manager for Desktop"
npm install
```

### 開発サーバー起動

```bash
npm run tauri:dev
```

### プロダクションビルド

```bash
npm run tauri:build
```

ビルドされたインストーラーは `src-tauri/target/release/bundle/` に出力されます。

## ディレクトリ構造

```
NAI Prompt Manager for Desktop/
├── src/
│   ├── main.tsx                 # エントリーポイント
│   ├── App.tsx                  # ルートコンポーネント
│   ├── components/
│   │   ├── gallery/             # ギャラリー関連
│   │   ├── sidebar/             # サイドバー関連
│   │   ├── upload/              # アップロードモーダル
│   │   ├── settings/            # 設定画面
│   │   └── layout/              # レイアウト
│   ├── stores/                  # Zustand stores
│   ├── lib/
│   │   ├── database/            # SQLite操作
│   │   ├── png-metadata.ts      # PNGメタデータ抽出
│   │   ├── export.ts            # エクスポート機能
│   │   └── utils.ts             # ユーティリティ
│   ├── types/                   # 型定義
│   └── styles/                  # グローバルスタイル
├── src-tauri/                   # Tauriバックエンド
│   ├── Cargo.toml
│   ├── src/main.rs
│   ├── tauri.conf.json
│   └── capabilities/
└── package.json
```

## 機能一覧

### 画像管理

- ✅ 画像インポート（ファイル選択）
- ✅ PNGメタデータ自動抽出（NovelAI形式対応）
- ✅ ギャラリー表示（グリッド/リスト）
- ✅ サムネイルサイズ調整
- ✅ ソート（日付/名前/サイズ）

### 整理機能

- ✅ フォルダ/プロジェクト管理
- ✅ タグ管理（カラー対応）
- ✅ お気に入り機能
- ✅ 複数選択モード

### 検索・フィルタ

- ✅ キーワード検索（ファイル名/プロンプト）
- ✅ タグフィルタ
- ✅ お気に入りフィルタ
- ✅ フォルダフィルタ

### 詳細・編集

- ✅ 画像詳細モーダル
- ✅ プロンプト情報表示
- ✅ プロンプト編集
- ✅ タグ追加/削除

### エクスポート

- ✅ JSONエクスポート（メタデータのみ）
- ✅ ファイル付きエクスポート

### 設定

- ✅ 画像保存フォルダ設定
- ✅ サムネイルサイズ設定
- ✅ 自動バックアップ設定

## データ保存場所

- **データベース**: `%APPDATA%/com.nai-prompt-manager.desktop/nai_prompt_manager.db`
- **画像**: `%APPDATA%/com.nai-prompt-manager.desktop/images/`
- **サムネイル**: `%APPDATA%/com.nai-prompt-manager.desktop/thumbnails/`

## License

MIT
