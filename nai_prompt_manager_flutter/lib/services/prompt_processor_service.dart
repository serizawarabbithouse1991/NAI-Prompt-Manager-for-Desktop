import 'package:flutter/foundation.dart';
import 'tag_dictionary.dart';

/// 分解済みプロンプト（役割別）
@immutable
class DecomposedPrompt {
  final List<String> character;    // 髪色, 目, 表情, 服装
  final List<String> composition;  // ポーズ, アングル, 構図
  final List<String> style;        // 品質タグ, artist:xxx
  final List<String> background;   // 背景, シチュエーション
  final List<String> misc;         // その他

  const DecomposedPrompt({
    this.character = const [],
    this.composition = const [],
    this.style = const [],
    this.background = const [],
    this.misc = const [],
  });

  /// 全タグ数
  int get totalCount => 
    character.length + composition.length + style.length + background.length + misc.length;

  /// カテゴリ別にタグリストを取得
  List<String> getByCategory(TagCategory category) {
    switch (category) {
      case TagCategory.character:
        return character;
      case TagCategory.composition:
        return composition;
      case TagCategory.style:
        return style;
      case TagCategory.background:
        return background;
      case TagCategory.misc:
        return misc;
    }
  }
}

/// 処理済みプロンプト（3系統出力）
@immutable
class ProcessedPrompts {
  /// 再生成用: 正規化済み、そのまま使える
  final String forRegeneration;
  
  /// 改変用: キャラクター部分を{{CHAR}}で置換
  final String forModification;
  
  /// スタイル固定用: スタイルタグのみ抽出
  final String forStyleLock;
  
  /// スタイル要約（1行）
  final String styleSummary;
  
  /// 分解済みプロンプト
  final DecomposedPrompt decomposed;

  const ProcessedPrompts({
    required this.forRegeneration,
    required this.forModification,
    required this.forStyleLock,
    required this.styleSummary,
    required this.decomposed,
  });
}

/// ルールベースプロンプト処理サービス
/// 
/// 主な機能:
/// - トークン正規化（冗長性除去、フォーマット統一）
/// - 役割別分解（キャラクター、構図、スタイル、背景）
/// - 出力生成（再生成用、改変用、スタイル固定用）
class PromptProcessorService {
  
  /// プロンプト文字列を個別タグにトークン化
  /// (tag:1.2) や {tag} などの重み構文を考慮
  static List<String> tokenize(String prompt) {
    if (prompt.trim().isEmpty) {
      return [];
    }

    final tokens = <String>[];
    var current = StringBuffer();
    var depth = 0;
    var braceDepth = 0;

    for (var i = 0; i < prompt.length; i++) {
      final char = prompt[i];

      if (char == '(') {
        depth++;
        current.write(char);
      } else if (char == ')') {
        depth--;
        current.write(char);
      } else if (char == '{') {
        braceDepth++;
        current.write(char);
      } else if (char == '}') {
        braceDepth--;
        current.write(char);
      } else if (char == ',' && depth == 0 && braceDepth == 0) {
        // 分割ポイント - 括弧の外
        final trimmed = current.toString().trim();
        if (trimmed.isNotEmpty) {
          tokens.add(trimmed);
        }
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }

    // 最後のトークンを追加
    final trimmed = current.toString().trim();
    if (trimmed.isNotEmpty) {
      tokens.add(trimmed);
    }

    return tokens;
  }

  /// 単一トークンの正規化
  /// - 空白のトリム
  /// - 複数スペースの統一
  /// - 重み構文は保持
  static String normalizeToken(String token) {
    // トリムと空白の統一
    var normalized = token.trim().replaceAll(RegExp(r'\s+'), ' ');
    return normalized;
  }

  /// 重み構文から基本タグを抽出
  /// 例: "(blue hair:1.2)" -> "blue hair"
  static String extractBaseTag(String token) {
    var base = token;
    
    // (tag:weight) 形式を処理
    final weightMatch = RegExp(r'^\((.+):[\d.]+\)$').firstMatch(base);
    if (weightMatch != null) {
      base = weightMatch.group(1)!;
    }
    
    // 複数括弧 ((tag)) を処理
    while (base.startsWith('(') && base.endsWith(')') && !base.contains(':')) {
      base = base.substring(1, base.length - 1);
    }
    
    // {tag} 形式（NovelAI強調）を処理
    while (base.startsWith('{') && base.endsWith('}')) {
      base = base.substring(1, base.length - 1);
    }
    
    // [tag] 形式（弱調）を処理
    while (base.startsWith('[') && base.endsWith(']')) {
      base = base.substring(1, base.length - 1);
    }
    
    return base.trim();
  }

  /// 重複トークンを削除（大文字小文字を区別しない比較）
  static List<String> deduplicateTokens(List<String> tokens) {
    final seen = <String>{};
    final result = <String>[];

    for (final token in tokens) {
      final base = extractBaseTag(token).toLowerCase();
      if (!seen.contains(base)) {
        seen.add(base);
        result.add(token);
      }
    }

    return result;
  }

  /// トークンを役割別グループに分類
  static DecomposedPrompt categorizeTokens(List<String> tokens) {
    final character = <String>[];
    final composition = <String>[];
    final style = <String>[];
    final background = <String>[];
    final misc = <String>[];

    for (final token in tokens) {
      final baseTag = extractBaseTag(token);
      final category = TagDictionary.categorizeTag(baseTag);
      
      switch (category) {
        case TagCategory.character:
          character.add(token);
        case TagCategory.composition:
          composition.add(token);
        case TagCategory.style:
          style.add(token);
        case TagCategory.background:
          background.add(token);
        case TagCategory.misc:
          misc.add(token);
      }
    }

    return DecomposedPrompt(
      character: character,
      composition: composition,
      style: style,
      background: background,
      misc: misc,
    );
  }

  /// スタイル要約を生成（1行）
  static String generateStyleSummary(DecomposedPrompt decomposed) {
    final styleTags = decomposed.style;
    
    // 品質タグを検出
    final qualityTags = <String>[];
    for (final tag in styleTags) {
      final base = extractBaseTag(tag).toLowerCase();
      for (final quality in TagDictionary.qualitySummaryTags) {
        if (base.contains(quality)) {
          qualityTags.add(quality);
          break;
        }
      }
    }
    
    // アーティストタグを検出
    final artistTag = styleTags.cast<String?>().firstWhere(
      (t) => t != null && (t.toLowerCase().contains('artist:') || t.toLowerCase().startsWith('by ')),
      orElse: () => null,
    );
    
    // 要約を構築
    final parts = <String>[];
    
    if (qualityTags.isNotEmpty) {
      parts.add(qualityTags.take(2).join(', '));
    }
    
    if (artistTag != null) {
      parts.add(artistTag);
    }
    
    // その他のスタイルタグ数
    final otherCount = styleTags.length - qualityTags.length - (artistTag != null ? 1 : 0);
    if (otherCount > 0) {
      parts.add('+$otherCount style tags');
    }
    
    return parts.isNotEmpty ? parts.join(' | ') : 'No style tags detected';
  }

  /// キャラクタープレースホルダー付き改変用プロンプトを構築
  static String buildModificationPrompt(DecomposedPrompt decomposed) {
    final parts = <String>[];
    
    // スタイルタグを最初に追加
    if (decomposed.style.isNotEmpty) {
      parts.add(decomposed.style.join(', '));
    }
    
    // キャラクタープレースホルダー
    parts.add('{{CHAR}}');
    
    // 構図を追加
    if (decomposed.composition.isNotEmpty) {
      parts.add(decomposed.composition.join(', '));
    }
    
    // 背景を追加
    if (decomposed.background.isNotEmpty) {
      parts.add(decomposed.background.join(', '));
    }
    
    // その他を追加
    if (decomposed.misc.isNotEmpty) {
      parts.add(decomposed.misc.join(', '));
    }
    
    return parts.join(', ');
  }

  /// メイン処理関数
  static ProcessedPrompts process(String positivePrompt) {
    // Step 1: トークン化
    final tokens = tokenize(positivePrompt);
    
    // Step 2: 正規化
    final normalized = tokens.map(normalizeToken).toList();
    
    // Step 3: 重複削除
    final deduped = deduplicateTokens(normalized);
    
    // Step 4: カテゴリ分類
    final decomposed = categorizeTokens(deduped);
    
    // Step 5: 出力生成
    return ProcessedPrompts(
      // 再生成用: 正規化・重複削除済みプロンプト
      forRegeneration: deduped.join(', '),
      
      // 改変用: キャラクター部分をプレースホルダーで置換
      forModification: buildModificationPrompt(decomposed),
      
      // スタイル固定用: スタイルタグのみ
      forStyleLock: decomposed.style.join(', '),
      
      // スタイル要約
      styleSummary: generateStyleSummary(decomposed),
      
      // 分解済みデータ
      decomposed: decomposed,
    );
  }

  /// プロンプト内のトークン数をカウント
  static int countTokens(String prompt) {
    return tokenize(prompt).length;
  }

  /// CLIPトークン数の推定（概算）
  /// NovelAIは1プロンプトセクションあたり約77トークン
  static int estimateClipTokens(String prompt) {
    final tags = tokenize(prompt);
    var estimate = 0;
    
    for (final tag in tags) {
      // 基本: 1単語あたり1トークン
      final words = tag.split(RegExp(r'\s+')).length;
      estimate += words;
      // セパレータ（カンマ）用に1追加
      estimate += 1;
    }
    
    return estimate;
  }
}
