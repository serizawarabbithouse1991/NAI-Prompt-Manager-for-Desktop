import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'png_metadata_service.dart';
import 'thumbnail_service.dart';

/// 画像インポートサービス
class ImageImportService {
  final ImageRepository _imageRepository;
  static const _uuid = Uuid();

  ImageImportService(this._imageRepository);

  /// 画像ファイルをインポート
  Future<ImportResult> importImage({
    required String sourcePath,
    String? folderId,
    bool checkDuplicates = true,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return ImportResult.error('ファイルが見つかりません: $sourcePath');
    }

    try {
      // ファイルを読み込み
      final bytes = await sourceFile.readAsBytes();
      final filename = p.basename(sourcePath);
      final ext = p.extension(sourcePath).toLowerCase();

      // ハッシュを計算（重複検出用）
      final fileHash = _calculateHash(bytes);

      // 重複チェック
      if (checkDuplicates) {
        final duplicates = await _imageRepository.findDuplicates();
        final isDuplicate = duplicates.any((img) => img.fileHash == fileHash);
        if (isDuplicate) {
          return ImportResult.duplicate(fileHash);
        }
      }

      // アプリのデータディレクトリを取得
      final appDir = await getApplicationSupportDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // ユニークなファイル名を生成
      final id = _uuid.v4();
      final destFilename = '$id$ext';
      final destPath = p.join(imagesDir.path, destFilename);

      // ファイルをコピー
      await sourceFile.copy(destPath);

      // 画像のサイズを取得
      final dimensions = PngMetadataService.getImageDimensions(bytes);

      // PNGの場合、メタデータを抽出
      ParsedPromptData? promptData;
      if (ext == '.png') {
        final metadata = PngMetadataService.extractNovelAIMetadata(bytes);
        if (metadata != null) {
          promptData = PngMetadataService.convertToPromptData(metadata);
        }
      }

      // サムネイルを生成
      final thumbnailPath = await ThumbnailService.generateThumbnailFromBytes(bytes);

      // 画像モデルを作成
      final imageModel = ImageModel(
        id: id,
        folderId: folderId,
        filePath: destPath,
        thumbnailPath: thumbnailPath,
        filename: filename,
        width: dimensions?.width,
        height: dimensions?.height,
        fileSize: bytes.length,
        fileHash: fileHash,
        createdAt: DateTime.now(),
      );

      // プロンプトモデルを作成
      Prompt? prompt;
      if (promptData != null) {
        prompt = Prompt(
          id: _uuid.v4(),
          imageId: id,
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
              ? promptData.rawMetadata.toString() : null,
          sourceType: promptData.sourceType ?? AISourceType.unknown,
          createdAt: DateTime.now(),
        );
      }

      // DBに保存
      await _imageRepository.insertImage(imageModel, prompt);

      return ImportResult.success(imageModel, prompt);
    } catch (e) {
      return ImportResult.error('インポート失敗: $e');
    }
  }

  /// 複数ファイルを一括インポート
  Stream<ImportProgress> importImages({
    required List<String> sourcePaths,
    String? folderId,
    bool checkDuplicates = true,
  }) async* {
    final total = sourcePaths.length;
    var processed = 0;
    var succeeded = 0;
    var failed = 0;
    var duplicates = 0;

    for (final path in sourcePaths) {
      final result = await importImage(
        sourcePath: path,
        folderId: folderId,
        checkDuplicates: checkDuplicates,
      );

      processed++;
      
      switch (result.status) {
        case ImportStatus.success:
          succeeded++;
        case ImportStatus.duplicate:
          duplicates++;
        case ImportStatus.error:
          failed++;
      }

      yield ImportProgress(
        current: processed,
        total: total,
        currentFile: p.basename(path),
        succeeded: succeeded,
        failed: failed,
        duplicates: duplicates,
        lastResult: result,
      );
    }
  }

  /// ファイルハッシュを計算
  String _calculateHash(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// 画像ディレクトリを取得
  static Future<Directory> getImagesDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }
}

/// インポート結果
class ImportResult {
  final ImportStatus status;
  final ImageModel? image;
  final Prompt? prompt;
  final String? error;
  final String? duplicateHash;

  const ImportResult._({
    required this.status,
    this.image,
    this.prompt,
    this.error,
    this.duplicateHash,
  });

  factory ImportResult.success(ImageModel image, Prompt? prompt) {
    return ImportResult._(
      status: ImportStatus.success,
      image: image,
      prompt: prompt,
    );
  }

  factory ImportResult.error(String error) {
    return ImportResult._(
      status: ImportStatus.error,
      error: error,
    );
  }

  factory ImportResult.duplicate(String hash) {
    return ImportResult._(
      status: ImportStatus.duplicate,
      duplicateHash: hash,
    );
  }
}

/// インポートステータス
enum ImportStatus {
  success,
  duplicate,
  error,
}

/// インポート進捗
class ImportProgress {
  final int current;
  final int total;
  final String currentFile;
  final int succeeded;
  final int failed;
  final int duplicates;
  final ImportResult lastResult;

  const ImportProgress({
    required this.current,
    required this.total,
    required this.currentFile,
    required this.succeeded,
    required this.failed,
    required this.duplicates,
    required this.lastResult,
  });

  double get progress => total > 0 ? current / total : 0;
  bool get isComplete => current >= total;
}
