import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'png_metadata_service.dart';

const _uuid = Uuid();

/// 再スキャン結果
class RescanResult {
  final int totalScanned;
  final int updatedCount;
  final int newCount;
  final int failedCount;
  final int skippedCount;
  final String? error;

  const RescanResult({
    required this.totalScanned,
    required this.updatedCount,
    required this.newCount,
    required this.failedCount,
    required this.skippedCount,
    this.error,
  });

  factory RescanResult.error(String error) {
    return RescanResult(
      totalScanned: 0,
      updatedCount: 0,
      newCount: 0,
      failedCount: 0,
      skippedCount: 0,
      error: error,
    );
  }
}

/// 再スキャン進捗
class RescanProgress {
  final int current;
  final int total;
  final int updated;
  final int newPrompts;
  final int failed;
  final int skipped;
  final String? currentFile;
  final bool isRunning;
  final String? error;

  const RescanProgress({
    this.current = 0,
    this.total = 0,
    this.updated = 0,
    this.newPrompts = 0,
    this.failed = 0,
    this.skipped = 0,
    this.currentFile,
    this.isRunning = false,
    this.error,
  });

  double get progress => total > 0 ? current / total : 0;
  bool get isComplete => !isRunning && current >= total && total > 0;

  RescanProgress copyWith({
    int? current,
    int? total,
    int? updated,
    int? newPrompts,
    int? failed,
    int? skipped,
    String? currentFile,
    bool? isRunning,
    String? error,
  }) {
    return RescanProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      updated: updated ?? this.updated,
      newPrompts: newPrompts ?? this.newPrompts,
      failed: failed ?? this.failed,
      skipped: skipped ?? this.skipped,
      currentFile: currentFile ?? this.currentFile,
      isRunning: isRunning ?? this.isRunning,
      error: error,
    );
  }
}

/// メタデータ再スキャンサービス
class RescanService {
  final ImageRepository _imageRepository;
  bool _cancelled = false;

  RescanService(this._imageRepository);

  /// 再スキャンをキャンセル
  void cancel() {
    _cancelled = true;
  }

  /// 全画像を再スキャンしてメタデータを更新
  Stream<RescanProgress> rescanAllImages({
    bool onlyWithoutPrompt = false,
  }) async* {
    _cancelled = false;

    yield const RescanProgress(isRunning: true);

    try {
      // 対象画像を取得
      final imagePaths = onlyWithoutPrompt
          ? await _imageRepository.getImagesWithoutPrompt()
          : await _imageRepository.getAllImagePaths();

      if (imagePaths.isEmpty) {
        yield const RescanProgress(
          isRunning: false,
          total: 0,
          current: 0,
        );
        return;
      }

      final total = imagePaths.length;
      var current = 0;
      var updated = 0;
      var newPrompts = 0;
      var failed = 0;
      var skipped = 0;

      yield RescanProgress(
        isRunning: true,
        total: total,
        current: 0,
      );

      for (final imageInfo in imagePaths) {
        if (_cancelled) {
          yield RescanProgress(
            isRunning: false,
            total: total,
            current: current,
            updated: updated,
            newPrompts: newPrompts,
            failed: failed,
            skipped: skipped,
            error: 'キャンセルされました',
          );
          return;
        }

        current++;
        final fileName = imageInfo.filePath.split(Platform.pathSeparator).last;

        yield RescanProgress(
          isRunning: true,
          total: total,
          current: current,
          updated: updated,
          newPrompts: newPrompts,
          failed: failed,
          skipped: skipped,
          currentFile: fileName,
        );

        try {
          final result = await _processImage(imageInfo.id, imageInfo.filePath);
          
          switch (result) {
            case _ProcessResult.updated:
              updated++;
            case _ProcessResult.newPrompt:
              newPrompts++;
            case _ProcessResult.skipped:
              skipped++;
            case _ProcessResult.failed:
              failed++;
          }
        } catch (e) {
          failed++;
          debugPrint('再スキャンエラー (${imageInfo.id}): $e');
        }
      }

      yield RescanProgress(
        isRunning: false,
        total: total,
        current: current,
        updated: updated,
        newPrompts: newPrompts,
        failed: failed,
        skipped: skipped,
      );
    } catch (e) {
      yield RescanProgress(
        isRunning: false,
        error: '再スキャン中にエラーが発生しました: $e',
      );
    }
  }

  /// 単一画像を処理
  Future<_ProcessResult> _processImage(String imageId, String filePath) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      return _ProcessResult.failed;
    }

    final ext = filePath.toLowerCase();
    if (!ext.endsWith('.png')) {
      // PNGファイル以外はスキップ
      return _ProcessResult.skipped;
    }

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      return _ProcessResult.failed;
    }

    // メタデータを抽出
    final metadata = PngMetadataService.extractNovelAIMetadata(bytes);
    if (metadata == null) {
      // メタデータがない場合はスキップ
      return _ProcessResult.skipped;
    }

    final promptData = PngMetadataService.convertToPromptData(metadata);
    if (promptData == null) {
      return _ProcessResult.skipped;
    }

    // プロンプト情報が有効かチェック
    if (promptData.positivePrompt == null && 
        promptData.negativePrompt == null &&
        promptData.model == null) {
      return _ProcessResult.skipped;
    }

    // 既存のプロンプトを確認
    final existingImage = await _imageRepository.getImageById(imageId);
    final hadPrompt = existingImage?.prompt != null;

    // プロンプトを作成/更新
    final prompt = Prompt(
      id: hadPrompt ? existingImage!.prompt!.id : _uuid.v4(),
      imageId: imageId,
      positivePrompt: promptData.positivePrompt,
      negativePrompt: promptData.negativePrompt,
      model: promptData.model,
      sampler: promptData.sampler,
      steps: promptData.steps,
      cfgScale: promptData.cfgScale,
      seed: promptData.seed,
      resolutionWidth: promptData.width,
      resolutionHeight: promptData.height,
      noiseSchedule: promptData.noiseSchedule,
      rawMetadata: promptData.rawMetadata.isNotEmpty 
          ? promptData.rawMetadata.toString() 
          : null,
      sourceType: promptData.sourceType ?? AISourceType.novelai,
      createdAt: DateTime.now(),
    );

    await _imageRepository.upsertPrompt(prompt);

    return hadPrompt ? _ProcessResult.updated : _ProcessResult.newPrompt;
  }
}

enum _ProcessResult {
  updated,
  newPrompt,
  skipped,
  failed,
}
