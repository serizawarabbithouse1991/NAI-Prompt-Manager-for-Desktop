import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../themes/nai_theme.dart';
import '../widgets/image_grid.dart';
import '../widgets/explorer_pane.dart';
import 'upload_dialog.dart';

/// ギャラリー画面
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

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
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

    // Ctrl+A: 全選択
    if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
      _selectAll();
      return KeyEventResult.handled;
    }

    // Ctrl+F: 検索フォーカス
    if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
      setState(() => _showSearch = !_showSearch);
      return KeyEventResult.handled;
    }

    // Delete: 選択削除
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      _deleteSelected();
      return KeyEventResult.handled;
    }

    // Escape: 選択解除 or 検索閉じる
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_showSearch) {
        setState(() {
          _showSearch = false;
          _searchController.clear();
        });
      } else {
        ref.read(selectedImageIdsProvider.notifier).state = {};
      }
      return KeyEventResult.handled;
    }

    // F5: リフレッシュ
    if (event.logicalKey == LogicalKeyboardKey.f5) {
      ref.read(imageListProvider.notifier).refreshImages();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _selectAll() {
    final images = ref.read(imageListProvider).images;
    ref.read(selectedImageIdsProvider.notifier).state = 
        images.map((img) => img.id).toSet();
  }

  void _deleteSelected() {
    final selectedIds = ref.read(selectedImageIdsProvider);
    if (selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('画像を削除'),
        content: Text(
          selectedIds.length == 1
              ? '選択した画像を削除しますか？'
              : '${selectedIds.length}枚の画像を削除しますか？',
        ),
        actions: [
          Button(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(NaiTheme.error),
            ),
            onPressed: () {
              for (final id in selectedIds) {
                ref.read(imageListProvider.notifier).removeImage(id);
              }
              ref.read(selectedImageIdsProvider.notifier).state = {};
              Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    ref.read(imageListProvider.notifier).loadImages(
      ImageFilter(searchQuery: query.isEmpty ? null : query),
    );
  }

  void _batchToggleFavorite() {
    final selectedIds = ref.read(selectedImageIdsProvider);
    for (final id in selectedIds) {
      ref.read(imageListProvider.notifier).toggleFavorite(id);
    }
  }

  void _showBatchAddTagDialog() {
    final tagState = ref.read(tagListProvider);
    final selectedIds = ref.read(selectedImageIdsProvider);
    String? selectedTagId;

    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text('タグを追加 (${selectedIds.length}枚)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '選択した画像にタグを追加します',
              style: TextStyle(color: NaiTheme.text2),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return ComboBox<String>(
                  value: selectedTagId,
                  placeholder: const Text('タグを選択'),
                  items: tagState.tags.map((tag) {
                    return ComboBoxItem<String>(
                      value: tag.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tag.color != null)
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Color(int.parse(tag.color!.replaceFirst('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          Text(tag.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedTagId = value);
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            onPressed: selectedTagId == null
                ? null
                : () {
                    final tag = tagState.tags.firstWhere((t) => t.id == selectedTagId);
                    for (final imageId in selectedIds) {
                      ref.read(imageListProvider.notifier).addTagToImage(imageId, tag);
                    }
                    Navigator.pop(ctx);
                  },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _showBatchMoveDialog() {
    final folderState = ref.read(folderListProvider);
    final selectedIds = ref.read(selectedImageIdsProvider);
    String? selectedFolderId;

    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text('フォルダに移動 (${selectedIds.length}枚)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '移動先のフォルダを選択してください',
              style: TextStyle(color: NaiTheme.text2),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return ComboBox<String?>(
                  value: selectedFolderId,
                  placeholder: const Text('フォルダを選択'),
                  items: [
                    const ComboBoxItem<String?>(
                      value: null,
                      child: Text('(なし)'),
                    ),
                    ...folderState.folders.map((folder) {
                      return ComboBoxItem<String?>(
                        value: folder.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(FluentIcons.folder, size: 16),
                            const SizedBox(width: 8),
                            Text(folder.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => selectedFolderId = value);
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(imageListProvider.notifier).moveToFolder(
                selectedIds,
                selectedFolderId,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('移動'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(imageListProvider);
    // Watch explorerState for changes even if not directly used
    ref.watch(explorerProvider);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Row(
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
              // 検索バー（表示時のみ）
              if (_showSearch)
                _buildSearchBar(),
              // 画像グリッド
              Expanded(
                child: _buildContent(imageState),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: NaiTheme.bg2,
        border: Border(
          bottom: BorderSide(color: NaiTheme.bg3, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(FluentIcons.search, size: 14, color: NaiTheme.text2),
          const SizedBox(width: 8),
          Expanded(
            child: TextBox(
              controller: _searchController,
              placeholder: '検索... (Ctrl+F で閉じる)',
              autofocus: true,
              onChanged: (value) => _performSearch(value),
              onSubmitted: (value) => _performSearch(value),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(FluentIcons.cancel, size: 14, color: NaiTheme.text2),
            onPressed: () {
              setState(() {
                _showSearch = false;
                _searchController.clear();
              });
              _performSearch('');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ImageListState state) {
    final selectedCount = ref.watch(selectedImageIdsProvider).length;
    final thumbnailSize = ref.watch(thumbnailSizeProvider);
    final sortSettings = ref.watch(sortSettingsProvider);
    final viewMode = ref.watch(viewModeProvider);

    return Container(
      height: 52,
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
            '${state.pagination.totalCount} 枚',
            style: TextStyle(color: NaiTheme.text1, fontSize: 13),
          ),
          
          // 選択中の表示と一括操作
          if (selectedCount > 0) ...[
            _buildVerticalDivider(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: NaiTheme.accent.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$selectedCount 件選択中',
                style: TextStyle(color: NaiTheme.accent, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            // 一括操作ボタン群
            _buildIconButtonWithTooltip(
              icon: FluentIcons.select_all,
              tooltip: '全選択 (Ctrl+A)',
              onPressed: _selectAll,
            ),
            _buildIconButtonWithTooltip(
              icon: FluentIcons.heart,
              tooltip: 'お気に入りに追加',
              onPressed: _batchToggleFavorite,
            ),
            _buildIconButtonWithTooltip(
              icon: FluentIcons.tag,
              tooltip: 'タグを追加',
              onPressed: _showBatchAddTagDialog,
            ),
            _buildIconButtonWithTooltip(
              icon: FluentIcons.move_to_folder,
              tooltip: 'フォルダに移動',
              onPressed: _showBatchMoveDialog,
            ),
            _buildIconButtonWithTooltip(
              icon: FluentIcons.delete,
              tooltip: '削除 (Delete)',
              onPressed: _deleteSelected,
              color: NaiTheme.error,
            ),
            _buildIconButtonWithTooltip(
              icon: FluentIcons.cancel,
              tooltip: '選択解除 (Esc)',
              onPressed: () {
                ref.read(selectedImageIdsProvider.notifier).state = {};
              },
            ),
          ],
          
          const Spacer(),

          // 検索ボタン
          _buildIconButtonWithTooltip(
            icon: _showSearch ? FluentIcons.search : FluentIcons.search,
            tooltip: '検索 (Ctrl+F)',
            onPressed: () => setState(() => _showSearch = !_showSearch),
            isActive: _showSearch,
          ),

          _buildVerticalDivider(),

          // ソート
          _buildSortDropdown(sortSettings),

          _buildVerticalDivider(),

          // サムネイルサイズ
          _buildThumbnailSizeDropdown(thumbnailSize),

          _buildVerticalDivider(),
          
          // 表示モード切替（セグメントボタン風）
          _buildViewModeToggle(viewMode),
          
          _buildVerticalDivider(),
          
          // リフレッシュ
          _buildIconButtonWithTooltip(
            icon: FluentIcons.refresh,
            tooltip: '更新 (F5)',
            onPressed: () {
              ref.read(imageListProvider.notifier).refreshImages();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: NaiTheme.bg3,
    );
  }

  Widget _buildIconButtonWithTooltip({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? NaiTheme.accent.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 14,
            color: isActive ? NaiTheme.accent : (color ?? NaiTheme.text1),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildViewModeToggle(ViewMode currentMode) {
    return Container(
      decoration: BoxDecoration(
        color: NaiTheme.bg2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(
            icon: FluentIcons.grid_view_medium,
            label: 'グリッド',
            isSelected: currentMode == ViewMode.grid,
            onTap: () {
              ref.read(appSettingsProvider.notifier).updateViewOptions(
                (options) => options.copyWith(mode: ViewMode.grid),
              );
            },
          ),
          _buildViewModeButton(
            icon: FluentIcons.list,
            label: 'リスト',
            isSelected: currentMode == ViewMode.list,
            onTap: () {
              ref.read(appSettingsProvider.notifier).updateViewOptions(
                (options) => options.copyWith(mode: ViewMode.list),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? NaiTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? NaiTheme.bg0 : NaiTheme.text2,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? NaiTheme.bg0 : NaiTheme.text2,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailSizeDropdown(ThumbnailSize currentSize) {
    String getSizeLabel(ThumbnailSize size) {
      switch (size) {
        case ThumbnailSize.small:
          return '小';
        case ThumbnailSize.medium:
          return '中';
        case ThumbnailSize.large:
          return '大';
        case ThumbnailSize.xlarge:
          return '特大';
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(FluentIcons.picture_stretch, size: 14, color: NaiTheme.text2),
        const SizedBox(width: 4),
        ComboBox<ThumbnailSize>(
          value: currentSize,
          items: ThumbnailSize.values.map((size) {
            return ComboBoxItem<ThumbnailSize>(
              value: size,
              child: Text('${getSizeLabel(size)} (${size.pixels}px)'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(appSettingsProvider.notifier).updateViewOptions(
                (options) => options.copyWith(thumbnailSize: value),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSortDropdown(({SortBy sortBy, SortOrder sortOrder}) sortSettings) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(FluentIcons.sort, size: 14, color: NaiTheme.text2),
        const SizedBox(width: 4),
        ComboBox<String>(
          value: '${sortSettings.sortBy.name}_${sortSettings.sortOrder.name}',
          items: [
            ComboBoxItem<String>(value: 'date_desc', child: Text('日付（新しい順）')),
            ComboBoxItem<String>(value: 'date_asc', child: Text('日付（古い順）')),
            ComboBoxItem<String>(value: 'name_asc', child: Text('名前（A-Z）')),
            ComboBoxItem<String>(value: 'name_desc', child: Text('名前（Z-A）')),
            ComboBoxItem<String>(value: 'size_desc', child: Text('サイズ（大→小）')),
            ComboBoxItem<String>(value: 'size_asc', child: Text('サイズ（小→大）')),
          ],
          onChanged: (value) {
            if (value != null) {
              final parts = value.split('_');
              final sortBy = SortBy.values.firstWhere((s) => s.name == parts[0]);
              final sortOrder = SortOrder.values.firstWhere((o) => o.name == parts[1]);
              ref.read(appSettingsProvider.notifier).updateViewOptions(
                (options) => options.copyWith(sortBy: sortBy, sortOrder: sortOrder),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildContent(ImageListState state) {
    if (state.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ProgressRing(),
            const SizedBox(height: 16),
            Text(
              '画像を読み込み中...',
              style: TextStyle(color: NaiTheme.text2, fontSize: 13),
            ),
          ],
        ),
      );
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
            const SizedBox(height: 24),
            FilledButton(
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.upload, size: 16),
                  SizedBox(width: 8),
                  Text('画像をアップロード'),
                ],
              ),
              onPressed: () {
                UploadDialog.show(context);
              },
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
