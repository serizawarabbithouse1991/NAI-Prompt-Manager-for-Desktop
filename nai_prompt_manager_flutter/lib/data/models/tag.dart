import 'package:flutter/foundation.dart';
import 'enums.dart';

/// タグモデル
@immutable
class Tag {
  final String id;
  final String name;
  final String? color;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    this.color,
    required this.createdAt,
  });

  Tag copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 画像タグ関連
@immutable
class ImageTag {
  final String imageId;
  final String tagId;

  const ImageTag({
    required this.imageId,
    required this.tagId,
  });

  Map<String, dynamic> toJson() {
    return {
      'image_id': imageId,
      'tag_id': tagId,
    };
  }

  factory ImageTag.fromJson(Map<String, dynamic> json) {
    return ImageTag(
      imageId: json['image_id'] as String,
      tagId: json['tag_id'] as String,
    );
  }
}

/// 画像評価
@immutable
class ImageRating {
  final String imageId;
  final bool isFavorite;
  final int? rating;

  const ImageRating({
    required this.imageId,
    this.isFavorite = false,
    this.rating,
  });

  ImageRating copyWith({
    String? imageId,
    bool? isFavorite,
    int? rating,
  }) {
    return ImageRating(
      imageId: imageId ?? this.imageId,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_id': imageId,
      'is_favorite': isFavorite ? 1 : 0,
      'rating': rating,
    };
  }

  factory ImageRating.fromJson(Map<String, dynamic> json) {
    return ImageRating(
      imageId: json['image_id'] as String,
      isFavorite: json['is_favorite'] == 1,
      rating: json['rating'] as int?,
    );
  }
}

/// Danbooruタグ情報
@immutable
class DanbooruTag {
  final int id;
  final String name;
  final DanbooruTagCategory category;
  final int postCount;

  const DanbooruTag({
    required this.id,
    required this.name,
    required this.category,
    required this.postCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.value,
      'post_count': postCount,
    };
  }

  factory DanbooruTag.fromJson(Map<String, dynamic> json) {
    return DanbooruTag(
      id: json['id'] as int,
      name: json['name'] as String,
      category: DanbooruTagCategory.fromString(json['category'] as String?) ??
          DanbooruTagCategory.general,
      postCount: json['post_count'] as int,
    );
  }
}

/// 処理済みタグ（自動タグ付け結果）
@immutable
class ProcessedTag {
  final String original;
  final String normalized;
  final DanbooruTagCategory? category;
  final int? postCount;

  const ProcessedTag({
    required this.original,
    required this.normalized,
    this.category,
    this.postCount,
  });
}

/// 自動タグ付け結果
@immutable
class AutoTagResult {
  final String imageId;
  final List<String> extractedTags;
  final List<ProcessedTag> normalizedTags;
  final int newTagsCreated;
  final int tagsAssigned;

  const AutoTagResult({
    required this.imageId,
    required this.extractedTags,
    required this.normalizedTags,
    required this.newTagsCreated,
    required this.tagsAssigned,
  });
}
