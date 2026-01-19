import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:sqlite3/sqlite3.dart';

import '../data/services/danbooru_tag_service.dart';
import '../data/repositories/suggestion_repository.dart';

// #region debug log
void _debugLog(String location, String message, Map<String, dynamic> data) {
  try {
    final logFile = File(r'c:\Users\rt032\001-WEBDEV\NAI Prompt Manager\.cursor\debug.log');
    final logEntry = jsonEncode({
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    logFile.writeAsStringSync('$logEntry\n', mode: FileMode.append);
  } catch (_) {}
}
// #endregion

/// 提案タグ
class SuggestedTag {
  final String name;
  final String displayName;
  final DanbooruTagCategory category;
  final int popularity;
  final String? reason;

  const SuggestedTag({
    required this.name,
    required this.displayName,
    required this.category,
    required this.popularity,
    this.reason,
  });
}

/// タグ組み合わせ提案
class SuggestedCombination {
  final List<SuggestedTag> tags;
  final String description;
  final String combinationType;

  const SuggestedCombination({
    required this.tags,
    required this.description,
    required this.combinationType,
  });

  /// プロンプト形式で出力
  String toPromptString() {
    return tags.map((t) => t.displayName).join(', ');
  }
}

/// 提案結果
class SuggestionResult {
  final List<SuggestedTag> tagSuggestions;
  final List<SuggestedCombination> combinationSuggestions;
  final bool danbooruAvailable;
  final String? message;

  const SuggestionResult({
    required this.tagSuggestions,
    required this.combinationSuggestions,
    required this.danbooruAvailable,
    this.message,
  });
}

/// プロンプト提案サービス
class SuggestionService {
  final String? _danbooruDbPath;
  Database? _danbooruDb;
  bool _initialized = false;

  SuggestionService({String? danbooruDbPath}) : _danbooruDbPath = danbooruDbPath;

  /// 初期化
  Future<bool> initialize() async {
    _debugLog('SuggestionService.initialize', 'Starting initialization', {
      'alreadyInitialized': _initialized,
      'dbPath': _danbooruDbPath,
    });

    if (_initialized) {
      _debugLog('SuggestionService.initialize', 'Already initialized', {
        'dbAvailable': _danbooruDb != null,
      });
      return _danbooruDb != null;
    }

    final dbPath = _danbooruDbPath;
    if (dbPath == null) {
      _debugLog('SuggestionService.initialize', 'DB path is null', {});
      _initialized = true;
      return false;
    }

    final file = File(dbPath);
    final exists = await file.exists();
    _debugLog('SuggestionService.initialize', 'Checking DB file', {
      'path': dbPath,
      'exists': exists,
    });

    if (!exists) {
      _initialized = true;
      return false;
    }

    try {
      _danbooruDb = sqlite3.open(dbPath, mode: OpenMode.readOnly);
      _initialized = true;
      
      // DBの確認クエリを実行
      final testResult = _danbooruDb!.select('SELECT COUNT(*) as cnt FROM tag LIMIT 1');
      final tagCount = testResult.isNotEmpty ? testResult.first['cnt'] : 0;
      
      _debugLog('SuggestionService.initialize', 'DB opened successfully', {
        'path': dbPath,
        'tagCount': tagCount,
      });
      return true;
    } catch (e) {
      _debugLog('SuggestionService.initialize', 'Failed to open DB', {
        'error': e.toString(),
      });
      _initialized = true;
      return false;
    }
  }

  /// Danbooruが利用可能かどうか
  bool get isDanbooruAvailable => _danbooruDb != null;

  /// 人気タグを取得（カテゴリ指定可能）
  Future<List<SuggestedTag>> getPopularTags({
    DanbooruTagCategory? category,
    int limit = 100,
    int minPopularity = 1000,
  }) async {
    if (_danbooruDb == null) {
      _debugLog('SuggestionService.getPopularTags', 'DB not available', {});
      return [];
    }

    try {
      String sql;
      List<Object?> params;

      if (category != null && category != DanbooruTagCategory.unknown) {
        sql = '''
          SELECT id, name, type, popularity 
          FROM tag 
          WHERE type = ? AND popularity >= ?
          ORDER BY popularity DESC 
          LIMIT ?
        ''';
        params = [category.typeId, minPopularity, limit];
      } else {
        sql = '''
          SELECT id, name, type, popularity 
          FROM tag 
          WHERE popularity >= ?
          ORDER BY popularity DESC 
          LIMIT ?
        ''';
        params = [minPopularity, limit];
      }

      final result = _danbooruDb!.select(sql, params);
      
      _debugLog('SuggestionService.getPopularTags', 'Query executed', {
        'category': category?.displayName,
        'minPopularity': minPopularity,
        'limit': limit,
        'resultCount': result.length,
      });

      return result.map((row) {
        final name = row['name'] as String;
        final type = row['type'] as int?;
        final popularity = row['popularity'] as int? ?? 0;

        return SuggestedTag(
          name: name,
          displayName: name.replaceAll('_', ' '),
          category: DanbooruTagCategory.fromTypeId(type),
          popularity: popularity,
        );
      }).toList();
    } catch (e) {
      _debugLog('SuggestionService.getPopularTags', 'Query failed', {
        'error': e.toString(),
      });
      return [];
    }
  }

  /// 未使用の人気タグを提案
  Future<List<SuggestedTag>> suggestUnusedTags({
    required UserUsageAnalysis userAnalysis,
    DanbooruTagCategory? category,
    int limit = 50,
  }) async {
    final popularTags = await getPopularTags(
      category: category,
      limit: limit * 3, // 多めに取得してフィルタリング
    );

    // 使用済みタグを除外
    final unusedTags = popularTags
        .where((tag) => !userAnalysis.hasUsedTag(tag.name))
        .take(limit)
        .map((tag) => SuggestedTag(
              name: tag.name,
              displayName: tag.displayName,
              category: tag.category,
              popularity: tag.popularity,
              reason: '人気タグ（${_formatPopularity(tag.popularity)}件）',
            ))
        .toList();

    return unusedTags;
  }

  /// カテゴリ別に未使用タグを提案
  Future<Map<DanbooruTagCategory, List<SuggestedTag>>> suggestUnusedTagsByCategory({
    required UserUsageAnalysis userAnalysis,
    int limitPerCategory = 20,
  }) async {
    final result = <DanbooruTagCategory, List<SuggestedTag>>{};

    for (final category in [
      DanbooruTagCategory.artist,
      DanbooruTagCategory.character,
      DanbooruTagCategory.copyright,
      DanbooruTagCategory.general,
      DanbooruTagCategory.meta,
    ]) {
      final suggestions = await suggestUnusedTags(
        userAnalysis: userAnalysis,
        category: category,
        limit: limitPerCategory,
      );
      if (suggestions.isNotEmpty) {
        result[category] = suggestions;
      }
    }

    return result;
  }

  /// タグの組み合わせを提案
  Future<List<SuggestedCombination>> suggestCombinations({
    required UserUsageAnalysis userAnalysis,
    int limit = 10,
  }) async {
    final combinations = <SuggestedCombination>[];

    // 1. ユーザーのよく使うタグ + 未使用の人気タグ
    final userTopTags = userAnalysis.tagStats.values.toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    final topUserTags = userTopTags.take(5).toList();

    final unusedGeneral = await suggestUnusedTags(
      userAnalysis: userAnalysis,
      category: DanbooruTagCategory.general,
      limit: 20,
    );

    final unusedCharacter = await suggestUnusedTags(
      userAnalysis: userAnalysis,
      category: DanbooruTagCategory.character,
      limit: 10,
    );

    final unusedArtist = await suggestUnusedTags(
      userAnalysis: userAnalysis,
      category: DanbooruTagCategory.artist,
      limit: 10,
    );

    final random = Random();

    // よく使うタグ + 未使用キャラクター
    if (topUserTags.isNotEmpty && unusedCharacter.isNotEmpty) {
      for (var i = 0; i < min(3, unusedCharacter.length); i++) {
        final character = unusedCharacter[i];
        final userTag = topUserTags[random.nextInt(topUserTags.length)];

        combinations.add(SuggestedCombination(
          tags: [
            character,
            SuggestedTag(
              name: userTag.normalizedTag,
              displayName: userTag.displayName,
              category: userTag.category ?? DanbooruTagCategory.general,
              popularity: userTag.popularity ?? 0,
            ),
          ],
          description: '新しいキャラクター「${character.displayName}」を試してみましょう',
          combinationType: 'character_exploration',
        ));
      }
    }

    // よく使うタグ + 未使用アーティスト
    if (topUserTags.isNotEmpty && unusedArtist.isNotEmpty) {
      for (var i = 0; i < min(2, unusedArtist.length); i++) {
        final artist = unusedArtist[i];

        combinations.add(SuggestedCombination(
          tags: [artist],
          description: '人気アーティスト「${artist.displayName}」のスタイルを試してみましょう',
          combinationType: 'artist_exploration',
        ));
      }
    }

    // テーマ別の組み合わせ
    final themeCombinations = _generateThemeCombinations(
      unusedGeneral: unusedGeneral,
      userAnalysis: userAnalysis,
    );
    combinations.addAll(themeCombinations.take(5));

    return combinations.take(limit).toList();
  }

  /// テーマ別の組み合わせを生成
  List<SuggestedCombination> _generateThemeCombinations({
    required List<SuggestedTag> unusedGeneral,
    required UserUsageAnalysis userAnalysis,
  }) {
    final combinations = <SuggestedCombination>[];

    // 風景系タグを探す
    final landscapeTags = unusedGeneral
        .where((t) => _isLandscapeTag(t.name))
        .take(3)
        .toList();

    if (landscapeTags.isNotEmpty) {
      combinations.add(SuggestedCombination(
        tags: landscapeTags,
        description: '風景・背景系のタグを試してみましょう',
        combinationType: 'landscape_theme',
      ));
    }

    // 衣装系タグを探す
    final clothingTags = unusedGeneral
        .where((t) => _isClothingTag(t.name))
        .take(3)
        .toList();

    if (clothingTags.isNotEmpty) {
      combinations.add(SuggestedCombination(
        tags: clothingTags,
        description: '新しい衣装・ファッションを試してみましょう',
        combinationType: 'clothing_theme',
      ));
    }

    // 表情・ポーズ系タグを探す
    final expressionTags = unusedGeneral
        .where((t) => _isExpressionTag(t.name))
        .take(3)
        .toList();

    if (expressionTags.isNotEmpty) {
      combinations.add(SuggestedCombination(
        tags: expressionTags,
        description: '新しい表情・ポーズを試してみましょう',
        combinationType: 'expression_theme',
      ));
    }

    return combinations;
  }

  bool _isLandscapeTag(String tag) {
    final keywords = [
      'sky', 'cloud', 'sunset', 'sunrise', 'night', 'day', 'outdoor',
      'city', 'nature', 'forest', 'ocean', 'mountain', 'street', 'room',
      'scenery', 'landscape', 'background',
    ];
    return keywords.any((k) => tag.contains(k));
  }

  bool _isClothingTag(String tag) {
    final keywords = [
      'dress', 'shirt', 'skirt', 'pants', 'uniform', 'armor', 'kimono',
      'suit', 'jacket', 'coat', 'swimsuit', 'bikini', 'lingerie',
      'outfit', 'costume', 'clothes',
    ];
    return keywords.any((k) => tag.contains(k));
  }

  bool _isExpressionTag(String tag) {
    final keywords = [
      'smile', 'grin', 'frown', 'blush', 'crying', 'angry', 'surprised',
      'pose', 'standing', 'sitting', 'lying', 'walking', 'running',
      'looking', 'expression',
    ];
    return keywords.any((k) => tag.contains(k));
  }

  String _formatPopularity(int popularity) {
    if (popularity >= 1000000) {
      return '${(popularity / 1000000).toStringAsFixed(1)}M';
    }
    if (popularity >= 1000) {
      return '${(popularity / 1000).toStringAsFixed(1)}K';
    }
    return popularity.toString();
  }

  /// ランダムな発見用タグを提案
  Future<List<SuggestedTag>> suggestRandomDiscovery({
    required UserUsageAnalysis userAnalysis,
    int limit = 10,
  }) async {
    if (_danbooruDb == null) {
      _debugLog('SuggestionService.suggestRandomDiscovery', 'DB not available', {});
      return [];
    }

    try {
      // ランダムに人気タグを取得
      final result = _danbooruDb!.select('''
        SELECT id, name, type, popularity 
        FROM tag 
        WHERE popularity >= 5000
        ORDER BY RANDOM() 
        LIMIT ?
      ''', [limit * 3]);

      _debugLog('SuggestionService.suggestRandomDiscovery', 'Query executed', {
        'resultCount': result.length,
      });

      final tags = result.map((row) {
        final name = row['name'] as String;
        final type = row['type'] as int?;
        final popularity = row['popularity'] as int? ?? 0;

        return SuggestedTag(
          name: name,
          displayName: name.replaceAll('_', ' '),
          category: DanbooruTagCategory.fromTypeId(type),
          popularity: popularity,
          reason: 'ランダム発見',
        );
      }).toList();

      // 使用済みタグを除外
      final filtered = tags
          .where((tag) => !userAnalysis.hasUsedTag(tag.name))
          .take(limit)
          .toList();
      
      _debugLog('SuggestionService.suggestRandomDiscovery', 'Filtered results', {
        'beforeFilter': tags.length,
        'afterFilter': filtered.length,
      });

      return filtered;
    } catch (e) {
      _debugLog('SuggestionService.suggestRandomDiscovery', 'Query failed', {
        'error': e.toString(),
      });
      return [];
    }
  }

  /// リソース解放
  void dispose() {
    _danbooruDb?.dispose();
    _danbooruDb = null;
    _initialized = false;
  }
}
