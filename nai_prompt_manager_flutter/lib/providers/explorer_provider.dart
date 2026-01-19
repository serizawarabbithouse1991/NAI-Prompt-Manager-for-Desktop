import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';

/// エクスプローラーパネルの状態
class ExplorerState {
  final String? selectedFolderId;
  final bool showUncategorized;
  final bool showFavoritesOnly;
  final Set<String> expandedFolderIds;
  final List<SavedSearch> savedSearches;
  final List<String> recentFolderIds;

  const ExplorerState({
    this.selectedFolderId,
    this.showUncategorized = false,
    this.showFavoritesOnly = false,
    this.expandedFolderIds = const {},
    this.savedSearches = const [],
    this.recentFolderIds = const [],
  });

  ExplorerState copyWith({
    String? selectedFolderId,
    bool? showUncategorized,
    bool? showFavoritesOnly,
    Set<String>? expandedFolderIds,
    List<SavedSearch>? savedSearches,
    List<String>? recentFolderIds,
    bool clearFolderId = false,
  }) {
    return ExplorerState(
      selectedFolderId: clearFolderId ? null : (selectedFolderId ?? this.selectedFolderId),
      showUncategorized: showUncategorized ?? this.showUncategorized,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      expandedFolderIds: expandedFolderIds ?? this.expandedFolderIds,
      savedSearches: savedSearches ?? this.savedSearches,
      recentFolderIds: recentFolderIds ?? this.recentFolderIds,
    );
  }
}

/// エクスプローラーのNotifier
class ExplorerNotifier extends StateNotifier<ExplorerState> {
  ExplorerNotifier() : super(const ExplorerState());

  /// フォルダを選択
  void selectFolder(String? folderId) {
    state = state.copyWith(
      selectedFolderId: folderId,
      showUncategorized: false,
      showFavoritesOnly: false,
      clearFolderId: folderId == null,
    );
    
    if (folderId != null) {
      _addToRecent(folderId);
    }
  }

  /// 未分類を選択
  void selectUncategorized() {
    state = state.copyWith(
      showUncategorized: true,
      showFavoritesOnly: false,
      clearFolderId: true,
    );
  }

  /// お気に入りを選択
  void selectFavorites() {
    state = state.copyWith(
      showFavoritesOnly: true,
      showUncategorized: false,
      clearFolderId: true,
    );
  }

  /// すべての画像を選択
  void selectAll() {
    state = state.copyWith(
      showUncategorized: false,
      showFavoritesOnly: false,
      clearFolderId: true,
    );
  }

  /// フォルダの展開をトグル
  void toggleFolderExpanded(String folderId) {
    final newExpanded = Set<String>.from(state.expandedFolderIds);
    if (newExpanded.contains(folderId)) {
      newExpanded.remove(folderId);
    } else {
      newExpanded.add(folderId);
    }
    state = state.copyWith(expandedFolderIds: newExpanded);
  }

  /// 検索を保存
  void saveSearch(SavedSearch search) {
    state = state.copyWith(
      savedSearches: [...state.savedSearches, search],
    );
  }

  /// 保存済み検索を削除
  void deleteSavedSearch(String id) {
    state = state.copyWith(
      savedSearches: state.savedSearches.where((s) => s.id != id).toList(),
    );
  }

  /// 最近のフォルダに追加
  void _addToRecent(String folderId) {
    final recent = state.recentFolderIds.where((id) => id != folderId).toList();
    recent.insert(0, folderId);
    // 最大10件
    if (recent.length > 10) {
      recent.removeLast();
    }
    state = state.copyWith(recentFolderIds: recent);
  }

  /// 最近の履歴をクリア
  void clearRecent() {
    state = state.copyWith(recentFolderIds: []);
  }
}

/// エクスプローラーのプロバイダー
final explorerProvider =
    StateNotifierProvider<ExplorerNotifier, ExplorerState>((ref) {
  return ExplorerNotifier();
});

/// 現在の画像フィルタ（エクスプローラー状態から派生）
final currentImageFilterProvider = Provider<ImageFilter>((ref) {
  final explorer = ref.watch(explorerProvider);
  
  return ImageFilter(
    folderId: explorer.selectedFolderId,
    uncategorizedOnly: explorer.showUncategorized,
    sortBy: SortBy.date,
    sortOrder: SortOrder.desc,
  );
});
