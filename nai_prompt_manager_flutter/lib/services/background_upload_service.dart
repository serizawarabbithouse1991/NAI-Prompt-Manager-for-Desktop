import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'png_metadata_service.dart';
import 'nsfw_service.dart';
import 'danbooru_service.dart';

/// 並列処理の同時実行数
const int _maxConcurrency = 8;

/// バックグラウンドアップロード進捗
class BackgroundUploadProgress {
  final int total;
  final int completed;
  final int failed;
  final int duplicates;
  final String? currentFile;
  final bool isRunning;
  final String? error;

  const BackgroundUploadProgress({
    this.total = 0,
    this.completed = 0,
    this.failed = 0,
    this.duplicates = 0,
    this.currentFile,
    this.isRunning = false,
    this.error,
  });

  double get progress => total > 0 ? (completed + failed + duplicates) / total : 0;
  int get processed => completed + failed + duplicates;
  bool get isComplete => !isRunning && processed >= total;

  BackgroundUploadProgress copyWith({
    int? total,
    int? completed,
    int? failed,
    int? duplicates,
    String? currentFile,
    bool? isRunning,
    String? error,
  }) {
    return BackgroundUploadProgress(
      total: total ?? this.total,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      duplicates: duplicates ?? this.duplicates,
      currentFile: currentFile ?? this.currentFile,
      isRunning: isRunning ?? this.isRunning,
      error: error,
    );
  }
}

/// アップロードタスク
class UploadTask {
  final String id;
  final String filePath;
  final String fileName;
  final String? folderId;

  const UploadTask({
    required this.id,
    required this.filePath,
    required this.fileName,
    this.folderId,
  });
}

/// Isolateで実行する重い処理の結果
class ProcessedImageData {
  final String id;
  final String filePath;
  final String fileName;
  final Uint8List bytes;
  final String fileHash;
  final int? width;
  final int? height;
  final ParsedPromptData? promptData;
  final Uint8List? thumbnailBytes;
  final String? error;

  const ProcessedImageData({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.bytes,
    required this.fileHash,
    this.width,
    this.height,
    this.promptData,
    this.thumbnailBytes,
    this.error,
  });
}

/// Isolateで実行する画像処理
Future<ProcessedImageData> _processImageInIsolate(Map<String, dynamic> params) async {
  final id = params['id'] as String;
  final filePath = params['filePath'] as String;
  final fileName = params['fileName'] as String;

  try {
    final file = File(filePath);
    if (!await file.exists()) {
      return ProcessedImageData(
        id: id,
        filePath: filePath,
        fileName: fileName,
        bytes: Uint8List(0),
        fileHash: '',
        error: 'ファイルが見つかりません',
      );
    }

    final bytes = await file.readAsBytes();
    
    // ハッシュ計算
    final fileHash = sha256.convert(bytes).toString();
    
    // 画像サイズ取得
    int? width;
    int? height;
    final ext = p.extension(filePath).toLowerCase();
    
    if (ext == '.png') {
      final dimensions = PngMetadataService.getImageDimensions(bytes);
      width = dimensions?.width;
      height = dimensions?.height;
    }

    // メタデータ抽出
    ParsedPromptData? promptData;
    if (ext == '.png') {
      final metadata = PngMetadataService.extractNovelAIMetadata(bytes);
      if (metadata != null) {
        promptData = PngMetadataService.convertToPromptData(metadata);
      }
    }

    // サムネイル生成
    Uint8List? thumbnailBytes;
    try {
      final image = img.decodeImage(bytes);
      if (image != null) {
        // アスペクト比を維持してリサイズ
        img.Image thumbnail;
        const size = 150;
        if (image.width > image.height) {
          thumbnail = img.copyResize(image, width: size, interpolation: img.Interpolation.linear);
        } else {
          thumbnail = img.copyResize(image, height: size, interpolation: img.Interpolation.linear);
        }
        
        // 正方形にクロップ
        final cropSize = thumbnail.width < thumbnail.height ? thumbnail.width : thumbnail.height;
        final x = (thumbnail.width - cropSize) ~/ 2;
        final y = (thumbnail.height - cropSize) ~/ 2;
        thumbnail = img.copyCrop(thumbnail, x: x, y: y, width: cropSize, height: cropSize);
        
        thumbnailBytes = Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
      }
    } catch (e) {
      // サムネイル生成失敗は無視
    }

    return ProcessedImageData(
      id: id,
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
      fileHash: fileHash,
      width: width,
      height: height,
      promptData: promptData,
      thumbnailBytes: thumbnailBytes,
    );
  } catch (e) {
    return ProcessedImageData(
      id: id,
      filePath: filePath,
      fileName: fileName,
      bytes: Uint8List(0),
      fileHash: '',
      error: e.toString(),
    );
  }
}

/// バックグラウンドアップロードサービス
/// グローバルシングルトンとして動作し、ダイアログを閉じても処理を継続
class BackgroundUploadService {
  static final BackgroundUploadService _instance = BackgroundUploadService._internal();
  factory BackgroundUploadService() => _instance;
  BackgroundUploadService._internal();

  final _progressController = StreamController<BackgroundUploadProgress>.broadcast();
  Stream<BackgroundUploadProgress> get progressStream => _progressController.stream;

  BackgroundUploadProgress _currentProgress = const BackgroundUploadProgress();
  BackgroundUploadProgress get currentProgress => _currentProgress;

  bool _isRunning = false;
  bool _isCancelled = false;

  ImageRepository? _imageRepository;
  TagRepository? _tagRepository;
  NsfwService? _nsfwService;
  bool _enableNsfwDetection = false;

  static const _uuid = Uuid();

  /// サービスを初期化
  void initialize({
    required ImageRepository imageRepository,
    TagRepository? tagRepository,
    NsfwService? nsfwService,
    bool enableNsfwDetection = false,
  }) {
    _imageRepository = imageRepository;
    _tagRepository = tagRepository;
    _nsfwService = nsfwService;
    _enableNsfwDetection = enableNsfwDetection;
  }

  /// アップロードを開始
  Future<void> startUpload({
    required List<UploadTask> tasks,
    Set<String>? existingHashes,
    bool enableAutoTag = false,
  }) async {
    if (_isRunning) {
      debugPrint('BackgroundUploadService: Already running');
      return;
    }

    if (_imageRepository == null) {
      debugPrint('BackgroundUploadService: Not initialized');
      return;
    }

    _isRunning = true;
    _isCancelled = false;

    _currentProgress = BackgroundUploadProgress(
      total: tasks.length,
      isRunning: true,
    );
    _progressController.add(_currentProgress);

    // 既存ハッシュをキャッシュ（渡されていない場合は取得）
    final hashSet = existingHashes ?? await _imageRepository!.getAllFileHashes();

    // アプリのデータディレクトリを取得
    final appDir = await getApplicationSupportDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'images'));
    final thumbnailsDir = Directory(p.join(appDir.path, 'thumbnails'));
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }

    // 並列処理用のセマフォ
    final semaphore = _Semaphore(_maxConcurrency);
    final futures = <Future<void>>[];

    for (final task in tasks) {
      if (_isCancelled) break;

      final future = semaphore.run(() async {
        if (_isCancelled) return;

        _currentProgress = _currentProgress.copyWith(currentFile: task.fileName);
        _progressController.add(_currentProgress);

        try {
          // Isolateで重い処理を実行
          final processedData = await compute(_processImageInIsolate, {
            'id': task.id,
            'filePath': task.filePath,
            'fileName': task.fileName,
          });

          if (processedData.error != null) {
            _currentProgress = _currentProgress.copyWith(
              failed: _currentProgress.failed + 1,
            );
            _progressController.add(_currentProgress);
            return;
          }

          // 重複チェック
          if (hashSet.contains(processedData.fileHash)) {
            _currentProgress = _currentProgress.copyWith(
              duplicates: _currentProgress.duplicates + 1,
            );
            _progressController.add(_currentProgress);
            return;
          }

          // ハッシュをセットに追加（同じバッチ内での重複防止）
          hashSet.add(processedData.fileHash);

          // ファイルをコピー
          final ext = p.extension(task.filePath).toLowerCase();
          final destFilename = '${task.id}$ext';
          final destPath = p.join(imagesDir.path, destFilename);
          await File(task.filePath).copy(destPath);

          // サムネイルを保存
          String? thumbnailPath;
          if (processedData.thumbnailBytes != null) {
            final thumbFilename = '${task.id}.jpg';
            thumbnailPath = p.join(thumbnailsDir.path, thumbFilename);
            await File(thumbnailPath).writeAsBytes(processedData.thumbnailBytes!);
          }

          // NSFW判定
          NsfwResult? nsfwResult;
          if (_enableNsfwDetection && _nsfwService != null) {
            nsfwResult = _nsfwService!.detectFromPrompt(
              processedData.promptData?.positivePrompt,
            );
          }

          // 画像モデルを作成
          final imageModel = ImageModel(
            id: task.id,
            folderId: task.folderId,
            filePath: destPath,
            thumbnailPath: thumbnailPath,
            filename: task.fileName,
            width: processedData.width,
            height: processedData.height,
            fileSize: processedData.bytes.length,
            fileHash: processedData.fileHash,
            createdAt: DateTime.now(),
            isNsfw: nsfwResult?.isNsfw,
            nsfwScore: nsfwResult?.score,
            nsfwCategory: nsfwResult?.category,
          );

          // プロンプトモデルを作成
          Prompt? prompt;
          if (processedData.promptData != null) {
            final pd = processedData.promptData!;
            prompt = Prompt(
              id: _uuid.v4(),
              imageId: task.id,
              positivePrompt: pd.positivePrompt,
              negativePrompt: pd.negativePrompt,
              model: pd.model,
              sampler: pd.sampler,
              steps: pd.steps,
              cfgScale: pd.cfgScale,
              seed: pd.seed,
              resolutionWidth: pd.width,
              resolutionHeight: pd.height,
              noiseSchedule: pd.noiseSchedule,
              rawMetadata: pd.rawMetadata.isNotEmpty ? pd.rawMetadata.toString() : null,
              sourceType: pd.sourceType ?? AISourceType.unknown,
              createdAt: DateTime.now(),
            );
          }

          // DBに保存
          await _imageRepository!.insertImage(imageModel, prompt);

          // Danbooru自動タグ付け
          if (enableAutoTag && _tagRepository != null) {
            await _applyDanbooruTags(task.id, processedData.bytes);
          }

          _currentProgress = _currentProgress.copyWith(
            completed: _currentProgress.completed + 1,
          );
          _progressController.add(_currentProgress);
        } catch (e) {
          debugPrint('BackgroundUploadService: Error processing ${task.fileName}: $e');
          _currentProgress = _currentProgress.copyWith(
            failed: _currentProgress.failed + 1,
          );
          _progressController.add(_currentProgress);
        }
      });

      futures.add(future);
    }

    // 全ての処理を待機
    await Future.wait(futures);

    _isRunning = false;
    _currentProgress = _currentProgress.copyWith(
      isRunning: false,
      currentFile: null,
    );
    _progressController.add(_currentProgress);
  }

  /// アップロードをキャンセル
  void cancel() {
    _isCancelled = true;
    _isRunning = false;
    _currentProgress = _currentProgress.copyWith(
      isRunning: false,
      currentFile: null,
    );
    _progressController.add(_currentProgress);
  }

  /// 進捗をリセット
  void reset() {
    if (!_isRunning) {
      _currentProgress = const BackgroundUploadProgress();
      _progressController.add(_currentProgress);
    }
  }

  /// リソースを解放
  void dispose() {
    _progressController.close();
  }

  /// MD5ハッシュを計算
  String _calculateMd5(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  /// Danbooruタグを自動付与
  Future<List<String>> _applyDanbooruTags(String imageId, Uint8List bytes) async {
    final service = DanbooruService();
    if (!service.isConfigured || _tagRepository == null) {
      return [];
    }

    try {
      // MD5ハッシュを計算
      final md5Hash = _calculateMd5(bytes);

      // Danbooruからタグを取得
      final danbooruTags = await service.getTagsByMd5(md5Hash);
      if (danbooruTags.isEmpty) return [];

      // 人気タグを上位50件に制限
      final topTags = service.getTopTags(danbooruTags, limit: 50);
      final appliedTags = <String>[];

      for (final dTag in topTags) {
        // タグが存在するか確認、なければ作成
        var tag = await _tagRepository!.findTagByName(dTag.name);
        if (tag == null) {
          final newTag = Tag(
            id: _uuid.v4(),
            name: dTag.name,
            createdAt: DateTime.now(),
          );
          await _tagRepository!.insertTag(newTag);
          tag = newTag;
        }

        // 画像にタグを関連付け
        await _tagRepository!.addTagToImage(imageId, tag.id);
        appliedTags.add(tag.name);
      }

      return appliedTags;
    } catch (e) {
      debugPrint('BackgroundUploadService: Auto-tagging error: $e');
      // エラーは無視して空リストを返す
      return [];
    }
  }
}

/// セマフォ（同時実行数制限）
class _Semaphore {
  final int maxCount;
  int _currentCount = 0;
  final _waitQueue = <Completer<void>>[];

  _Semaphore(this.maxCount);

  Future<T> run<T>(Future<T> Function() task) async {
    await _acquire();
    try {
      return await task();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_currentCount < maxCount) {
      _currentCount++;
      return;
    }
    final completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
  }

  void _release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeAt(0);
      completer.complete();
    } else {
      _currentCount--;
    }
  }
}
