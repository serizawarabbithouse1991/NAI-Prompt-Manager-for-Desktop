import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/database/database.dart' hide Folder, Tag, ImageRating, Prompt;
import 'database_provider.dart';

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
  final AppDatabase _db;

  TagListNotifier(this._db) : super(const TagListState());

  /// タグを読み込む
  Future<void> loadTags() async {
    state = state.copyWith(loading: true, error: null);

    try {
      // TODO: DBからタグを取得
      final tags = <Tag>[];

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
      // TODO: DBにタグを作成
      final newTag = Tag(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        color: color,
        createdAt: DateTime.now(),
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
      // TODO: DBのタグを更新
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
      // TODO: DBからタグを削除
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
}

/// タグリストのプロバイダー
final tagListProvider =
    StateNotifierProvider<TagListNotifier, TagListState>((ref) {
  final db = ref.watch(databaseProvider);
  return TagListNotifier(db);
});

/// 選択中のタグリスト
final selectedTagsProvider = Provider<List<Tag>>((ref) {
  final state = ref.watch(tagListProvider);
  return state.tags
      .where((t) => state.selectedTagIds.contains(t.id))
      .toList();
});
