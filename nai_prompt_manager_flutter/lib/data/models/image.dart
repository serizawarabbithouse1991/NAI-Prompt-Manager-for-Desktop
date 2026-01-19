import 'package:flutter/foundation.dart';
import 'enums.dart';

/// 画像モデル
@immutable
class ImageModel {
  final String id;
  final String? folderId;
  final String filePath;
  final String? thumbnailPath;
  final String? filename;
  final int? width;
  final int? height;
  final int? fileSize;
  final String? fileHash;
  final DateTime? deletedAt;
  final DateTime createdAt;
  // NSFW detection fields
  final bool? isNsfw;
  final double? nsfwScore;
  final NSFWCategory? nsfwCategory;
  // CLIP embedding
  final Uint8List? clipEmbedding;

  const ImageModel({
    required this.id,
    this.folderId,
    required this.filePath,
    this.thumbnailPath,
    this.filename,
    this.width,
    this.height,
    this.fileSize,
    this.fileHash,
    this.deletedAt,
    required this.createdAt,
    this.isNsfw,
    this.nsfwScore,
    this.nsfwCategory,
    this.clipEmbedding,
  });

  ImageModel copyWith({
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
    NSFWCategory? nsfwCategory,
    Uint8List? clipEmbedding,
  }) {
    return ImageModel(
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folder_id': folderId,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'filename': filename,
      'width': width,
      'height': height,
      'file_size': fileSize,
      'file_hash': fileHash,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_nsfw': isNsfw == true ? 1 : 0,
      'nsfw_score': nsfwScore,
      'nsfw_category': nsfwCategory?.value,
      'clip_embedding': clipEmbedding,
    };
  }

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'] as String,
      folderId: json['folder_id'] as String?,
      filePath: json['file_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      filename: json['filename'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      fileSize: json['file_size'] as int?,
      fileHash: json['file_hash'] as String?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      isNsfw: json['is_nsfw'] == 1,
      nsfwScore: json['nsfw_score'] as double?,
      nsfwCategory: NSFWCategory.fromString(json['nsfw_category'] as String?),
      clipEmbedding: json['clip_embedding'] as Uint8List?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
