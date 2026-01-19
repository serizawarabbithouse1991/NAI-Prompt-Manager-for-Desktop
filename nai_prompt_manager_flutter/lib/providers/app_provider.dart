import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/database/database.dart' hide Folder, Tag, ImageRating, Prompt;
import 'database_provider.dart';

/// アプリケーション設定の状態
class AppSettingsState {
  final AppSettings settings;
  final ViewOptions viewOptions;
  final bool initialized;
  final bool loading;
  final String? error;

  const AppSettingsState({
    this.settings = const AppSettings(),
    this.viewOptions = const ViewOptions(),
    this.initialized = false,
    this.loading = false,
    this.error,
  });

  AppSettingsState copyWith({
    AppSettings? settings,
    ViewOptions? viewOptions,
    bool? initialized,
    bool? loading,
    String? error,
  }) {
    return AppSettingsState(
      settings: settings ?? this.settings,
      viewOptions: viewOptions ?? this.viewOptions,
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// アプリケーション設定のNotifier
class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final AppDatabase _db;

  AppSettingsNotifier(this._db) : super(const AppSettingsState());

  /// 設定を読み込む
  Future<void> loadSettings() async {
    if (state.initialized) return;

    state = state.copyWith(loading: true, error: null);

    try {
      // TODO: DBから設定を読み込む
      state = state.copyWith(
        settings: const AppSettings(),
        viewOptions: const ViewOptions(),
        initialized: true,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        loading: false,
        initialized: true,
      );
    }
  }

  /// 設定を更新
  Future<void> updateSettings(AppSettings Function(AppSettings) updater) async {
    final newSettings = updater(state.settings);
    state = state.copyWith(settings: newSettings);

    try {
      // TODO: DBに設定を保存
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 表示オプションを更新
  void updateViewOptions(ViewOptions Function(ViewOptions) updater) {
    state = state.copyWith(viewOptions: updater(state.viewOptions));
  }

  /// テーマを変更
  Future<void> setTheme(ThemeMode theme) async {
    await updateSettings((s) => s.copyWith(theme: theme));
  }

  /// 言語を変更
  Future<void> setLanguage(String language) async {
    await updateSettings((s) => s.copyWith(language: language));
  }

  /// NSFW表示設定を変更
  Future<void> setNsfwSettings({
    bool? showNSFW,
    bool? blurNSFW,
    bool? nsfwDetectionEnabled,
  }) async {
    await updateSettings((s) => s.copyWith(
          showNSFW: showNSFW,
          blurNSFW: blurNSFW,
          nsfwDetectionEnabled: nsfwDetectionEnabled,
        ));
  }

  /// 画像保存パスを設定
  Future<void> setImageStoragePath(String path) async {
    await updateSettings((s) => s.copyWith(imageStoragePath: path));
  }

  /// バックアップ設定を更新
  Future<void> setBackupSettings({
    bool? autoBackupEnabled,
    String? backupPath,
    int? autoBackupIntervalHours,
    int? backupRetentionCount,
  }) async {
    await updateSettings((s) => s.copyWith(
          autoBackupEnabled: autoBackupEnabled,
          backupPath: backupPath,
          autoBackupIntervalHours: autoBackupIntervalHours,
          backupRetentionCount: backupRetentionCount,
        ));
  }
}

/// アプリケーション設定のプロバイダー
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final db = ref.watch(databaseProvider);
  return AppSettingsNotifier(db);
});

/// 表示モードのショートカットプロバイダー
final viewModeProvider = Provider<ViewMode>((ref) {
  return ref.watch(appSettingsProvider).viewOptions.mode;
});

/// サムネイルサイズのショートカットプロバイダー
final thumbnailSizeProvider = Provider<ThumbnailSize>((ref) {
  return ref.watch(appSettingsProvider).viewOptions.thumbnailSize;
});

/// ソート設定のショートカットプロバイダー
final sortSettingsProvider = Provider<({SortBy sortBy, SortOrder sortOrder})>((ref) {
  final options = ref.watch(appSettingsProvider).viewOptions;
  return (sortBy: options.sortBy, sortOrder: options.sortOrder);
});

/// テーマモードのショートカットプロバイダー
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appSettingsProvider).settings.theme;
});

/// 言語のショートカットプロバイダー
final languageProvider = Provider<String>((ref) {
  return ref.watch(appSettingsProvider).settings.language;
});
