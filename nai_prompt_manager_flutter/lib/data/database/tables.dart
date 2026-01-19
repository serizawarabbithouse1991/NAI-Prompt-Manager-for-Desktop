import 'package:drift/drift.dart';

/// フォルダテーブル
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable().references(Folders, #id)();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 画像テーブル
class Images extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text().nullable().references(Folders, #id)();
  TextColumn get filePath => text().unique()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get filename => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get fileHash => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // V3: NSFW detection
  BoolColumn get isNsfw => boolean().withDefault(const Constant(false))();
  RealColumn get nsfwScore => real().nullable()();
  TextColumn get nsfwCategory => text().nullable()();
  // V4: CLIP embedding
  BlobColumn get clipEmbedding => blob().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// プロンプトテーブル
class Prompts extends Table {
  TextColumn get id => text()();
  TextColumn get imageId => text().references(Images, #id, onDelete: KeyAction.cascade)();
  TextColumn get positivePrompt => text().nullable()();
  TextColumn get negativePrompt => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get sampler => text().nullable()();
  IntColumn get steps => integer().nullable()();
  RealColumn get cfgScale => real().nullable()();
  IntColumn get seed => integer().nullable()();
  IntColumn get resolutionWidth => integer().nullable()();
  IntColumn get resolutionHeight => integer().nullable()();
  TextColumn get noiseSchedule => text().nullable()();
  RealColumn get promptGuidanceRescale => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get rawMetadata => text().nullable()();
  // V2: Multi AI support
  TextColumn get sourceType => text().withDefault(const Constant('unknown'))();
  TextColumn get workflowJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// タグテーブル
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 画像タグ関連テーブル
class ImageTags extends Table {
  TextColumn get imageId => text().references(Images, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId => text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {imageId, tagId};
}

/// 画像評価テーブル
class ImageRatings extends Table {
  TextColumn get imageId => text().references(Images, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get rating => integer().nullable()();

  @override
  Set<Column> get primaryKey => {imageId};
}

/// 設定テーブル
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// アップロード履歴テーブル
class UploadHistories extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'image', 'zip', 'folder'
  TextColumn get sourcePath => text()();
  TextColumn get filename => text()();
  IntColumn get fileCount => integer().withDefault(const Constant(1))();
  IntColumn get successCount => integer().withDefault(const Constant(0))();
  IntColumn get failCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text()(); // 'completed', 'failed', 'partial'
  DateTimeColumn get uploadedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
