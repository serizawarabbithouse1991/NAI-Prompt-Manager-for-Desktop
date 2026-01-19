import 'package:flutter/foundation.dart';

/// フォルダモデル
@immutable
class Folder {
  final String id;
  final String? parentId;
  final String name;
  final String? color;
  final int sortOrder;
  final DateTime createdAt;

  const Folder({
    required this.id,
    this.parentId,
    required this.name,
    this.color,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Folder copyWith({
    String? id,
    String? parentId,
    String? name,
    String? color,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Folder(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name': name,
      'color': color,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String,
      color: json['color'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Folder &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// フォルダ（子フォルダ付き）
@immutable
class FolderWithChildren extends Folder {
  final List<FolderWithChildren> children;
  final int? imageCount;

  const FolderWithChildren({
    required super.id,
    super.parentId,
    required super.name,
    super.color,
    super.sortOrder,
    required super.createdAt,
    this.children = const [],
    this.imageCount,
  });

  @override
  FolderWithChildren copyWith({
    String? id,
    String? parentId,
    String? name,
    String? color,
    int? sortOrder,
    DateTime? createdAt,
    List<FolderWithChildren>? children,
    int? imageCount,
  }) {
    return FolderWithChildren(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      children: children ?? this.children,
      imageCount: imageCount ?? this.imageCount,
    );
  }

  factory FolderWithChildren.fromFolder(
    Folder folder, {
    List<FolderWithChildren> children = const [],
    int? imageCount,
  }) {
    return FolderWithChildren(
      id: folder.id,
      parentId: folder.parentId,
      name: folder.name,
      color: folder.color,
      sortOrder: folder.sortOrder,
      createdAt: folder.createdAt,
      children: children,
      imageCount: imageCount,
    );
  }
}
