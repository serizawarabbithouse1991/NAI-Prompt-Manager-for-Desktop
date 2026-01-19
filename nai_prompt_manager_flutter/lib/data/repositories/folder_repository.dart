import 'package:drift/drift.dart';
import '../database/database.dart' as db;
import '../models/models.dart';

/// フォルダリポジトリ
class FolderRepository {
  final db.AppDatabase _db;

  FolderRepository(this._db);

  /// 全フォルダを取得
  Future<List<Folder>> getAllFolders() async {
    final rows = await (_db.select(_db.folders)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();

    return rows.map((row) => _mapFolder(row)).toList();
  }

  /// フォルダをID指定で取得
  Future<Folder?> getFolderById(String id) async {
    final row = await (_db.select(_db.folders)
      ..where((t) => t.id.equals(id)))
      .getSingleOrNull();

    return row != null ? _mapFolder(row) : null;
  }

  /// フォルダを作成
  Future<Folder> createFolder({
    required String id,
    required String name,
    String? parentId,
    String? color,
    int sortOrder = 0,
  }) async {
    final companion = db.FoldersCompanion.insert(
      id: id,
      name: name,
      parentId: Value(parentId),
      color: Value(color),
      sortOrder: Value(sortOrder),
    );

    await _db.into(_db.folders).insert(companion);
    
    return Folder(
      id: id,
      name: name,
      parentId: parentId,
      color: color,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );
  }

  /// フォルダを更新
  Future<void> updateFolder(String id, {
    String? name,
    String? parentId,
    String? color,
    int? sortOrder,
  }) async {
    final companion = db.FoldersCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      parentId: parentId != null ? Value(parentId) : const Value.absent(),
      color: color != null ? Value(color) : const Value.absent(),
      sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
    );

    await (_db.update(_db.folders)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// フォルダを削除
  Future<void> deleteFolder(String id) async {
    // 子フォルダの親をnullに設定
    await (_db.update(_db.folders)..where((t) => t.parentId.equals(id)))
        .write(const db.FoldersCompanion(parentId: Value(null)));
    
    // 画像のフォルダIDをnullに設定
    await (_db.update(_db.images)..where((t) => t.folderId.equals(id)))
        .write(const db.ImagesCompanion(folderId: Value(null)));
    
    // フォルダを削除
    await (_db.delete(_db.folders)..where((t) => t.id.equals(id))).go();
  }

  /// フォルダ内の画像数を取得
  Future<Map<String, int>> getImageCountByFolder() async {
    final query = _db.customSelect('''
      SELECT folder_id, COUNT(*) as count 
      FROM images 
      WHERE deleted_at IS NULL 
      GROUP BY folder_id
    ''');

    final rows = await query.get();
    final Map<String, int> result = {};

    for (final row in rows) {
      final folderId = row.read<String?>('folder_id');
      final count = row.read<int>('count');
      if (folderId != null) {
        result[folderId] = count;
      }
    }

    return result;
  }

  /// フォルダツリーを構築
  Future<List<FolderWithChildren>> buildFolderTree() async {
    final folders = await getAllFolders();
    final imageCounts = await getImageCountByFolder();

    // フォルダをparentIdでグループ化
    final Map<String?, List<Folder>> grouped = {};
    for (final folder in folders) {
      grouped.putIfAbsent(folder.parentId, () => []);
      grouped[folder.parentId]!.add(folder);
    }

    // 再帰的にツリーを構築
    List<FolderWithChildren> buildChildren(String? parentId) {
      final children = grouped[parentId] ?? [];
      return children.map((folder) {
        return FolderWithChildren.fromFolder(
          folder,
          children: buildChildren(folder.id),
          imageCount: imageCounts[folder.id] ?? 0,
        );
      }).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return buildChildren(null);
  }

  /// DriftのFolderをモデルのFolderにマッピング
  Folder _mapFolder(db.Folder data) {
    return Folder(
      id: data.id,
      parentId: data.parentId,
      name: data.name,
      color: data.color,
      sortOrder: data.sortOrder,
      createdAt: data.createdAt,
    );
  }
}
