import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'danbooru_service.dart';

/// タグ付けモード
enum TaggingMode {
  /// 全画像にタグ付け
  all,
  /// タグがない画像のみ
  untaggedOnly,
  /// 選択した画像のみ
  selected,
}

/// タグ付け進捗
class TaggingProgress {
  final int current;
  final int total;
  final String? currentImageName;
  final int tagsApplied;
  final int imagesTagged;
  final int imagesSkipped;
  final String? error;
  final bool isComplete;

  const TaggingProgress({
    required this.current,
    required this.total,
    this.currentImageName,
    this.tagsApplied = 0,
    this.imagesTagged = 0,
    this.imagesSkipped = 0,
    this.error,
    this.isComplete = false,
  });

  double get progress => total > 0 ? current / total : 0;

  TaggingProgress copyWith({
    int? current,
    int? total,
    String? currentImageName,
    int? tagsApplied,
    int? imagesTagged,
    int? imagesSkipped,
    String? error,
    bool? isComplete,
  }) {
    return TaggingProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      currentImageName: currentImageName ?? this.currentImageName,
      tagsApplied: tagsApplied ?? this.tagsApplied,
      imagesTagged: imagesTagged ?? this.imagesTagged,
      imagesSkipped: imagesSkipped ?? this.imagesSkipped,
      error: error ?? this.error,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// タグ付け結果
class TaggingResult {
  final int totalImages;
  final int imagesTagged;
  final int imagesSkipped;
  final int totalTagsApplied;
  final Duration duration;
  final List<String> errors;

  const TaggingResult({
    required this.totalImages,
    required this.imagesTagged,
    required this.imagesSkipped,
    required this.totalTagsApplied,
    required this.duration,
    this.errors = const [],
  });
}

/// Danbooruタグ付けサービス
class DanbooruTaggingService {
  final ImageRepository _imageRepository;
  final TagRepository _tagRepository;
  static const _uuid = Uuid();

  DanbooruTaggingService({
    required ImageRepository imageRepository,
    required TagRepository tagRepository,
  })  : _imageRepository = imageRepository,
        _tagRepository = tagRepository;

  /// MD5ハッシュを計算
  String _calculateMd5(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  /// 単一画像にDanbooruタグを付与
  Future<List<String>> tagImage(String imageId) async {
    final service = DanbooruService();
    if (!service.isConfigured) {
      return [];
    }

    try {
      // 画像情報を取得
      final image = await _imageRepository.getImageById(imageId);
      if (image == null) return [];

      final file = File(image.filePath);
      if (!await file.exists()) return [];

      // MD5を計算
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
      return [];
    }
  }

  /// 複数画像に一括でタグを付与（Stream版）
  Stream<TaggingProgress> tagImages({
    required TaggingMode mode,
    List<String>? selectedImageIds,
  }) async* {
    final service = DanbooruService();
    if (!service.isConfigured) {
      yield const TaggingProgress(
        current: 0,
        total: 0,
        error: 'Danbooru DBが設定されていません',
        isComplete: true,
      );
      return;
    }

    // 対象画像を取得
    List<ImageWithDetails> images;
    switch (mode) {
      case TaggingMode.all:
        final ids = await _imageRepository.getAllImageIds();
        images = await _imageRepository.getImagesByIds(ids);
        break;
      case TaggingMode.untaggedOnly:
        images = await _imageRepository.getImagesWithoutTags();
        break;
      case TaggingMode.selected:
        if (selectedImageIds == null || selectedImageIds.isEmpty) {
          yield const TaggingProgress(
            current: 0,
            total: 0,
            error: '画像が選択されていません',
            isComplete: true,
          );
          return;
        }
        images = await _imageRepository.getImagesByIds(selectedImageIds);
        break;
    }

    if (images.isEmpty) {
      yield const TaggingProgress(
        current: 0,
        total: 0,
        error: '対象の画像がありません',
        isComplete: true,
      );
      return;
    }

    final total = images.length;
    var current = 0;
    var tagsApplied = 0;
    var imagesTagged = 0;
    var imagesSkipped = 0;
    final errors = <String>[];

    for (final image in images) {
      current++;

      yield TaggingProgress(
        current: current,
        total: total,
        currentImageName: image.filename,
        tagsApplied: tagsApplied,
        imagesTagged: imagesTagged,
        imagesSkipped: imagesSkipped,
      );

      try {
        final tags = await tagImage(image.id);
        if (tags.isNotEmpty) {
          tagsApplied += tags.length;
          imagesTagged++;
        } else {
          imagesSkipped++;
        }
      } catch (e) {
        errors.add('${image.filename}: $e');
        imagesSkipped++;
      }

      // 少し間を空けてUIを更新させる
      await Future.delayed(const Duration(milliseconds: 10));
    }

    yield TaggingProgress(
      current: current,
      total: total,
      tagsApplied: tagsApplied,
      imagesTagged: imagesTagged,
      imagesSkipped: imagesSkipped,
      isComplete: true,
    );
  }

  /// 複数画像に一括でタグを付与（結果を返す版）
  Future<TaggingResult> tagImagesAndGetResult({
    required TaggingMode mode,
    List<String>? selectedImageIds,
  }) async {
    final startTime = DateTime.now();
    final errors = <String>[];

    var totalImages = 0;
    var imagesTagged = 0;
    var imagesSkipped = 0;
    var totalTagsApplied = 0;

    await for (final progress in tagImages(
      mode: mode,
      selectedImageIds: selectedImageIds,
    )) {
      if (progress.isComplete) {
        totalImages = progress.total;
        imagesTagged = progress.imagesTagged;
        imagesSkipped = progress.imagesSkipped;
        totalTagsApplied = progress.tagsApplied;
        if (progress.error != null) {
          errors.add(progress.error!);
        }
      }
    }

    return TaggingResult(
      totalImages: totalImages,
      imagesTagged: imagesTagged,
      imagesSkipped: imagesSkipped,
      totalTagsApplied: totalTagsApplied,
      duration: DateTime.now().difference(startTime),
      errors: errors,
    );
  }
}
