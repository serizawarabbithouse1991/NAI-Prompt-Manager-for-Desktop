import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

/// Danbooruタグのカテゴリ
enum DanbooruTagCategory {
  general(0, 'General', 0xFF6B7280),    // Gray
  artist(1, 'Artist', 0xFFEF4444),       // Red
  copyright(2, 'Copyright', 0xFF8B5CF6), // Purple
  character(3, 'Character', 0xFF22C55E), // Green
  meta(4, 'Meta', 0xFFF59E0B),           // Yellow
  unknown(-1, 'Unknown', 0xFF9CA3AF);    // Gray

  final int typeId;
  final String displayName;
  final int colorValue;

  const DanbooruTagCategory(this.typeId, this.displayName, this.colorValue);

  static DanbooruTagCategory fromTypeId(int? typeId) {
    return DanbooruTagCategory.values.firstWhere(
      (e) => e.typeId == typeId,
      orElse: () => DanbooruTagCategory.unknown,
    );
  }
}

/// Danbooruタグ情報
class DanbooruTag {
  final int id;
  final String name;
  final DanbooruTagCategory category;
  final int popularity;

  const DanbooruTag({
    required this.id,
    required this.name,
    required this.category,
    required this.popularity,
  });

  /// プロンプトで使用される形式（スペース区切り）に変換
  String get promptName => name.replaceAll('_', ' ');
}

/// 分類済みプロンプト
class CategorizedPrompt {
  final List<PromptToken> artists;
  final List<PromptToken> characters;
  final List<PromptToken> copyrights;
  final List<PromptToken> generals;
  final List<PromptToken> metas;
  final List<PromptToken> unknowns;

  const CategorizedPrompt({
    this.artists = const [],
    this.characters = const [],
    this.copyrights = const [],
    this.generals = const [],
    this.metas = const [],
    this.unknowns = const [],
  });

  /// 全てのトークンを取得
  List<PromptToken> get allTokens => [
    ...artists,
    ...characters,
    ...copyrights,
    ...generals,
    ...metas,
    ...unknowns,
  ];

  /// カテゴリ別にソートされたトークンを取得
  Map<DanbooruTagCategory, List<PromptToken>> get byCategory => {
    DanbooruTagCategory.artist: artists,
    DanbooruTagCategory.character: characters,
    DanbooruTagCategory.copyright: copyrights,
    DanbooruTagCategory.general: generals,
    DanbooruTagCategory.meta: metas,
    DanbooruTagCategory.unknown: unknowns,
  };

  /// 空かどうか
  bool get isEmpty => allTokens.isEmpty;
}

/// プロンプトトークン
class PromptToken {
  final String originalText;
  final DanbooruTag? matchedTag;
  final DanbooruTagCategory category;

  const PromptToken({
    required this.originalText,
    this.matchedTag,
    required this.category,
  });

  /// タグがマッチしたかどうか
  bool get isMatched => matchedTag != null;
}

/// Danbooruタグサービス
class DanbooruTagService {
  Database? _database;
  final String dbPath;
  Map<String, DanbooruTag>? _tagCache;
  bool _initialized = false;

  DanbooruTagService({required this.dbPath});

  /// データベースを初期化
  Future<void> initialize() async {
    if (_initialized) return;

    final file = File(dbPath);
    if (!await file.exists()) {
      throw Exception('Danbooru database not found at: $dbPath');
    }

    _database = sqlite3.open(dbPath, mode: OpenMode.readOnly);
    _initialized = true;
  }

  /// データベースが利用可能かどうか
  bool get isAvailable => _initialized && _database != null;

  /// タグを名前で検索
  DanbooruTag? findTag(String name) {
    if (!isAvailable) return null;

    // プロンプト形式（スペース区切り）をDB形式（アンダースコア区切り）に変換
    final normalizedName = name.trim().toLowerCase().replaceAll(' ', '_');
    
    // 括弧や特殊記号を除去（例: "{tag}" -> "tag"）
    final cleanName = normalizedName
        .replaceAll(RegExp(r'[{}()\[\]<>]'), '')
        .replaceAll(RegExp(r'^[:\d.]+'), '') // 先頭の重み指定を除去
        .trim();

    if (cleanName.isEmpty) return null;

    try {
      final result = _database!.select(
        'SELECT id, name, type, popularity FROM tag WHERE name = ? LIMIT 1',
        [cleanName],
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return DanbooruTag(
          id: row['id'] as int,
          name: row['name'] as String,
          category: DanbooruTagCategory.fromTypeId(row['type'] as int?),
          popularity: row['popularity'] as int? ?? 0,
        );
      }
    } catch (e) {
      // エラーを無視
    }

    return null;
  }

  /// プロンプトを解析してカテゴリ別に分類
  CategorizedPrompt analyzePrompt(String? prompt) {
    if (prompt == null || prompt.isEmpty) {
      return const CategorizedPrompt();
    }

    // ","で分割
    final tokens = prompt.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    final artists = <PromptToken>[];
    final characters = <PromptToken>[];
    final copyrights = <PromptToken>[];
    final generals = <PromptToken>[];
    final metas = <PromptToken>[];
    final unknowns = <PromptToken>[];

    for (final tokenText in tokens) {
      final tag = findTag(tokenText);
      final category = tag?.category ?? DanbooruTagCategory.unknown;

      final token = PromptToken(
        originalText: tokenText,
        matchedTag: tag,
        category: category,
      );

      switch (category) {
        case DanbooruTagCategory.artist:
          artists.add(token);
          break;
        case DanbooruTagCategory.character:
          characters.add(token);
          break;
        case DanbooruTagCategory.copyright:
          copyrights.add(token);
          break;
        case DanbooruTagCategory.general:
          generals.add(token);
          break;
        case DanbooruTagCategory.meta:
          metas.add(token);
          break;
        case DanbooruTagCategory.unknown:
          unknowns.add(token);
          break;
      }
    }

    return CategorizedPrompt(
      artists: artists,
      characters: characters,
      copyrights: copyrights,
      generals: generals,
      metas: metas,
      unknowns: unknowns,
    );
  }

  /// データベースを閉じる
  void dispose() {
    _database?.dispose();
    _database = null;
    _initialized = false;
  }
}
