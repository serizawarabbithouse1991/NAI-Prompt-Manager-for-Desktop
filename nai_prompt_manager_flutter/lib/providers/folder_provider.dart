import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'repository_providers.dart';

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
  final FolderRepository _repository;
  static const _uuid = Uuid();

  FolderListNotifier(this._repository) : super(const FolderListState());

  /// フォルダを読み込む
  Future<void> loadFolders() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final folders = await _repository.getAllFolders();
      final tree = await _repository.buildFolderTree();

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
      final newFolder = await _repository.createFolder(
        id: _uuid.v4(),
        name: name,
        parentId: parentId,
        color: color,
        sortOrder: state.folders.length,
      );

      state = state.copyWith(
        folders: [...state.folders, newFolder],
      );
      
      // ツリーを再構築
      final tree = await _repository.buildFolderTree();
      state = state.copyWith(folderTree: tree);

      return newFolder;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// フォルダを更新
  Future<void> updateFolder(String id, {String? name, String? color}) async {
    try {
      await _repository.updateFolder(id, name: name, color: color);
      
      state = state.copyWith(
        folders: state.folders.map((f) {
          if (f.id == id) {
            return f.copyWith(name: name, color: color);
          }
          return f;
        }).toList(),
      );
      
      final tree = await _repository.buildFolderTree();
      state = state.copyWith(folderTree: tree);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// フォルダを削除
  Future<void> deleteFolder(String id) async {
    try {
      await _repository.deleteFolder(id);
      
      final newFolders = state.folders.where((f) => f.id != id).toList();
      final tree = await _repository.buildFolderTree();
      
      state = state.copyWith(
        folders: newFolders,
        folderTree: tree,
      );

      if (state.selectedFolderId == id) {
        state = state.copyWith(selectedFolderId: null);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// フォルダリストのプロバイダー
final folderListProvider =
    StateNotifierProvider<FolderListNotifier, FolderListState>((ref) {
  final repository = ref.watch(folderRepositoryProvider);
  return FolderListNotifier(repository);
});

/// 選択中のフォルダ
final selectedFolderProvider = Provider<Folder?>((ref) {
  final state = ref.watch(folderListProvider);
  if (state.selectedFolderId == null) return null;
  return state.folders
      .where((f) => f.id == state.selectedFolderId)
      .firstOrNull;
});
