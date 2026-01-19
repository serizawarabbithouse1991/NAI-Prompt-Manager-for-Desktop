import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../themes/nai_theme.dart';
import '../screens/image_detail_dialog.dart';

/// 画像コンテキストメニュー
class ImageContextMenu {
  static OverlayEntry? _currentOverlay;

  /// コンテキストメニューを表示
  static void show(
    BuildContext context,
    WidgetRef ref,
    ImageWithDetails image,
    Offset position,
  ) {
    // 既存のメニューを閉じる
    _closeCurrentMenu();

    final selectedIds = ref.read(selectedImageIdsProvider);
    final isMultipleSelected = selectedIds.length > 1 && selectedIds.contains(image.id);
    final selectedCount = isMultipleSelected ? selectedIds.length : 1;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // 背景（タップで閉じる）
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _closeCurrentMenu(),
                child: Container(color: Colors.transparent),
              ),
            ),
            // メニュー本体
            Positioned(
              left: position.dx,
              top: position.dy,
              child: _buildMenu(context, ref, image, selectedIds, isMultipleSelected, selectedCount),
            ),
          ],
        );
      },
    );

    _currentOverlay = overlayEntry;
    Overlay.of(context).insert(overlayEntry);
  }

  static void _closeCurrentMenu() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  static Widget _buildMenu(
    BuildContext context,
    WidgetRef ref,
    ImageWithDetails image,
    Set<String> selectedIds,
    bool isMultipleSelected,
    int selectedCount,
  ) {
    void closeMenu() {
      _closeCurrentMenu();
    }

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: NaiTheme.bg1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NaiTheme.bg3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 開く
          _buildMenuItem(
            icon: FluentIcons.open_file,
            label: '開く',
            shortcut: 'Enter',
            onTap: () {
              closeMenu();
              // 画像リストとインデックスを取得してダイアログを開く
              final images = ref.read(imageListProvider).images;
              final imageIds = images.map((img) => img.id).toList();
              final index = imageIds.indexOf(image.id);
              ImageDetailDialog.show(
                context,
                imageIds: imageIds,
                initialIndex: index >= 0 ? index : 0,
              );
            },
          ),

          // エクスプローラーで表示
          _buildMenuItem(
            icon: FluentIcons.open_folder_horizontal,
            label: 'エクスプローラーで表示',
            onTap: () {
              closeMenu();
              _openInExplorer(image.filePath);
            },
          ),

          _buildDivider(),

          // お気に入り
          _buildMenuItem(
            icon: image.rating?.isFavorite == true
                ? FluentIcons.heart_fill
                : FluentIcons.heart,
            label: image.rating?.isFavorite == true
                ? 'お気に入りを解除'
                : 'お気に入りに追加',
            onTap: () {
              closeMenu();
              if (isMultipleSelected) {
                for (final id in selectedIds) {
                  ref.read(imageListProvider.notifier).toggleFavorite(id);
                }
              } else {
                ref.read(imageListProvider.notifier).toggleFavorite(image.id);
              }
            },
          ),

          // タグを追加
          _buildMenuItem(
            icon: FluentIcons.tag,
            label: isMultipleSelected ? 'タグを追加 ($selectedCount枚)' : 'タグを追加',
            onTap: () {
              closeMenu();
              _showAddTagDialog(context, ref, isMultipleSelected ? selectedIds : {image.id});
            },
          ),

          // フォルダに移動
          _buildMenuItem(
            icon: FluentIcons.move_to_folder,
            label: isMultipleSelected ? 'フォルダに移動 ($selectedCount枚)' : 'フォルダに移動',
            onTap: () {
              closeMenu();
              _showMoveToFolderDialog(context, ref, isMultipleSelected ? selectedIds : {image.id});
            },
          ),

          _buildDivider(),

          // パスをコピー
          _buildMenuItem(
            icon: FluentIcons.copy,
            label: 'パスをコピー',
            shortcut: 'Ctrl+C',
            onTap: () {
              closeMenu();
              Clipboard.setData(ClipboardData(text: image.filePath));
            },
          ),

          // プロンプトをコピー
          if (image.prompt?.positivePrompt != null)
            _buildMenuItem(
              icon: FluentIcons.text_document,
              label: 'プロンプトをコピー',
              onTap: () {
                closeMenu();
                Clipboard.setData(ClipboardData(text: image.prompt!.positivePrompt!));
              },
            ),

          _buildDivider(),

          // 削除
          _buildMenuItem(
            icon: FluentIcons.delete,
            label: isMultipleSelected ? '削除 ($selectedCount枚)' : '削除',
            isDestructive: true,
            shortcut: 'Del',
            onTap: () {
              closeMenu();
              _showDeleteConfirmDialog(
                context,
                ref,
                isMultipleSelected ? selectedIds : {image.id},
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    String? shortcut,
  }) {
    final color = isDestructive ? NaiTheme.error : NaiTheme.text0;

    return HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: states.isHovered ? NaiTheme.bg2 : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 13),
                ),
              ),
              if (shortcut != null)
                Text(
                  shortcut,
                  style: TextStyle(color: NaiTheme.text2, fontSize: 11),
                ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: NaiTheme.bg2,
    );
  }

  static Future<void> _openInExplorer(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final uri = Uri.file(file.parent.path);
      await launchUrl(uri);
    }
  }

  static void _showAddTagDialog(
    BuildContext context,
    WidgetRef ref,
    Set<String> imageIds,
  ) {
    final tagState = ref.read(tagListProvider);
    String? selectedTagId;

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text('タグを追加 (${imageIds.length}枚)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '追加するタグを選択してください',
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
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            onPressed: selectedTagId == null
                ? null
                : () {
                    final tag = tagState.tags.firstWhere((t) => t.id == selectedTagId);
                    for (final imageId in imageIds) {
                      ref.read(imageListProvider.notifier).addTagToImage(imageId, tag);
                    }
                    Navigator.pop(context);
                  },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  static void _showMoveToFolderDialog(
    BuildContext context,
    WidgetRef ref,
    Set<String> imageIds,
  ) {
    final folderState = ref.read(folderListProvider);
    String? selectedFolderId;

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text('フォルダに移動 (${imageIds.length}枚)'),
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
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(imageListProvider.notifier).moveToFolder(
                imageIds,
                selectedFolderId,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('移動'),
          ),
        ],
      ),
    );
  }

  static void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Set<String> imageIds,
  ) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('画像を削除'),
        content: Text(
          imageIds.length == 1
              ? 'この画像を削除しますか？\nこの操作は取り消せません。'
              : '${imageIds.length}枚の画像を削除しますか？\nこの操作は取り消せません。',
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
              for (final imageId in imageIds) {
                ref.read(imageListProvider.notifier).removeImage(imageId);
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
}
