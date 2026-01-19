import 'dart:io';
import 'dart:ui' as ui;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../screens/image_detail_dialog.dart';
import '../themes/nai_theme.dart';
import 'image_context_menu.dart';

/// 最後にクリックした画像のインデックスを保持（Shift+クリック用）
int? _lastClickedIndex;

/// 画像グリッドウィジェット
class ImageGrid extends ConsumerWidget {
  final List<ImageWithDetails> images;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;

  const ImageGrid({
    super.key,
    required this.images,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailSize = ref.watch(thumbnailSizeProvider);
    final selectedIds = ref.watch(selectedImageIdsProvider);
    final viewMode = ref.watch(viewModeProvider);
    final itemSize = thumbnailSize.pixels.toDouble() + 16;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.extentAfter < 200 && hasMore && !loadingMore) {
            onLoadMore();
          }
        }
        return false;
      },
      child: viewMode == ViewMode.list
          ? _buildListView(context, ref, selectedIds)
          : _buildGridView(context, ref, selectedIds, itemSize, thumbnailSize),
    );
  }

  /// グリッド表示
  Widget _buildGridView(BuildContext context, WidgetRef ref, Set<String> selectedIds, double itemSize, ThumbnailSize thumbnailSize) {
    return GridView.builder(
      key: ValueKey('grid_${thumbnailSize.pixels}'),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: itemSize,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length + (loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= images.length) {
          return const Center(child: ProgressRing());
        }

        final image = images[index];
        final isSelected = selectedIds.contains(image.id);

        return ImageTile(
          key: ValueKey('tile_${image.id}_${thumbnailSize.pixels}'),
          image: image,
          isSelected: isSelected,
          thumbnailSize: thumbnailSize,
          onTap: () => _handleTap(context, ref, image, isSelected, index),
          onDoubleTap: () => _handleDoubleTap(context, ref, image, index),
          onSecondaryTapUp: (details) => _handleSecondaryTap(context, ref, image, details),
        );
      },
    );
  }

  /// リスト表示（Windows 11 エクスプローラー風）
  Widget _buildListView(BuildContext context, WidgetRef ref, Set<String> selectedIds) {
    return Column(
      children: [
        // ヘッダー行
        _buildListHeader(),
        // リスト本体
        Expanded(
          child: ListView.builder(
            key: const ValueKey('list_view'),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: images.length + (loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= images.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: ProgressRing()),
                );
              }

              final image = images[index];
              final isSelected = selectedIds.contains(image.id);

              return ImageListItem(
                image: image,
                isSelected: isSelected,
                onTap: () => _handleTap(context, ref, image, isSelected, index),
                onDoubleTap: () => _handleDoubleTap(context, ref, image, index),
                onSecondaryTapUp: (details) => _handleSecondaryTap(context, ref, image, details),
              );
            },
          ),
        ),
      ],
    );
  }

  /// リストヘッダー
  Widget _buildListHeader() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: NaiTheme.bg1,
        border: Border(
          bottom: BorderSide(color: NaiTheme.bg3, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 48), // サムネイル用スペース
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              '名前',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NaiTheme.text1,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '更新日時',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NaiTheme.text1,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'サイズ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NaiTheme.text1,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '解像度',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NaiTheme.text1,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, ImageWithDetails image, bool isSelected, int index) {
    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final currentSelection = ref.read(selectedImageIdsProvider);

    if (isCtrlPressed) {
      // Ctrl+クリック: トグル選択
      if (isSelected) {
        ref.read(selectedImageIdsProvider.notifier).state = 
            currentSelection.difference({image.id});
      } else {
        ref.read(selectedImageIdsProvider.notifier).state = 
            currentSelection.union({image.id});
      }
      _lastClickedIndex = index;
    } else if (isShiftPressed && _lastClickedIndex != null) {
      // Shift+クリック: 範囲選択
      final start = _lastClickedIndex! < index ? _lastClickedIndex! : index;
      final end = _lastClickedIndex! > index ? _lastClickedIndex! : index;
      final rangeIds = images.sublist(start, end + 1).map((img) => img.id).toSet();
      ref.read(selectedImageIdsProvider.notifier).state = 
          currentSelection.union(rangeIds);
    } else {
      // 通常クリック: 単一選択/選択解除
      if (isSelected && currentSelection.length == 1) {
        // 既に選択中で唯一の選択なら選択解除
        ref.read(selectedImageIdsProvider.notifier).state = {};
      } else {
        // それ以外は単一選択
        ref.read(selectedImageIdsProvider.notifier).state = {image.id};
      }
      _lastClickedIndex = index;
    }
  }

  void _handleDoubleTap(BuildContext context, WidgetRef ref, ImageWithDetails image, int index) {
    // ダブルクリックで詳細モーダルを開く
    final imageIds = images.map((img) => img.id).toList();
    ImageDetailDialog.show(
      context,
      imageIds: imageIds,
      initialIndex: index,
    );
  }

  /// 右クリックでコンテキストメニュー
  void _handleSecondaryTap(BuildContext context, WidgetRef ref, ImageWithDetails image, TapUpDetails details) {
    // 選択されていない場合は選択状態にする
    final selectedIds = ref.read(selectedImageIdsProvider);
    if (!selectedIds.contains(image.id)) {
      ref.read(selectedImageIdsProvider.notifier).state = {image.id};
    }
    
    // コンテキストメニューを表示
    ImageContextMenu.show(context, ref, image, details.globalPosition);
  }
}

/// 画像タイルウィジェット
class ImageTile extends ConsumerStatefulWidget {
  final ImageWithDetails image;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final void Function(TapUpDetails)? onSecondaryTapUp;
  final ThumbnailSize thumbnailSize;

  const ImageTile({
    super.key,
    required this.image,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    this.onSecondaryTapUp,
    this.thumbnailSize = ThumbnailSize.medium,
  });

  @override
  ConsumerState<ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends ConsumerState<ImageTile> {
  bool _isHovered = false;
  bool _blurRevealed = false; // ユーザーがぼかしを一時的に解除

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider).settings;
    final isNsfw = widget.image.isNsfw == true;
    final shouldBlur = isNsfw && appSettings.blurNSFW && !_blurRevealed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _blurRevealed = false; // マウスが離れたらぼかしをリセット
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onSecondaryTapUp: widget.onSecondaryTapUp,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected 
                  ? NaiTheme.accent 
                  : (_isHovered ? NaiTheme.bg3 : Colors.transparent),
              width: widget.isSelected ? 2 : 1,
            ),
            color: NaiTheme.bg1,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // サムネイル（ぼかし付き）
                _buildThumbnail(context, shouldBlur),
                
                // ぼかし解除オーバーレイ
                if (shouldBlur && _isHovered)
                  _buildBlurRevealOverlay(),
                
                // オーバーレイ（ホバー時）
                if ((_isHovered || widget.isSelected) && !shouldBlur)
                  _buildOverlay(),
                
                // お気に入りバッジ
                if (widget.image.rating?.isFavorite == true)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: NaiTheme.bg0.withAlpha(200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        FluentIcons.heart_fill,
                        size: 12,
                        color: NaiTheme.error,
                      ),
                    ),
                  ),
                
                // NSFWバッジ
                if (isNsfw)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: NaiTheme.warning.withAlpha(200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NSFW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: NaiTheme.bg0,
                        ),
                      ),
                    ),
                  ),
                
                // タグ数
                if (widget.image.tags.isNotEmpty && !shouldBlur)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: NaiTheme.bg0.withAlpha(200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.tag, size: 10, color: NaiTheme.text1),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.image.tags.length}',
                            style: TextStyle(fontSize: 10, color: NaiTheme.text1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurRevealOverlay() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // イベント伝播を止めてぼかしのみ解除
        setState(() => _blurRevealed = true);
      },
      child: Container(
        color: NaiTheme.bg0.withAlpha(150),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.view, size: 24, color: NaiTheme.text0),
              const SizedBox(height: 4),
              Text(
                'クリックで表示',
                style: TextStyle(
                  fontSize: 10,
                  color: NaiTheme.text0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, bool shouldBlur) {
    final thumbnailPath = widget.image.thumbnailPath;
    final filePath = widget.image.filePath;

    // 大きいサムネイルサイズ（200px以上）の場合は元画像を使用して高品質表示
    // 小さいサイズの場合はサムネイルを使用してメモリ節約
    final useOriginal = widget.thumbnailSize.pixels >= 200;
    final path = useOriginal ? filePath : (thumbnailPath ?? filePath);
    final file = File(path);

    Widget thumbnail;
    if (file.existsSync()) {
      // HiDPI対応: デバイスピクセル比を考慮してキャッシュサイズを計算
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      // 高品質表示のため、最低でも2倍のキャッシュサイズを確保
      final minScale = useOriginal ? 2.0 : 1.0;
      final scale = devicePixelRatio > minScale ? devicePixelRatio : minScale;
      final cacheSize = (widget.thumbnailSize.pixels * scale).toInt();
      
      thumbnail = Image.file(
        file,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        cacheWidth: cacheSize,
        // cacheHeightは指定しない（アスペクト比を維持するため自動計算）
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    } else {
      thumbnail = _buildPlaceholder();
    }

    // ぼかし効果を適用
    if (shouldBlur) {
      return ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: thumbnail,
      );
    }

    return thumbnail;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: NaiTheme.bg2,
      child: Center(
        child: Icon(
          FluentIcons.photo2,
          size: 32,
          color: NaiTheme.text2,
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            NaiTheme.bg0.withAlpha(150),
          ],
          stops: const [0.6, 1.0],
        ),
      ),
      child: widget.isSelected
          ? Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: NaiTheme.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    FluentIcons.check_mark,
                    size: 14,
                    color: NaiTheme.bg0,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// リスト表示用アイテム（Windows 11 エクスプローラー風）
class ImageListItem extends ConsumerStatefulWidget {
  final ImageWithDetails image;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final void Function(TapUpDetails)? onSecondaryTapUp;

  const ImageListItem({
    super.key,
    required this.image,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    this.onSecondaryTapUp,
  });

  @override
  ConsumerState<ImageListItem> createState() => _ImageListItemState();
}

class _ImageListItemState extends ConsumerState<ImageListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final modifiedDate = widget.image.createdAt;
    final isNsfw = widget.image.isNsfw == true;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onSecondaryTapUp: widget.onSecondaryTapUp,
        child: Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? NaiTheme.accent.withAlpha(40)
                : _isHovered
                    ? NaiTheme.bg2
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: widget.isSelected
                ? Border.all(color: NaiTheme.accent, width: 1)
                : null,
          ),
          child: Row(
            children: [
              // サムネイル
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: NaiTheme.bg2,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildMiniThumbnail(),
              ),
              const SizedBox(width: 12),
              
              // ファイル名
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    // お気に入りアイコン
                    if (widget.image.rating?.isFavorite == true)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          FluentIcons.heart_fill,
                          size: 12,
                          color: NaiTheme.error,
                        ),
                      ),
                    // NSFWバッジ
                    if (isNsfw)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: NaiTheme.warning.withAlpha(200),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          'NSFW',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: NaiTheme.bg0,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        widget.image.filename ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.isSelected ? NaiTheme.accent : NaiTheme.text0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // タグ数
                    if (widget.image.tags.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: NaiTheme.bg3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.tag, size: 10, color: NaiTheme.text2),
                            const SizedBox(width: 2),
                            Text(
                              '${widget.image.tags.length}',
                              style: TextStyle(fontSize: 10, color: NaiTheme.text2),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // 更新日時
              SizedBox(
                width: 100,
                child: Text(
                  dateFormat.format(modifiedDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: NaiTheme.text2,
                  ),
                ),
              ),
              
              // ファイルサイズ
              SizedBox(
                width: 80,
                child: Text(
                  _formatFileSize(widget.image.fileSize ?? 0),
                  style: TextStyle(
                    fontSize: 12,
                    color: NaiTheme.text2,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              
              // 解像度
              SizedBox(
                width: 80,
                child: Text(
                  widget.image.width != null && widget.image.height != null
                      ? '${widget.image.width}x${widget.image.height}'
                      : '-',
                  style: TextStyle(
                    fontSize: 12,
                    color: NaiTheme.text2,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniThumbnail() {
    final thumbnailPath = widget.image.thumbnailPath;
    final filePath = widget.image.filePath;
    final path = thumbnailPath ?? filePath;
    final file = File(path);

    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(FluentIcons.photo2, size: 16, color: NaiTheme.text2);
        },
      );
    }
    return Icon(FluentIcons.photo2, size: 16, color: NaiTheme.text2);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
