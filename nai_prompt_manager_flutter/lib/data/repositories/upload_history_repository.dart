import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/database.dart' as db;

// #region agent log
void _repoDebugLog(String location, String message, Map<String, dynamic> data, String hypothesisId) {
  final entry = '[DEBUG][$hypothesisId] $location: $message | $data';
  print(entry);
  try {
    final logFile = File(r'c:\Users\rt032\001-WEBDEV\NAI Prompt Manager\.cursor\debug.log');
    logFile.writeAsStringSync('$entry\n', mode: FileMode.append);
  } catch (e) {
    print('[DEBUG] Log write error: $e');
  }
}
// #endregion

/// アップロード履歴リポジトリ
class UploadHistoryRepository {
  final db.AppDatabase _db;

  UploadHistoryRepository(this._db);

  /// 履歴を追加
  Future<void> addHistory({
    required String id,
    required String type,
    required String sourcePath,
    required String filename,
    int fileCount = 1,
    int successCount = 0,
    int failCount = 0,
    required String status,
  }) async {
    await _db.into(_db.uploadHistories).insert(
      db.UploadHistoriesCompanion.insert(
        id: id,
        type: type,
        sourcePath: sourcePath,
        filename: filename,
        fileCount: Value(fileCount),
        successCount: Value(successCount),
        failCount: Value(failCount),
        status: status,
      ),
    );
  }

  /// 履歴を更新
  Future<void> updateHistory({
    required String id,
    int? successCount,
    int? failCount,
    String? status,
  }) async {
    await (_db.update(_db.uploadHistories)
          ..where((t) => t.id.equals(id)))
        .write(
      db.UploadHistoriesCompanion(
        successCount: successCount != null ? Value(successCount) : const Value.absent(),
        failCount: failCount != null ? Value(failCount) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
      ),
    );
  }

  /// 全履歴を取得（新しい順）
  Future<List<UploadHistoryModel>> getAllHistories() async {
    // #region agent log
    _repoDebugLog('upload_history_repository.dart:getAllHistories', 'Method called', {}, 'A');
    // #endregion
    try {
      final query = _db.select(_db.uploadHistories)
        ..orderBy([(t) => OrderingTerm.desc(t.uploadedAt)]);
      final results = await query.get();
      // #region agent log
      _repoDebugLog('upload_history_repository.dart:getAllHistories', 'Query result', {'rawCount': results.length, 'types': results.map((e) => e.type).toSet().toList()}, 'B');
      // #endregion
      return results.map(_mapToModel).toList();
    } catch (e, st) {
      // #region agent log
      _repoDebugLog('upload_history_repository.dart:getAllHistories', 'Error', {'error': e.toString(), 'stack': st.toString().substring(0, 300)}, 'A');
      // #endregion
      rethrow;
    }
  }

  /// タイプ別に履歴を取得
  Future<List<UploadHistoryModel>> getHistoriesByType(String type) async {
    // #region agent log
    _repoDebugLog('upload_history_repository.dart:getHistoriesByType', 'Method called', {'type': type}, 'B');
    // #endregion
    final query = _db.select(_db.uploadHistories)
      ..where((t) => t.type.equals(type))
      ..orderBy([(t) => OrderingTerm.desc(t.uploadedAt)]);
    final results = await query.get();
    // #region agent log
    _repoDebugLog('upload_history_repository.dart:getHistoriesByType', 'Query result', {'type': type, 'count': results.length}, 'B');
    // #endregion
    return results.map(_mapToModel).toList();
  }

  /// 最近の履歴を取得（件数指定）
  Future<List<UploadHistoryModel>> getRecentHistories({int limit = 50}) async {
    final query = _db.select(_db.uploadHistories)
      ..orderBy([(t) => OrderingTerm.desc(t.uploadedAt)])
      ..limit(limit);
    final results = await query.get();
    return results.map(_mapToModel).toList();
  }

  /// 履歴を削除
  Future<void> deleteHistory(String id) async {
    await (_db.delete(_db.uploadHistories)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// 全履歴をクリア
  Future<void> clearAllHistories() async {
    await _db.delete(_db.uploadHistories).go();
  }

  /// タイプ別に履歴をクリア
  Future<void> clearHistoriesByType(String type) async {
    await (_db.delete(_db.uploadHistories)
          ..where((t) => t.type.equals(type)))
        .go();
  }

  /// 古い履歴を削除（日数指定）
  Future<int> deleteOldHistories({int daysOld = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    final deleted = await (_db.delete(_db.uploadHistories)
          ..where((t) => t.uploadedAt.isSmallerThanValue(cutoff)))
        .go();
    return deleted;
  }

  /// 統計情報を取得
  Future<UploadStats> getStats() async {
    final all = await getAllHistories();
    
    var totalImages = 0;
    var totalZips = 0;
    var totalFolders = 0;
    var totalSuccess = 0;
    var totalFail = 0;

    for (final h in all) {
      switch (h.type) {
        case 'image':
          totalImages++;
        case 'zip':
          totalZips++;
        case 'folder':
          totalFolders++;
      }
      totalSuccess += h.successCount;
      totalFail += h.failCount;
    }

    return UploadStats(
      totalImages: totalImages,
      totalZips: totalZips,
      totalFolders: totalFolders,
      totalSuccess: totalSuccess,
      totalFail: totalFail,
    );
  }

  UploadHistoryModel _mapToModel(db.UploadHistory data) {
    return UploadHistoryModel(
      id: data.id,
      type: data.type,
      sourcePath: data.sourcePath,
      filename: data.filename,
      fileCount: data.fileCount,
      successCount: data.successCount,
      failCount: data.failCount,
      status: data.status,
      uploadedAt: data.uploadedAt,
    );
  }
}

/// アップロード履歴モデル
class UploadHistoryModel {
  final String id;
  final String type;
  final String sourcePath;
  final String filename;
  final int fileCount;
  final int successCount;
  final int failCount;
  final String status;
  final DateTime uploadedAt;

  const UploadHistoryModel({
    required this.id,
    required this.type,
    required this.sourcePath,
    required this.filename,
    required this.fileCount,
    required this.successCount,
    required this.failCount,
    required this.status,
    required this.uploadedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isPartial => status == 'partial';

  String get statusText {
    switch (status) {
      case 'completed':
        return '完了';
      case 'failed':
        return '失敗';
      case 'partial':
        return '一部失敗';
      default:
        return status;
    }
  }

  String get typeText {
    switch (type) {
      case 'image':
        return '画像';
      case 'zip':
        return 'ZIP';
      case 'folder':
        return 'フォルダ';
      default:
        return type;
    }
  }
}

/// アップロード統計
class UploadStats {
  final int totalImages;
  final int totalZips;
  final int totalFolders;
  final int totalSuccess;
  final int totalFail;

  const UploadStats({
    required this.totalImages,
    required this.totalZips,
    required this.totalFolders,
    required this.totalSuccess,
    required this.totalFail,
  });

  int get totalUploads => totalImages + totalZips + totalFolders;
}
