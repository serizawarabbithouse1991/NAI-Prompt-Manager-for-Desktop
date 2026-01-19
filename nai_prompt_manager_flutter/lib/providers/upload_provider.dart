import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../services/image_import_service.dart';
import 'repository_providers.dart';
import 'nsfw_provider.dart';
import 'app_provider.dart';

/// アップロード進捗項目
class UploadItem {
  final String id;
  final String filePath;
  final String fileName;
  final UploadStatus status;
  final double progress;
  final String? error;
  final ImageWithDetails? result;

  const UploadItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    this.status = UploadStatus.pending,
    this.progress = 0,
    this.error,
    this.result,
  });

  UploadItem copyWith({
    String? id,
    String? filePath,
    String? fileName,
    UploadStatus? status,
    double? progress,
    String? error,
    ImageWithDetails? result,
  }) {
    return UploadItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
      result: result ?? this.result,
    );
  }
}

/// アップロード状態
enum UploadStatus {
  pending,
  processing,
  completed,
  failed,
}

/// アップロード状態
class UploadState {
  final List<UploadItem> items;
  final bool isUploading;
  final int completedCount;
  final int failedCount;

  const UploadState({
    this.items = const [],
    this.isUploading = false,
    this.completedCount = 0,
    this.failedCount = 0,
  });

  UploadState copyWith({
    List<UploadItem>? items,
    bool? isUploading,
    int? completedCount,
    int? failedCount,
  }) {
    return UploadState(
      items: items ?? this.items,
      isUploading: isUploading ?? this.isUploading,
      completedCount: completedCount ?? this.completedCount,
      failedCount: failedCount ?? this.failedCount,
    );
  }

  int get totalCount => items.length;
  int get pendingCount => items.where((i) => i.status == UploadStatus.pending).length;
  int get processingCount => items.where((i) => i.status == UploadStatus.processing).length;
  double get overallProgress {
    if (items.isEmpty) return 0;
    return items.map((i) => i.progress).reduce((a, b) => a + b) / items.length;
  }
}

/// アップロードのNotifier
class UploadNotifier extends StateNotifier<UploadState> {
  final ImageImportService _importService;

  UploadNotifier(this._importService) : super(const UploadState());

  /// ファイルを追加
  void addFiles(List<File> files) {
    final newItems = files.map((file) {
      return UploadItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + file.path.hashCode.toString(),
        filePath: file.path,
        fileName: file.uri.pathSegments.last,
      );
    }).toList();

    state = state.copyWith(items: [...state.items, ...newItems]);
  }

  /// 単一ファイルをアップロード
  Future<void> uploadFile({
    required String filePath,
    String? folderId,
  }) async {
    final result = await _importService.importImage(
      sourcePath: filePath,
      folderId: folderId,
      checkDuplicates: true,
    );

    if (result.status == ImportStatus.error) {
      throw Exception(result.error);
    }
  }

  /// アップロードを開始
  Future<void> startUpload({String? folderId}) async {
    if (state.isUploading) return;

    state = state.copyWith(isUploading: true);

    for (var i = 0; i < state.items.length; i++) {
      final item = state.items[i];
      if (item.status != UploadStatus.pending) continue;

      // 処理中に更新
      _updateItem(item.id, item.copyWith(status: UploadStatus.processing));

      try {
        final result = await _importService.importImage(
          sourcePath: item.filePath,
          folderId: folderId,
          checkDuplicates: true,
        );

        if (result.status == ImportStatus.success) {
          // 完了
          _updateItem(
            item.id,
            item.copyWith(
              status: UploadStatus.completed,
              progress: 1.0,
            ),
          );
          state = state.copyWith(completedCount: state.completedCount + 1);
        } else if (result.status == ImportStatus.duplicate) {
          // 重複
          _updateItem(
            item.id,
            item.copyWith(
              status: UploadStatus.failed,
              error: '重複ファイル',
            ),
          );
          state = state.copyWith(failedCount: state.failedCount + 1);
        } else {
          throw Exception(result.error);
        }
      } catch (e) {
        // 失敗
        _updateItem(
          item.id,
          item.copyWith(
            status: UploadStatus.failed,
            error: e.toString(),
          ),
        );
        state = state.copyWith(failedCount: state.failedCount + 1);
      }
    }

    state = state.copyWith(isUploading: false);
  }

  /// アイテムを更新
  void _updateItem(String id, UploadItem updatedItem) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == id) return updatedItem;
        return item;
      }).toList(),
    );
  }

  /// 完了したアイテムをクリア
  void clearCompleted() {
    state = state.copyWith(
      items: state.items.where((i) => i.status != UploadStatus.completed).toList(),
      completedCount: 0,
    );
  }

  /// すべてクリア
  void clearAll() {
    state = const UploadState();
  }

  /// キャンセル
  void cancel() {
    state = state.copyWith(isUploading: false);
  }
}

/// アップロードのプロバイダー
final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  final imageRepository = ref.watch(imageRepositoryProvider);
  final tagRepository = ref.watch(tagRepositoryProvider);
  final nsfwState = ref.watch(nsfwServiceProvider);
  final appSettings = ref.watch(appSettingsProvider).settings;
  
  final importService = ImageImportService(
    imageRepository,
    tagRepository,
    nsfwState.service,
    appSettings.nsfwDetectionEnabled,
  );
  return UploadNotifier(importService);
});

/// アップロードモーダル表示状態
final uploadModalVisibleProvider = StateProvider<bool>((ref) => false);
