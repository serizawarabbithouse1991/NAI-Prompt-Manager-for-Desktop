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

## iOS版の開発

このプロジェクトは Tauri v2 ベースなので、同じ React 画面を iOS アプリとして利用できます。
iOS のプロジェクト生成・実機起動・署名は macOS + Xcode が必要です。
Windows では Tauri CLI の `ios` サブコマンドが利用できないため、以下の `ios:*` コマンドはMac上で実行してください。

### 必要環境

- macOS
- Xcode
- Rust / Node.js 18+
- 実機配布・App Store 配布を行う場合は Apple Developer Program

### 初回セットアップ

```bash
cd "NAI Prompt Manager for Desktop"
npm install
npm run ios:init
```

### iPhone / Simulator で起動

```bash
npm run ios:dev
```

実機で開発サーバーに接続する場合は、Tauri CLI が渡す `TAURI_DEV_HOST` を Vite が利用します。
このリポジトリの `vite.config.ts` は iOS 実機開発向けに設定済みです。

### iOSビルド

```bash
npm run ios:build
```

署名、Bundle ID、Provisioning Profile は Xcode 側で設定してください。
Bundle ID は `src-tauri/tauri.conf.json` の `identifier` と合わせます。

## データ共有

デスクトップ版とiOS版は、iCloud Drive上の同期フォルダを経由してデータを共有します。

推奨フォルダ:

```text
iCloud Drive/NAI-Prompt-Manager
```

同期フォルダ構造:

```text
NAI-Prompt-Manager/
├── sync/
│   ├── manifest.json
│   ├── device.json
│   └── changes/
├── images/
├── thumbnails/
├── meta/
├── tags/
└── folders/
```

### デスクトップからiOSへ共有

1. デスクトップ版の設定で `iCloud Drive 同期` を有効にします。
2. 同期フォルダに `iCloud Drive/NAI-Prompt-Manager` を選びます。
3. 初回は `初回フルエクスポート` を実行します。
4. iOS版で同じ同期フォルダを選び、`同期フォルダから取り込み` を実行します。

### 共有されるデータ

- 画像ファイル
- サムネイル
- プロンプト情報
- タグ
- フォルダ
- お気に入り / レーティング

現在の同期は「同期フォルダへの書き出し」と「同期フォルダからの取り込み」が中心です。
同じ画像IDのデータは取り込み時に上書き更新されます。

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
