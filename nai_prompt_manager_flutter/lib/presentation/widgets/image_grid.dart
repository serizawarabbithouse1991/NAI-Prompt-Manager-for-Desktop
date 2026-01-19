import 'dart:io';
import 'dart:ui' as ui;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      child: GridView.builder(
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
            image: image,
            isSelected: isSelected,
            onTap: () => _handleTap(context, ref, image, isSelected, index),
            onDoubleTap: () => _handleDoubleTap(context, ref, image),
            onSecondaryTapUp: (details) => _handleSecondaryTap(context, ref, image, details),
          );
        },
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

  void _handleDoubleTap(BuildContext context, WidgetRef ref, ImageWithDetails image) {
    // ダブルクリックで詳細モーダルを開く
    ImageDetailDialog.show(context, image.id);
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

  const ImageTile({
    super.key,
    required this.image,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    this.onSecondaryTapUp,
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
                _buildThumbnail(shouldBlur),
                
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

  Widget _buildThumbnail(bool shouldBlur) {
    final thumbnailPath = widget.image.thumbnailPath;
    final filePath = widget.image.filePath;

    // サムネイルがあればそれを使用
    final path = thumbnailPath ?? filePath;
    final file = File(path);

    Widget thumbnail;
    if (file.existsSync()) {
      thumbnail = Image.file(
        file,
        fit: BoxFit.cover,
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
