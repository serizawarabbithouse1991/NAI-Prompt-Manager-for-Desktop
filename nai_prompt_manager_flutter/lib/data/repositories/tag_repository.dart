import 'package:drift/drift.dart';
import '../database/database.dart' as db;
import '../models/models.dart';

/// タグリポジトリ
class TagRepository {
  final db.AppDatabase _db;

  TagRepository(this._db);

  /// 全タグを取得
  Future<List<Tag>> getAllTags() async {
    final rows = await (_db.select(_db.tags)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .get();

    return rows.map((row) => _mapTag(row)).toList();
  }

  /// タグをID指定で取得
  Future<Tag?> getTagById(String id) async {
    final row = await (_db.select(_db.tags)
      ..where((t) => t.id.equals(id)))
      .getSingleOrNull();

    return row != null ? _mapTag(row) : null;
  }

  /// タグを名前で検索
  Future<Tag?> getTagByName(String name) async {
    final row = await (_db.select(_db.tags)
      ..where((t) => t.name.equals(name.toLowerCase())))
      .getSingleOrNull();

    return row != null ? _mapTag(row) : null;
  }

  /// タグを作成
  Future<Tag> createTag({
    required String id,
    required String name,
    String? color,
  }) async {
    final companion = db.TagsCompanion.insert(
      id: id,
      name: name.toLowerCase(),
      color: Value(color),
    );

    await _db.into(_db.tags).insert(companion);
    
    return Tag(
      id: id,
      name: name.toLowerCase(),
      color: color,
      createdAt: DateTime.now(),
    );
  }

  /// タグを取得または作成
  Future<Tag> getOrCreateTag({
    required String id,
    required String name,
    String? color,
  }) async {
    final existing = await getTagByName(name);
    if (existing != null) return existing;
    return createTag(id: id, name: name, color: color);
  }

  /// タグを更新
  Future<void> updateTag(String id, {
    String? name,
    String? color,
  }) async {
    final companion = db.TagsCompanion(
      name: name != null ? Value(name.toLowerCase()) : const Value.absent(),
      color: color != null ? Value(color) : const Value.absent(),
    );

    await (_db.update(_db.tags)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// タグを削除
  Future<void> deleteTag(String id) async {
    // 関連するimage_tagsも自動削除される（CASCADE）
    await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
  }

  /// タグの使用数を取得
  Future<Map<String, int>> getTagUsageCounts() async {
    final query = _db.customSelect('''
      SELECT tag_id, COUNT(*) as count 
      FROM image_tags 
      INNER JOIN images ON images.id = image_tags.image_id
      WHERE images.deleted_at IS NULL
      GROUP BY tag_id
    ''');

    final rows = await query.get();
    final Map<String, int> result = {};

    for (final row in rows) {
      final tagId = row.read<String>('tag_id');
      final count = row.read<int>('count');
      result[tagId] = count;
    }

    return result;
  }

  /// 画像のタグを取得
  Future<List<Tag>> getTagsForImage(String imageId) async {
    final query = _db.select(_db.imageTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.imageTags.tagId)),
    ])..where(_db.imageTags.imageId.equals(imageId));

    final rows = await query.get();
    return rows.map((row) => _mapTag(row.readTable(_db.tags))).toList();
  }

  /// 名前で部分一致検索
  Future<List<Tag>> searchTags(String query) async {
    final rows = await (_db.select(_db.tags)
      ..where((t) => t.name.like('%${query.toLowerCase()}%'))
      ..limit(20))
      .get();

    return rows.map((row) => _mapTag(row)).toList();
  }

  /// DriftのTagをモデルのTagにマッピング
  Tag _mapTag(db.Tag data) {
    return Tag(
      id: data.id,
      name: data.name,
      color: data.color,
      createdAt: data.createdAt,
    );
  }
}
