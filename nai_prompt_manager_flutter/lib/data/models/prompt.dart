import 'package:flutter/foundation.dart';
import 'enums.dart';

/// プロンプトモデル
@immutable
class Prompt {
  final String id;
  final String imageId;
  final String? positivePrompt;
  final String? negativePrompt;
  final String? model;
  final String? sampler;
  final int? steps;
  final double? cfgScale;
  final int? seed;
  final int? resolutionWidth;
  final int? resolutionHeight;
  final String? noiseSchedule;
  final double? promptGuidanceRescale;
  final String? notes;
  final String? rawMetadata;
  final AISourceType sourceType;
  final String? workflowJson;
  final DateTime createdAt;

  const Prompt({
    required this.id,
    required this.imageId,
    this.positivePrompt,
    this.negativePrompt,
    this.model,
    this.sampler,
    this.steps,
    this.cfgScale,
    this.seed,
    this.resolutionWidth,
    this.resolutionHeight,
    this.noiseSchedule,
    this.promptGuidanceRescale,
    this.notes,
    this.rawMetadata,
    this.sourceType = AISourceType.unknown,
    this.workflowJson,
    required this.createdAt,
  });

  Prompt copyWith({
    String? id,
    String? imageId,
    String? positivePrompt,
    String? negativePrompt,
    String? model,
    String? sampler,
    int? steps,
    double? cfgScale,
    int? seed,
    int? resolutionWidth,
    int? resolutionHeight,
    String? noiseSchedule,
    double? promptGuidanceRescale,
    String? notes,
    String? rawMetadata,
    AISourceType? sourceType,
    String? workflowJson,
    DateTime? createdAt,
  }) {
    return Prompt(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      positivePrompt: positivePrompt ?? this.positivePrompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      model: model ?? this.model,
      sampler: sampler ?? this.sampler,
      steps: steps ?? this.steps,
      cfgScale: cfgScale ?? this.cfgScale,
      seed: seed ?? this.seed,
      resolutionWidth: resolutionWidth ?? this.resolutionWidth,
      resolutionHeight: resolutionHeight ?? this.resolutionHeight,
      noiseSchedule: noiseSchedule ?? this.noiseSchedule,
      promptGuidanceRescale: promptGuidanceRescale ?? this.promptGuidanceRescale,
      notes: notes ?? this.notes,
      rawMetadata: rawMetadata ?? this.rawMetadata,
      sourceType: sourceType ?? this.sourceType,
      workflowJson: workflowJson ?? this.workflowJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_id': imageId,
      'positive_prompt': positivePrompt,
      'negative_prompt': negativePrompt,
      'model': model,
      'sampler': sampler,
      'steps': steps,
      'cfg_scale': cfgScale,
      'seed': seed,
      'resolution_width': resolutionWidth,
      'resolution_height': resolutionHeight,
      'noise_schedule': noiseSchedule,
      'prompt_guidance_rescale': promptGuidanceRescale,
      'notes': notes,
      'raw_metadata': rawMetadata,
      'source_type': sourceType.value,
      'workflow_json': workflowJson,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String,
      imageId: json['image_id'] as String,
      positivePrompt: json['positive_prompt'] as String?,
      negativePrompt: json['negative_prompt'] as String?,
      model: json['model'] as String?,
      sampler: json['sampler'] as String?,
      steps: json['steps'] as int?,
      cfgScale: json['cfg_scale'] as double?,
      seed: json['seed'] as int?,
      resolutionWidth: json['resolution_width'] as int?,
      resolutionHeight: json['resolution_height'] as int?,
      noiseSchedule: json['noise_schedule'] as String?,
      promptGuidanceRescale: json['prompt_guidance_rescale'] as double?,
      notes: json['notes'] as String?,
      rawMetadata: json['raw_metadata'] as String?,
      sourceType: AISourceType.fromString(json['source_type'] as String?),
      workflowJson: json['workflow_json'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Prompt && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// パース済みプロンプトデータ（メタデータ抽出結果）
@immutable
class ParsedPromptData {
  final String? positivePrompt;
  final String? negativePrompt;
  final String? model;
  final String? sampler;
  final int? steps;
  final double? cfgScale;
  final int? seed;
  final int? width;
  final int? height;
  final String? noiseSchedule;
  final Map<String, String> rawMetadata;
  final AISourceType? sourceType;
  final String? workflowJson;

  const ParsedPromptData({
    this.positivePrompt,
    this.negativePrompt,
    this.model,
    this.sampler,
    this.steps,
    this.cfgScale,
    this.seed,
    this.width,
    this.height,
    this.noiseSchedule,
    this.rawMetadata = const {},
    this.sourceType,
    this.workflowJson,
  });

  ParsedPromptData copyWith({
    String? positivePrompt,
    String? negativePrompt,
    String? model,
    String? sampler,
    int? steps,
    double? cfgScale,
    int? seed,
    int? width,
    int? height,
    String? noiseSchedule,
    Map<String, String>? rawMetadata,
    AISourceType? sourceType,
    String? workflowJson,
  }) {
    return ParsedPromptData(
      positivePrompt: positivePrompt ?? this.positivePrompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      model: model ?? this.model,
      sampler: sampler ?? this.sampler,
      steps: steps ?? this.steps,
      cfgScale: cfgScale ?? this.cfgScale,
      seed: seed ?? this.seed,
      width: width ?? this.width,
      height: height ?? this.height,
      noiseSchedule: noiseSchedule ?? this.noiseSchedule,
      rawMetadata: rawMetadata ?? this.rawMetadata,
      sourceType: sourceType ?? this.sourceType,
      workflowJson: workflowJson ?? this.workflowJson,
    );
  }
}
