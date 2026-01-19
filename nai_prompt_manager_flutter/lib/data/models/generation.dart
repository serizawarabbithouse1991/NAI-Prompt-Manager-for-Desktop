import 'package:flutter/foundation.dart';
import 'enums.dart';

/// 画像生成接続設定
@immutable
class ImageGenConfig {
  final String id;
  final String name;
  final ImageGenProvider provider;
  final String endpoint;
  final bool enabled;
  final bool isDefault;

  const ImageGenConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.endpoint,
    this.enabled = true,
    this.isDefault = false,
  });

  ImageGenConfig copyWith({
    String? id,
    String? name,
    ImageGenProvider? provider,
    String? endpoint,
    bool? enabled,
    bool? isDefault,
  }) {
    return ImageGenConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      endpoint: endpoint ?? this.endpoint,
      enabled: enabled ?? this.enabled,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// 生成パラメータ
@immutable
class GenerationParams {
  final String positivePrompt;
  final String negativePrompt;
  final int width;
  final int height;
  final int steps;
  final double cfgScale;
  final String sampler;
  final String? scheduler;
  final int seed;
  final String? model;
  final int? clipSkip;
  // img2img
  final String? initImage;
  final double? denoisingStrength;
  // Hires.fix
  final bool enableHiresFix;
  final String? hiresUpscaler;
  final int? hiresSteps;
  final double? hiresDenoisingStrength;
  final double? hiresScale;
  // Batch
  final int batchSize;
  final int batchCount;

  const GenerationParams({
    this.positivePrompt = '',
    this.negativePrompt =
        'lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry',
    this.width = 832,
    this.height = 1216,
    this.steps = 28,
    this.cfgScale = 7,
    this.sampler = 'Euler a',
    this.scheduler,
    this.seed = -1,
    this.model,
    this.clipSkip = 2,
    this.initImage,
    this.denoisingStrength,
    this.enableHiresFix = false,
    this.hiresUpscaler,
    this.hiresSteps,
    this.hiresDenoisingStrength,
    this.hiresScale,
    this.batchSize = 1,
    this.batchCount = 1,
  });

  GenerationParams copyWith({
    String? positivePrompt,
    String? negativePrompt,
    int? width,
    int? height,
    int? steps,
    double? cfgScale,
    String? sampler,
    String? scheduler,
    int? seed,
    String? model,
    int? clipSkip,
    String? initImage,
    double? denoisingStrength,
    bool? enableHiresFix,
    String? hiresUpscaler,
    int? hiresSteps,
    double? hiresDenoisingStrength,
    double? hiresScale,
    int? batchSize,
    int? batchCount,
  }) {
    return GenerationParams(
      positivePrompt: positivePrompt ?? this.positivePrompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      width: width ?? this.width,
      height: height ?? this.height,
      steps: steps ?? this.steps,
      cfgScale: cfgScale ?? this.cfgScale,
      sampler: sampler ?? this.sampler,
      scheduler: scheduler ?? this.scheduler,
      seed: seed ?? this.seed,
      model: model ?? this.model,
      clipSkip: clipSkip ?? this.clipSkip,
      initImage: initImage ?? this.initImage,
      denoisingStrength: denoisingStrength ?? this.denoisingStrength,
      enableHiresFix: enableHiresFix ?? this.enableHiresFix,
      hiresUpscaler: hiresUpscaler ?? this.hiresUpscaler,
      hiresSteps: hiresSteps ?? this.hiresSteps,
      hiresDenoisingStrength:
          hiresDenoisingStrength ?? this.hiresDenoisingStrength,
      hiresScale: hiresScale ?? this.hiresScale,
      batchSize: batchSize ?? this.batchSize,
      batchCount: batchCount ?? this.batchCount,
    );
  }

  static const GenerationParams defaultParams = GenerationParams();
}

/// 生成進捗
@immutable
class GenerationProgress {
  final double progress;
  final double etaRelative;
  final int currentStep;
  final int totalSteps;
  final String? currentImage;

  const GenerationProgress({
    required this.progress,
    required this.etaRelative,
    required this.currentStep,
    required this.totalSteps,
    this.currentImage,
  });
}

/// 生成結果
@immutable
class GenerationResult {
  final List<String> images;
  final GenerationParams parameters;
  final String info;
  final int seed;

  const GenerationResult({
    required this.images,
    required this.parameters,
    required this.info,
    required this.seed,
  });
}

/// 生成キュー状態
enum GenerationStatus { queued, generating, completed, failed }

/// 生成キュー項目
@immutable
class GenerationQueueItem {
  final String id;
  final GenerationParams params;
  final GenerationStatus status;
  final GenerationProgress? progress;
  final GenerationResult? result;
  final String? error;
  final DateTime createdAt;

  const GenerationQueueItem({
    required this.id,
    required this.params,
    required this.status,
    this.progress,
    this.result,
    this.error,
    required this.createdAt,
  });

  GenerationQueueItem copyWith({
    String? id,
    GenerationParams? params,
    GenerationStatus? status,
    GenerationProgress? progress,
    GenerationResult? result,
    String? error,
    DateTime? createdAt,
  }) {
    return GenerationQueueItem(
      id: id ?? this.id,
      params: params ?? this.params,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 解像度プリセット
@immutable
class ResolutionPreset {
  final String name;
  final int width;
  final int height;
  final String aspectRatio;

  const ResolutionPreset({
    required this.name,
    required this.width,
    required this.height,
    required this.aspectRatio,
  });

  static const List<ResolutionPreset> defaults = [
    ResolutionPreset(
        name: 'Portrait (SD)', width: 512, height: 768, aspectRatio: '2:3'),
    ResolutionPreset(
        name: 'Landscape (SD)', width: 768, height: 512, aspectRatio: '3:2'),
    ResolutionPreset(
        name: 'Square (SD)', width: 512, height: 512, aspectRatio: '1:1'),
    ResolutionPreset(
        name: 'Portrait (SDXL)', width: 832, height: 1216, aspectRatio: '2:3'),
    ResolutionPreset(
        name: 'Landscape (SDXL)', width: 1216, height: 832, aspectRatio: '3:2'),
    ResolutionPreset(
        name: 'Square (SDXL)', width: 1024, height: 1024, aspectRatio: '1:1'),
    ResolutionPreset(
        name: 'Portrait (NAI)', width: 832, height: 1216, aspectRatio: '2:3'),
    ResolutionPreset(
        name: 'Landscape (NAI)', width: 1216, height: 832, aspectRatio: '3:2'),
    ResolutionPreset(
        name: 'Wide (SDXL)', width: 1344, height: 768, aspectRatio: '16:9'),
    ResolutionPreset(
        name: 'Tall (SDXL)', width: 768, height: 1344, aspectRatio: '9:16'),
  ];
}
