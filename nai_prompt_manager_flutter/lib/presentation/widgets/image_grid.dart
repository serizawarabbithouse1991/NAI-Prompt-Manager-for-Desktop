import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../themes/nai_theme.dart';

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
            onTap: () => _handleTap(ref, image, isSelected),
            onDoubleTap: () => _handleDoubleTap(context, ref, image),
          );
        },
      ),
    );
  }

  void _handleTap(WidgetRef ref, ImageWithDetails image, bool isSelected) {
    final currentSelection = ref.read(selectedImageIdsProvider);
    if (isSelected) {
      ref.read(selectedImageIdsProvider.notifier).state = 
          currentSelection.difference({image.id});
    } else {
      ref.read(selectedImageIdsProvider.notifier).state = 
          currentSelection.union({image.id});
    }
  }

  void _handleDoubleTap(BuildContext context, WidgetRef ref, ImageWithDetails image) {
    // 画像詳細を開く
    ref.read(selectedImageIdsProvider.notifier).state = {image.id};
    // TODO: ImageDetailダイアログを開く
  }
}

/// 画像タイルウィジェット
class ImageTile extends StatefulWidget {
  final ImageWithDetails image;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const ImageTile({
    super.key,
    required this.image,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  State<ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<ImageTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
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
                // サムネイル
                _buildThumbnail(),
                
                // オーバーレイ（ホバー時）
                if (_isHovered || widget.isSelected)
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
                if (widget.image.isNsfw == true)
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
                if (widget.image.tags.isNotEmpty)
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

  Widget _buildThumbnail() {
    final thumbnailPath = widget.image.thumbnailPath;
    final filePath = widget.image.filePath;

    // サムネイルがあればそれを使用
    final path = thumbnailPath ?? filePath;
    final file = File(path);

    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    return _buildPlaceholder();
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
