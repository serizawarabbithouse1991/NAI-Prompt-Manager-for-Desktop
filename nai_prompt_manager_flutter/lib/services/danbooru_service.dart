import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

/// Danbooruタグタイプ
enum DanbooruTagType {
  general(0),
  artist(1),
  copyright(3),
  character(4),
  meta(5);

  final int value;
  const DanbooruTagType(this.value);

  static DanbooruTagType fromValue(int value) {
    return DanbooruTagType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => DanbooruTagType.general,
    );
  }

  String get displayName {
    switch (this) {
      case DanbooruTagType.general:
        return '一般';
      case DanbooruTagType.artist:
        return 'アーティスト';
      case DanbooruTagType.copyright:
        return '作品';
      case DanbooruTagType.character:
        return 'キャラクター';
      case DanbooruTagType.meta:
        return 'メタ';
    }
  }
}

/// Danbooruタグ
class DanbooruTag {
  final int id;
  final String name;
  final DanbooruTagType type;
  final int popularity;

  const DanbooruTag({
    required this.id,
    required this.name,
    required this.type,
    required this.popularity,
  });

  @override
  String toString() => 'DanbooruTag($name, ${type.displayName})';
}

/// Danbooru投稿情報
class DanbooruPost {
  final int id;
  final String? md5;
  final int rating;
  final int score;
  final int width;
  final int height;
  final List<DanbooruTag> tags;

  const DanbooruPost({
    required this.id,
    required this.md5,
    required this.rating,
    required this.score,
    required this.width,
    required this.height,
    required this.tags,
  });

  String get ratingText {
    switch (rating) {
      case 0:
        return 'g'; // general
      case 1:
        return 's'; // sensitive
      case 2:
        return 'q'; // questionable
      case 3:
        return 'e'; // explicit
      default:
        return 'unknown';
    }
  }
}

/// Danbooruデータベースサービス
class DanbooruService {
  Database? _db;
  String? _dbPath;

  /// シングルトンインスタンス
  static final DanbooruService _instance = DanbooruService._internal();
  factory DanbooruService() => _instance;
  DanbooruService._internal();

  /// DBが設定されているか
  bool get isConfigured => _dbPath != null && _db != null;

  /// 現在のDBパス
  String? get dbPath => _dbPath;

  /// Danbooru DBを開く
  Future<bool> openDatabase(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return false;
      }

      // 既存の接続を閉じる
      close();

      _db = sqlite3.open(path, mode: OpenMode.readOnly);
      _dbPath = path;

      // テーブル存在確認
      final result = _db!.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('post', 'tag', 'posttagrelation')"
      );
      if (result.length < 3) {
        close();
        return false;
      }

      return true;
    } catch (e) {
      close();
      return false;
    }
  }

  /// DBを閉じる
  void close() {
    _db?.dispose();
    _db = null;
    _dbPath = null;
  }

  /// MD5ハッシュで投稿を検索
  Future<DanbooruPost?> findPostByMd5(String md5) async {
    if (_db == null) return null;

    try {
      final result = _db!.select(
        'SELECT id, md5, rating, score, image_width, image_height FROM post WHERE md5 = ?',
        [md5],
      );

      if (result.isEmpty) return null;

      final row = result.first;
      final postId = row['id'] as int;

      // タグを取得
      final tags = await _getTagsForPost(postId);

      return DanbooruPost(
        id: postId,
        md5: row['md5'] as String?,
        rating: row['rating'] as int,
        score: row['score'] as int,
        width: row['image_width'] as int,
        height: row['image_height'] as int,
        tags: tags,
      );
    } catch (e) {
      return null;
    }
  }

  /// 投稿のタグを取得
  Future<List<DanbooruTag>> _getTagsForPost(int postId) async {
    if (_db == null) return [];

    try {
      final result = _db!.select('''
        SELECT t.id, t.name, t.type, t.popularity
        FROM tag t
        JOIN posttagrelation ptr ON t.id = ptr.tag_id
        WHERE ptr.post_id = ?
        ORDER BY t.popularity DESC
      ''', [postId]);

      return result.map((row) => DanbooruTag(
        id: row['id'] as int,
        name: row['name'] as String,
        type: DanbooruTagType.fromValue(row['type'] as int),
        popularity: row['popularity'] as int,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// MD5からタグを直接取得（簡易版）
  Future<List<DanbooruTag>> getTagsByMd5(String md5) async {
    final post = await findPostByMd5(md5);
    return post?.tags ?? [];
  }

  /// タグをフィルタリング（タイプ別）
  List<DanbooruTag> filterTagsByType(
    List<DanbooruTag> tags,
    Set<DanbooruTagType> types,
  ) {
    return tags.where((t) => types.contains(t.type)).toList();
  }

  /// 人気タグを取得（上位N件）
  List<DanbooruTag> getTopTags(List<DanbooruTag> tags, {int limit = 50}) {
    final sorted = List<DanbooruTag>.from(tags)
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    return sorted.take(limit).toList();
  }

  /// DB統計を取得
  Future<DanbooruDbStats?> getStats() async {
    if (_db == null) return null;

    try {
      final postCount = _db!.select('SELECT COUNT(*) as count FROM post').first['count'] as int;
      final tagCount = _db!.select('SELECT COUNT(*) as count FROM tag').first['count'] as int;

      return DanbooruDbStats(
        postCount: postCount,
        tagCount: tagCount,
        dbPath: _dbPath!,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Danbooru DB統計
class DanbooruDbStats {
  final int postCount;
  final int tagCount;
  final String dbPath;

  const DanbooruDbStats({
    required this.postCount,
    required this.tagCount,
    required this.dbPath,
  });

  String get postCountFormatted {
    if (postCount >= 1000000) {
      return '${(postCount / 1000000).toStringAsFixed(1)}M';
    }
    if (postCount >= 1000) {
      return '${(postCount / 1000).toStringAsFixed(1)}K';
    }
    return postCount.toString();
  }

  String get tagCountFormatted {
    if (tagCount >= 1000000) {
      return '${(tagCount / 1000000).toStringAsFixed(1)}M';
    }
    if (tagCount >= 1000) {
      return '${(tagCount / 1000).toStringAsFixed(1)}K';
    }
    return tagCount.toString();
  }
}
