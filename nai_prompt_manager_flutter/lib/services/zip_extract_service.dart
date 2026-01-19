import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// ZIP解凍サービス
class ZipExtractService {
  static const _uuid = Uuid();
  
  /// サポートする画像拡張子
  static const supportedImageExtensions = [
    '.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'
  ];

  /// ZIPファイルを解凍して画像ファイルのパスリストを返す
  static Future<ZipExtractResult> extractImages(String zipPath) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      return ZipExtractResult.error('ZIPファイルが見つかりません: $zipPath');
    }

    try {
      // 一時ディレクトリを作成
      final tempDir = await getTemporaryDirectory();
      final extractId = _uuid.v4();
      final extractDir = Directory(p.join(tempDir.path, 'zip_extract_$extractId'));
      await extractDir.create(recursive: true);

      // ZIPを読み込み
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final extractedImages = <String>[];
      var totalFiles = 0;
      var skippedFiles = 0;

      // ファイルを展開
      for (final file in archive) {
        totalFiles++;
        
        // ディレクトリはスキップ
        if (file.isFile) {
          final filename = file.name;
          final ext = p.extension(filename).toLowerCase();
          
          // 画像ファイルのみ処理
          if (supportedImageExtensions.contains(ext)) {
            // 隠しファイル（__MACOSX等）をスキップ
            if (filename.startsWith('__') || filename.startsWith('.')) {
              skippedFiles++;
              continue;
            }

            // ファイルパスを生成（フラット化）
            final safeFilename = p.basename(filename);
            final uniqueFilename = '${_uuid.v4()}_$safeFilename';
            final outputPath = p.join(extractDir.path, uniqueFilename);

            // ファイルを書き出し
            final outputFile = File(outputPath);
            await outputFile.writeAsBytes(file.content as List<int>);
            extractedImages.add(outputPath);
          } else {
            skippedFiles++;
          }
        }
      }

      return ZipExtractResult.success(
        extractDir: extractDir.path,
        imagePaths: extractedImages,
        totalFiles: totalFiles,
        skippedFiles: skippedFiles,
      );
    } catch (e) {
      return ZipExtractResult.error('ZIP解凍エラー: $e');
    }
  }

  /// 複数のZIPファイルを解凍
  static Stream<ZipExtractProgress> extractMultipleZips(
    List<String> zipPaths,
  ) async* {
    final allImages = <String>[];
    var processed = 0;

    for (final zipPath in zipPaths) {
      final filename = p.basename(zipPath);
      
      yield ZipExtractProgress(
        current: processed,
        total: zipPaths.length,
        currentFile: filename,
        status: ZipExtractStatus.extracting,
        extractedImages: List.from(allImages),
      );

      final result = await extractImages(zipPath);
      processed++;

      if (result.isSuccess) {
        allImages.addAll(result.imagePaths);
        yield ZipExtractProgress(
          current: processed,
          total: zipPaths.length,
          currentFile: filename,
          status: ZipExtractStatus.completed,
          extractedImages: List.from(allImages),
          lastResult: result,
        );
      } else {
        yield ZipExtractProgress(
          current: processed,
          total: zipPaths.length,
          currentFile: filename,
          status: ZipExtractStatus.failed,
          extractedImages: List.from(allImages),
          lastResult: result,
          error: result.error,
        );
      }
    }
  }

  /// 一時ディレクトリをクリーンアップ
  static Future<void> cleanupExtractDir(String extractDir) async {
    try {
      final dir = Directory(extractDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      // クリーンアップ失敗は無視
    }
  }

  /// 古い一時ディレクトリをクリーンアップ（24時間以上前）
  static Future<int> cleanupOldExtractDirs() async {
    var deletedCount = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      final entries = await tempDir.list().toList();
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));

      for (final entry in entries) {
        if (entry is Directory && p.basename(entry.path).startsWith('zip_extract_')) {
          final stat = await entry.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entry.delete(recursive: true);
            deletedCount++;
          }
        }
      }
    } catch (e) {
      // エラーは無視
    }
    return deletedCount;
  }
}

/// ZIP解凍結果
class ZipExtractResult {
  final bool isSuccess;
  final String? extractDir;
  final List<String> imagePaths;
  final int totalFiles;
  final int skippedFiles;
  final String? error;

  const ZipExtractResult._({
    required this.isSuccess,
    this.extractDir,
    this.imagePaths = const [],
    this.totalFiles = 0,
    this.skippedFiles = 0,
    this.error,
  });

  factory ZipExtractResult.success({
    required String extractDir,
    required List<String> imagePaths,
    required int totalFiles,
    required int skippedFiles,
  }) {
    return ZipExtractResult._(
      isSuccess: true,
      extractDir: extractDir,
      imagePaths: imagePaths,
      totalFiles: totalFiles,
      skippedFiles: skippedFiles,
    );
  }

  factory ZipExtractResult.error(String error) {
    return ZipExtractResult._(
      isSuccess: false,
      error: error,
    );
  }

  int get imageCount => imagePaths.length;
}

/// ZIP解凍ステータス
enum ZipExtractStatus {
  extracting,
  completed,
  failed,
}

/// ZIP解凍進捗
class ZipExtractProgress {
  final int current;
  final int total;
  final String currentFile;
  final ZipExtractStatus status;
  final List<String> extractedImages;
  final ZipExtractResult? lastResult;
  final String? error;

  const ZipExtractProgress({
    required this.current,
    required this.total,
    required this.currentFile,
    required this.status,
    required this.extractedImages,
    this.lastResult,
    this.error,
  });

  double get progress => total > 0 ? current / total : 0;
  bool get isComplete => current >= total;
}
