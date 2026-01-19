import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../themes/nai_theme.dart';

/// エクスプローラーペイン（左サイドバー）
class ExplorerPane extends ConsumerWidget {
  const ExplorerPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderState = ref.watch(folderListProvider);
    final tagState = ref.watch(tagListProvider);
    final explorerState = ref.watch(explorerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // クイックアクセス
        _buildSection(
          title: 'クイックアクセス',
          children: [
            _QuickAccessItem(
              icon: FluentIcons.photo2,
              label: 'すべての画像',
              isSelected: explorerState.selectedFolderId == null && 
                          !explorerState.showUncategorized,
              onTap: () {
                ref.read(explorerProvider.notifier).selectAll();
                ref.read(imageListProvider.notifier).loadImages(const ImageFilter());
              },
            ),
            _QuickAccessItem(
              icon: FluentIcons.heart,
              label: 'お気に入り',
              isSelected: explorerState.showFavoritesOnly,
              onTap: () {
                ref.read(explorerProvider.notifier).selectFavorites();
                ref.read(imageListProvider.notifier).loadImages(
                  const ImageFilter(favoritesOnly: true),
                );
              },
            ),
            _QuickAccessItem(
              icon: FluentIcons.folder_open,
              label: '未分類',
              isSelected: explorerState.showUncategorized,
              onTap: () {
                ref.read(explorerProvider.notifier).selectUncategorized();
                ref.read(imageListProvider.notifier).loadImages(
                  const ImageFilter(uncategorizedOnly: true),
                );
              },
            ),
          ],
        ),
        
        const Divider(style: DividerThemeData(
          horizontalMargin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        )),
        
        // フォルダツリー
        Expanded(
          child: _buildSection(
            title: 'フォルダ',
            trailing: IconButton(
              icon: Icon(FluentIcons.add, size: 12, color: NaiTheme.text1),
              onPressed: () => _showCreateFolderDialog(context, ref),
            ),
            children: folderState.loading
                ? [const Center(child: ProgressRing())]
                : folderState.folderTree.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'フォルダがありません',
                            style: TextStyle(
                              color: NaiTheme.text2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ]
                    : folderState.folderTree
                        .map((folder) => _FolderTreeItem(
                              folder: folder,
                              level: 0,
                            ))
                        .toList(),
          ),
        ),
        
        const Divider(style: DividerThemeData(
          horizontalMargin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        )),
        
        // タグリスト
        Flexible(
          flex: 1,
          child: _buildSection(
            title: 'タグ',
            children: tagState.loading
                ? [const Center(child: ProgressRing())]
                : tagState.tags.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'タグがありません',
                            style: TextStyle(
                              color: NaiTheme.text2,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ]
                    : [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: tagState.tags.length,
                            itemBuilder: (context, index) {
                              final tag = tagState.tags[index];
                              return _TagItem(tag: tag);
                            },
                          ),
                        ),
                      ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: NaiTheme.text1,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('新規フォルダ'),
        content: TextBox(
          controller: controller,
          placeholder: 'フォルダ名',
          autofocus: true,
        ),
        actions: [
          Button(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('作成'),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref.read(folderListProvider.notifier).createFolder(
                  name: controller.text,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// クイックアクセスアイテム
class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: HoverButton(
        onPressed: onTap,
        builder: (context, states) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? NaiTheme.accent.withAlpha(30)
                  : states.isHovered
                      ? NaiTheme.bg2
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? NaiTheme.accent : NaiTheme.text1,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? NaiTheme.accent : NaiTheme.text0,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// フォルダツリーアイテム
class _FolderTreeItem extends ConsumerWidget {
  final FolderWithChildren folder;
  final int level;

  const _FolderTreeItem({
    required this.folder,
    required this.level,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorerState = ref.watch(explorerProvider);
    final isSelected = explorerState.selectedFolderId == folder.id;
    final isExpanded = explorerState.expandedFolderIds.contains(folder.id);
    final hasChildren = folder.children.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.0 + level * 16),
          child: HoverButton(
            onPressed: () {
              ref.read(explorerProvider.notifier).selectFolder(folder.id);
              ref.read(imageListProvider.notifier).loadImages(
                ImageFilter(folderId: folder.id),
              );
            },
            builder: (context, states) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? NaiTheme.accent.withAlpha(30)
                      : states.isHovered
                          ? NaiTheme.bg2
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    // 展開ボタン
                    if (hasChildren)
                      GestureDetector(
                        onTap: () {
                          ref.read(explorerProvider.notifier)
                              .toggleFolderExpanded(folder.id);
                        },
                        child: Icon(
                          isExpanded
                              ? FluentIcons.chevron_down
                              : FluentIcons.chevron_right,
                          size: 10,
                          color: NaiTheme.text2,
                        ),
                      )
                    else
                      const SizedBox(width: 10),
                    const SizedBox(width: 4),
                    // フォルダアイコン
                    Icon(
                      isExpanded ? FluentIcons.folder_open : FluentIcons.folder,
                      size: 14,
                      color: folder.color != null
                          ? Color(int.parse(folder.color!.replaceFirst('#', '0xFF')))
                          : (isSelected ? NaiTheme.accent : NaiTheme.text1),
                    ),
                    const SizedBox(width: 8),
                    // フォルダ名
                    Expanded(
                      child: Text(
                        folder.name,
                        style: TextStyle(
                          color: isSelected ? NaiTheme.accent : NaiTheme.text0,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 画像数
                    if (folder.imageCount != null && folder.imageCount! > 0)
                      Text(
                        '${folder.imageCount}',
                        style: TextStyle(
                          color: NaiTheme.text2,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        // 子フォルダ
        if (isExpanded && hasChildren)
          ...folder.children.map((child) => _FolderTreeItem(
                folder: child,
                level: level + 1,
              )),
      ],
    );
  }
}

/// タグアイテム
class _TagItem extends ConsumerWidget {
  final Tag tag;

  const _TagItem({required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagState = ref.watch(tagListProvider);
    final isSelected = tagState.selectedTagIds.contains(tag.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: HoverButton(
        onPressed: () {
          ref.read(tagListProvider.notifier).toggleTagSelection(tag.id);
          // TODO: タグフィルタを適用
        },
        builder: (context, states) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? NaiTheme.accent.withAlpha(30)
                  : states.isHovered
                      ? NaiTheme.bg2
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tag.color != null
                        ? Color(int.parse(tag.color!.replaceFirst('#', '0xFF')))
                        : NaiTheme.text2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tag.name,
                    style: TextStyle(
                      color: isSelected ? NaiTheme.accent : NaiTheme.text0,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
