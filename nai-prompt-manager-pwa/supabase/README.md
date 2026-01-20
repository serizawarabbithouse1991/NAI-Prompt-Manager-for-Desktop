# Supabase セットアップ手順

## 1. Supabaseアカウント作成

1. https://supabase.com にアクセス
2. 「Start your project」をクリック
3. GitHubアカウントでサインアップ（推奨）

## 2. 新規プロジェクト作成

1. ダッシュボードで「New project」をクリック
2. 以下を設定:
   - **Name**: `nai-prompt-manager`（任意）
   - **Database Password**: 強力なパスワードを設定（保存しておく）
   - **Region**: `Northeast Asia (Tokyo)` を推奨
3. 「Create new project」をクリック

## 3. データベーススキーマの作成

1. 左メニューから「SQL Editor」を開く
2. 「New query」をクリック
3. `schema.sql` の内容をコピー&ペースト
4. 「Run」をクリックして実行
5. 同様に `storage.sql` を実行

## 4. APIキーの取得

1. 左メニューから「Project Settings」→「API」を開く
2. 以下の値をコピー:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIs...`

## 5. 環境変数の設定

プロジェクトルートに `.env` ファイルを作成:

```env
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
```

## 6. 認証設定（オプション）

### Magic Link認証を有効化（推奨）
1. 左メニューから「Authentication」→「Providers」
2. 「Email」が有効になっていることを確認
3. 「Confirm email」をオフにすると、即座にログイン可能

### 追加の認証プロバイダー
必要に応じてGoogle、GitHub等の認証を追加可能

## トラブルシューティング

### RLSエラーが発生する場合
- ログインしているか確認
- スキーマが正しく作成されているか確認

### 画像がアップロードできない場合
- Storage bucketが作成されているか確認
- ファイルサイズ制限（50MB）を超えていないか確認
