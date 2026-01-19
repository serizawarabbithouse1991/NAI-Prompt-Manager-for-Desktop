import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'repository_providers.dart';

/// タグリストの状態
class TagListState {
  final List<Tag> tags;
  final Set<String> selectedTagIds;
  final bool loading;
  final String? error;

  const TagListState({
    this.tags = const [],
    this.selectedTagIds = const {},
    this.loading = false,
    this.error,
  });

  TagListState copyWith({
    List<Tag>? tags,
    Set<String>? selectedTagIds,
    bool? loading,
    String? error,
  }) {
    return TagListState(
      tags: tags ?? this.tags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// タグリストのNotifier
class TagListNotifier extends StateNotifier<TagListState> {
  final TagRepository _repository;
  static const _uuid = Uuid();

  TagListNotifier(this._repository) : super(const TagListState());

  /// タグを読み込む
  Future<void> loadTags() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final tags = await _repository.getAllTags();

      state = state.copyWith(
        tags: tags,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        loading: false,
      );
    }
  }

  /// タグを作成
  Future<Tag?> createTag({
    required String name,
    String? color,
  }) async {
    try {
      final newTag = await _repository.createTag(
        id: _uuid.v4(),
        name: name,
        color: color,
      );

      state = state.copyWith(tags: [...state.tags, newTag]);
      return newTag;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// タグを更新
  Future<void> updateTag(String id, {String? name, String? color}) async {
    try {
      await _repository.updateTag(id, name: name, color: color);
      
      state = state.copyWith(
        tags: state.tags.map((t) {
          if (t.id == id) {
            return t.copyWith(name: name, color: color);
          }
          return t;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// タグを削除
  Future<void> deleteTag(String id) async {
    try {
      await _repository.deleteTag(id);
      
      state = state.copyWith(
        tags: state.tags.where((t) => t.id != id).toList(),
        selectedTagIds: state.selectedTagIds.difference({id}),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// タグの選択をトグル
  void toggleTagSelection(String tagId) {
    final newSelection = Set<String>.from(state.selectedTagIds);
    if (newSelection.contains(tagId)) {
      newSelection.remove(tagId);
    } else {
      newSelection.add(tagId);
    }
    state = state.copyWith(selectedTagIds: newSelection);
  }

  /// タグの選択をクリア
  void clearSelection() {
    state = state.copyWith(selectedTagIds: {});
  }

  /// 名前でタグを検索
  Tag? findTagByName(String name) {
    final normalizedName = name.trim().toLowerCase();
    return state.tags.where((t) => t.name.toLowerCase() == normalizedName).firstOrNull;
  }

  /// タグを取得または作成
  Future<Tag> getOrCreateTag(String name, {String? color}) async {
    final existing = findTagByName(name);
    if (existing != null) return existing;

    final newTag = await createTag(name: name, color: color);
    return newTag!;
  }

  /// タグを検索
  Future<List<Tag>> searchTags(String query) async {
    return _repository.searchTags(query);
  }
}

/// タグリストのプロバイダー
final tagListProvider =
    StateNotifierProvider<TagListNotifier, TagListState>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return TagListNotifier(repository);
});

/// 選択中のタグリスト
final selectedTagsProvider = Provider<List<Tag>>((ref) {
  final state = ref.watch(tagListProvider);
  return state.tags
      .where((t) => state.selectedTagIds.contains(t.id))
      .toList();
});
