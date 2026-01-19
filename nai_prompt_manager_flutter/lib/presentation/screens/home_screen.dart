import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../themes/nai_theme.dart';
import 'dashboard_screen.dart';
import 'gallery_screen.dart';
import 'prompt_analysis_screen.dart';
import 'settings_screen.dart';
import 'upload_dialog.dart';
import 'search_screen.dart';

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
