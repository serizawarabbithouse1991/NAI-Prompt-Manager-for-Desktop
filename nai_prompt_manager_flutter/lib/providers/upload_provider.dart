import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../services/image_import_service.dart';
import '../services/background_upload_service.dart';
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
  final SettingsRepository _settingsRepository;

  UploadNotifier(this._importService, this._settingsRepository) : super(const UploadState());

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

  /// 単一ファイルをアップロード（レガシー: 互換性のため残す）
  Future<void> uploadFile({
    required String filePath,
    String? folderId,
  }) async {
    final enableAutoTag = await _settingsRepository.getAutoTagEnabled();
    final result = await _importService.importImage(
      sourcePath: filePath,
      folderId: folderId,
      checkDuplicates: true,
      enableAutoTag: enableAutoTag,
    );

    if (result.status == ImportStatus.error) {
      throw Exception(result.error);
    }
  }

  /// アップロードを開始（レガシー: 互換性のため残す）
  Future<void> startUpload({String? folderId}) async {
    if (state.isUploading) return;

    state = state.copyWith(isUploading: true);
    
    // 自動タグ付け設定を取得
    final enableAutoTag = await _settingsRepository.getAutoTagEnabled();

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
          enableAutoTag: enableAutoTag,
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

/// アップロードのプロバイダー（レガシー）
final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  final imageRepository = ref.watch(imageRepositoryProvider);
  final tagRepository = ref.watch(tagRepositoryProvider);
  final nsfwState = ref.watch(nsfwServiceProvider);
  final appSettings = ref.watch(appSettingsProvider).settings;
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  
  final importService = ImageImportService(
    imageRepository,
    tagRepository,
    nsfwState.service,
    appSettings.nsfwDetectionEnabled,
  );
  return UploadNotifier(importService, settingsRepository);
});

/// アップロードモーダル表示状態
final uploadModalVisibleProvider = StateProvider<bool>((ref) => false);

// ============================================================================
// バックグラウンドアップロード関連
// ============================================================================

/// バックグラウンドアップロードサービスのプロバイダー
final backgroundUploadServiceProvider = Provider<BackgroundUploadService>((ref) {
  final service = BackgroundUploadService();
  final imageRepository = ref.watch(imageRepositoryProvider);
  final tagRepository = ref.watch(tagRepositoryProvider);
  final nsfwState = ref.watch(nsfwServiceProvider);
  final appSettings = ref.watch(appSettingsProvider).settings;
  
  service.initialize(
    imageRepository: imageRepository,
    tagRepository: tagRepository,
    nsfwService: nsfwState.service,
    enableNsfwDetection: appSettings.nsfwDetectionEnabled,
  );
  
  return service;
});

/// バックグラウンドアップロード進捗のプロバイダー
final backgroundUploadProgressProvider = StreamProvider<BackgroundUploadProgress>((ref) {
  final service = ref.watch(backgroundUploadServiceProvider);
  return service.progressStream;
});

/// 現在のアップロード進捗を取得（Stream以外から）
final currentUploadProgressProvider = Provider<BackgroundUploadProgress>((ref) {
  final service = ref.watch(backgroundUploadServiceProvider);
  return service.currentProgress;
});

/// バックグラウンドアップロードを開始
class BackgroundUploadNotifier extends StateNotifier<BackgroundUploadProgress> {
  final BackgroundUploadService _service;
  final ImageRepository _imageRepository;
  final SettingsRepository _settingsRepository;
  StreamSubscription<BackgroundUploadProgress>? _subscription;
  static const _uuid = Uuid();

  BackgroundUploadNotifier(
    this._service, 
    this._imageRepository,
    this._settingsRepository,
  ) : super(const BackgroundUploadProgress()) {
    _subscription = _service.progressStream.listen((progress) {
      state = progress;
    });
  }

  /// バックグラウンドアップロードを開始
  Future<void> startUpload({
    required List<String> filePaths,
    String? folderId,
  }) async {
    // 既存ハッシュを取得（O(1)重複チェック用）
    final existingHashes = await _imageRepository.getAllFileHashes();
    
    // 自動タグ付け設定を取得
    final enableAutoTag = await _settingsRepository.getAutoTagEnabled();
    
    // タスクを作成
    final tasks = filePaths.map((path) {
      final fileName = path.split(RegExp(r'[/\\]')).last;
      return UploadTask(
        id: _uuid.v4(),
        filePath: path,
        fileName: fileName,
        folderId: folderId,
      );
    }).toList();

    // バックグラウンドアップロードを開始
    await _service.startUpload(
      tasks: tasks,
      existingHashes: existingHashes,
      enableAutoTag: enableAutoTag,
    );
  }

  /// キャンセル
  void cancel() {
    _service.cancel();
  }

  /// リセット
  void reset() {
    _service.reset();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// バックグラウンドアップロードのNotifierプロバイダー
final backgroundUploadNotifierProvider = 
    StateNotifierProvider<BackgroundUploadNotifier, BackgroundUploadProgress>((ref) {
  final service = ref.watch(backgroundUploadServiceProvider);
  final imageRepository = ref.watch(imageRepositoryProvider);
  final settingsRepository = ref.watch(settingsRepositoryProvider);
  return BackgroundUploadNotifier(service, imageRepository, settingsRepository);
});
