import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../themes/nai_theme.dart';
import '../widgets/image_grid.dart';
import '../widgets/explorer_pane.dart';

/// ギャラリー画面
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    // 初期データ読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(imageListProvider.notifier).loadImages();
      ref.read(folderListProvider.notifier).loadFolders();
      ref.read(tagListProvider.notifier).loadTags();
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(imageListProvider);
    // Watch explorerState for changes even if not directly used
    ref.watch(explorerProvider);

    return Row(
      children: [
        // 左サイドバー - エクスプローラー
        SizedBox(
          width: 240,
          child: Container(
            color: NaiTheme.bg1,
            child: const ExplorerPane(),
          ),
        ),
        // メインコンテンツ
        Expanded(
          child: Column(
            children: [
              // ツールバー
              _buildToolbar(context, imageState),
              // 画像グリッド
              Expanded(
                child: _buildContent(imageState),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, ImageListState state) {
    final selectedCount = ref.watch(selectedImageIdsProvider).length;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: NaiTheme.bg1,
        border: Border(
          bottom: BorderSide(color: NaiTheme.bg2, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 画像数表示
          Text(
            '${state.pagination.totalCount} 枚の画像',
            style: TextStyle(color: NaiTheme.text1, fontSize: 13),
          ),
          const SizedBox(width: 16),
          
          // 選択中の表示
          if (selectedCount > 0) ...[
            Text(
              '$selectedCount 件選択中',
              style: TextStyle(color: NaiTheme.accent, fontSize: 13),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(FluentIcons.cancel, size: 14, color: NaiTheme.text1),
              onPressed: () {
                ref.read(selectedImageIdsProvider.notifier).state = {};
              },
            ),
          ],
          
          const Spacer(),
          
          // 表示モード切替
          ToggleSwitch(
            checked: ref.watch(viewModeProvider) == ViewMode.list,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).updateViewOptions(
                (options) => options.copyWith(
                  mode: value ? ViewMode.list : ViewMode.grid,
                ),
              );
            },
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.grid_view_medium, size: 14),
                const SizedBox(width: 4),
                const Text('グリッド'),
                const SizedBox(width: 8),
                Icon(FluentIcons.list, size: 14),
                const SizedBox(width: 4),
                const Text('リスト'),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // リフレッシュ
          IconButton(
            icon: Icon(FluentIcons.refresh, size: 16, color: NaiTheme.text0),
            onPressed: () {
              ref.read(imageListProvider.notifier).refreshImages();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ImageListState state) {
    if (state.loading) {
      return const Center(child: ProgressRing());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.error, size: 48, color: NaiTheme.error),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: TextStyle(color: NaiTheme.text0, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(color: NaiTheme.text2, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton(
              child: const Text('再試行'),
              onPressed: () {
                ref.read(imageListProvider.notifier).refreshImages();
              },
            ),
          ],
        ),
      );
    }

    if (state.images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.photo2, size: 64, color: NaiTheme.text2),
            const SizedBox(height: 16),
            Text(
              '画像がありません',
              style: TextStyle(color: NaiTheme.text0, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '画像をアップロードして始めましょう',
              style: TextStyle(color: NaiTheme.text2, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ImageGrid(
      images: state.images,
      hasMore: state.pagination.hasMore,
      loadingMore: state.loadingMore,
      onLoadMore: () {
        ref.read(imageListProvider.notifier).loadMoreImages();
      },
    );
  }
}
