// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES folders (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    name,
    color,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
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
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Folder copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? name,
    Value<String?> color = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
  }) => Folder(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, parentId, name, color, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String?> color;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Folder> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? name,
    Value<String?>? color,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImagesTable extends Images with TableInfo<$ImagesTable, Image> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES folders (id)',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isNsfwMeta = const VerificationMeta('isNsfw');
  @override
  late final GeneratedColumn<bool> isNsfw = GeneratedColumn<bool>(
    'is_nsfw',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_nsfw" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nsfwScoreMeta = const VerificationMeta(
    'nsfwScore',
  );
  @override
  late final GeneratedColumn<double> nsfwScore = GeneratedColumn<double>(
    'nsfw_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nsfwCategoryMeta = const VerificationMeta(
    'nsfwCategory',
  );
  @override
  late final GeneratedColumn<String> nsfwCategory = GeneratedColumn<String>(
    'nsfw_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clipEmbeddingMeta = const VerificationMeta(
    'clipEmbedding',
  );
  @override
  late final GeneratedColumn<Uint8List> clipEmbedding =
      GeneratedColumn<Uint8List>(
        'clip_embedding',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    folderId,
    filePath,
    thumbnailPath,
    filename,
    width,
    height,
    fileSize,
    fileHash,
    deletedAt,
    createdAt,
    isNsfw,
    nsfwScore,
    nsfwCategory,
    clipEmbedding,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'images';
  @override
  VerificationContext validateIntegrity(
    Insertable<Image> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('is_nsfw')) {
      context.handle(
        _isNsfwMeta,
        isNsfw.isAcceptableOrUnknown(data['is_nsfw']!, _isNsfwMeta),
      );
    }
    if (data.containsKey('nsfw_score')) {
      context.handle(
        _nsfwScoreMeta,
        nsfwScore.isAcceptableOrUnknown(data['nsfw_score']!, _nsfwScoreMeta),
      );
    }
    if (data.containsKey('nsfw_category')) {
      context.handle(
        _nsfwCategoryMeta,
        nsfwCategory.isAcceptableOrUnknown(
          data['nsfw_category']!,
          _nsfwCategoryMeta,
        ),
      );
    }
    if (data.containsKey('clip_embedding')) {
      context.handle(
        _clipEmbeddingMeta,
        clipEmbedding.isAcceptableOrUnknown(
          data['clip_embedding']!,
          _clipEmbeddingMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Image map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Image(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isNsfw: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_nsfw'],
      )!,
      nsfwScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}nsfw_score'],
      ),
      nsfwCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nsfw_category'],
      ),
      clipEmbedding: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}clip_embedding'],
      ),
    );
  }

  @override
  $ImagesTable createAlias(String alias) {
    return $ImagesTable(attachedDatabase, alias);
  }
}

class Image extends DataClass implements Insertable<Image> {
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
  final bool isNsfw;
  final double? nsfwScore;
  final String? nsfwCategory;
  final Uint8List? clipEmbedding;
  const Image({
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
    required this.isNsfw,
    this.nsfwScore,
    this.nsfwCategory,
    this.clipEmbedding,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || filename != null) {
      map['filename'] = Variable<String>(filename);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || fileHash != null) {
      map['file_hash'] = Variable<String>(fileHash);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_nsfw'] = Variable<bool>(isNsfw);
    if (!nullToAbsent || nsfwScore != null) {
      map['nsfw_score'] = Variable<double>(nsfwScore);
    }
    if (!nullToAbsent || nsfwCategory != null) {
      map['nsfw_category'] = Variable<String>(nsfwCategory);
    }
    if (!nullToAbsent || clipEmbedding != null) {
      map['clip_embedding'] = Variable<Uint8List>(clipEmbedding);
    }
    return map;
  }

  ImagesCompanion toCompanion(bool nullToAbsent) {
    return ImagesCompanion(
      id: Value(id),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      filePath: Value(filePath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      filename: filename == null && nullToAbsent
          ? const Value.absent()
          : Value(filename),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      fileHash: fileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fileHash),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdAt: Value(createdAt),
      isNsfw: Value(isNsfw),
      nsfwScore: nsfwScore == null && nullToAbsent
          ? const Value.absent()
          : Value(nsfwScore),
      nsfwCategory: nsfwCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(nsfwCategory),
      clipEmbedding: clipEmbedding == null && nullToAbsent
          ? const Value.absent()
          : Value(clipEmbedding),
    );
  }

  factory Image.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Image(
      id: serializer.fromJson<String>(json['id']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      filename: serializer.fromJson<String?>(json['filename']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      fileHash: serializer.fromJson<String?>(json['fileHash']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isNsfw: serializer.fromJson<bool>(json['isNsfw']),
      nsfwScore: serializer.fromJson<double?>(json['nsfwScore']),
      nsfwCategory: serializer.fromJson<String?>(json['nsfwCategory']),
      clipEmbedding: serializer.fromJson<Uint8List?>(json['clipEmbedding']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'folderId': serializer.toJson<String?>(folderId),
      'filePath': serializer.toJson<String>(filePath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'filename': serializer.toJson<String?>(filename),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'fileSize': serializer.toJson<int?>(fileSize),
      'fileHash': serializer.toJson<String?>(fileHash),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isNsfw': serializer.toJson<bool>(isNsfw),
      'nsfwScore': serializer.toJson<double?>(nsfwScore),
      'nsfwCategory': serializer.toJson<String?>(nsfwCategory),
      'clipEmbedding': serializer.toJson<Uint8List?>(clipEmbedding),
    };
  }

  Image copyWith({
    String? id,
    Value<String?> folderId = const Value.absent(),
    String? filePath,
    Value<String?> thumbnailPath = const Value.absent(),
    Value<String?> filename = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    Value<String?> fileHash = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? createdAt,
    bool? isNsfw,
    Value<double?> nsfwScore = const Value.absent(),
    Value<String?> nsfwCategory = const Value.absent(),
    Value<Uint8List?> clipEmbedding = const Value.absent(),
  }) => Image(
    id: id ?? this.id,
    folderId: folderId.present ? folderId.value : this.folderId,
    filePath: filePath ?? this.filePath,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    filename: filename.present ? filename.value : this.filename,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    fileHash: fileHash.present ? fileHash.value : this.fileHash,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    isNsfw: isNsfw ?? this.isNsfw,
    nsfwScore: nsfwScore.present ? nsfwScore.value : this.nsfwScore,
    nsfwCategory: nsfwCategory.present ? nsfwCategory.value : this.nsfwCategory,
    clipEmbedding: clipEmbedding.present
        ? clipEmbedding.value
        : this.clipEmbedding,
  );
  Image copyWithCompanion(ImagesCompanion data) {
    return Image(
      id: data.id.present ? data.id.value : this.id,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      filename: data.filename.present ? data.filename.value : this.filename,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isNsfw: data.isNsfw.present ? data.isNsfw.value : this.isNsfw,
      nsfwScore: data.nsfwScore.present ? data.nsfwScore.value : this.nsfwScore,
      nsfwCategory: data.nsfwCategory.present
          ? data.nsfwCategory.value
          : this.nsfwCategory,
      clipEmbedding: data.clipEmbedding.present
          ? data.clipEmbedding.value
          : this.clipEmbedding,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Image(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('filename: $filename, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileHash: $fileHash, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('isNsfw: $isNsfw, ')
          ..write('nsfwScore: $nsfwScore, ')
          ..write('nsfwCategory: $nsfwCategory, ')
          ..write('clipEmbedding: $clipEmbedding')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    folderId,
    filePath,
    thumbnailPath,
    filename,
    width,
    height,
    fileSize,
    fileHash,
    deletedAt,
    createdAt,
    isNsfw,
    nsfwScore,
    nsfwCategory,
    $driftBlobEquality.hash(clipEmbedding),
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Image &&
          other.id == this.id &&
          other.folderId == this.folderId &&
          other.filePath == this.filePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.filename == this.filename &&
          other.width == this.width &&
          other.height == this.height &&
          other.fileSize == this.fileSize &&
          other.fileHash == this.fileHash &&
          other.deletedAt == this.deletedAt &&
          other.createdAt == this.createdAt &&
          other.isNsfw == this.isNsfw &&
          other.nsfwScore == this.nsfwScore &&
          other.nsfwCategory == this.nsfwCategory &&
          $driftBlobEquality.equals(other.clipEmbedding, this.clipEmbedding));
}

class ImagesCompanion extends UpdateCompanion<Image> {
  final Value<String> id;
  final Value<String?> folderId;
  final Value<String> filePath;
  final Value<String?> thumbnailPath;
  final Value<String?> filename;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> fileSize;
  final Value<String?> fileHash;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> createdAt;
  final Value<bool> isNsfw;
  final Value<double?> nsfwScore;
  final Value<String?> nsfwCategory;
  final Value<Uint8List?> clipEmbedding;
  final Value<int> rowid;
  const ImagesCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.filename = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isNsfw = const Value.absent(),
    this.nsfwScore = const Value.absent(),
    this.nsfwCategory = const Value.absent(),
    this.clipEmbedding = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImagesCompanion.insert({
    required String id,
    this.folderId = const Value.absent(),
    required String filePath,
    this.thumbnailPath = const Value.absent(),
    this.filename = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isNsfw = const Value.absent(),
    this.nsfwScore = const Value.absent(),
    this.nsfwCategory = const Value.absent(),
    this.clipEmbedding = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       filePath = Value(filePath);
  static Insertable<Image> custom({
    Expression<String>? id,
    Expression<String>? folderId,
    Expression<String>? filePath,
    Expression<String>? thumbnailPath,
    Expression<String>? filename,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? fileSize,
    Expression<String>? fileHash,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? createdAt,
    Expression<bool>? isNsfw,
    Expression<double>? nsfwScore,
    Expression<String>? nsfwCategory,
    Expression<Uint8List>? clipEmbedding,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderId != null) 'folder_id': folderId,
      if (filePath != null) 'file_path': filePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (filename != null) 'filename': filename,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (fileSize != null) 'file_size': fileSize,
      if (fileHash != null) 'file_hash': fileHash,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (isNsfw != null) 'is_nsfw': isNsfw,
      if (nsfwScore != null) 'nsfw_score': nsfwScore,
      if (nsfwCategory != null) 'nsfw_category': nsfwCategory,
      if (clipEmbedding != null) 'clip_embedding': clipEmbedding,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImagesCompanion copyWith({
    Value<String>? id,
    Value<String?>? folderId,
    Value<String>? filePath,
    Value<String?>? thumbnailPath,
    Value<String?>? filename,
    Value<int?>? width,
    Value<int?>? height,
    Value<int?>? fileSize,
    Value<String?>? fileHash,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? createdAt,
    Value<bool>? isNsfw,
    Value<double?>? nsfwScore,
    Value<String?>? nsfwCategory,
    Value<Uint8List?>? clipEmbedding,
    Value<int>? rowid,
  }) {
    return ImagesCompanion(
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
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isNsfw.present) {
      map['is_nsfw'] = Variable<bool>(isNsfw.value);
    }
    if (nsfwScore.present) {
      map['nsfw_score'] = Variable<double>(nsfwScore.value);
    }
    if (nsfwCategory.present) {
      map['nsfw_category'] = Variable<String>(nsfwCategory.value);
    }
    if (clipEmbedding.present) {
      map['clip_embedding'] = Variable<Uint8List>(clipEmbedding.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImagesCompanion(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('filename: $filename, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileHash: $fileHash, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('isNsfw: $isNsfw, ')
          ..write('nsfwScore: $nsfwScore, ')
          ..write('nsfwCategory: $nsfwCategory, ')
          ..write('clipEmbedding: $clipEmbedding, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PromptsTable extends Prompts with TableInfo<$PromptsTable, Prompt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PromptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageIdMeta = const VerificationMeta(
    'imageId',
  );
  @override
  late final GeneratedColumn<String> imageId = GeneratedColumn<String>(
    'image_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES images (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positivePromptMeta = const VerificationMeta(
    'positivePrompt',
  );
  @override
  late final GeneratedColumn<String> positivePrompt = GeneratedColumn<String>(
    'positive_prompt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _negativePromptMeta = const VerificationMeta(
    'negativePrompt',
  );
  @override
  late final GeneratedColumn<String> negativePrompt = GeneratedColumn<String>(
    'negative_prompt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _samplerMeta = const VerificationMeta(
    'sampler',
  );
  @override
  late final GeneratedColumn<String> sampler = GeneratedColumn<String>(
    'sampler',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cfgScaleMeta = const VerificationMeta(
    'cfgScale',
  );
  @override
  late final GeneratedColumn<double> cfgScale = GeneratedColumn<double>(
    'cfg_scale',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
    'seed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolutionWidthMeta = const VerificationMeta(
    'resolutionWidth',
  );
  @override
  late final GeneratedColumn<int> resolutionWidth = GeneratedColumn<int>(
    'resolution_width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolutionHeightMeta = const VerificationMeta(
    'resolutionHeight',
  );
  @override
  late final GeneratedColumn<int> resolutionHeight = GeneratedColumn<int>(
    'resolution_height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noiseScheduleMeta = const VerificationMeta(
    'noiseSchedule',
  );
  @override
  late final GeneratedColumn<String> noiseSchedule = GeneratedColumn<String>(
    'noise_schedule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promptGuidanceRescaleMeta =
      const VerificationMeta('promptGuidanceRescale');
  @override
  late final GeneratedColumn<double> promptGuidanceRescale =
      GeneratedColumn<double>(
        'prompt_guidance_rescale',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawMetadataMeta = const VerificationMeta(
    'rawMetadata',
  );
  @override
  late final GeneratedColumn<String> rawMetadata = GeneratedColumn<String>(
    'raw_metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _workflowJsonMeta = const VerificationMeta(
    'workflowJson',
  );
  @override
  late final GeneratedColumn<String> workflowJson = GeneratedColumn<String>(
    'workflow_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    imageId,
    positivePrompt,
    negativePrompt,
    model,
    sampler,
    steps,
    cfgScale,
    seed,
    resolutionWidth,
    resolutionHeight,
    noiseSchedule,
    promptGuidanceRescale,
    notes,
    rawMetadata,
    sourceType,
    workflowJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prompts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Prompt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('image_id')) {
      context.handle(
        _imageIdMeta,
        imageId.isAcceptableOrUnknown(data['image_id']!, _imageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_imageIdMeta);
    }
    if (data.containsKey('positive_prompt')) {
      context.handle(
        _positivePromptMeta,
        positivePrompt.isAcceptableOrUnknown(
          data['positive_prompt']!,
          _positivePromptMeta,
        ),
      );
    }
    if (data.containsKey('negative_prompt')) {
      context.handle(
        _negativePromptMeta,
        negativePrompt.isAcceptableOrUnknown(
          data['negative_prompt']!,
          _negativePromptMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('sampler')) {
      context.handle(
        _samplerMeta,
        sampler.isAcceptableOrUnknown(data['sampler']!, _samplerMeta),
      );
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    }
    if (data.containsKey('cfg_scale')) {
      context.handle(
        _cfgScaleMeta,
        cfgScale.isAcceptableOrUnknown(data['cfg_scale']!, _cfgScaleMeta),
      );
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    }
    if (data.containsKey('resolution_width')) {
      context.handle(
        _resolutionWidthMeta,
        resolutionWidth.isAcceptableOrUnknown(
          data['resolution_width']!,
          _resolutionWidthMeta,
        ),
      );
    }
    if (data.containsKey('resolution_height')) {
      context.handle(
        _resolutionHeightMeta,
        resolutionHeight.isAcceptableOrUnknown(
          data['resolution_height']!,
          _resolutionHeightMeta,
        ),
      );
    }
    if (data.containsKey('noise_schedule')) {
      context.handle(
        _noiseScheduleMeta,
        noiseSchedule.isAcceptableOrUnknown(
          data['noise_schedule']!,
          _noiseScheduleMeta,
        ),
      );
    }
    if (data.containsKey('prompt_guidance_rescale')) {
      context.handle(
        _promptGuidanceRescaleMeta,
        promptGuidanceRescale.isAcceptableOrUnknown(
          data['prompt_guidance_rescale']!,
          _promptGuidanceRescaleMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('raw_metadata')) {
      context.handle(
        _rawMetadataMeta,
        rawMetadata.isAcceptableOrUnknown(
          data['raw_metadata']!,
          _rawMetadataMeta,
        ),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('workflow_json')) {
      context.handle(
        _workflowJsonMeta,
        workflowJson.isAcceptableOrUnknown(
          data['workflow_json']!,
          _workflowJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prompt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prompt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      imageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_id'],
      )!,
      positivePrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}positive_prompt'],
      ),
      negativePrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}negative_prompt'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      sampler: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sampler'],
      ),
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      ),
      cfgScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cfg_scale'],
      ),
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed'],
      ),
      resolutionWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolution_width'],
      ),
      resolutionHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolution_height'],
      ),
      noiseSchedule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}noise_schedule'],
      ),
      promptGuidanceRescale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prompt_guidance_rescale'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      rawMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_metadata'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      workflowJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workflow_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PromptsTable createAlias(String alias) {
    return $PromptsTable(attachedDatabase, alias);
  }
}

class Prompt extends DataClass implements Insertable<Prompt> {
  final String id;
  final String imageId;
  final String? positivePrompt;
  final String? negativePrompt;
  final String? model;
  final String? sampler;
  final int? steps;
  final double? cfgScale;
  final int? seed;
  final int? resolutionWidth;
  final int? resolutionHeight;
  final String? noiseSchedule;
  final double? promptGuidanceRescale;
  final String? notes;
  final String? rawMetadata;
  final String sourceType;
  final String? workflowJson;
  final DateTime createdAt;
  const Prompt({
    required this.id,
    required this.imageId,
    this.positivePrompt,
    this.negativePrompt,
    this.model,
    this.sampler,
    this.steps,
    this.cfgScale,
    this.seed,
    this.resolutionWidth,
    this.resolutionHeight,
    this.noiseSchedule,
    this.promptGuidanceRescale,
    this.notes,
    this.rawMetadata,
    required this.sourceType,
    this.workflowJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['image_id'] = Variable<String>(imageId);
    if (!nullToAbsent || positivePrompt != null) {
      map['positive_prompt'] = Variable<String>(positivePrompt);
    }
    if (!nullToAbsent || negativePrompt != null) {
      map['negative_prompt'] = Variable<String>(negativePrompt);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || sampler != null) {
      map['sampler'] = Variable<String>(sampler);
    }
    if (!nullToAbsent || steps != null) {
      map['steps'] = Variable<int>(steps);
    }
    if (!nullToAbsent || cfgScale != null) {
      map['cfg_scale'] = Variable<double>(cfgScale);
    }
    if (!nullToAbsent || seed != null) {
      map['seed'] = Variable<int>(seed);
    }
    if (!nullToAbsent || resolutionWidth != null) {
      map['resolution_width'] = Variable<int>(resolutionWidth);
    }
    if (!nullToAbsent || resolutionHeight != null) {
      map['resolution_height'] = Variable<int>(resolutionHeight);
    }
    if (!nullToAbsent || noiseSchedule != null) {
      map['noise_schedule'] = Variable<String>(noiseSchedule);
    }
    if (!nullToAbsent || promptGuidanceRescale != null) {
      map['prompt_guidance_rescale'] = Variable<double>(promptGuidanceRescale);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || rawMetadata != null) {
      map['raw_metadata'] = Variable<String>(rawMetadata);
    }
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || workflowJson != null) {
      map['workflow_json'] = Variable<String>(workflowJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PromptsCompanion toCompanion(bool nullToAbsent) {
    return PromptsCompanion(
      id: Value(id),
      imageId: Value(imageId),
      positivePrompt: positivePrompt == null && nullToAbsent
          ? const Value.absent()
          : Value(positivePrompt),
      negativePrompt: negativePrompt == null && nullToAbsent
          ? const Value.absent()
          : Value(negativePrompt),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      sampler: sampler == null && nullToAbsent
          ? const Value.absent()
          : Value(sampler),
      steps: steps == null && nullToAbsent
          ? const Value.absent()
          : Value(steps),
      cfgScale: cfgScale == null && nullToAbsent
          ? const Value.absent()
          : Value(cfgScale),
      seed: seed == null && nullToAbsent ? const Value.absent() : Value(seed),
      resolutionWidth: resolutionWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionWidth),
      resolutionHeight: resolutionHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionHeight),
      noiseSchedule: noiseSchedule == null && nullToAbsent
          ? const Value.absent()
          : Value(noiseSchedule),
      promptGuidanceRescale: promptGuidanceRescale == null && nullToAbsent
          ? const Value.absent()
          : Value(promptGuidanceRescale),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      rawMetadata: rawMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(rawMetadata),
      sourceType: Value(sourceType),
      workflowJson: workflowJson == null && nullToAbsent
          ? const Value.absent()
          : Value(workflowJson),
      createdAt: Value(createdAt),
    );
  }

  factory Prompt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prompt(
      id: serializer.fromJson<String>(json['id']),
      imageId: serializer.fromJson<String>(json['imageId']),
      positivePrompt: serializer.fromJson<String?>(json['positivePrompt']),
      negativePrompt: serializer.fromJson<String?>(json['negativePrompt']),
      model: serializer.fromJson<String?>(json['model']),
      sampler: serializer.fromJson<String?>(json['sampler']),
      steps: serializer.fromJson<int?>(json['steps']),
      cfgScale: serializer.fromJson<double?>(json['cfgScale']),
      seed: serializer.fromJson<int?>(json['seed']),
      resolutionWidth: serializer.fromJson<int?>(json['resolutionWidth']),
      resolutionHeight: serializer.fromJson<int?>(json['resolutionHeight']),
      noiseSchedule: serializer.fromJson<String?>(json['noiseSchedule']),
      promptGuidanceRescale: serializer.fromJson<double?>(
        json['promptGuidanceRescale'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      rawMetadata: serializer.fromJson<String?>(json['rawMetadata']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      workflowJson: serializer.fromJson<String?>(json['workflowJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'imageId': serializer.toJson<String>(imageId),
      'positivePrompt': serializer.toJson<String?>(positivePrompt),
      'negativePrompt': serializer.toJson<String?>(negativePrompt),
      'model': serializer.toJson<String?>(model),
      'sampler': serializer.toJson<String?>(sampler),
      'steps': serializer.toJson<int?>(steps),
      'cfgScale': serializer.toJson<double?>(cfgScale),
      'seed': serializer.toJson<int?>(seed),
      'resolutionWidth': serializer.toJson<int?>(resolutionWidth),
      'resolutionHeight': serializer.toJson<int?>(resolutionHeight),
      'noiseSchedule': serializer.toJson<String?>(noiseSchedule),
      'promptGuidanceRescale': serializer.toJson<double?>(
        promptGuidanceRescale,
      ),
      'notes': serializer.toJson<String?>(notes),
      'rawMetadata': serializer.toJson<String?>(rawMetadata),
      'sourceType': serializer.toJson<String>(sourceType),
      'workflowJson': serializer.toJson<String?>(workflowJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Prompt copyWith({
    String? id,
    String? imageId,
    Value<String?> positivePrompt = const Value.absent(),
    Value<String?> negativePrompt = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<String?> sampler = const Value.absent(),
    Value<int?> steps = const Value.absent(),
    Value<double?> cfgScale = const Value.absent(),
    Value<int?> seed = const Value.absent(),
    Value<int?> resolutionWidth = const Value.absent(),
    Value<int?> resolutionHeight = const Value.absent(),
    Value<String?> noiseSchedule = const Value.absent(),
    Value<double?> promptGuidanceRescale = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> rawMetadata = const Value.absent(),
    String? sourceType,
    Value<String?> workflowJson = const Value.absent(),
    DateTime? createdAt,
  }) => Prompt(
    id: id ?? this.id,
    imageId: imageId ?? this.imageId,
    positivePrompt: positivePrompt.present
        ? positivePrompt.value
        : this.positivePrompt,
    negativePrompt: negativePrompt.present
        ? negativePrompt.value
        : this.negativePrompt,
    model: model.present ? model.value : this.model,
    sampler: sampler.present ? sampler.value : this.sampler,
    steps: steps.present ? steps.value : this.steps,
    cfgScale: cfgScale.present ? cfgScale.value : this.cfgScale,
    seed: seed.present ? seed.value : this.seed,
    resolutionWidth: resolutionWidth.present
        ? resolutionWidth.value
        : this.resolutionWidth,
    resolutionHeight: resolutionHeight.present
        ? resolutionHeight.value
        : this.resolutionHeight,
    noiseSchedule: noiseSchedule.present
        ? noiseSchedule.value
        : this.noiseSchedule,
    promptGuidanceRescale: promptGuidanceRescale.present
        ? promptGuidanceRescale.value
        : this.promptGuidanceRescale,
    notes: notes.present ? notes.value : this.notes,
    rawMetadata: rawMetadata.present ? rawMetadata.value : this.rawMetadata,
    sourceType: sourceType ?? this.sourceType,
    workflowJson: workflowJson.present ? workflowJson.value : this.workflowJson,
    createdAt: createdAt ?? this.createdAt,
  );
  Prompt copyWithCompanion(PromptsCompanion data) {
    return Prompt(
      id: data.id.present ? data.id.value : this.id,
      imageId: data.imageId.present ? data.imageId.value : this.imageId,
      positivePrompt: data.positivePrompt.present
          ? data.positivePrompt.value
          : this.positivePrompt,
      negativePrompt: data.negativePrompt.present
          ? data.negativePrompt.value
          : this.negativePrompt,
      model: data.model.present ? data.model.value : this.model,
      sampler: data.sampler.present ? data.sampler.value : this.sampler,
      steps: data.steps.present ? data.steps.value : this.steps,
      cfgScale: data.cfgScale.present ? data.cfgScale.value : this.cfgScale,
      seed: data.seed.present ? data.seed.value : this.seed,
      resolutionWidth: data.resolutionWidth.present
          ? data.resolutionWidth.value
          : this.resolutionWidth,
      resolutionHeight: data.resolutionHeight.present
          ? data.resolutionHeight.value
          : this.resolutionHeight,
      noiseSchedule: data.noiseSchedule.present
          ? data.noiseSchedule.value
          : this.noiseSchedule,
      promptGuidanceRescale: data.promptGuidanceRescale.present
          ? data.promptGuidanceRescale.value
          : this.promptGuidanceRescale,
      notes: data.notes.present ? data.notes.value : this.notes,
      rawMetadata: data.rawMetadata.present
          ? data.rawMetadata.value
          : this.rawMetadata,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      workflowJson: data.workflowJson.present
          ? data.workflowJson.value
          : this.workflowJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prompt(')
          ..write('id: $id, ')
          ..write('imageId: $imageId, ')
          ..write('positivePrompt: $positivePrompt, ')
          ..write('negativePrompt: $negativePrompt, ')
          ..write('model: $model, ')
          ..write('sampler: $sampler, ')
          ..write('steps: $steps, ')
          ..write('cfgScale: $cfgScale, ')
          ..write('seed: $seed, ')
          ..write('resolutionWidth: $resolutionWidth, ')
          ..write('resolutionHeight: $resolutionHeight, ')
          ..write('noiseSchedule: $noiseSchedule, ')
          ..write('promptGuidanceRescale: $promptGuidanceRescale, ')
          ..write('notes: $notes, ')
          ..write('rawMetadata: $rawMetadata, ')
          ..write('sourceType: $sourceType, ')
          ..write('workflowJson: $workflowJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    imageId,
    positivePrompt,
    negativePrompt,
    model,
    sampler,
    steps,
    cfgScale,
    seed,
    resolutionWidth,
    resolutionHeight,
    noiseSchedule,
    promptGuidanceRescale,
    notes,
    rawMetadata,
    sourceType,
    workflowJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prompt &&
          other.id == this.id &&
          other.imageId == this.imageId &&
          other.positivePrompt == this.positivePrompt &&
          other.negativePrompt == this.negativePrompt &&
          other.model == this.model &&
          other.sampler == this.sampler &&
          other.steps == this.steps &&
          other.cfgScale == this.cfgScale &&
          other.seed == this.seed &&
          other.resolutionWidth == this.resolutionWidth &&
          other.resolutionHeight == this.resolutionHeight &&
          other.noiseSchedule == this.noiseSchedule &&
          other.promptGuidanceRescale == this.promptGuidanceRescale &&
          other.notes == this.notes &&
          other.rawMetadata == this.rawMetadata &&
          other.sourceType == this.sourceType &&
          other.workflowJson == this.workflowJson &&
          other.createdAt == this.createdAt);
}

class PromptsCompanion extends UpdateCompanion<Prompt> {
  final Value<String> id;
  final Value<String> imageId;
  final Value<String?> positivePrompt;
  final Value<String?> negativePrompt;
  final Value<String?> model;
  final Value<String?> sampler;
  final Value<int?> steps;
  final Value<double?> cfgScale;
  final Value<int?> seed;
  final Value<int?> resolutionWidth;
  final Value<int?> resolutionHeight;
  final Value<String?> noiseSchedule;
  final Value<double?> promptGuidanceRescale;
  final Value<String?> notes;
  final Value<String?> rawMetadata;
  final Value<String> sourceType;
  final Value<String?> workflowJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PromptsCompanion({
    this.id = const Value.absent(),
    this.imageId = const Value.absent(),
    this.positivePrompt = const Value.absent(),
    this.negativePrompt = const Value.absent(),
    this.model = const Value.absent(),
    this.sampler = const Value.absent(),
    this.steps = const Value.absent(),
    this.cfgScale = const Value.absent(),
    this.seed = const Value.absent(),
    this.resolutionWidth = const Value.absent(),
    this.resolutionHeight = const Value.absent(),
    this.noiseSchedule = const Value.absent(),
    this.promptGuidanceRescale = const Value.absent(),
    this.notes = const Value.absent(),
    this.rawMetadata = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.workflowJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PromptsCompanion.insert({
    required String id,
    required String imageId,
    this.positivePrompt = const Value.absent(),
    this.negativePrompt = const Value.absent(),
    this.model = const Value.absent(),
    this.sampler = const Value.absent(),
    this.steps = const Value.absent(),
    this.cfgScale = const Value.absent(),
    this.seed = const Value.absent(),
    this.resolutionWidth = const Value.absent(),
    this.resolutionHeight = const Value.absent(),
    this.noiseSchedule = const Value.absent(),
    this.promptGuidanceRescale = const Value.absent(),
    this.notes = const Value.absent(),
    this.rawMetadata = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.workflowJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       imageId = Value(imageId);
  static Insertable<Prompt> custom({
    Expression<String>? id,
    Expression<String>? imageId,
    Expression<String>? positivePrompt,
    Expression<String>? negativePrompt,
    Expression<String>? model,
    Expression<String>? sampler,
    Expression<int>? steps,
    Expression<double>? cfgScale,
    Expression<int>? seed,
    Expression<int>? resolutionWidth,
    Expression<int>? resolutionHeight,
    Expression<String>? noiseSchedule,
    Expression<double>? promptGuidanceRescale,
    Expression<String>? notes,
    Expression<String>? rawMetadata,
    Expression<String>? sourceType,
    Expression<String>? workflowJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imageId != null) 'image_id': imageId,
      if (positivePrompt != null) 'positive_prompt': positivePrompt,
      if (negativePrompt != null) 'negative_prompt': negativePrompt,
      if (model != null) 'model': model,
      if (sampler != null) 'sampler': sampler,
      if (steps != null) 'steps': steps,
      if (cfgScale != null) 'cfg_scale': cfgScale,
      if (seed != null) 'seed': seed,
      if (resolutionWidth != null) 'resolution_width': resolutionWidth,
      if (resolutionHeight != null) 'resolution_height': resolutionHeight,
      if (noiseSchedule != null) 'noise_schedule': noiseSchedule,
      if (promptGuidanceRescale != null)
        'prompt_guidance_rescale': promptGuidanceRescale,
      if (notes != null) 'notes': notes,
      if (rawMetadata != null) 'raw_metadata': rawMetadata,
      if (sourceType != null) 'source_type': sourceType,
      if (workflowJson != null) 'workflow_json': workflowJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PromptsCompanion copyWith({
    Value<String>? id,
    Value<String>? imageId,
    Value<String?>? positivePrompt,
    Value<String?>? negativePrompt,
    Value<String?>? model,
    Value<String?>? sampler,
    Value<int?>? steps,
    Value<double?>? cfgScale,
    Value<int?>? seed,
    Value<int?>? resolutionWidth,
    Value<int?>? resolutionHeight,
    Value<String?>? noiseSchedule,
    Value<double?>? promptGuidanceRescale,
    Value<String?>? notes,
    Value<String?>? rawMetadata,
    Value<String>? sourceType,
    Value<String?>? workflowJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PromptsCompanion(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      positivePrompt: positivePrompt ?? this.positivePrompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      model: model ?? this.model,
      sampler: sampler ?? this.sampler,
      steps: steps ?? this.steps,
      cfgScale: cfgScale ?? this.cfgScale,
      seed: seed ?? this.seed,
      resolutionWidth: resolutionWidth ?? this.resolutionWidth,
      resolutionHeight: resolutionHeight ?? this.resolutionHeight,
      noiseSchedule: noiseSchedule ?? this.noiseSchedule,
      promptGuidanceRescale:
          promptGuidanceRescale ?? this.promptGuidanceRescale,
      notes: notes ?? this.notes,
      rawMetadata: rawMetadata ?? this.rawMetadata,
      sourceType: sourceType ?? this.sourceType,
      workflowJson: workflowJson ?? this.workflowJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (imageId.present) {
      map['image_id'] = Variable<String>(imageId.value);
    }
    if (positivePrompt.present) {
      map['positive_prompt'] = Variable<String>(positivePrompt.value);
    }
    if (negativePrompt.present) {
      map['negative_prompt'] = Variable<String>(negativePrompt.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (sampler.present) {
      map['sampler'] = Variable<String>(sampler.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (cfgScale.present) {
      map['cfg_scale'] = Variable<double>(cfgScale.value);
    }
    if (seed.present) {
      map['seed'] = Variable<int>(seed.value);
    }
    if (resolutionWidth.present) {
      map['resolution_width'] = Variable<int>(resolutionWidth.value);
    }
    if (resolutionHeight.present) {
      map['resolution_height'] = Variable<int>(resolutionHeight.value);
    }
    if (noiseSchedule.present) {
      map['noise_schedule'] = Variable<String>(noiseSchedule.value);
    }
    if (promptGuidanceRescale.present) {
      map['prompt_guidance_rescale'] = Variable<double>(
        promptGuidanceRescale.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rawMetadata.present) {
      map['raw_metadata'] = Variable<String>(rawMetadata.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (workflowJson.present) {
      map['workflow_json'] = Variable<String>(workflowJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PromptsCompanion(')
          ..write('id: $id, ')
          ..write('imageId: $imageId, ')
          ..write('positivePrompt: $positivePrompt, ')
          ..write('negativePrompt: $negativePrompt, ')
          ..write('model: $model, ')
          ..write('sampler: $sampler, ')
          ..write('steps: $steps, ')
          ..write('cfgScale: $cfgScale, ')
          ..write('seed: $seed, ')
          ..write('resolutionWidth: $resolutionWidth, ')
          ..write('resolutionHeight: $resolutionHeight, ')
          ..write('noiseSchedule: $noiseSchedule, ')
          ..write('promptGuidanceRescale: $promptGuidanceRescale, ')
          ..write('notes: $notes, ')
          ..write('rawMetadata: $rawMetadata, ')
          ..write('sourceType: $sourceType, ')
          ..write('workflowJson: $workflowJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: Value(createdAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    Value<String?> color = const Value.absent(),
    DateTime? createdAt,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    createdAt: createdAt ?? this.createdAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.createdAt == this.createdAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? color,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImageTagsTable extends ImageTags
    with TableInfo<$ImageTagsTable, ImageTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImageTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _imageIdMeta = const VerificationMeta(
    'imageId',
  );
  @override
  late final GeneratedColumn<String> imageId = GeneratedColumn<String>(
    'image_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES images (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [imageId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'image_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('image_id')) {
      context.handle(
        _imageIdMeta,
        imageId.isAcceptableOrUnknown(data['image_id']!, _imageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_imageIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {imageId, tagId};
  @override
  ImageTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageTag(
      imageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $ImageTagsTable createAlias(String alias) {
    return $ImageTagsTable(attachedDatabase, alias);
  }
}

class ImageTag extends DataClass implements Insertable<ImageTag> {
  final String imageId;
  final String tagId;
  const ImageTag({required this.imageId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['image_id'] = Variable<String>(imageId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  ImageTagsCompanion toCompanion(bool nullToAbsent) {
    return ImageTagsCompanion(imageId: Value(imageId), tagId: Value(tagId));
  }

  factory ImageTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageTag(
      imageId: serializer.fromJson<String>(json['imageId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'imageId': serializer.toJson<String>(imageId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  ImageTag copyWith({String? imageId, String? tagId}) =>
      ImageTag(imageId: imageId ?? this.imageId, tagId: tagId ?? this.tagId);
  ImageTag copyWithCompanion(ImageTagsCompanion data) {
    return ImageTag(
      imageId: data.imageId.present ? data.imageId.value : this.imageId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageTag(')
          ..write('imageId: $imageId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(imageId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageTag &&
          other.imageId == this.imageId &&
          other.tagId == this.tagId);
}

class ImageTagsCompanion extends UpdateCompanion<ImageTag> {
  final Value<String> imageId;
  final Value<String> tagId;
  final Value<int> rowid;
  const ImageTagsCompanion({
    this.imageId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImageTagsCompanion.insert({
    required String imageId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : imageId = Value(imageId),
       tagId = Value(tagId);
  static Insertable<ImageTag> custom({
    Expression<String>? imageId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (imageId != null) 'image_id': imageId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImageTagsCompanion copyWith({
    Value<String>? imageId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return ImageTagsCompanion(
      imageId: imageId ?? this.imageId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (imageId.present) {
      map['image_id'] = Variable<String>(imageId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageTagsCompanion(')
          ..write('imageId: $imageId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImageRatingsTable extends ImageRatings
    with TableInfo<$ImageRatingsTable, ImageRating> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImageRatingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _imageIdMeta = const VerificationMeta(
    'imageId',
  );
  @override
  late final GeneratedColumn<String> imageId = GeneratedColumn<String>(
    'image_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES images (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [imageId, isFavorite, rating];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'image_ratings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageRating> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('image_id')) {
      context.handle(
        _imageIdMeta,
        imageId.isAcceptableOrUnknown(data['image_id']!, _imageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_imageIdMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {imageId};
  @override
  ImageRating map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageRating(
      imageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_id'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
    );
  }

  @override
  $ImageRatingsTable createAlias(String alias) {
    return $ImageRatingsTable(attachedDatabase, alias);
  }
}

class ImageRating extends DataClass implements Insertable<ImageRating> {
  final String imageId;
  final bool isFavorite;
  final int? rating;
  const ImageRating({
    required this.imageId,
    required this.isFavorite,
    this.rating,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['image_id'] = Variable<String>(imageId);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    return map;
  }

  ImageRatingsCompanion toCompanion(bool nullToAbsent) {
    return ImageRatingsCompanion(
      imageId: Value(imageId),
      isFavorite: Value(isFavorite),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
    );
  }

  factory ImageRating.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageRating(
      imageId: serializer.fromJson<String>(json['imageId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      rating: serializer.fromJson<int?>(json['rating']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'imageId': serializer.toJson<String>(imageId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'rating': serializer.toJson<int?>(rating),
    };
  }

  ImageRating copyWith({
    String? imageId,
    bool? isFavorite,
    Value<int?> rating = const Value.absent(),
  }) => ImageRating(
    imageId: imageId ?? this.imageId,
    isFavorite: isFavorite ?? this.isFavorite,
    rating: rating.present ? rating.value : this.rating,
  );
  ImageRating copyWithCompanion(ImageRatingsCompanion data) {
    return ImageRating(
      imageId: data.imageId.present ? data.imageId.value : this.imageId,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      rating: data.rating.present ? data.rating.value : this.rating,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageRating(')
          ..write('imageId: $imageId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rating: $rating')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(imageId, isFavorite, rating);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageRating &&
          other.imageId == this.imageId &&
          other.isFavorite == this.isFavorite &&
          other.rating == this.rating);
}

class ImageRatingsCompanion extends UpdateCompanion<ImageRating> {
  final Value<String> imageId;
  final Value<bool> isFavorite;
  final Value<int?> rating;
  final Value<int> rowid;
  const ImageRatingsCompanion({
    this.imageId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rating = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImageRatingsCompanion.insert({
    required String imageId,
    this.isFavorite = const Value.absent(),
    this.rating = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : imageId = Value(imageId);
  static Insertable<ImageRating> custom({
    Expression<String>? imageId,
    Expression<bool>? isFavorite,
    Expression<int>? rating,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (imageId != null) 'image_id': imageId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rating != null) 'rating': rating,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImageRatingsCompanion copyWith({
    Value<String>? imageId,
    Value<bool>? isFavorite,
    Value<int?>? rating,
    Value<int>? rowid,
  }) {
    return ImageRatingsCompanion(
      imageId: imageId ?? this.imageId,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (imageId.present) {
      map['image_id'] = Variable<String>(imageId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageRatingsCompanion(')
          ..write('imageId: $imageId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rating: $rating, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String? value;
  const Setting({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  Setting copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => Setting(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $ImagesTable images = $ImagesTable(this);
  late final $PromptsTable prompts = $PromptsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $ImageTagsTable imageTags = $ImageTagsTable(this);
  late final $ImageRatingsTable imageRatings = $ImageRatingsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    folders,
    images,
    prompts,
    tags,
    imageTags,
    imageRatings,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'images',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('prompts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'images',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('image_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('image_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'images',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('image_ratings', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FoldersTableCreateCompanionBuilder =
    FoldersCompanion Function({
      required String id,
      Value<String?> parentId,
      required String name,
      Value<String?> color,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$FoldersTableUpdateCompanionBuilder =
    FoldersCompanion Function({
      Value<String> id,
      Value<String?> parentId,
      Value<String> name,
      Value<String?> color,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$FoldersTableReferences
    extends BaseReferences<_$AppDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _parentIdTable(_$AppDatabase db) => db.folders
      .createAlias($_aliasNameGenerator(db.folders.parentId, db.folders.id));

  $$FoldersTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ImagesTable, List<Image>> _imagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.images,
    aliasName: $_aliasNameGenerator(db.folders.id, db.images.folderId),
  );

  $$ImagesTableProcessedTableManager get imagesRefs {
    final manager = $$ImagesTableTableManager(
      $_db,
      $_db.images,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_imagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FoldersTableFilterComposer get parentId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> imagesRefs(
    Expression<bool> Function($$ImagesTableFilterComposer f) f,
  ) {
    final $$ImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableFilterComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoldersTableOrderingComposer get parentId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FoldersTableAnnotationComposer get parentId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> imagesRefs<T extends Object>(
    Expression<T> Function($$ImagesTableAnnotationComposer a) f,
  ) {
    final $$ImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, $$FoldersTableReferences),
          Folder,
          PrefetchHooks Function({bool parentId, bool imagesRefs})
        > {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                parentId: parentId,
                name: name,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String name,
                Value<String?> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                parentId: parentId,
                name: name,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false, imagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (imagesRefs) db.images],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (parentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.parentId,
                                referencedTable: $$FoldersTableReferences
                                    ._parentIdTable(db),
                                referencedColumn: $$FoldersTableReferences
                                    ._parentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (imagesRefs)
                    await $_getPrefetchedData<Folder, $FoldersTable, Image>(
                      currentTable: table,
                      referencedTable: $$FoldersTableReferences
                          ._imagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FoldersTableReferences(db, table, p0).imagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, $$FoldersTableReferences),
      Folder,
      PrefetchHooks Function({bool parentId, bool imagesRefs})
    >;
typedef $$ImagesTableCreateCompanionBuilder =
    ImagesCompanion Function({
      required String id,
      Value<String?> folderId,
      required String filePath,
      Value<String?> thumbnailPath,
      Value<String?> filename,
      Value<int?> width,
      Value<int?> height,
      Value<int?> fileSize,
      Value<String?> fileHash,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<bool> isNsfw,
      Value<double?> nsfwScore,
      Value<String?> nsfwCategory,
      Value<Uint8List?> clipEmbedding,
      Value<int> rowid,
    });
typedef $$ImagesTableUpdateCompanionBuilder =
    ImagesCompanion Function({
      Value<String> id,
      Value<String?> folderId,
      Value<String> filePath,
      Value<String?> thumbnailPath,
      Value<String?> filename,
      Value<int?> width,
      Value<int?> height,
      Value<int?> fileSize,
      Value<String?> fileHash,
      Value<DateTime?> deletedAt,
      Value<DateTime> createdAt,
      Value<bool> isNsfw,
      Value<double?> nsfwScore,
      Value<String?> nsfwCategory,
      Value<Uint8List?> clipEmbedding,
      Value<int> rowid,
    });

final class $$ImagesTableReferences
    extends BaseReferences<_$AppDatabase, $ImagesTable, Image> {
  $$ImagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _folderIdTable(_$AppDatabase db) => db.folders
      .createAlias($_aliasNameGenerator(db.images.folderId, db.folders.id));

  $$FoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<String>('folder_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PromptsTable, List<Prompt>> _promptsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.prompts,
    aliasName: $_aliasNameGenerator(db.images.id, db.prompts.imageId),
  );

  $$PromptsTableProcessedTableManager get promptsRefs {
    final manager = $$PromptsTableTableManager(
      $_db,
      $_db.prompts,
    ).filter((f) => f.imageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_promptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ImageTagsTable, List<ImageTag>>
  _imageTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.imageTags,
    aliasName: $_aliasNameGenerator(db.images.id, db.imageTags.imageId),
  );

  $$ImageTagsTableProcessedTableManager get imageTagsRefs {
    final manager = $$ImageTagsTableTableManager(
      $_db,
      $_db.imageTags,
    ).filter((f) => f.imageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_imageTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ImageRatingsTable, List<ImageRating>>
  _imageRatingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.imageRatings,
    aliasName: $_aliasNameGenerator(db.images.id, db.imageRatings.imageId),
  );

  $$ImageRatingsTableProcessedTableManager get imageRatingsRefs {
    final manager = $$ImageRatingsTableTableManager(
      $_db,
      $_db.imageRatings,
    ).filter((f) => f.imageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_imageRatingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNsfw => $composableBuilder(
    column: $table.isNsfw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get nsfwScore => $composableBuilder(
    column: $table.nsfwScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nsfwCategory => $composableBuilder(
    column: $table.nsfwCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get clipEmbedding => $composableBuilder(
    column: $table.clipEmbedding,
    builder: (column) => ColumnFilters(column),
  );

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> promptsRefs(
    Expression<bool> Function($$PromptsTableFilterComposer f) f,
  ) {
    final $$PromptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.imageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableFilterComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> imageTagsRefs(
    Expression<bool> Function($$ImageTagsTableFilterComposer f) f,
  ) {
    final $$ImageTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageTags,
      getReferencedColumn: (t) => t.imageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageTagsTableFilterComposer(
            $db: $db,
            $table: $db.imageTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> imageRatingsRefs(
    Expression<bool> Function($$ImageRatingsTableFilterComposer f) f,
  ) {
    final $$ImageRatingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageRatings,
      getReferencedColumn: (t) => t.imageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageRatingsTableFilterComposer(
            $db: $db,
            $table: $db.imageRatings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNsfw => $composableBuilder(
    column: $table.isNsfw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get nsfwScore => $composableBuilder(
    column: $table.nsfwScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nsfwCategory => $composableBuilder(
    column: $table.nsfwCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get clipEmbedding => $composableBuilder(
    column: $table.clipEmbedding,
    builder: (column) => ColumnOrderings(column),
  );

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isNsfw =>
      $composableBuilder(column: $table.isNsfw, builder: (column) => column);

  GeneratedColumn<double> get nsfwScore =>
      $composableBuilder(column: $table.nsfwScore, builder: (column) => column);

  GeneratedColumn<String> get nsfwCategory => $composableBuilder(
    column: $table.nsfwCategory,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get clipEmbedding => $composableBuilder(
    column: $table.clipEmbedding,
    builder: (column) => column,
  );

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> promptsRefs<T extends Object>(
    Expression<T> Function($$PromptsTableAnnotationComposer a) f,
  ) {
    final $$PromptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prompts,
      getReferencedColumn: (t) => t.imageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PromptsTableAnnotationComposer(
            $db: $db,
            $table: $db.prompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> imageTagsRefs<T extends Object>(
    Expression<T> Function($$ImageTagsTableAnnotationComposer a) f,
  ) {
    final $$ImageTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageTags,
      getReferencedColumn: (t) => t.imageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.imageTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> imageRatingsRefs<T extends Object>(
    Expression<T> Function($$ImageRatingsTableAnnotationComposer a) f,
  ) {
    final $$ImageRatingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageRatings,
      getReferencedColumn: (t) => t.imageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageRatingsTableAnnotationComposer(
            $db: $db,
            $table: $db.imageRatings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImagesTable,
          Image,
          $$ImagesTableFilterComposer,
          $$ImagesTableOrderingComposer,
          $$ImagesTableAnnotationComposer,
          $$ImagesTableCreateCompanionBuilder,
          $$ImagesTableUpdateCompanionBuilder,
          (Image, $$ImagesTableReferences),
          Image,
          PrefetchHooks Function({
            bool folderId,
            bool promptsRefs,
            bool imageTagsRefs,
            bool imageRatingsRefs,
          })
        > {
  $$ImagesTableTableManager(_$AppDatabase db, $ImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> filename = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isNsfw = const Value.absent(),
                Value<double?> nsfwScore = const Value.absent(),
                Value<String?> nsfwCategory = const Value.absent(),
                Value<Uint8List?> clipEmbedding = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion(
                id: id,
                folderId: folderId,
                filePath: filePath,
                thumbnailPath: thumbnailPath,
                filename: filename,
                width: width,
                height: height,
                fileSize: fileSize,
                fileHash: fileHash,
                deletedAt: deletedAt,
                createdAt: createdAt,
                isNsfw: isNsfw,
                nsfwScore: nsfwScore,
                nsfwCategory: nsfwCategory,
                clipEmbedding: clipEmbedding,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> folderId = const Value.absent(),
                required String filePath,
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> filename = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isNsfw = const Value.absent(),
                Value<double?> nsfwScore = const Value.absent(),
                Value<String?> nsfwCategory = const Value.absent(),
                Value<Uint8List?> clipEmbedding = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion.insert(
                id: id,
                folderId: folderId,
                filePath: filePath,
                thumbnailPath: thumbnailPath,
                filename: filename,
                width: width,
                height: height,
                fileSize: fileSize,
                fileHash: fileHash,
                deletedAt: deletedAt,
                createdAt: createdAt,
                isNsfw: isNsfw,
                nsfwScore: nsfwScore,
                nsfwCategory: nsfwCategory,
                clipEmbedding: clipEmbedding,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ImagesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                folderId = false,
                promptsRefs = false,
                imageTagsRefs = false,
                imageRatingsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (promptsRefs) db.prompts,
                    if (imageTagsRefs) db.imageTags,
                    if (imageRatingsRefs) db.imageRatings,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (folderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.folderId,
                                    referencedTable: $$ImagesTableReferences
                                        ._folderIdTable(db),
                                    referencedColumn: $$ImagesTableReferences
                                        ._folderIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (promptsRefs)
                        await $_getPrefetchedData<Image, $ImagesTable, Prompt>(
                          currentTable: table,
                          referencedTable: $$ImagesTableReferences
                              ._promptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ImagesTableReferences(
                                db,
                                table,
                                p0,
                              ).promptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.imageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (imageTagsRefs)
                        await $_getPrefetchedData<
                          Image,
                          $ImagesTable,
                          ImageTag
                        >(
                          currentTable: table,
                          referencedTable: $$ImagesTableReferences
                              ._imageTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ImagesTableReferences(
                                db,
                                table,
                                p0,
                              ).imageTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.imageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (imageRatingsRefs)
                        await $_getPrefetchedData<
                          Image,
                          $ImagesTable,
                          ImageRating
                        >(
                          currentTable: table,
                          referencedTable: $$ImagesTableReferences
                              ._imageRatingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ImagesTableReferences(
                                db,
                                table,
                                p0,
                              ).imageRatingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.imageId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImagesTable,
      Image,
      $$ImagesTableFilterComposer,
      $$ImagesTableOrderingComposer,
      $$ImagesTableAnnotationComposer,
      $$ImagesTableCreateCompanionBuilder,
      $$ImagesTableUpdateCompanionBuilder,
      (Image, $$ImagesTableReferences),
      Image,
      PrefetchHooks Function({
        bool folderId,
        bool promptsRefs,
        bool imageTagsRefs,
        bool imageRatingsRefs,
      })
    >;
typedef $$PromptsTableCreateCompanionBuilder =
    PromptsCompanion Function({
      required String id,
      required String imageId,
      Value<String?> positivePrompt,
      Value<String?> negativePrompt,
      Value<String?> model,
      Value<String?> sampler,
      Value<int?> steps,
      Value<double?> cfgScale,
      Value<int?> seed,
      Value<int?> resolutionWidth,
      Value<int?> resolutionHeight,
      Value<String?> noiseSchedule,
      Value<double?> promptGuidanceRescale,
      Value<String?> notes,
      Value<String?> rawMetadata,
      Value<String> sourceType,
      Value<String?> workflowJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$PromptsTableUpdateCompanionBuilder =
    PromptsCompanion Function({
      Value<String> id,
      Value<String> imageId,
      Value<String?> positivePrompt,
      Value<String?> negativePrompt,
      Value<String?> model,
      Value<String?> sampler,
      Value<int?> steps,
      Value<double?> cfgScale,
      Value<int?> seed,
      Value<int?> resolutionWidth,
      Value<int?> resolutionHeight,
      Value<String?> noiseSchedule,
      Value<double?> promptGuidanceRescale,
      Value<String?> notes,
      Value<String?> rawMetadata,
      Value<String> sourceType,
      Value<String?> workflowJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PromptsTableReferences
    extends BaseReferences<_$AppDatabase, $PromptsTable, Prompt> {
  $$PromptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ImagesTable _imageIdTable(_$AppDatabase db) => db.images.createAlias(
    $_aliasNameGenerator(db.prompts.imageId, db.images.id),
  );

  $$ImagesTableProcessedTableManager get imageId {
    final $_column = $_itemColumn<String>('image_id')!;

    final manager = $$ImagesTableTableManager(
      $_db,
      $_db.images,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_imageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PromptsTableFilterComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get positivePrompt => $composableBuilder(
    column: $table.positivePrompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get negativePrompt => $composableBuilder(
    column: $table.negativePrompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sampler => $composableBuilder(
    column: $table.sampler,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cfgScale => $composableBuilder(
    column: $table.cfgScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resolutionWidth => $composableBuilder(
    column: $table.resolutionWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resolutionHeight => $composableBuilder(
    column: $table.resolutionHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noiseSchedule => $composableBuilder(
    column: $table.noiseSchedule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get promptGuidanceRescale => $composableBuilder(
    column: $table.promptGuidanceRescale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawMetadata => $composableBuilder(
    column: $table.rawMetadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workflowJson => $composableBuilder(
    column: $table.workflowJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ImagesTableFilterComposer get imageId {
    final $$ImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableFilterComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromptsTableOrderingComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get positivePrompt => $composableBuilder(
    column: $table.positivePrompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get negativePrompt => $composableBuilder(
    column: $table.negativePrompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sampler => $composableBuilder(
    column: $table.sampler,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cfgScale => $composableBuilder(
    column: $table.cfgScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resolutionWidth => $composableBuilder(
    column: $table.resolutionWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resolutionHeight => $composableBuilder(
    column: $table.resolutionHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noiseSchedule => $composableBuilder(
    column: $table.noiseSchedule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get promptGuidanceRescale => $composableBuilder(
    column: $table.promptGuidanceRescale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawMetadata => $composableBuilder(
    column: $table.rawMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workflowJson => $composableBuilder(
    column: $table.workflowJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ImagesTableOrderingComposer get imageId {
    final $$ImagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableOrderingComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PromptsTable> {
  $$PromptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get positivePrompt => $composableBuilder(
    column: $table.positivePrompt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get negativePrompt => $composableBuilder(
    column: $table.negativePrompt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get sampler =>
      $composableBuilder(column: $table.sampler, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<double> get cfgScale =>
      $composableBuilder(column: $table.cfgScale, builder: (column) => column);

  GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);

  GeneratedColumn<int> get resolutionWidth => $composableBuilder(
    column: $table.resolutionWidth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get resolutionHeight => $composableBuilder(
    column: $table.resolutionHeight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get noiseSchedule => $composableBuilder(
    column: $table.noiseSchedule,
    builder: (column) => column,
  );

  GeneratedColumn<double> get promptGuidanceRescale => $composableBuilder(
    column: $table.promptGuidanceRescale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get rawMetadata => $composableBuilder(
    column: $table.rawMetadata,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workflowJson => $composableBuilder(
    column: $table.workflowJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ImagesTableAnnotationComposer get imageId {
    final $$ImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PromptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PromptsTable,
          Prompt,
          $$PromptsTableFilterComposer,
          $$PromptsTableOrderingComposer,
          $$PromptsTableAnnotationComposer,
          $$PromptsTableCreateCompanionBuilder,
          $$PromptsTableUpdateCompanionBuilder,
          (Prompt, $$PromptsTableReferences),
          Prompt,
          PrefetchHooks Function({bool imageId})
        > {
  $$PromptsTableTableManager(_$AppDatabase db, $PromptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PromptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PromptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PromptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> imageId = const Value.absent(),
                Value<String?> positivePrompt = const Value.absent(),
                Value<String?> negativePrompt = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> sampler = const Value.absent(),
                Value<int?> steps = const Value.absent(),
                Value<double?> cfgScale = const Value.absent(),
                Value<int?> seed = const Value.absent(),
                Value<int?> resolutionWidth = const Value.absent(),
                Value<int?> resolutionHeight = const Value.absent(),
                Value<String?> noiseSchedule = const Value.absent(),
                Value<double?> promptGuidanceRescale = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> rawMetadata = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> workflowJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromptsCompanion(
                id: id,
                imageId: imageId,
                positivePrompt: positivePrompt,
                negativePrompt: negativePrompt,
                model: model,
                sampler: sampler,
                steps: steps,
                cfgScale: cfgScale,
                seed: seed,
                resolutionWidth: resolutionWidth,
                resolutionHeight: resolutionHeight,
                noiseSchedule: noiseSchedule,
                promptGuidanceRescale: promptGuidanceRescale,
                notes: notes,
                rawMetadata: rawMetadata,
                sourceType: sourceType,
                workflowJson: workflowJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String imageId,
                Value<String?> positivePrompt = const Value.absent(),
                Value<String?> negativePrompt = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> sampler = const Value.absent(),
                Value<int?> steps = const Value.absent(),
                Value<double?> cfgScale = const Value.absent(),
                Value<int?> seed = const Value.absent(),
                Value<int?> resolutionWidth = const Value.absent(),
                Value<int?> resolutionHeight = const Value.absent(),
                Value<String?> noiseSchedule = const Value.absent(),
                Value<double?> promptGuidanceRescale = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> rawMetadata = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> workflowJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PromptsCompanion.insert(
                id: id,
                imageId: imageId,
                positivePrompt: positivePrompt,
                negativePrompt: negativePrompt,
                model: model,
                sampler: sampler,
                steps: steps,
                cfgScale: cfgScale,
                seed: seed,
                resolutionWidth: resolutionWidth,
                resolutionHeight: resolutionHeight,
                noiseSchedule: noiseSchedule,
                promptGuidanceRescale: promptGuidanceRescale,
                notes: notes,
                rawMetadata: rawMetadata,
                sourceType: sourceType,
                workflowJson: workflowJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PromptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({imageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (imageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.imageId,
                                referencedTable: $$PromptsTableReferences
                                    ._imageIdTable(db),
                                referencedColumn: $$PromptsTableReferences
                                    ._imageIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PromptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PromptsTable,
      Prompt,
      $$PromptsTableFilterComposer,
      $$PromptsTableOrderingComposer,
      $$PromptsTableAnnotationComposer,
      $$PromptsTableCreateCompanionBuilder,
      $$PromptsTableUpdateCompanionBuilder,
      (Prompt, $$PromptsTableReferences),
      Prompt,
      PrefetchHooks Function({bool imageId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      Value<String?> color,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> color,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ImageTagsTable, List<ImageTag>>
  _imageTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.imageTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.imageTags.tagId),
  );

  $$ImageTagsTableProcessedTableManager get imageTagsRefs {
    final manager = $$ImageTagsTableTableManager(
      $_db,
      $_db.imageTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_imageTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> imageTagsRefs(
    Expression<bool> Function($$ImageTagsTableFilterComposer f) f,
  ) {
    final $$ImageTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageTagsTableFilterComposer(
            $db: $db,
            $table: $db.imageTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> imageTagsRefs<T extends Object>(
    Expression<T> Function($$ImageTagsTableAnnotationComposer a) f,
  ) {
    final $$ImageTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.imageTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImageTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.imageTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool imageTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                color: color,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({imageTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (imageTagsRefs) db.imageTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (imageTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, ImageTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._imageTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).imageTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool imageTagsRefs})
    >;
typedef $$ImageTagsTableCreateCompanionBuilder =
    ImageTagsCompanion Function({
      required String imageId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$ImageTagsTableUpdateCompanionBuilder =
    ImageTagsCompanion Function({
      Value<String> imageId,
      Value<String> tagId,
      Value<int> rowid,
    });

final class $$ImageTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ImageTagsTable, ImageTag> {
  $$ImageTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ImagesTable _imageIdTable(_$AppDatabase db) => db.images.createAlias(
    $_aliasNameGenerator(db.imageTags.imageId, db.images.id),
  );

  $$ImagesTableProcessedTableManager get imageId {
    final $_column = $_itemColumn<String>('image_id')!;

    final manager = $$ImagesTableTableManager(
      $_db,
      $_db.images,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_imageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.imageTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImageTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ImageTagsTable> {
  $$ImageTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ImagesTableFilterComposer get imageId {
    final $$ImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableFilterComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImageTagsTable> {
  $$ImageTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ImagesTableOrderingComposer get imageId {
    final $$ImagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableOrderingComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImageTagsTable> {
  $$ImageTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ImagesTableAnnotationComposer get imageId {
    final $$ImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImageTagsTable,
          ImageTag,
          $$ImageTagsTableFilterComposer,
          $$ImageTagsTableOrderingComposer,
          $$ImageTagsTableAnnotationComposer,
          $$ImageTagsTableCreateCompanionBuilder,
          $$ImageTagsTableUpdateCompanionBuilder,
          (ImageTag, $$ImageTagsTableReferences),
          ImageTag,
          PrefetchHooks Function({bool imageId, bool tagId})
        > {
  $$ImageTagsTableTableManager(_$AppDatabase db, $ImageTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImageTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImageTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImageTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> imageId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageTagsCompanion(
                imageId: imageId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String imageId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => ImageTagsCompanion.insert(
                imageId: imageId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImageTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({imageId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (imageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.imageId,
                                referencedTable: $$ImageTagsTableReferences
                                    ._imageIdTable(db),
                                referencedColumn: $$ImageTagsTableReferences
                                    ._imageIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$ImageTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$ImageTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImageTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImageTagsTable,
      ImageTag,
      $$ImageTagsTableFilterComposer,
      $$ImageTagsTableOrderingComposer,
      $$ImageTagsTableAnnotationComposer,
      $$ImageTagsTableCreateCompanionBuilder,
      $$ImageTagsTableUpdateCompanionBuilder,
      (ImageTag, $$ImageTagsTableReferences),
      ImageTag,
      PrefetchHooks Function({bool imageId, bool tagId})
    >;
typedef $$ImageRatingsTableCreateCompanionBuilder =
    ImageRatingsCompanion Function({
      required String imageId,
      Value<bool> isFavorite,
      Value<int?> rating,
      Value<int> rowid,
    });
typedef $$ImageRatingsTableUpdateCompanionBuilder =
    ImageRatingsCompanion Function({
      Value<String> imageId,
      Value<bool> isFavorite,
      Value<int?> rating,
      Value<int> rowid,
    });

final class $$ImageRatingsTableReferences
    extends BaseReferences<_$AppDatabase, $ImageRatingsTable, ImageRating> {
  $$ImageRatingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ImagesTable _imageIdTable(_$AppDatabase db) => db.images.createAlias(
    $_aliasNameGenerator(db.imageRatings.imageId, db.images.id),
  );

  $$ImagesTableProcessedTableManager get imageId {
    final $_column = $_itemColumn<String>('image_id')!;

    final manager = $$ImagesTableTableManager(
      $_db,
      $_db.images,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_imageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImageRatingsTableFilterComposer
    extends Composer<_$AppDatabase, $ImageRatingsTable> {
  $$ImageRatingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  $$ImagesTableFilterComposer get imageId {
    final $$ImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableFilterComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageRatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImageRatingsTable> {
  $$ImageRatingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  $$ImagesTableOrderingComposer get imageId {
    final $$ImagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableOrderingComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageRatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImageRatingsTable> {
  $$ImageRatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  $$ImagesTableAnnotationComposer get imageId {
    final $$ImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.imageId,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImageRatingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImageRatingsTable,
          ImageRating,
          $$ImageRatingsTableFilterComposer,
          $$ImageRatingsTableOrderingComposer,
          $$ImageRatingsTableAnnotationComposer,
          $$ImageRatingsTableCreateCompanionBuilder,
          $$ImageRatingsTableUpdateCompanionBuilder,
          (ImageRating, $$ImageRatingsTableReferences),
          ImageRating,
          PrefetchHooks Function({bool imageId})
        > {
  $$ImageRatingsTableTableManager(_$AppDatabase db, $ImageRatingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImageRatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImageRatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImageRatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> imageId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageRatingsCompanion(
                imageId: imageId,
                isFavorite: isFavorite,
                rating: rating,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String imageId,
                Value<bool> isFavorite = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageRatingsCompanion.insert(
                imageId: imageId,
                isFavorite: isFavorite,
                rating: rating,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImageRatingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({imageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (imageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.imageId,
                                referencedTable: $$ImageRatingsTableReferences
                                    ._imageIdTable(db),
                                referencedColumn: $$ImageRatingsTableReferences
                                    ._imageIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImageRatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImageRatingsTable,
      ImageRating,
      $$ImageRatingsTableFilterComposer,
      $$ImageRatingsTableOrderingComposer,
      $$ImageRatingsTableAnnotationComposer,
      $$ImageRatingsTableCreateCompanionBuilder,
      $$ImageRatingsTableUpdateCompanionBuilder,
      (ImageRating, $$ImageRatingsTableReferences),
      ImageRating,
      PrefetchHooks Function({bool imageId})
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$ImagesTableTableManager get images =>
      $$ImagesTableTableManager(_db, _db.images);
  $$PromptsTableTableManager get prompts =>
      $$PromptsTableTableManager(_db, _db.prompts);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$ImageTagsTableTableManager get imageTags =>
      $$ImageTagsTableTableManager(_db, _db.imageTags);
  $$ImageRatingsTableTableManager get imageRatings =>
      $$ImageRatingsTableTableManager(_db, _db.imageRatings);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
