import 'dart:typed_data';
import 'dart:math' as math;

import '../data/models/models.dart';

/// NSFW検出サービス
/// 
/// NOTE: 実際の実装では TFLite または ONNX Runtime を使用。
/// 現在はプレースホルダー実装。
class NsfwService {
  bool _isInitialized = false;
  bool _isLoading = false;

  /// サービスが初期化されているか
  bool get isInitialized => _isInitialized;
  
  /// モデルをロード中か
  bool get isLoading => _isLoading;

  /// モデルをロード
  Future<void> loadModel() async {
    if (_isInitialized || _isLoading) return;
    
    _isLoading = true;
    
    try {
      // TODO: NSFWモデルをロード
      await Future.delayed(const Duration(milliseconds: 100));
      _isInitialized = true;
    } finally {
      _isLoading = false;
    }
  }

  /// 画像のNSFW検出を実行
  Future<NsfwResult> detect(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await loadModel();
    }

    try {
      // TODO: 実際のNSFW推論
      // 1. 画像を224x224にリサイズ
      // 2. モデルで推論
      // 3. 各カテゴリのスコアを取得
      
      // プレースホルダー: ほぼ安全と判定
      final random = math.Random(imageBytes.hashCode);
      final scores = {
        NSFWCategory.neutral: 0.85 + random.nextDouble() * 0.1,
        NSFWCategory.drawing: random.nextDouble() * 0.05,
        NSFWCategory.sexy: random.nextDouble() * 0.03,
        NSFWCategory.hentai: random.nextDouble() * 0.02,
        NSFWCategory.porn: random.nextDouble() * 0.01,
      };
      
      // 合計が1になるよう正規化
      final total = scores.values.reduce((a, b) => a + b);
      scores.updateAll((key, value) => value / total);
      
      // 最高スコアのカテゴリを特定
      NSFWCategory topCategory = NSFWCategory.neutral;
      double topScore = 0;
      for (final entry in scores.entries) {
        if (entry.value > topScore) {
          topScore = entry.value;
          topCategory = entry.key;
        }
      }
      
      return NsfwResult(
        isNsfw: topCategory != NSFWCategory.neutral && 
                topCategory != NSFWCategory.drawing,
        category: topCategory,
        score: topScore,
        allScores: scores,
      );
    } catch (e) {
      return NsfwResult.safe();
    }
  }

  /// リソースを解放
  void dispose() {
    _isInitialized = false;
  }
}

/// NSFW検出結果
class NsfwResult {
  final bool isNsfw;
  final NSFWCategory category;
  final double score;
  final Map<NSFWCategory, double> allScores;

  const NsfwResult({
    required this.isNsfw,
    required this.category,
    required this.score,
    required this.allScores,
  });

  /// 安全な結果を生成
  factory NsfwResult.safe() {
    return const NsfwResult(
      isNsfw: false,
      category: NSFWCategory.neutral,
      score: 1.0,
      allScores: {
        NSFWCategory.neutral: 1.0,
        NSFWCategory.drawing: 0.0,
        NSFWCategory.sexy: 0.0,
        NSFWCategory.hentai: 0.0,
        NSFWCategory.porn: 0.0,
      },
    );
  }

  /// NSFWレベル（0-4）
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
}
