import 'package:drift/drift.dart';

import '../database/database.dart';
import '../models/models.dart';

/// 設定リポジトリ
/// key-value形式で設定を保存・読み込みする
class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  // ====================
  // 設定キー定数
  // ====================
  static const String keyTheme = 'theme';
  static const String keyLanguage = 'language';
  static const String keyShowNsfw = 'show_nsfw';
  static const String keyBlurNsfw = 'blur_nsfw';
  static const String keyNsfwDetectionEnabled = 'nsfw_detection_enabled';
  static const String keyNsfwThreshold = 'nsfw_threshold';
  static const String keyThumbnailSize = 'thumbnail_size';
  static const String keyViewMode = 'view_mode';
  static const String keySortBy = 'sort_by';
  static const String keySortOrder = 'sort_order';
  static const String keyListRowSize = 'list_row_size';
  static const String keyDanbooruDbPath = 'danbooru_db_path';
  static const String keyAutoTagEnabled = 'auto_tag_enabled';
  static const String keyAutoTagMinPostCount = 'auto_tag_min_post_count';
  static const String keyImageStoragePath = 'image_storage_path';

  // ====================
  // 基本操作
  // ====================

  /// 設定値を取得
  Future<String?> getValue(String key) async {
    final query = _db.select(_db.settings)
      ..where((tbl) => tbl.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  /// 設定値を保存
  Future<void> setValue(String key, String? value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
      SettingsCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  /// 設定値を削除
  Future<void> deleteValue(String key) async {
    await (_db.delete(_db.settings)
      ..where((tbl) => tbl.key.equals(key)))
        .go();
  }

  /// すべての設定を取得
  Future<Map<String, String?>> getAllSettings() async {
    final results = await _db.select(_db.settings).get();
    return {for (var s in results) s.key: s.value};
  }

  // ====================
  // AppSettings 操作
  // ====================

  /// AppSettings を読み込み
  Future<AppSettings> loadAppSettings() async {
    final settings = await getAllSettings();

    return AppSettings(
      theme: _parseThemeMode(settings[keyTheme]),
      language: settings[keyLanguage] ?? 'en',
      showNSFW: settings[keyShowNsfw] == 'true' || settings[keyShowNsfw] == null,
      blurNSFW: settings[keyBlurNsfw] == 'true',
      nsfwDetectionEnabled: settings[keyNsfwDetectionEnabled] == 'true',
      nsfwThreshold: double.tryParse(settings[keyNsfwThreshold] ?? '') ?? 0.5,
      imageStoragePath: settings[keyImageStoragePath] ?? '',
    );
  }

  /// AppSettings を保存
  Future<void> saveAppSettings(AppSettings settings) async {
    await Future.wait([
      setValue(keyTheme, settings.theme.value),
      setValue(keyLanguage, settings.language),
      setValue(keyShowNsfw, settings.showNSFW.toString()),
      setValue(keyBlurNsfw, settings.blurNSFW.toString()),
      setValue(keyNsfwDetectionEnabled, settings.nsfwDetectionEnabled.toString()),
      setValue(keyNsfwThreshold, settings.nsfwThreshold.toString()),
      setValue(keyImageStoragePath, settings.imageStoragePath),
    ]);
  }

  // ====================
  // ViewOptions 操作
  // ====================

  /// ViewOptions を読み込み
  Future<ViewOptions> loadViewOptions() async {
    final settings = await getAllSettings();

    return ViewOptions(
      mode: _parseViewMode(settings[keyViewMode]),
      thumbnailSize: _parseThumbnailSize(settings[keyThumbnailSize]),
      sortBy: _parseSortBy(settings[keySortBy]),
      sortOrder: _parseSortOrder(settings[keySortOrder]),
      listRowSize: _parseListRowSize(settings[keyListRowSize]),
    );
  }

  /// ViewOptions を保存
  Future<void> saveViewOptions(ViewOptions options) async {
    await Future.wait([
      setValue(keyViewMode, options.mode.value),
      setValue(keyThumbnailSize, options.thumbnailSize.value),
      setValue(keySortBy, options.sortBy.value),
      setValue(keySortOrder, options.sortOrder.value),
      setValue(keyListRowSize, options.listRowSize.value),
    ]);
  }

  // ====================
  // Danbooru 設定操作
  // ====================

  /// Danbooru DB パスを取得
  Future<String?> getDanbooruDbPath() async {
    return await getValue(keyDanbooruDbPath);
  }

  /// Danbooru DB パスを保存
  Future<void> setDanbooruDbPath(String? path) async {
    if (path == null || path.isEmpty) {
      await deleteValue(keyDanbooruDbPath);
    } else {
      await setValue(keyDanbooruDbPath, path);
    }
  }

  /// 自動タグ付けの有効/無効を取得
  Future<bool> getAutoTagEnabled() async {
    final value = await getValue(keyAutoTagEnabled);
    return value == 'true' || value == null; // デフォルトはtrue
  }

  /// 自動タグ付けの有効/無効を保存
  Future<void> setAutoTagEnabled(bool enabled) async {
    await setValue(keyAutoTagEnabled, enabled.toString());
  }

  /// 自動タグの最小投稿数を取得
  Future<int> getAutoTagMinPostCount() async {
    final value = await getValue(keyAutoTagMinPostCount);
    return int.tryParse(value ?? '') ?? 100;
  }

  /// 自動タグの最小投稿数を保存
  Future<void> setAutoTagMinPostCount(int count) async {
    await setValue(keyAutoTagMinPostCount, count.toString());
  }

  // ====================
  // ヘルパーメソッド
  // ====================

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  ViewMode _parseViewMode(String? value) {
    switch (value) {
      case 'list':
        return ViewMode.list;
      case 'grid':
      default:
        return ViewMode.grid;
    }
  }

  ThumbnailSize _parseThumbnailSize(String? value) {
    switch (value) {
      case 'small':
        return ThumbnailSize.small;
      case 'large':
        return ThumbnailSize.large;
      case 'xlarge':
        return ThumbnailSize.xlarge;
      case 'medium':
      default:
        return ThumbnailSize.medium;
    }
  }

  SortBy _parseSortBy(String? value) {
    switch (value) {
      case 'name':
        return SortBy.name;
      case 'size':
        return SortBy.size;
      case 'date':
      default:
        return SortBy.date;
    }
  }

  SortOrder _parseSortOrder(String? value) {
    switch (value) {
      case 'asc':
        return SortOrder.asc;
      case 'desc':
      default:
        return SortOrder.desc;
    }
  }

  ListRowSize _parseListRowSize(String? value) {
    switch (value) {
      case 'compact':
        return ListRowSize.compact;
      case 'comfortable':
        return ListRowSize.comfortable;
      case 'normal':
      default:
        return ListRowSize.normal;
    }
  }
}
