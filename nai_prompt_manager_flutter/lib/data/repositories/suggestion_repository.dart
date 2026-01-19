import '../database/database.dart' as db;
import '../services/danbooru_tag_service.dart';

/// タグ使用統計
class TagUsageStats {
  final String tag;
  final String normalizedTag;
  final int usageCount;
  final DanbooruTagCategory? category;
  final int? popularity;

  const TagUsageStats({
    required this.tag,
    required this.normalizedTag,
    required this.usageCount,
    this.category,
    this.popularity,
  });

  /// プロンプト形式（スペース区切り）のタグ名
  String get displayName => normalizedTag.replaceAll('_', ' ');
}

/// カテゴリ別の使用傾向
class CategoryUsageTrend {
  final DanbooruTagCategory category;
  final int totalTags;
  final int totalUsage;
  final List<TagUsageStats> topTags;

  const CategoryUsageTrend({
    required this.category,
    required this.totalTags,
    required this.totalUsage,
    required this.topTags,
  });

  double get averageUsage => totalTags > 0 ? totalUsage / totalTags : 0;
}

/// ユーザーの使用履歴分析結果
class UserUsageAnalysis {
  final Set<String> usedTags;
  final Map<String, TagUsageStats> tagStats;
  final Map<DanbooruTagCategory, CategoryUsageTrend> categoryTrends;
  final int totalPrompts;
  final int totalUniqueTags;

  const UserUsageAnalysis({
    required this.usedTags,
    required this.tagStats,
    required this.categoryTrends,
    required this.totalPrompts,
    required this.totalUniqueTags,
  });

  /// 特定のタグが使用済みかどうか
  bool hasUsedTag(String tag) {
    final normalized = _normalizeTag(tag);
    return usedTags.contains(normalized);
  }

  /// タグを正規化（小文字、スペース→アンダースコア）
  static String _normalizeTag(String tag) {
    return tag.trim().toLowerCase().replaceAll(' ', '_');
  }
}

/// プロンプト提案用リポジトリ
class SuggestionRepository {
  final db.AppDatabase _db;
  final DanbooruTagService? _danbooruService;

  SuggestionRepository(this._db, [this._danbooruService]);

  /// ユーザーの全プロンプトからタグ使用履歴を分析
  Future<UserUsageAnalysis> analyzeUserUsage() async {
    // 全プロンプトを取得
    final prompts = await _db.select(_db.prompts).get();

    final tagCounts = <String, int>{};
    final originalTags = <String, String>{}; // normalized -> original

    for (final prompt in prompts) {
      final positivePrompt = prompt.positivePrompt;
      if (positivePrompt == null || positivePrompt.isEmpty) continue;

      // カンマ区切りでタグを抽出
      final tags = _extractTags(positivePrompt);
      for (final tag in tags) {
        final normalized = _normalizeTag(tag);
        if (normalized.isEmpty) continue;

        tagCounts[normalized] = (tagCounts[normalized] ?? 0) + 1;
        originalTags.putIfAbsent(normalized, () => tag);
      }
    }

    // タグ統計を構築
    final tagStats = <String, TagUsageStats>{};
    final categoryTagCounts = <DanbooruTagCategory, List<TagUsageStats>>{};

    for (final entry in tagCounts.entries) {
      final normalized = entry.key;
      final count = entry.value;
      final original = originalTags[normalized] ?? normalized;

      // Danbooruでカテゴリを検索
      DanbooruTagCategory? category;
      int? popularity;

      if (_danbooruService != null && _danbooruService.isAvailable) {
        final danbooruTag = _danbooruService.findTag(normalized);
        if (danbooruTag != null) {
          category = danbooruTag.category;
          popularity = danbooruTag.popularity;
        }
      }

      final stats = TagUsageStats(
        tag: original,
        normalizedTag: normalized,
        usageCount: count,
        category: category,
        popularity: popularity,
      );

      tagStats[normalized] = stats;

      // カテゴリ別に分類
      final cat = category ?? DanbooruTagCategory.unknown;
      categoryTagCounts.putIfAbsent(cat, () => []);
      categoryTagCounts[cat]!.add(stats);
    }

    // カテゴリ別の傾向を計算
    final categoryTrends = <DanbooruTagCategory, CategoryUsageTrend>{};
    for (final entry in categoryTagCounts.entries) {
      final category = entry.key;
      final tags = entry.value;

      // 使用回数でソート
      tags.sort((a, b) => b.usageCount.compareTo(a.usageCount));

      final totalUsage = tags.fold<int>(0, (sum, t) => sum + t.usageCount);

      categoryTrends[category] = CategoryUsageTrend(
        category: category,
        totalTags: tags.length,
        totalUsage: totalUsage,
        topTags: tags.take(10).toList(),
      );
    }

    return UserUsageAnalysis(
      usedTags: tagCounts.keys.toSet(),
      tagStats: tagStats,
      categoryTrends: categoryTrends,
      totalPrompts: prompts.length,
      totalUniqueTags: tagCounts.length,
    );
  }

  /// よく使うタグを取得（上位N件）
  Future<List<TagUsageStats>> getTopUsedTags({int limit = 50}) async {
    final analysis = await analyzeUserUsage();
    final allStats = analysis.tagStats.values.toList();
    allStats.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return allStats.take(limit).toList();
  }

  /// カテゴリ別によく使うタグを取得
  Future<Map<DanbooruTagCategory, List<TagUsageStats>>> getTopUsedTagsByCategory({
    int limitPerCategory = 10,
  }) async {
    final analysis = await analyzeUserUsage();
    final result = <DanbooruTagCategory, List<TagUsageStats>>{};

    for (final entry in analysis.categoryTrends.entries) {
      result[entry.key] = entry.value.topTags.take(limitPerCategory).toList();
    }

    return result;
  }

  /// プロンプトからタグを抽出
  List<String> _extractTags(String prompt) {
    return prompt
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .where((t) => !_isWeightOrSpecialSyntax(t))
        .toList();
  }

  /// タグを正規化
  String _normalizeTag(String tag) {
    // 括弧や重み指定を除去
    var cleaned = tag
        .replaceAll(RegExp(r'[{}()\[\]<>]'), '')
        .replaceAll(RegExp(r'^[:\d.]+'), '')
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_');

    return cleaned;
  }

  /// 重み指定や特殊構文かどうか
  bool _isWeightOrSpecialSyntax(String tag) {
    // 数字のみ、または特殊構文は除外
    if (RegExp(r'^[\d.:]+$').hasMatch(tag)) return true;
    if (tag.startsWith('BREAK')) return true;
    if (tag.startsWith('AND')) return true;
    return false;
  }
}
