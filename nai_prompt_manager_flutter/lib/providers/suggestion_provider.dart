import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../data/repositories/suggestion_repository.dart';
import '../data/services/danbooru_tag_service.dart';
import '../services/suggestion_service.dart';
import 'database_provider.dart';
import 'danbooru_provider.dart';

/// 提案の表示モード
enum SuggestionViewMode {
  tags,
  combinations,
}

/// カテゴリフィルタ
enum SuggestionCategoryFilter {
  all,
  artist,
  character,
  copyright,
  general,
  meta,
}

extension SuggestionCategoryFilterExtension on SuggestionCategoryFilter {
  String get displayName {
    switch (this) {
      case SuggestionCategoryFilter.all:
        return '全て';
      case SuggestionCategoryFilter.artist:
        return 'アーティスト';
      case SuggestionCategoryFilter.character:
        return 'キャラクター';
      case SuggestionCategoryFilter.copyright:
        return '作品';
      case SuggestionCategoryFilter.general:
        return '一般';
      case SuggestionCategoryFilter.meta:
        return 'メタ';
    }
  }

  DanbooruTagCategory? toDanbooruCategory() {
    switch (this) {
      case SuggestionCategoryFilter.all:
        return null;
      case SuggestionCategoryFilter.artist:
        return DanbooruTagCategory.artist;
      case SuggestionCategoryFilter.character:
        return DanbooruTagCategory.character;
      case SuggestionCategoryFilter.copyright:
        return DanbooruTagCategory.copyright;
      case SuggestionCategoryFilter.general:
        return DanbooruTagCategory.general;
      case SuggestionCategoryFilter.meta:
        return DanbooruTagCategory.meta;
    }
  }
}

/// 提案状態
class SuggestionState {
  final bool loading;
  final bool initialized;
  final String? error;
  final SuggestionViewMode viewMode;
  final SuggestionCategoryFilter categoryFilter;
  final UserUsageAnalysis? userAnalysis;
  final List<SuggestedTag> tagSuggestions;
  final List<SuggestedCombination> combinationSuggestions;
  final List<SuggestedTag> randomDiscovery;
  final bool danbooruAvailable;

  const SuggestionState({
    this.loading = false,
    this.initialized = false,
    this.error,
    this.viewMode = SuggestionViewMode.tags,
    this.categoryFilter = SuggestionCategoryFilter.all,
    this.userAnalysis,
    this.tagSuggestions = const [],
    this.combinationSuggestions = const [],
    this.randomDiscovery = const [],
    this.danbooruAvailable = false,
  });

  SuggestionState copyWith({
    bool? loading,
    bool? initialized,
    String? error,
    SuggestionViewMode? viewMode,
    SuggestionCategoryFilter? categoryFilter,
    UserUsageAnalysis? userAnalysis,
    List<SuggestedTag>? tagSuggestions,
    List<SuggestedCombination>? combinationSuggestions,
    List<SuggestedTag>? randomDiscovery,
    bool? danbooruAvailable,
  }) {
    return SuggestionState(
      loading: loading ?? this.loading,
      initialized: initialized ?? this.initialized,
      error: error,
      viewMode: viewMode ?? this.viewMode,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      userAnalysis: userAnalysis ?? this.userAnalysis,
      tagSuggestions: tagSuggestions ?? this.tagSuggestions,
      combinationSuggestions: combinationSuggestions ?? this.combinationSuggestions,
      randomDiscovery: randomDiscovery ?? this.randomDiscovery,
      danbooruAvailable: danbooruAvailable ?? this.danbooruAvailable,
    );
  }

  /// フィルタ適用後のタグ提案
  List<SuggestedTag> get filteredTagSuggestions {
    if (categoryFilter == SuggestionCategoryFilter.all) {
      return tagSuggestions;
    }
    final targetCategory = categoryFilter.toDanbooruCategory();
    return tagSuggestions.where((t) => t.category == targetCategory).toList();
  }
}

/// 提案プロバイダー
class SuggestionNotifier extends StateNotifier<SuggestionState> {
  final SuggestionRepository _repository;
  final SuggestionService _service;

  SuggestionNotifier(this._repository, this._service) : super(const SuggestionState());

  /// 初期化
  Future<void> initialize() async {
    if (state.initialized) return;

    state = state.copyWith(loading: true);

    try {
      final danbooruAvailable = await _service.initialize();

      // ユーザーの使用履歴を分析
      final userAnalysis = await _repository.analyzeUserUsage();

      // タグ提案を生成
      List<SuggestedTag> tagSuggestions = [];
      List<SuggestedCombination> combinationSuggestions = [];
      List<SuggestedTag> randomDiscovery = [];

      if (danbooruAvailable) {
        tagSuggestions = await _service.suggestUnusedTags(
          userAnalysis: userAnalysis,
          limit: 100,
        );

        combinationSuggestions = await _service.suggestCombinations(
          userAnalysis: userAnalysis,
          limit: 10,
        );

        randomDiscovery = await _service.suggestRandomDiscovery(
          userAnalysis: userAnalysis,
          limit: 10,
        );
      }

      state = state.copyWith(
        loading: false,
        initialized: true,
        danbooruAvailable: danbooruAvailable,
        userAnalysis: userAnalysis,
        tagSuggestions: tagSuggestions,
        combinationSuggestions: combinationSuggestions,
        randomDiscovery: randomDiscovery,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        initialized: true,
        error: e.toString(),
      );
    }
  }

  /// 提案を再読み込み
  Future<void> refresh() async {
    state = state.copyWith(loading: true, initialized: false);
    await initialize();
  }

  /// 表示モードを変更
  void setViewMode(SuggestionViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// カテゴリフィルタを変更
  void setCategoryFilter(SuggestionCategoryFilter filter) {
    state = state.copyWith(categoryFilter: filter);
  }

  /// ランダム発見を再シャッフル
  Future<void> shuffleRandomDiscovery() async {
    if (!state.danbooruAvailable || state.userAnalysis == null) return;

    final newDiscovery = await _service.suggestRandomDiscovery(
      userAnalysis: state.userAnalysis!,
      limit: 10,
    );

    state = state.copyWith(randomDiscovery: newDiscovery);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// SuggestionRepositoryのプロバイダー
final suggestionRepositoryProvider = Provider<SuggestionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final danbooruState = ref.watch(danbooruServiceProvider);
  return SuggestionRepository(db, danbooruState.service);
});

/// SuggestionServiceのプロバイダー
final suggestionServiceProvider = Provider<SuggestionService>((ref) {
  // Danbooruデータベースのパスを探索
  final possiblePaths = [
    'danbooru2023.db',
    p.join(Directory.current.path, 'danbooru2023.db'),
    p.join(Directory.current.parent.path, 'danbooru2023.db'),
    r'c:\Users\rt032\001-WEBDEV\NAI Prompt Manager\danbooru2023.db',
  ];

  String? foundPath;
  for (final path in possiblePaths) {
    final file = File(path);
    if (file.existsSync()) {
      foundPath = path;
      break;
    }
  }

  return SuggestionService(danbooruDbPath: foundPath);
});

/// 提案状態のプロバイダー
final suggestionProvider =
    StateNotifierProvider<SuggestionNotifier, SuggestionState>((ref) {
  final repository = ref.watch(suggestionRepositoryProvider);
  final service = ref.watch(suggestionServiceProvider);
  return SuggestionNotifier(repository, service);
});
