import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// サムネイル生成サービス
class ThumbnailService {
  static const _uuid = Uuid();
  static const defaultSize = 150;
  static const defaultQuality = 85;

  /// サムネイルを生成
  static Future<String?> generateThumbnail(
    String sourcePath, {
    int size = defaultSize,
    int quality = defaultQuality,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      final bytes = await sourceFile.readAsBytes();
      return generateThumbnailFromBytes(
        bytes,
        size: size,
        quality: quality,
      );
    } catch (e) {
      return null;
    }
  }

  /// バイト配列からサムネイルを生成
  static Future<String?> generateThumbnailFromBytes(
    Uint8List bytes, {
    int size = defaultSize,
    int quality = defaultQuality,
  }) async {
    try {
      // 画像をデコード
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // アスペクト比を維持してリサイズ
      img.Image thumbnail;
      if (image.width > image.height) {
        thumbnail = img.copyResize(
          image,
          width: size,
          interpolation: img.Interpolation.linear,
        );
      } else {
        thumbnail = img.copyResize(
          image,
          height: size,
          interpolation: img.Interpolation.linear,
        );
      }

      // 正方形にクロップ（中央から）
      final cropSize = thumbnail.width < thumbnail.height
          ? thumbnail.width
          : thumbnail.height;
      final x = (thumbnail.width - cropSize) ~/ 2;
      final y = (thumbnail.height - cropSize) ~/ 2;
      thumbnail = img.copyCrop(thumbnail, x: x, y: y, width: cropSize, height: cropSize);

      // JPEGとしてエンコード
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: quality);

      // サムネイルディレクトリを取得
      final thumbnailsDir = await getThumbnailsDirectory();

      // ファイルに保存
      final filename = '${_uuid.v4()}.jpg';
      final outputPath = p.join(thumbnailsDir.path, filename);
      await File(outputPath).writeAsBytes(thumbnailBytes);

      return outputPath;
    } catch (e) {
      return null;
    }
  }

  /// 複数のサムネイルを一括生成
  static Stream<ThumbnailProgress> generateThumbnails(
    List<ThumbnailRequest> requests, {
    int size = defaultSize,
    int quality = defaultQuality,
  }) async* {
    final total = requests.length;
    var processed = 0;
    var succeeded = 0;
    var failed = 0;

    for (final request in requests) {
      String? thumbnailPath;

      try {
        thumbnailPath = await generateThumbnail(
          request.sourcePath,
          size: size,
          quality: quality,
        );

        if (thumbnailPath != null) {
          succeeded++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
      }

      processed++;

      yield ThumbnailProgress(
        current: processed,
        total: total,
        succeeded: succeeded,
        failed: failed,
        lastImageId: request.imageId,
        lastThumbnailPath: thumbnailPath,
      );
    }
  }

  /// サムネイルディレクトリを取得
  static Future<Directory> getThumbnailsDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final thumbnailsDir = Directory(p.join(appDir.path, 'thumbnails'));
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }
    return thumbnailsDir;
  }

  /// サムネイルファイルを削除
  static Future<void> deleteThumbnail(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 削除失敗は無視
    }
  }

  /// 古いサムネイルをクリーンアップ（DBに存在しないサムネイル）
  static Future<int> cleanupOrphanedThumbnails(
    Set<String> validThumbnailPaths,
  ) async {
    var deletedCount = 0;
    
    try {
      final thumbnailsDir = await getThumbnailsDirectory();
      final files = await thumbnailsDir.list().toList();

      for (final entity in files) {
        if (entity is File) {
          if (!validThumbnailPaths.contains(entity.path)) {
            await entity.delete();
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

/// サムネイル生成リクエスト
class ThumbnailRequest {
  final String imageId;
  final String sourcePath;

  const ThumbnailRequest({
    required this.imageId,
    required this.sourcePath,
  });
}

/// サムネイル生成進捗
class ThumbnailProgress {
  final int current;
  final int total;
  final int succeeded;
  final int failed;
  final String lastImageId;
  final String? lastThumbnailPath;

  const ThumbnailProgress({
    required this.current,
    required this.total,
    required this.succeeded,
    required this.failed,
    required this.lastImageId,
    this.lastThumbnailPath,
  });

  double get progress => total > 0 ? current / total : 0;
  bool get isComplete => current >= total;
}
