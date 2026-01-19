import 'package:drift/drift.dart';
import '../database/database.dart' as db;
import '../models/models.dart';

/// 画像リポジトリ
class ImageRepository {
  final db.AppDatabase _db;

  ImageRepository(this._db);

  /// 画像を取得（ページネーション対応）
  Future<PaginatedImagesResult> getImages({
    required ImageFilter filter,
    required int offset,
    required int limit,
  }) async {
    // 基本クエリ
    var query = _db.select(_db.images).join([
      leftOuterJoin(_db.prompts, _db.prompts.imageId.equalsExp(_db.images.id)),
      leftOuterJoin(_db.imageRatings, _db.imageRatings.imageId.equalsExp(_db.images.id)),
    ]);

    // 削除されていない画像のみ
    query = query..where(_db.images.deletedAt.isNull());

    // フォルダフィルタ
    if (filter.folderId != null) {
      query = query..where(_db.images.folderId.equals(filter.folderId!));
    } else if (filter.uncategorizedOnly) {
      query = query..where(_db.images.folderId.isNull());
    }

    // お気に入りフィルタ
    if (filter.favoritesOnly) {
      query = query..where(_db.imageRatings.isFavorite.equals(true));
    }

    // NSFWフィルタ
    if (!filter.showNSFW) {
      query = query..where(_db.images.isNsfw.equals(false));
    }

    // 検索クエリ
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final searchTerm = '%${filter.searchQuery}%';
      query = query..where(
        _db.images.filename.like(searchTerm) |
        _db.prompts.positivePrompt.like(searchTerm) |
        _db.prompts.negativePrompt.like(searchTerm)
      );
    }

    // 総数を取得
    final countQuery = _db.selectOnly(_db.images)..addColumns([_db.images.id.count()]);
    countQuery.where(_db.images.deletedAt.isNull());
    if (filter.folderId != null) {
      countQuery.where(_db.images.folderId.equals(filter.folderId!));
    }
    final countResult = await countQuery.getSingle();
    final totalCount = countResult.read(_db.images.id.count()) ?? 0;

    // ソート
    switch (filter.sortBy) {
      case SortBy.date:
        query = query..orderBy([
          if (filter.sortOrder == SortOrder.desc)
            OrderingTerm.desc(_db.images.createdAt)
          else
            OrderingTerm.asc(_db.images.createdAt)
        ]);
      case SortBy.name:
        query = query..orderBy([
          if (filter.sortOrder == SortOrder.desc)
            OrderingTerm.desc(_db.images.filename)
          else
            OrderingTerm.asc(_db.images.filename)
        ]);
      case SortBy.size:
        query = query..orderBy([
          if (filter.sortOrder == SortOrder.desc)
            OrderingTerm.desc(_db.images.fileSize)
          else
            OrderingTerm.asc(_db.images.fileSize)
        ]);
    }

    // ページネーション
    query = query..limit(limit, offset: offset);

    // クエリ実行
    final rows = await query.get();

    // 画像IDを収集してタグを一括取得
    final imageIds = rows.map((r) => r.readTable(_db.images).id).toList();
    final tagsMap = await _getTagsForImages(imageIds);

    // 結果をマッピング
    final images = rows.map((row) {
      final image = row.readTable(_db.images);
      final prompt = row.readTableOrNull(_db.prompts);
      final rating = row.readTableOrNull(_db.imageRatings);
      final tags = tagsMap[image.id] ?? [];

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
        nsfwCategory: NSFWCategory.fromString(image.nsfwCategory),
        clipEmbedding: image.clipEmbedding,
        prompt: prompt != null ? _mapPrompt(prompt) : null,
        tags: tags,
        rating: rating != null ? _mapRating(rating) : null,
      );
    }).toList();

    return PaginatedImagesResult(
      images: images,
      totalCount: totalCount,
      hasMore: offset + images.length < totalCount,
    );
  }

  /// 画像を取得（ID指定）
  Future<ImageWithDetails?> getImageById(String id) async {
    final query = _db.select(_db.images).join([
      leftOuterJoin(_db.prompts, _db.prompts.imageId.equalsExp(_db.images.id)),
      leftOuterJoin(_db.imageRatings, _db.imageRatings.imageId.equalsExp(_db.images.id)),
    ])..where(_db.images.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final image = row.readTable(_db.images);
    final prompt = row.readTableOrNull(_db.prompts);
    final rating = row.readTableOrNull(_db.imageRatings);
    final tagsMap = await _getTagsForImages([id]);
    final tags = tagsMap[id] ?? [];

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
      nsfwCategory: NSFWCategory.fromString(image.nsfwCategory),
      clipEmbedding: image.clipEmbedding,
      prompt: prompt != null ? _mapPrompt(prompt) : null,
      tags: tags,
      rating: rating != null ? _mapRating(rating) : null,
    );
  }

  /// 画像を追加
  Future<void> insertImage(ImageModel image, [Prompt? prompt]) async {
    await _db.transaction(() async {
      await _db.into(_db.images).insert(db.ImagesCompanion.insert(
        id: image.id,
        folderId: Value(image.folderId),
        filePath: image.filePath,
        thumbnailPath: Value(image.thumbnailPath),
        filename: Value(image.filename),
        width: Value(image.width),
        height: Value(image.height),
        fileSize: Value(image.fileSize),
        fileHash: Value(image.fileHash),
        isNsfw: Value(image.isNsfw ?? false),
        nsfwScore: Value(image.nsfwScore),
        nsfwCategory: Value(image.nsfwCategory?.value),
      ));

      if (prompt != null) {
        await _db.into(_db.prompts).insert(db.PromptsCompanion.insert(
          id: prompt.id,
          imageId: prompt.imageId,
          positivePrompt: Value(prompt.positivePrompt),
          negativePrompt: Value(prompt.negativePrompt),
          model: Value(prompt.model),
          sampler: Value(prompt.sampler),
          steps: Value(prompt.steps),
          cfgScale: Value(prompt.cfgScale),
          seed: Value(prompt.seed),
          resolutionWidth: Value(prompt.resolutionWidth),
          resolutionHeight: Value(prompt.resolutionHeight),
          noiseSchedule: Value(prompt.noiseSchedule),
          promptGuidanceRescale: Value(prompt.promptGuidanceRescale),
          notes: Value(prompt.notes),
          rawMetadata: Value(prompt.rawMetadata),
          sourceType: Value(prompt.sourceType.value),
          workflowJson: Value(prompt.workflowJson),
        ));
      }
    });
  }

  /// 画像を削除（論理削除）
  Future<void> deleteImage(String id) async {
    await (_db.update(_db.images)..where((t) => t.id.equals(id)))
        .write(db.ImagesCompanion(deletedAt: Value(DateTime.now())));
  }

  /// 画像を一括削除
  Future<void> deleteImages(List<String> ids) async {
    await (_db.update(_db.images)..where((t) => t.id.isIn(ids)))
        .write(db.ImagesCompanion(deletedAt: Value(DateTime.now())));
  }

  /// 画像をフォルダに移動
  Future<void> moveImagesToFolder(List<String> imageIds, String? folderId) async {
    await (_db.update(_db.images)..where((t) => t.id.isIn(imageIds)))
        .write(db.ImagesCompanion(folderId: Value(folderId)));
  }

  /// お気に入りを更新
  Future<void> updateFavorite(String imageId, bool isFavorite) async {
    final existing = await (_db.select(_db.imageRatings)
      ..where((t) => t.imageId.equals(imageId)))
      .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.imageRatings)..where((t) => t.imageId.equals(imageId)))
          .write(db.ImageRatingsCompanion(isFavorite: Value(isFavorite)));
    } else {
      await _db.into(_db.imageRatings).insert(db.ImageRatingsCompanion.insert(
        imageId: imageId,
        isFavorite: Value(isFavorite),
      ));
    }
  }

  /// タグを画像に追加
  Future<void> addTagToImage(String imageId, String tagId) async {
    await _db.into(_db.imageTags).insert(db.ImageTagsCompanion.insert(
      imageId: imageId,
      tagId: tagId,
    ));
  }

  /// タグを画像から削除
  Future<void> removeTagFromImage(String imageId, String tagId) async {
    await (_db.delete(_db.imageTags)
      ..where((t) => t.imageId.equals(imageId) & t.tagId.equals(tagId)))
      .go();
  }

  /// プロンプトを更新
  Future<void> updatePrompt(String imageId, Map<String, dynamic> updates) async {
    final companion = db.PromptsCompanion(
      positivePrompt: updates.containsKey('positive_prompt') 
          ? Value(updates['positive_prompt'] as String?) : const Value.absent(),
      negativePrompt: updates.containsKey('negative_prompt')
          ? Value(updates['negative_prompt'] as String?) : const Value.absent(),
      notes: updates.containsKey('notes')
          ? Value(updates['notes'] as String?) : const Value.absent(),
    );

    await (_db.update(_db.prompts)..where((t) => t.imageId.equals(imageId)))
        .write(companion);
  }

  /// 重複画像を検索（ハッシュで）
  Future<List<ImageWithDetails>> findDuplicates() async {
    final query = _db.customSelect('''
      SELECT file_hash, COUNT(*) as count FROM images 
      WHERE deleted_at IS NULL AND file_hash IS NOT NULL
      GROUP BY file_hash HAVING count > 1
    ''');
    
    final duplicateHashes = await query.get();
    final hashes = duplicateHashes.map((r) => r.read<String>('file_hash')).toList();

    if (hashes.isEmpty) return [];

    final result = await getImages(
      filter: const ImageFilter(),
      offset: 0,
      limit: 1000,
    );

    return result.images
        .where((img) => img.fileHash != null && hashes.contains(img.fileHash))
        .toList();
  }

  /// 全ファイルハッシュを取得（重複チェック用キャッシュ）
  /// O(1)での重複判定を可能にする
  Future<Set<String>> getAllFileHashes() async {
    final query = _db.customSelect('''
      SELECT file_hash FROM images 
      WHERE deleted_at IS NULL AND file_hash IS NOT NULL
    ''');
    
    final results = await query.get();
    return results
        .map((r) => r.read<String>('file_hash'))
        .toSet();
  }

  /// ハッシュが既に存在するかチェック
  Future<bool> hashExists(String fileHash) async {
    final query = _db.customSelect('''
      SELECT 1 FROM images 
      WHERE deleted_at IS NULL AND file_hash = ?
      LIMIT 1
    ''', variables: [Variable.withString(fileHash)]);
    
    final results = await query.get();
    return results.isNotEmpty;
  }

  /// 複数画像を一括挿入（バッチ処理用）
  Future<void> insertImages(List<(ImageModel, Prompt?)> items) async {
    await _db.transaction(() async {
      for (final (image, prompt) in items) {
        await _db.into(_db.images).insert(db.ImagesCompanion.insert(
          id: image.id,
          folderId: Value(image.folderId),
          filePath: image.filePath,
          thumbnailPath: Value(image.thumbnailPath),
          filename: Value(image.filename),
          width: Value(image.width),
          height: Value(image.height),
          fileSize: Value(image.fileSize),
          fileHash: Value(image.fileHash),
          isNsfw: Value(image.isNsfw ?? false),
          nsfwScore: Value(image.nsfwScore),
          nsfwCategory: Value(image.nsfwCategory?.value),
        ));

        if (prompt != null) {
          await _db.into(_db.prompts).insert(db.PromptsCompanion.insert(
            id: prompt.id,
            imageId: prompt.imageId,
            positivePrompt: Value(prompt.positivePrompt),
            negativePrompt: Value(prompt.negativePrompt),
            model: Value(prompt.model),
            sampler: Value(prompt.sampler),
            steps: Value(prompt.steps),
            cfgScale: Value(prompt.cfgScale),
            seed: Value(prompt.seed),
            resolutionWidth: Value(prompt.resolutionWidth),
            resolutionHeight: Value(prompt.resolutionHeight),
            noiseSchedule: Value(prompt.noiseSchedule),
            promptGuidanceRescale: Value(prompt.promptGuidanceRescale),
            notes: Value(prompt.notes),
            rawMetadata: Value(prompt.rawMetadata),
            sourceType: Value(prompt.sourceType.value),
            workflowJson: Value(prompt.workflowJson),
          ));
        }
      }
    });
  }

  /// 複数画像のタグを一括取得
  Future<Map<String, List<Tag>>> _getTagsForImages(List<String> imageIds) async {
    if (imageIds.isEmpty) return {};

    final query = _db.select(_db.imageTags).join([
      innerJoin(_db.tags, _db.tags.id.equalsExp(_db.imageTags.tagId)),
    ])..where(_db.imageTags.imageId.isIn(imageIds));

    final rows = await query.get();
    
    final Map<String, List<Tag>> result = {};
    for (final row in rows) {
      final imageTag = row.readTable(_db.imageTags);
      final tag = row.readTable(_db.tags);
      
      result.putIfAbsent(imageTag.imageId, () => []);
      result[imageTag.imageId]!.add(Tag(
        id: tag.id,
        name: tag.name,
        color: tag.color,
        createdAt: tag.createdAt,
      ));
    }

    return result;
  }

  /// DriftのPromptをモデルのPromptにマッピング
  Prompt _mapPrompt(db.Prompt data) {
    return Prompt(
      id: data.id,
      imageId: data.imageId,
      positivePrompt: data.positivePrompt,
      negativePrompt: data.negativePrompt,
      model: data.model,
      sampler: data.sampler,
      steps: data.steps,
      cfgScale: data.cfgScale,
      seed: data.seed,
      resolutionWidth: data.resolutionWidth,
      resolutionHeight: data.resolutionHeight,
      noiseSchedule: data.noiseSchedule,
      promptGuidanceRescale: data.promptGuidanceRescale,
      notes: data.notes,
      rawMetadata: data.rawMetadata,
      sourceType: AISourceType.fromString(data.sourceType),
      workflowJson: data.workflowJson,
      createdAt: data.createdAt,
    );
  }

  /// DriftのImageRatingをモデルのImageRatingにマッピング
  ImageRating _mapRating(db.ImageRating data) {
    return ImageRating(
      imageId: data.imageId,
      isFavorite: data.isFavorite,
      rating: data.rating,
    );
  }
}
