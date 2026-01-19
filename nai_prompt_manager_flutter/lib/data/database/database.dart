import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Folders,
  Images,
  Prompts,
  Tags,
  ImageTags,
  ImageRatings,
  Settings,
  UploadHistories,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);
  
  /// 既存のDBファイルから接続を作成
  factory AppDatabase.fromFile(File file) {
    return AppDatabase._fromExecutor(
      LazyDatabase(() async => NativeDatabase.createInBackground(file)),
    );
  }
  
  AppDatabase._fromExecutor(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createIndexes(m);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // V2: Multi AI support
          await m.addColumn(prompts, prompts.sourceType);
          await m.addColumn(prompts, prompts.workflowJson);
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_prompts_source_type ON prompts(source_type)');
        }
        if (from < 3) {
          // V3: NSFW detection
          await m.addColumn(images, images.isNsfw);
          await m.addColumn(images, images.nsfwScore);
          await m.addColumn(images, images.nsfwCategory);
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_images_nsfw ON images(is_nsfw)');
        }
        if (from < 4) {
          // V4: CLIP embedding
          await m.addColumn(images, images.clipEmbedding);
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_images_has_clip ON images(id) WHERE clip_embedding IS NOT NULL');
        }
        if (from < 5) {
          // V5: FTS5 - 既存DBとの互換性のためスキップ可能
          // FTS5はSQLite拡張機能のため、必要に応じて有効化
          await _createFTSTables();
        }
        if (from < 6) {
          // V6: Upload history
          await m.createTable(uploadHistories);
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_upload_histories_type ON upload_histories(type)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_upload_histories_uploaded ON upload_histories(uploaded_at)');
        }
      },
      beforeOpen: (details) async {
        // 外部キー制約を有効化
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// インデックスを作成
  Future<void> _createIndexes(Migrator m) async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_images_folder ON images(folder_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_images_created ON images(created_at)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_images_deleted ON images(deleted_at)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_images_hash ON images(file_hash)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_prompts_image ON prompts(image_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_image_tags_image ON image_tags(image_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_image_tags_tag ON image_tags(tag_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_prompts_source_type ON prompts(source_type)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_images_nsfw ON images(is_nsfw)');
  }

  /// FTS5テーブルを作成（全文検索）
  Future<void> _createFTSTables() async {
    // プロンプト検索用FTS
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS prompts_fts USING fts5(
        image_id UNINDEXED,
        positive_prompt,
        negative_prompt,
        model,
        content='prompts',
        content_rowid='rowid',
        tokenize='unicode61'
      )
    ''');

    // ファイル名検索用FTS
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS images_fts USING fts5(
        id UNINDEXED,
        filename,
        content='images',
        content_rowid='rowid',
        tokenize='unicode61'
      )
    ''');

    // トリガーは必要に応じて別途作成
  }
}

/// データベース接続を開く
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'promptvault', 'promptvault.db'));

    // フォルダが存在しない場合は作成
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    return NativeDatabase.createInBackground(file);
  });
}

/// 既存のTauri DBファイルパスからDrift接続を取得
Future<AppDatabase?> openTauriDatabase(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return AppDatabase.fromFile(file);
}
