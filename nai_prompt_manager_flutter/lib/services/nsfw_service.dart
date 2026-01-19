import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../data/models/models.dart';
import '../data/constants/nsfw_keywords.dart';

/// NSFW検出サービス
/// 
/// プロンプトベースの判定とオプションのローカルLLM判定をサポート
class NsfwService {
  bool _isInitialized = false;
  bool _isLoading = false;
  
  // Ollama設定
  String _ollamaUrl = 'http://localhost:11434';
  String _ollamaModel = 'llava';
  bool _ollamaAvailable = false;

  /// サービスが初期化されているか
  bool get isInitialized => _isInitialized;
  
  /// モデルをロード中か
  bool get isLoading => _isLoading;

  /// Ollamaが利用可能か
  bool get isOllamaAvailable => _ollamaAvailable;

  /// Ollama URLを設定
  void setOllamaUrl(String url) {
    _ollamaUrl = url;
    _ollamaAvailable = false; // 再検証が必要
  }

  /// Ollamaモデルを設定
  void setOllamaModel(String model) {
    _ollamaModel = model;
  }

  /// サービスを初期化
  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;
    
    _isLoading = true;
    
    try {
      // Ollamaの可用性をチェック
      await checkOllamaAvailability();
      _isInitialized = true;
    } finally {
      _isLoading = false;
    }
  }

  /// Ollamaの可用性をチェック
  Future<bool> checkOllamaAvailability() async {
    try {
      final response = await http.get(
        Uri.parse('$_ollamaUrl/api/tags'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List?;
        _ollamaAvailable = models != null && models.isNotEmpty;
        return _ollamaAvailable;
      }
    } catch (e) {
      // Ollamaが起動していない
    }
    _ollamaAvailable = false;
    return false;
  }

  /// 利用可能なOllamaモデル一覧を取得
  Future<List<String>> getOllamaModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_ollamaUrl/api/tags'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List?;
        if (models != null) {
          return models
              .map((m) => m['name'] as String)
              .where((name) => 
                  name.contains('llava') || 
                  name.contains('bakllava') ||
                  name.contains('vision'))
              .toList();
        }
      }
    } catch (e) {
      // エラーを無視
    }
    return [];
  }

  // ============================================================
  // プロンプトベース判定
  // ============================================================

  /// プロンプトからNSFW判定を実行
  NsfwResult detectFromPrompt(String? prompt) {
    if (prompt == null || prompt.isEmpty) {
      return NsfwResult.safe();
    }

    // プロンプトをトークンに分割
    final tokens = _parsePromptTokens(prompt);
    
    // NSFWキーワードを検索
    final matchedKeywords = <NsfwKeyword>[];
    for (final token in tokens) {
      final keyword = NsfwKeywordDatabase.find(token);
      if (keyword != null) {
        matchedKeywords.add(keyword);
      }
    }

    if (matchedKeywords.isEmpty) {
      return NsfwResult.safe();
    }

    // スコアを計算
    double totalWeight = 0;
    NsfwLevel highestLevel = NsfwLevel.safe;
    
    for (final kw in matchedKeywords) {
      totalWeight += kw.weight;
      if (kw.level.level > highestLevel.level) {
        highestLevel = kw.level;
      }
    }

    // スコアを正規化（0.0〜1.0）
    final normalizedScore = (totalWeight / matchedKeywords.length).clamp(0.0, 1.0);

    // NSFWカテゴリを決定
    final category = _levelToCategory(highestLevel);

    return NsfwResult(
      isNsfw: highestLevel.level >= NsfwLevel.questionable.level,
      category: category,
      score: normalizedScore,
      allScores: _calculateCategoryScores(matchedKeywords),
      matchedKeywords: matchedKeywords.map((k) => k.keyword).toList(),
      detectionMethod: NsfwDetectionMethod.prompt,
    );
  }

  /// プロンプトをトークンに分割
  List<String> _parsePromptTokens(String prompt) {
    // ","で分割し、各トークンを正規化
    return prompt
        .split(',')
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .map((t) {
          // 括弧や重み指定を除去
          var cleaned = t
              .replaceAll(RegExp(r'[{}()\[\]<>]'), '')
              .replaceAll(RegExp(r'^[:\d.]+'), '')
              .replaceAll(RegExp(r'[:\d.]+$'), '')
              .trim();
          // スペースをアンダースコアに変換
          return cleaned.replaceAll(' ', '_');
        })
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// NsfwLevelをNSFWCategoryに変換
  NSFWCategory _levelToCategory(NsfwLevel level) {
    switch (level) {
      case NsfwLevel.safe:
        return NSFWCategory.neutral;
      case NsfwLevel.suggestive:
        return NSFWCategory.sexy;
      case NsfwLevel.questionable:
        return NSFWCategory.sexy;
      case NsfwLevel.explicit:
        return NSFWCategory.hentai;
    }
  }

  /// カテゴリ別スコアを計算
  Map<NSFWCategory, double> _calculateCategoryScores(List<NsfwKeyword> keywords) {
    final scores = <NSFWCategory, double>{
      NSFWCategory.neutral: 0.0,
      NSFWCategory.drawing: 0.0,
      NSFWCategory.sexy: 0.0,
      NSFWCategory.hentai: 0.0,
      NSFWCategory.porn: 0.0,
    };

    if (keywords.isEmpty) {
      scores[NSFWCategory.neutral] = 1.0;
      return scores;
    }

    for (final kw in keywords) {
      switch (kw.level) {
        case NsfwLevel.safe:
          scores[NSFWCategory.neutral] = (scores[NSFWCategory.neutral]! + kw.weight);
          break;
        case NsfwLevel.suggestive:
          scores[NSFWCategory.sexy] = (scores[NSFWCategory.sexy]! + kw.weight);
          break;
        case NsfwLevel.questionable:
          scores[NSFWCategory.sexy] = (scores[NSFWCategory.sexy]! + kw.weight * 0.5);
          scores[NSFWCategory.hentai] = (scores[NSFWCategory.hentai]! + kw.weight * 0.5);
          break;
        case NsfwLevel.explicit:
          scores[NSFWCategory.hentai] = (scores[NSFWCategory.hentai]! + kw.weight * 0.3);
          scores[NSFWCategory.porn] = (scores[NSFWCategory.porn]! + kw.weight * 0.7);
          break;
      }
    }

    // 正規化
    final total = scores.values.reduce((a, b) => a + b);
    if (total > 0) {
      scores.updateAll((key, value) => value / total);
    } else {
      scores[NSFWCategory.neutral] = 1.0;
    }

    return scores;
  }

  // ============================================================
  // ローカルLLM判定（Ollama）
  // ============================================================

  /// Ollamaを使用してNSFW判定を実行
  Future<NsfwResult> detectWithOllama(Uint8List imageBytes) async {
    if (!_ollamaAvailable) {
      // フォールバック
      return NsfwResult.safe();
    }

    try {
      final base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        Uri.parse('$_ollamaUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _ollamaModel,
          'prompt': '''Analyze this image and rate its content safety on a scale of 0-10.
0-2: Safe (no sexual or violent content)
3-4: Suggestive (mild exposure, suggestive poses)
5-6: Questionable (nudity, partial exposure)
7-10: Explicit (sexual content, graphic content)

Respond ONLY with a JSON object in this exact format:
{"score": <number>, "category": "<safe|suggestive|questionable|explicit>", "reason": "<brief reason>"}''',
          'images': [base64Image],
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['response'] as String?;
        
        if (responseText != null) {
          return _parseOllamaResponse(responseText);
        }
      }
    } catch (e) {
      // エラーを無視してフォールバック
    }

    return NsfwResult.safe();
  }

  /// Ollamaのレスポンスをパース
  NsfwResult _parseOllamaResponse(String response) {
    try {
      // JSONを抽出
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = jsonDecode(jsonStr);
        
        final score = (data['score'] as num?)?.toDouble() ?? 0;
        final categoryStr = data['category'] as String? ?? 'safe';
        
        // スコアを0-1に正規化
        final normalizedScore = (score / 10).clamp(0.0, 1.0);
        
        // カテゴリを決定
        NSFWCategory category;
        bool isNsfw;
        
        switch (categoryStr.toLowerCase()) {
          case 'suggestive':
            category = NSFWCategory.sexy;
            isNsfw = false;
            break;
          case 'questionable':
            category = NSFWCategory.sexy;
            isNsfw = true;
            break;
          case 'explicit':
            category = normalizedScore > 0.8 ? NSFWCategory.porn : NSFWCategory.hentai;
            isNsfw = true;
            break;
          default:
            category = NSFWCategory.neutral;
            isNsfw = false;
        }

        return NsfwResult(
          isNsfw: isNsfw,
          category: category,
          score: normalizedScore,
          allScores: {
            NSFWCategory.neutral: categoryStr == 'safe' ? 1.0 - normalizedScore : 0.0,
            NSFWCategory.drawing: 0.0,
            NSFWCategory.sexy: categoryStr == 'suggestive' || categoryStr == 'questionable' ? normalizedScore : 0.0,
            NSFWCategory.hentai: categoryStr == 'explicit' && normalizedScore <= 0.8 ? normalizedScore : 0.0,
            NSFWCategory.porn: categoryStr == 'explicit' && normalizedScore > 0.8 ? normalizedScore : 0.0,
          },
          matchedKeywords: [],
          detectionMethod: NsfwDetectionMethod.ollama,
        );
      }
    } catch (e) {
      // パースエラー
    }

    return NsfwResult.safe();
  }

  // ============================================================
  // 統合判定
  // ============================================================

  /// プロンプトと画像の両方を使用して判定（可能な場合）
  Future<NsfwResult> detect({
    String? prompt,
    Uint8List? imageBytes,
    bool useOllama = false,
  }) async {
    // プロンプトベースの判定
    final promptResult = detectFromPrompt(prompt);

    // Ollamaが有効で画像がある場合
    if (useOllama && imageBytes != null && _ollamaAvailable) {
      final ollamaResult = await detectWithOllama(imageBytes);
      
      // 両方の結果を組み合わせ（より高いスコアを採用）
      if (ollamaResult.score > promptResult.score) {
        return ollamaResult;
      }
    }

    return promptResult;
  }

  /// リソースを解放
  void dispose() {
    _isInitialized = false;
  }
}

/// NSFW検出方法
enum NsfwDetectionMethod {
  prompt,
  ollama,
  combined,
}

/// NSFW検出結果
class NsfwResult {
  final bool isNsfw;
  final NSFWCategory category;
  final double score;
  final Map<NSFWCategory, double> allScores;
  final List<String> matchedKeywords;
  final NsfwDetectionMethod detectionMethod;

  const NsfwResult({
    required this.isNsfw,
    required this.category,
    required this.score,
    required this.allScores,
    this.matchedKeywords = const [],
    this.detectionMethod = NsfwDetectionMethod.prompt,
  });

  /// 安全な結果を生成
  factory NsfwResult.safe() {
    return const NsfwResult(
      isNsfw: false,
      category: NSFWCategory.neutral,
      score: 0.0,
      allScores: {
        NSFWCategory.neutral: 1.0,
        NSFWCategory.drawing: 0.0,
        NSFWCategory.sexy: 0.0,
        NSFWCategory.hentai: 0.0,
        NSFWCategory.porn: 0.0,
      },
    );
  }

  /// NSFWレベル（0-3）
  int get nsfwLevel {
    if (!isNsfw) return 0;
    switch (category) {
      case NSFWCategory.neutral:
      case NSFWCategory.drawing:
        return 0;
      case NSFWCategory.sexy:
        return 1;
      case NSFWCategory.hentai:
        return 2;
      case NSFWCategory.porn:
        return 3;
    }
  }

  /// スコアをパーセント表示
  String get scorePercent => '${(score * 100).toStringAsFixed(1)}%';

  /// 検出されたキーワードの概要
  String get keywordsSummary {
    if (matchedKeywords.isEmpty) return 'なし';
    if (matchedKeywords.length <= 3) {
      return matchedKeywords.join(', ');
    }
    return '${matchedKeywords.take(3).join(', ')} 他${matchedKeywords.length - 3}件';
  }
}
