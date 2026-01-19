import 'package:flutter/foundation.dart';
import 'enums.dart';
import 'image_with_details.dart';

/// 画像フィルタ（DBクエリ用）
@immutable
class ImageFilter {
  final String? folderId;
  final bool uncategorizedOnly;
  final String? searchQuery;
  final List<String> tagIds;
  final bool favoritesOnly;
  final bool duplicatesOnly;
  final bool noTagsOnly;
  final bool showNSFW;
  final SortBy sortBy;
  final SortOrder sortOrder;

  const ImageFilter({
    this.folderId,
    this.uncategorizedOnly = false,
    this.searchQuery,
    this.tagIds = const [],
    this.favoritesOnly = false,
    this.duplicatesOnly = false,
    this.noTagsOnly = false,
    this.showNSFW = true,
    this.sortBy = SortBy.date,
    this.sortOrder = SortOrder.desc,
  });

  ImageFilter copyWith({
    String? folderId,
    bool? uncategorizedOnly,
    String? searchQuery,
    List<String>? tagIds,
    bool? favoritesOnly,
    bool? duplicatesOnly,
    bool? noTagsOnly,
    bool? showNSFW,
    SortBy? sortBy,
    SortOrder? sortOrder,
  }) {
    return ImageFilter(
      folderId: folderId ?? this.folderId,
      uncategorizedOnly: uncategorizedOnly ?? this.uncategorizedOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      tagIds: tagIds ?? this.tagIds,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      duplicatesOnly: duplicatesOnly ?? this.duplicatesOnly,
      noTagsOnly: noTagsOnly ?? this.noTagsOnly,
      showNSFW: showNSFW ?? this.showNSFW,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static const ImageFilter defaultFilter = ImageFilter(
    sortBy: SortBy.date,
    sortOrder: SortOrder.desc,
    showNSFW: true,
  );
}

/// ページネーション状態
@immutable
class PaginationState {
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const PaginationState({
    this.page = 0,
    this.pageSize = 50,
    this.totalCount = 0,
    this.hasMore = false,
  });

  PaginationState copyWith({
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
  }) {
    return PaginationState(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// ページネーション対応画像取得結果
@immutable
class PaginatedImagesResult {
  final List<ImageWithDetails> images;
  final int totalCount;
  final bool hasMore;

  const PaginatedImagesResult({
    required this.images,
    required this.totalCount,
    required this.hasMore,
  });
}

/// デフォルトのページサイズ
const int defaultPageSize = 50;
