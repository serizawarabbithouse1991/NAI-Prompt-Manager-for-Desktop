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
import 'danbooru_service.dart';
import 'nsfw_service.dart';

/// 画像インポートサービス
class ImageImportService {
  final ImageRepository _imageRepository;
  final TagRepository? _tagRepository;
  final NsfwService? _nsfwService;
  final bool _enableNsfwDetection;
  static const _uuid = Uuid();

  ImageImportService(
    this._imageRepository, [
    this._tagRepository,
    this._nsfwService,
    this._enableNsfwDetection = false,
  ]);

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

      // NSFW判定を実行
      NsfwResult? nsfwResult;
      if (_enableNsfwDetection && _nsfwService != null) {
        // プロンプトベースの判定
        nsfwResult = _nsfwService.detectFromPrompt(promptData?.positivePrompt);
      }

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
        isNsfw: nsfwResult?.isNsfw,
        nsfwScore: nsfwResult?.score,
        nsfwCategory: nsfwResult?.category,
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

      // Danbooru自動タグ付け
      List<String> autoTags = [];
      if (_tagRepository != null) {
        autoTags = await _applyDanbooruTags(id, fileHash);
      }

      return ImportResult.success(imageModel, prompt, autoTags: autoTags);
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

  /// MD5ハッシュを計算（Danbooru用）
  String _calculateMd5(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  /// Danbooruタグを自動付与
  Future<List<String>> _applyDanbooruTags(String imageId, String fileHash) async {
    final service = DanbooruService();
    if (!service.isConfigured || _tagRepository == null) {
      return [];
    }

    try {
      // ファイルを読み込んでMD5を計算
      final image = await _imageRepository.getImageById(imageId);
      if (image == null) return [];

      final file = File(image.filePath);
      if (!await file.exists()) return [];

      final bytes = await file.readAsBytes();
      final md5Hash = _calculateMd5(bytes);

      // Danbooruからタグを取得
      final danbooruTags = await service.getTagsByMd5(md5Hash);
      if (danbooruTags.isEmpty) return [];

      // 人気タグを上位50件に制限
      final topTags = service.getTopTags(danbooruTags, limit: 50);
      final appliedTags = <String>[];

      for (final dTag in topTags) {
        // タグが存在するか確認、なければ作成
        var tag = await _tagRepository.findTagByName(dTag.name);
        if (tag == null) {
          final newTag = Tag(
            id: _uuid.v4(),
            name: dTag.name,
            createdAt: DateTime.now(),
          );
          await _tagRepository.insertTag(newTag);
          tag = newTag;
        }

        // 画像にタグを関連付け
        await _tagRepository.addTagToImage(imageId, tag.id);
        appliedTags.add(tag.name);
      }

      return appliedTags;
    } catch (e) {
      // エラーは無視して空リストを返す
      return [];
    }
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
  final List<String> autoTags;

  const ImportResult._({
    required this.status,
    this.image,
    this.prompt,
    this.error,
    this.duplicateHash,
    this.autoTags = const [],
  });

  factory ImportResult.success(ImageModel image, Prompt? prompt, {List<String> autoTags = const []}) {
    return ImportResult._(
      status: ImportStatus.success,
      image: image,
      prompt: prompt,
      autoTags: autoTags,
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
