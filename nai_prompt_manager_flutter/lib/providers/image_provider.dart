import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'repository_providers.dart';
import 'app_provider.dart';

/// 画像リストの状態
class ImageListState {
  final List<ImageWithDetails> images;
  final PaginationState pagination;
  final ImageFilter currentFilter;
  final bool loading;
  final bool loadingMore;
  final String? error;

  const ImageListState({
    this.images = const [],
    this.pagination = const PaginationState(),
    this.currentFilter = ImageFilter.defaultFilter,
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  ImageListState copyWith({
    List<ImageWithDetails>? images,
    PaginationState? pagination,
    ImageFilter? currentFilter,
    bool? loading,
    bool? loadingMore,
    String? error,
  }) {
    return ImageListState(
      images: images ?? this.images,
      pagination: pagination ?? this.pagination,
      currentFilter: currentFilter ?? this.currentFilter,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }
}

/// 画像リストのNotifier
class ImageListNotifier extends StateNotifier<ImageListState> {
  final ImageRepository _repository;
  final bool showNsfw;

  ImageListNotifier(this._repository, {this.showNsfw = true}) : super(const ImageListState());

  /// 画像を読み込む
  Future<void> loadImages([ImageFilter? filter]) async {
    final newFilter = filter ?? state.currentFilter;
    state = state.copyWith(
      loading: true,
      error: null,
      currentFilter: newFilter,
    );

    try {
      final result = await _repository.getImages(
        filter: newFilter,
        offset: 0,
        limit: defaultPageSize,
      );
      
      // NSFW画像をフィルタリング
      final filteredImages = showNsfw 
          ? result.images 
          : result.images.where((img) => img.isNsfw != true).toList();
      
      state = state.copyWith(
        images: filteredImages,
        pagination: PaginationState(
          page: 0,
          pageSize: defaultPageSize,
          totalCount: showNsfw ? result.totalCount : filteredImages.length,
          hasMore: result.hasMore,
        ),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        loading: false,
        images: [],
        pagination: const PaginationState(),
      );
    }
  }

  /// 追加読み込み（無限スクロール）
  Future<void> loadMoreImages() async {
    if (state.loadingMore || !state.pagination.hasMore) return;

    state = state.copyWith(loadingMore: true);

    try {
      final offset = state.images.length;
      final result = await _getImagesWithPagination(
        state.currentFilter,
        offset,
        defaultPageSize,
      );

      state = state.copyWith(
        images: [...state.images, ...result.images],
        pagination: state.pagination.copyWith(
          page: state.pagination.page + 1,
          hasMore: result.hasMore,
        ),
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false);
    }
  }

  /// 現在のフィルタで再読み込み
  Future<void> refreshImages() async {
    await loadImages(state.currentFilter);
  }

  /// 画像をローカル状態に追加
  void addImage(ImageModel image, [Prompt? prompt]) {
    final newImage = ImageWithDetails.fromImageModel(
      image,
      prompt: prompt,
    );
    state = state.copyWith(
      images: [newImage, ...state.images],
      pagination: state.pagination.copyWith(
        totalCount: state.pagination.totalCount + 1,
      ),
    );
  }

  /// 画像を更新
  void updateImage(String id, ImageModel Function(ImageModel) updater) {
    state = state.copyWith(
      images: state.images.map((img) {
        if (img.id == id) {
          final updated = updater(img);
          return ImageWithDetails.fromImageModel(
            updated,
            prompt: img.prompt,
            tags: img.tags,
            rating: img.rating,
          );
        }
        return img;
      }).toList(),
    );
  }

  /// 画像を削除
  void removeImage(String id) {
    state = state.copyWith(
      images: state.images.where((img) => img.id != id).toList(),
      pagination: state.pagination.copyWith(
        totalCount: state.pagination.totalCount - 1,
      ),
    );
  }

  /// お気に入りをトグル
  void toggleFavorite(String imageId) {
    state = state.copyWith(
      images: state.images.map((img) {
        if (img.id == imageId) {
          final newFavorite = !(img.rating?.isFavorite ?? false);
          return img.copyWith(
            rating: ImageRating(
              imageId: imageId,
              isFavorite: newFavorite,
              rating: img.rating?.rating,
            ),
          );
        }
        return img;
      }).toList(),
    );
  }

  /// タグを追加
  void addTagToImage(String imageId, Tag tag) {
    state = state.copyWith(
      images: state.images.map((img) {
        if (img.id == imageId) {
          return img.copyWith(tags: [...img.tags, tag]);
        }
        return img;
      }).toList(),
    );
  }

  /// タグを削除
  void removeTagFromImage(String imageId, String tagId) {
    state = state.copyWith(
      images: state.images.map((img) {
        if (img.id == imageId) {
          return img.copyWith(
            tags: img.tags.where((t) => t.id != tagId).toList(),
          );
        }
        return img;
      }).toList(),
    );
  }

  /// 画像をフォルダに移動
  Future<void> moveToFolder(Set<String> imageIds, String? folderId) async {
    // ローカル状態を更新
    state = state.copyWith(
      images: state.images.map((img) {
        if (imageIds.contains(img.id)) {
          return img.copyWith(folderId: folderId);
        }
        return img;
      }).toList(),
    );

    // TODO: 実際のDB操作を実装
    // for (final imageId in imageIds) {
    //   await _repository.updateImage(imageId, folderId: folderId);
    // }
  }

  /// ページネーション対応の画像取得（内部メソッド）
  Future<PaginatedImagesResult> _getImagesWithPagination(
    ImageFilter filter,
    int offset,
    int limit,
  ) async {
    // TODO: 実際のDB操作を実装
    // 暫定的に空の結果を返す
    return const PaginatedImagesResult(
      images: [],
      totalCount: 0,
      hasMore: false,
    );
  }
}

/// 画像リストのプロバイダー
final imageListProvider =
    StateNotifierProvider<ImageListNotifier, ImageListState>((ref) {
  final repository = ref.watch(imageRepositoryProvider);
  final appSettings = ref.watch(appSettingsProvider).settings;
  return ImageListNotifier(repository, showNsfw: appSettings.showNSFW);
});

/// 選択中の画像IDリスト
final selectedImageIdsProvider = StateProvider<Set<String>>((ref) => {});

/// 選択中の画像詳細表示用
final selectedImageProvider = Provider<ImageWithDetails?>((ref) {
  final selectedIds = ref.watch(selectedImageIdsProvider);
  if (selectedIds.isEmpty) return null;

  final images = ref.watch(imageListProvider).images;
  final firstId = selectedIds.first;
  return images.where((img) => img.id == firstId).firstOrNull;
});

/// 選択された画像の詳細を提供するプロバイダー
final selectedImagesProvider = Provider<List<ImageWithDetails>>((ref) {
  final selectedIds = ref.watch(selectedImageIdsProvider);
  final imageState = ref.watch(imageListProvider);
  return imageState.images.where((img) => selectedIds.contains(img.id)).toList();
});
