// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'NAI Prompt Manager';

  @override
  String get home => 'ホーム';

  @override
  String get gallery => 'ギャラリー';

  @override
  String get search => '検索';

  @override
  String get promptAnalysis => 'プロンプト分析';

  @override
  String get settings => '設定';

  @override
  String get upload => 'アップロード';

  @override
  String get uploadImages => '画像をアップロード';

  @override
  String get selectFiles => 'ファイルを選択';

  @override
  String get dragAndDrop => 'ドラッグ&ドロップまたはクリックしてファイルを選択';

  @override
  String get supportedFormats => 'PNG, JPG, WEBP, GIF（複数選択可）';

  @override
  String get selectedFiles => '選択されたファイル';

  @override
  String get uploading => 'アップロード中...';

  @override
  String get cancel => 'キャンセル';

  @override
  String get clear => 'クリア';

  @override
  String get allImages => 'すべての画像';

  @override
  String get favorites => 'お気に入り';

  @override
  String get uncategorized => '未分類';

  @override
  String get folders => 'フォルダ';

  @override
  String get tags => 'タグ';

  @override
  String get noFolders => 'フォルダがありません';

  @override
  String get noTags => 'タグがありません';

  @override
  String get noImages => '画像がありません';

  @override
  String get createFolder => '新規フォルダ';

  @override
  String get folderName => 'フォルダ名';

  @override
  String get create => '作成';

  @override
  String get delete => '削除';

  @override
  String get rename => '名前変更';

  @override
  String get moveToFolder => 'フォルダに移動';

  @override
  String get addTag => 'タグを追加';

  @override
  String get removeTag => 'タグを削除';

  @override
  String get searchPlaceholder => 'プロンプト、ファイル名で検索...';

  @override
  String get searchResults => '検索結果';

  @override
  String get noSearchResults => '検索結果がありません';

  @override
  String get filters => 'フィルタ';

  @override
  String get clearFilters => 'フィルタをクリア';

  @override
  String get favoritesOnly => 'お気に入りのみ';

  @override
  String get positivePrompt => 'Positive Prompt';

  @override
  String get negativePrompt => 'Negative Prompt';

  @override
  String get model => 'モデル';

  @override
  String get sampler => 'サンプラー';

  @override
  String get steps => 'ステップ';

  @override
  String get cfgScale => 'CFG Scale';

  @override
  String get seed => 'シード';

  @override
  String get resolution => '解像度';

  @override
  String get info => '情報';

  @override
  String get filename => 'ファイル名';

  @override
  String get fileSize => 'ファイルサイズ';

  @override
  String get imageSize => '画像サイズ';

  @override
  String get createdAt => '作成日時';

  @override
  String get sourceType => 'ソースタイプ';

  @override
  String get nsfwScore => 'NSFWスコア';

  @override
  String get openInExplorer => 'エクスプローラーで開く';

  @override
  String get copyToClipboard => 'クリップボードにコピー';

  @override
  String get settingsDatabase => 'データベース';

  @override
  String get settingsDatabaseMigration => 'データベース移行';

  @override
  String get settingsTauriMigration => 'Tauri版からの移行';

  @override
  String get settingsTauriMigrationDescription =>
      '既存のTauri版NAI Prompt Managerのデータをインポートできます';

  @override
  String get settingsTauriDbFound => 'Tauri版DBを検出しました';

  @override
  String get settingsTauriDbNotFound => 'Tauri版のDBが見つかりませんでした';

  @override
  String get settingsSelectDbFile => 'DBファイルを選択';

  @override
  String get settingsImport => 'インポート';

  @override
  String get settingsImporting => 'インポート中...';

  @override
  String get settingsImportComplete => 'インポート完了。アプリを再起動してください。';

  @override
  String get settingsDisplay => '表示設定';

  @override
  String get settingsApplication => 'アプリケーション';

  @override
  String get error => 'エラー';

  @override
  String get errorOccurred => 'エラーが発生しました';

  @override
  String get retry => '再試行';

  @override
  String get close => '閉じる';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get confirm => '確認';

  @override
  String get warning => '警告';

  @override
  String get processing => '処理中';

  @override
  String get duplicate => '重複';

  @override
  String get duplicateFile => '重複ファイル';
}
