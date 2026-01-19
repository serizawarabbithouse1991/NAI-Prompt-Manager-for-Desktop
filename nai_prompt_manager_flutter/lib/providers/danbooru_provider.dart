import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../data/services/danbooru_tag_service.dart';

/// Danbooruタグサービスの状態
class DanbooruServiceState {
  final DanbooruTagService? service;
  final bool initialized;
  final bool available;
  final String? error;
  final String? dbPath;

  const DanbooruServiceState({
    this.service,
    this.initialized = false,
    this.available = false,
    this.error,
    this.dbPath,
  });

  DanbooruServiceState copyWith({
    DanbooruTagService? service,
    bool? initialized,
    bool? available,
    String? error,
    String? dbPath,
  }) {
    return DanbooruServiceState(
      service: service ?? this.service,
      initialized: initialized ?? this.initialized,
      available: available ?? this.available,
      error: error,
      dbPath: dbPath ?? this.dbPath,
    );
  }
}

/// Danbooruタグサービスのプロバイダー
class DanbooruServiceNotifier extends StateNotifier<DanbooruServiceState> {
  DanbooruServiceNotifier() : super(const DanbooruServiceState());

  /// サービスを初期化
  Future<void> initialize() async {
    if (state.initialized) return;

    // デフォルトのDBパスを探索
    final possiblePaths = [
      // カレントディレクトリ
      'danbooru2023.db',
      // プロジェクトルート
      p.join(Directory.current.path, 'danbooru2023.db'),
      // 親ディレクトリ（Flutter プロジェクトの場合）
      p.join(Directory.current.parent.path, 'danbooru2023.db'),
      // ワークスペースルート
      r'c:\Users\rt032\001-WEBDEV\NAI Prompt Manager\danbooru2023.db',
    ];

    String? foundPath;
    for (final path in possiblePaths) {
      final file = File(path);
      if (await file.exists()) {
        foundPath = path;
        break;
      }
    }

    if (foundPath == null) {
      state = state.copyWith(
        initialized: true,
        available: false,
        error: 'Danbooru database not found',
      );
      return;
    }

    try {
      final service = DanbooruTagService(dbPath: foundPath);
      await service.initialize();
      
      state = state.copyWith(
        service: service,
        initialized: true,
        available: true,
        dbPath: foundPath,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        initialized: true,
        available: false,
        error: e.toString(),
      );
    }
  }

  /// プロンプトを解析
  CategorizedPrompt analyzePrompt(String? prompt) {
    if (!state.available || state.service == null) {
      return const CategorizedPrompt();
    }
    return state.service!.analyzePrompt(prompt);
  }

  /// 手動でDBパスを設定
  Future<void> setDatabasePath(String path) async {
    state.service?.dispose();
    
    try {
      final service = DanbooruTagService(dbPath: path);
      await service.initialize();
      
      state = state.copyWith(
        service: service,
        initialized: true,
        available: true,
        dbPath: path,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        initialized: true,
        available: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    state.service?.dispose();
    super.dispose();
  }
}

/// Danbooruサービスプロバイダー
final danbooruServiceProvider =
    StateNotifierProvider<DanbooruServiceNotifier, DanbooruServiceState>((ref) {
  final notifier = DanbooruServiceNotifier();
  // 初期化を自動実行
  notifier.initialize();
  return notifier;
});

/// プロンプト解析のショートカットプロバイダー
final analyzedPromptProvider = Provider.family<CategorizedPrompt, String?>((ref, prompt) {
  final state = ref.watch(danbooruServiceProvider);
  if (!state.available || state.service == null) {
    return const CategorizedPrompt();
  }
  return state.service!.analyzePrompt(prompt);
});
