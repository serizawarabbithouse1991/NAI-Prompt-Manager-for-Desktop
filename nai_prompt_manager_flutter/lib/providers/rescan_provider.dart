import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/repositories.dart';
import '../services/rescan_service.dart';
import 'repository_providers.dart';

/// 再スキャン状態
class RescanState {
  final bool isScanning;
  final int currentCount;
  final int totalCount;
  final int updatedCount;
  final int newCount;
  final int skippedCount;
  final int failedCount;
  final String? currentFile;
  final String? error;
  final bool isComplete;

  const RescanState({
    this.isScanning = false,
    this.currentCount = 0,
    this.totalCount = 0,
    this.updatedCount = 0,
    this.newCount = 0,
    this.skippedCount = 0,
    this.failedCount = 0,
    this.currentFile,
    this.error,
    this.isComplete = false,
  });

  double get progress => totalCount > 0 ? currentCount / totalCount : 0;
  int get totalUpdated => updatedCount + newCount;

  RescanState copyWith({
    bool? isScanning,
    int? currentCount,
    int? totalCount,
    int? updatedCount,
    int? newCount,
    int? skippedCount,
    int? failedCount,
    String? currentFile,
    String? error,
    bool? isComplete,
  }) {
    return RescanState(
      isScanning: isScanning ?? this.isScanning,
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      updatedCount: updatedCount ?? this.updatedCount,
      newCount: newCount ?? this.newCount,
      skippedCount: skippedCount ?? this.skippedCount,
      failedCount: failedCount ?? this.failedCount,
      currentFile: currentFile,
      error: error,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// 再スキャンのNotifier
class RescanNotifier extends StateNotifier<RescanState> {
  final ImageRepository _imageRepository;
  RescanService? _service;
  StreamSubscription<RescanProgress>? _subscription;

  RescanNotifier(this._imageRepository) : super(const RescanState());

  /// 再スキャンを開始
  Future<void> startRescan({bool onlyWithoutPrompt = false}) async {
    if (state.isScanning) return;

    state = const RescanState(isScanning: true);

    _service = RescanService(_imageRepository);
    
    _subscription = _service!.rescanAllImages(
      onlyWithoutPrompt: onlyWithoutPrompt,
    ).listen(
      (progress) {
        state = RescanState(
          isScanning: progress.isRunning,
          currentCount: progress.current,
          totalCount: progress.total,
          updatedCount: progress.updated,
          newCount: progress.newPrompts,
          skippedCount: progress.skipped,
          failedCount: progress.failed,
          currentFile: progress.currentFile,
          error: progress.error,
          isComplete: progress.isComplete,
        );
      },
      onError: (error) {
        state = state.copyWith(
          isScanning: false,
          error: error.toString(),
        );
      },
      onDone: () {
        _subscription = null;
        _service = null;
      },
    );
  }

  /// 再スキャンをキャンセル
  void cancel() {
    _service?.cancel();
  }

  /// 状態をリセット
  void reset() {
    if (!state.isScanning) {
      state = const RescanState();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// 再スキャンプロバイダー
final rescanProvider = StateNotifierProvider<RescanNotifier, RescanState>((ref) {
  final imageRepository = ref.watch(imageRepositoryProvider);
  return RescanNotifier(imageRepository);
});
