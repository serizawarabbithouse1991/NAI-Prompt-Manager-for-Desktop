import 'package:flutter/foundation.dart';
import 'enums.dart';

/// アプリ設定
@immutable
class AppSettings {
  final String imageStoragePath;
  final int thumbnailSize;
  final bool autoBackupEnabled;
  final String? backupPath;
  final int autoBackupIntervalHours;
  final int backupRetentionCount;
  final List<String> forbiddenTags;
  // Theme
  final ThemeMode theme;
  // NSFW Display
  final bool showNSFW;
  final bool blurNSFW;
  // NSFW Detection
  final bool nsfwDetectionEnabled;
  final double nsfwThreshold;
  final List<NSFWCategory> nsfwCategories;
  // Skin Exposure (R15)
  final bool showSkinExposure;
  final bool blurSkinExposure;
  final List<NSFWCategory> skinExposureCategories;
  // Language
  final String language;
  // Post-upload action
  final PostUploadAction postUploadAction;
  final String? postUploadMoveDestination;

  const AppSettings({
    this.imageStoragePath = '',
    this.thumbnailSize = 200,
    this.autoBackupEnabled = false,
    this.backupPath,
    this.autoBackupIntervalHours = 24,
    this.backupRetentionCount = 5,
    this.forbiddenTags = const [],
    this.theme = ThemeMode.dark,
    this.showNSFW = true,
    this.blurNSFW = false,
    this.nsfwDetectionEnabled = false,
    this.nsfwThreshold = 0.5,
    this.nsfwCategories = const [NSFWCategory.hentai, NSFWCategory.porn],
    this.showSkinExposure = true,
    this.blurSkinExposure = false,
    this.skinExposureCategories = const [NSFWCategory.sexy],
    this.language = 'en',
    this.postUploadAction = PostUploadAction.keep,
    this.postUploadMoveDestination,
  });

  AppSettings copyWith({
    String? imageStoragePath,
    int? thumbnailSize,
    bool? autoBackupEnabled,
    String? backupPath,
    int? autoBackupIntervalHours,
    int? backupRetentionCount,
    List<String>? forbiddenTags,
    ThemeMode? theme,
    bool? showNSFW,
    bool? blurNSFW,
    bool? nsfwDetectionEnabled,
    double? nsfwThreshold,
    List<NSFWCategory>? nsfwCategories,
    bool? showSkinExposure,
    bool? blurSkinExposure,
    List<NSFWCategory>? skinExposureCategories,
    String? language,
    PostUploadAction? postUploadAction,
    String? postUploadMoveDestination,
  }) {
    return AppSettings(
      imageStoragePath: imageStoragePath ?? this.imageStoragePath,
      thumbnailSize: thumbnailSize ?? this.thumbnailSize,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupPath: backupPath ?? this.backupPath,
      autoBackupIntervalHours:
          autoBackupIntervalHours ?? this.autoBackupIntervalHours,
      backupRetentionCount: backupRetentionCount ?? this.backupRetentionCount,
      forbiddenTags: forbiddenTags ?? this.forbiddenTags,
      theme: theme ?? this.theme,
      showNSFW: showNSFW ?? this.showNSFW,
      blurNSFW: blurNSFW ?? this.blurNSFW,
      nsfwDetectionEnabled: nsfwDetectionEnabled ?? this.nsfwDetectionEnabled,
      nsfwThreshold: nsfwThreshold ?? this.nsfwThreshold,
      nsfwCategories: nsfwCategories ?? this.nsfwCategories,
      showSkinExposure: showSkinExposure ?? this.showSkinExposure,
      blurSkinExposure: blurSkinExposure ?? this.blurSkinExposure,
      skinExposureCategories:
          skinExposureCategories ?? this.skinExposureCategories,
      language: language ?? this.language,
      postUploadAction: postUploadAction ?? this.postUploadAction,
      postUploadMoveDestination:
          postUploadMoveDestination ?? this.postUploadMoveDestination,
    );
  }
}

/// 表示オプション
@immutable
class ViewOptions {
  final ViewMode mode;
  final ThumbnailSize thumbnailSize;
  final SortBy sortBy;
  final SortOrder sortOrder;
  final ListRowSize listRowSize;
  final List<ListColumn> listVisibleColumns;

  const ViewOptions({
    this.mode = ViewMode.grid,
    this.thumbnailSize = ThumbnailSize.medium,
    this.sortBy = SortBy.date,
    this.sortOrder = SortOrder.desc,
    this.listRowSize = ListRowSize.normal,
    this.listVisibleColumns = const [
      ListColumn.thumbnail,
      ListColumn.filename,
      ListColumn.prompt,
      ListColumn.createdAt,
    ],
  });

  ViewOptions copyWith({
    ViewMode? mode,
    ThumbnailSize? thumbnailSize,
    SortBy? sortBy,
    SortOrder? sortOrder,
    ListRowSize? listRowSize,
    List<ListColumn>? listVisibleColumns,
  }) {
    return ViewOptions(
      mode: mode ?? this.mode,
      thumbnailSize: thumbnailSize ?? this.thumbnailSize,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      listRowSize: listRowSize ?? this.listRowSize,
      listVisibleColumns: listVisibleColumns ?? this.listVisibleColumns,
    );
  }
}

/// フィルタオプション
@immutable
class FilterOptions {
  final String searchQuery;
  final String? folderId;
  final List<String> tagIds;
  final bool favoritesOnly;
  final bool untaggedOnly;
  final bool duplicatesOnly;

  const FilterOptions({
    this.searchQuery = '',
    this.folderId,
    this.tagIds = const [],
    this.favoritesOnly = false,
    this.untaggedOnly = false,
    this.duplicatesOnly = false,
  });

  FilterOptions copyWith({
    String? searchQuery,
    String? folderId,
    List<String>? tagIds,
    bool? favoritesOnly,
    bool? untaggedOnly,
    bool? duplicatesOnly,
  }) {
    return FilterOptions(
      searchQuery: searchQuery ?? this.searchQuery,
      folderId: folderId ?? this.folderId,
      tagIds: tagIds ?? this.tagIds,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      untaggedOnly: untaggedOnly ?? this.untaggedOnly,
      duplicatesOnly: duplicatesOnly ?? this.duplicatesOnly,
    );
  }
}

/// 保存済み検索
@immutable
class SavedSearch {
  final String id;
  final String name;
  final FilterOptions filters;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedSearch({
    required this.id,
    required this.name,
    required this.filters,
    required this.createdAt,
    required this.updatedAt,
  });

  SavedSearch copyWith({
    String? id,
    String? name,
    FilterOptions? filters,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedSearch(
      id: id ?? this.id,
      name: name ?? this.name,
      filters: filters ?? this.filters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 自動タグ付け設定
@immutable
class AutoTagSettings {
  final String? danbooruDbPath;
  final bool normalizeWithDanbooru;
  final bool assignCategories;
  final int minPostCount;

  const AutoTagSettings({
    this.danbooruDbPath,
    this.normalizeWithDanbooru = true,
    this.assignCategories = true,
    this.minPostCount = 100,
  });

  AutoTagSettings copyWith({
    String? danbooruDbPath,
    bool? normalizeWithDanbooru,
    bool? assignCategories,
    int? minPostCount,
  }) {
    return AutoTagSettings(
      danbooruDbPath: danbooruDbPath ?? this.danbooruDbPath,
      normalizeWithDanbooru:
          normalizeWithDanbooru ?? this.normalizeWithDanbooru,
      assignCategories: assignCategories ?? this.assignCategories,
      minPostCount: minPostCount ?? this.minPostCount,
    );
  }
}
