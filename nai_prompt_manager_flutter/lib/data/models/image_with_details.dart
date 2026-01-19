import 'package:flutter/foundation.dart';
import 'image.dart';
import 'prompt.dart';
import 'tag.dart';

/// 画像（詳細情報付き）
@immutable
class ImageWithDetails extends ImageModel {
  final Prompt? prompt;
  final List<Tag> tags;
  final ImageRating? rating;

  const ImageWithDetails({
    required super.id,
    super.folderId,
    required super.filePath,
    super.thumbnailPath,
    super.filename,
    super.width,
    super.height,
    super.fileSize,
    super.fileHash,
    super.deletedAt,
    required super.createdAt,
    super.isNsfw,
    super.nsfwScore,
    super.nsfwCategory,
    super.clipEmbedding,
    this.prompt,
    this.tags = const [],
    this.rating,
  });

  @override
  ImageWithDetails copyWith({
    String? id,
    String? folderId,
    String? filePath,
    String? thumbnailPath,
    String? filename,
    int? width,
    int? height,
    int? fileSize,
    String? fileHash,
    DateTime? deletedAt,
    DateTime? createdAt,
    bool? isNsfw,
    double? nsfwScore,
    dynamic nsfwCategory,
    dynamic clipEmbedding,
    Prompt? prompt,
    List<Tag>? tags,
    ImageRating? rating,
  }) {
    return ImageWithDetails(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      filename: filename ?? this.filename,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      fileHash: fileHash ?? this.fileHash,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      isNsfw: isNsfw ?? this.isNsfw,
      nsfwScore: nsfwScore ?? this.nsfwScore,
      nsfwCategory: nsfwCategory ?? this.nsfwCategory,
      clipEmbedding: clipEmbedding ?? this.clipEmbedding,
      prompt: prompt ?? this.prompt,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
    );
  }

  factory ImageWithDetails.fromImageModel(
    ImageModel image, {
    Prompt? prompt,
    List<Tag> tags = const [],
    ImageRating? rating,
  }) {
    return ImageWithDetails(
      id: image.id,
      folderId: image.folderId,
      filePath: image.filePath,
      thumbnailPath: image.thumbnailPath,
      filename: image.filename,
      width: image.width,
      height: image.height,
      fileSize: image.fileSize,
      fileHash: image.fileHash,
      deletedAt: image.deletedAt,
      createdAt: image.createdAt,
      isNsfw: image.isNsfw,
      nsfwScore: image.nsfwScore,
      nsfwCategory: image.nsfwCategory,
      clipEmbedding: image.clipEmbedding,
      prompt: prompt,
      tags: tags,
      rating: rating,
    );
  }
}
