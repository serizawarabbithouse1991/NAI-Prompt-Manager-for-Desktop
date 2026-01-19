import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/database/database.dart' hide Folder, Tag, ImageRating, Prompt;
import 'database_provider.dart';

/// フォルダリストの状態
class FolderListState {
  final List<Folder> folders;
  final List<FolderWithChildren> folderTree;
  final String? selectedFolderId;
  final bool loading;
  final String? error;

  const FolderListState({
    this.folders = const [],
    this.folderTree = const [],
    this.selectedFolderId,
    this.loading = false,
    this.error,
  });

  FolderListState copyWith({
    List<Folder>? folders,
    List<FolderWithChildren>? folderTree,
    String? selectedFolderId,
    bool? loading,
    String? error,
  }) {
    return FolderListState(
      folders: folders ?? this.folders,
      folderTree: folderTree ?? this.folderTree,
      selectedFolderId: selectedFolderId ?? this.selectedFolderId,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// フォルダリストのNotifier
class FolderListNotifier extends StateNotifier<FolderListState> {
  final AppDatabase _db;

  FolderListNotifier(this._db) : super(const FolderListState());

  /// フォルダを読み込む
  Future<void> loadFolders() async {
    state = state.copyWith(loading: true, error: null);

    try {
      // TODO: DBからフォルダを取得
      final folders = <Folder>[];
      final tree = _buildFolderTree(folders);

      state = state.copyWith(
        folders: folders,
        folderTree: tree,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        loading: false,
      );
    }
  }

  /// フォルダを選択
  void selectFolder(String? folderId) {
    state = state.copyWith(selectedFolderId: folderId);
  }

  /// フォルダを作成
  Future<Folder?> createFolder({
    required String name,
    String? parentId,
    String? color,
  }) async {
    try {
      // TODO: DBにフォルダを作成
      final newFolder = Folder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        name: name,
        color: color,
        sortOrder: state.folders.length,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        folders: [...state.folders, newFolder],
        folderTree: _buildFolderTree([...state.folders, newFolder]),
      );

      return newFolder;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// フォルダを更新
  Future<void> updateFolder(String id, {String? name, String? color}) async {
    try {
      // TODO: DBのフォルダを更新
      state = state.copyWith(
        folders: state.folders.map((f) {
          if (f.id == id) {
            return f.copyWith(name: name, color: color);
          }
          return f;
        }).toList(),
      );
      state = state.copyWith(folderTree: _buildFolderTree(state.folders));
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// フォルダを削除
  Future<void> deleteFolder(String id) async {
    try {
      // TODO: DBからフォルダを削除
      final newFolders = state.folders.where((f) => f.id != id).toList();
      state = state.copyWith(
        folders: newFolders,
        folderTree: _buildFolderTree(newFolders),
      );

      if (state.selectedFolderId == id) {
        state = state.copyWith(selectedFolderId: null);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// フラットなフォルダリストからツリー構造を構築
  List<FolderWithChildren> _buildFolderTree(List<Folder> folders) {
    final Map<String?, List<Folder>> grouped = {};
    for (final folder in folders) {
      grouped.putIfAbsent(folder.parentId, () => []);
      grouped[folder.parentId]!.add(folder);
    }

    List<FolderWithChildren> buildChildren(String? parentId) {
      final children = grouped[parentId] ?? [];
      return children.map((folder) {
        return FolderWithChildren.fromFolder(
          folder,
          children: buildChildren(folder.id),
        );
      }).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return buildChildren(null);
  }
}

/// フォルダリストのプロバイダー
final folderListProvider =
    StateNotifierProvider<FolderListNotifier, FolderListState>((ref) {
  final db = ref.watch(databaseProvider);
  return FolderListNotifier(db);
});

/// 選択中のフォルダ
final selectedFolderProvider = Provider<Folder?>((ref) {
  final state = ref.watch(folderListProvider);
  if (state.selectedFolderId == null) return null;
  return state.folders
      .where((f) => f.id == state.selectedFolderId)
      .firstOrNull;
});
