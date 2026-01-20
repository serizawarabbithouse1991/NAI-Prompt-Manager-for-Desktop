import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../providers/providers.dart';
import '../../services/background_upload_service.dart';
import '../themes/nai_theme.dart';
import 'dashboard_screen.dart';
import 'gallery_screen.dart';
import 'prompt_analysis_screen.dart';
import 'suggestion_screen.dart';
import 'settings_screen.dart';
import 'upload_dialog.dart';
import 'search_screen.dart';
import 'upload_history_screen.dart';
import 'bulk_tagging_dialog.dart';

/// ホーム画面（メインナビゲーション）
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WindowListener {
  int _selectedIndex = 0;

  final List<NavigationPaneItem> _items = [
    PaneItem(
      icon: const Icon(FluentIcons.home),
      title: const Text('ホーム'),
      body: const DashboardScreen(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.photo2),
      title: const Text('ギャラリー'),
      body: const GalleryScreen(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.search),
      title: const Text('検索'),
      body: const SearchScreen(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.chart),
      title: const Text('プロンプト分析'),
      body: const PromptAnalysisScreen(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.trending12),
      title: const Text('プロンプト提案'),
      body: const SuggestionScreen(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.history),
      title: const Text('履歴'),
      body: const UploadHistoryScreen(),
    ),
    PaneItemSeparator(),
    PaneItem(
      icon: const Icon(FluentIcons.settings),
      title: const Text('設定'),
      body: const SettingsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadProgress = ref.watch(backgroundUploadNotifierProvider);

    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: const DragToMoveArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'PromptVault',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // グローバルアップロード進捗インジケーター
            if (uploadProgress.isRunning || 
                (uploadProgress.total > 0 && !uploadProgress.isComplete))
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _GlobalUploadProgress(progress: uploadProgress),
              ),
            // 一括タグ付けボタン
            Builder(
              builder: (context) {
                final danbooruState = ref.watch(danbooruServiceProvider);
                if (!danbooruState.available) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                    message: 'Danbooruタグ一括付与',
                    child: Button(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.tag, size: 14, color: NaiTheme.accent),
                          const SizedBox(width: 6),
                          const Text('自動タグ付け'),
                        ],
                      ),
                      onPressed: () {
                        BulkTaggingDialog.show(context);
                      },
                    ),
                  ),
                );
              },
            ),
            // アップロードボタン
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.upload, size: 14),
                    SizedBox(width: 6),
                    Text('アップロード'),
                  ],
                ),
                onPressed: () {
                  UploadDialog.show(context);
                },
              ),
            ),
            // ウィンドウコントロール
            const WindowButtons(),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        displayMode: PaneDisplayMode.compact,
        items: _items,
      ),
    );
  }
}

/// グローバルアップロード進捗インジケーター
class _GlobalUploadProgress extends ConsumerWidget {
  final BackgroundUploadProgress progress;

  const _GlobalUploadProgress({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = (progress.progress * 100).toInt();
    final isComplete = progress.isComplete;
    
    return Tooltip(
      message: _buildTooltipMessage(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isComplete ? NaiTheme.success.withAlpha(30) : NaiTheme.accent.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isComplete ? NaiTheme.success : NaiTheme.accent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress.isRunning) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: ProgressRing(
                  strokeWidth: 2,
                  activeColor: NaiTheme.accent,
                ),
              ),
              const SizedBox(width: 8),
            ] else if (isComplete) ...[
              Icon(
                FluentIcons.check_mark,
                size: 14,
                color: NaiTheme.success,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              isComplete
                  ? '完了: ${progress.completed}件'
                  : '$percentage% (${progress.processed}/${progress.total})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isComplete ? NaiTheme.success : NaiTheme.text0,
              ),
            ),
            if (isComplete) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ref.read(backgroundUploadNotifierProvider.notifier).reset();
                  // 画像リストをリフレッシュ
                  ref.read(imageListProvider.notifier).refreshImages();
                },
                child: Icon(
                  FluentIcons.cancel,
                  size: 12,
                  color: NaiTheme.text2,
                ),
              ),
            ] else ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ref.read(backgroundUploadNotifierProvider.notifier).cancel();
                },
                child: Icon(
                  FluentIcons.cancel,
                  size: 12,
                  color: NaiTheme.text2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildTooltipMessage() {
    final buffer = StringBuffer();
    buffer.writeln('アップロード進捗');
    buffer.writeln('成功: ${progress.completed}件');
    buffer.writeln('失敗: ${progress.failed}件');
    buffer.writeln('重複: ${progress.duplicates}件');
    if (progress.currentFile != null) {
      buffer.writeln('処理中: ${progress.currentFile}');
    }
    return buffer.toString().trim();
  }
}

/// ウィンドウボタン（最小化・最大化・閉じる）
class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(FluentIcons.chrome_minimize, size: 12),
          onPressed: () => windowManager.minimize(),
        ),
        IconButton(
          icon: const Icon(FluentIcons.checkbox_fill, size: 12),
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        IconButton(
          icon: Icon(
            FluentIcons.chrome_close,
            size: 12,
            color: NaiTheme.error,
          ),
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}

/// プレースホルダーページ
class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.withPadding(
      header: PageHeader(title: Text(title)),
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.settings,
              size: 64,
              color: NaiTheme.text2,
            ),
            const SizedBox(height: 16),
            Text(
              '$title - 実装中',
              style: TextStyle(
                fontSize: 18,
                color: NaiTheme.text1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'このページは開発中です',
              style: TextStyle(
                fontSize: 14,
                color: NaiTheme.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
