import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../data/repositories/settings_repository.dart';
import '../data/services/danbooru_tag_service.dart';
import '../services/danbooru_service.dart';
import 'database_provider.dart';

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
  final SettingsRepository _settingsRepository;

  DanbooruServiceNotifier(this._settingsRepository) : super(const DanbooruServiceState()) {
    initialize();
  }

  /// サービスを初期化
  Future<void> initialize() async {
    if (state.initialized) return;

    // 1. まず保存されたパスを確認
    String? savedPath = await _settingsRepository.getDanbooruDbPath();
    if (savedPath != null) {
      final file = File(savedPath);
      if (await file.exists()) {
        await _openDatabase(savedPath);
        return;
      }
    }

    // 2. デフォルトのDBパスを探索
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

    await _openDatabase(foundPath);
  }

  /// データベースを開く（内部用）
  Future<void> _openDatabase(String path) async {
    try {
      final service = DanbooruTagService(dbPath: path);
      await service.initialize();

      // DanbooruService（シングルトン）も同じパスで初期化
      final danbooruService = DanbooruService();
      await danbooruService.openDatabase(path);

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

  /// プロンプトを解析
  CategorizedPrompt analyzePrompt(String? prompt) {
    if (!state.available || state.service == null) {
      return const CategorizedPrompt();
    }
    return state.service!.analyzePrompt(prompt);
  }

  /// 手動でDBパスを設定（永続化も行う）
  Future<bool> setDatabasePath(String path) async {
    state.service?.dispose();

    try {
      final file = File(path);
      if (!await file.exists()) {
        state = state.copyWith(
          initialized: true,
          available: false,
          error: 'File not found: $path',
        );
        return false;
      }

      final service = DanbooruTagService(dbPath: path);
      await service.initialize();

      // DanbooruService（シングルトン）も同じパスで初期化
      final danbooruService = DanbooruService();
      await danbooruService.openDatabase(path);

      // 設定を永続化
      await _settingsRepository.setDanbooruDbPath(path);

      state = state.copyWith(
        service: service,
        initialized: true,
        available: true,
        dbPath: path,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        initialized: true,
        available: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// データベースを閉じる
  Future<void> closeDatabase() async {
    state.service?.dispose();

    // DanbooruService（シングルトン）も閉じる
    final danbooruService = DanbooruService();
    danbooruService.close();

    // 設定から削除
    await _settingsRepository.setDanbooruDbPath(null);

    state = state.copyWith(
      service: null,
      available: false,
      dbPath: null,
      error: null,
    );
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
  final db = ref.watch(databaseProvider);
  final settingsRepository = SettingsRepository(db);
  return DanbooruServiceNotifier(settingsRepository);
});

/// プロンプト解析のショートカットプロバイダー
final analyzedPromptProvider = Provider.family<CategorizedPrompt, String?>((ref, prompt) {
  final state = ref.watch(danbooruServiceProvider);
  if (!state.available || state.service == null) {
    return const CategorizedPrompt();
  }
  return state.service!.analyzePrompt(prompt);
});
