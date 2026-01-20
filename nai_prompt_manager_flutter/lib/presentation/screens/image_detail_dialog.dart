import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../services/danbooru_tagging_service.dart';
import '../themes/nai_theme.dart';

/// 画像詳細ダイアログ
class ImageDetailDialog extends ConsumerStatefulWidget {
  final List<String> imageIds;
  final int initialIndex;

  const ImageDetailDialog({
    super.key,
    required this.imageIds,
    required this.initialIndex,
  });

  @override
  ConsumerState<ImageDetailDialog> createState() => _ImageDetailDialogState();

  /// ダイアログを表示
  static Future<void> show(
    BuildContext context, {
    required List<String> imageIds,
    required int initialIndex,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      dismissWithEsc: false, // キーボードナビゲーションのため無効化
      builder: (dialogContext) => ImageDetailDialog(
        imageIds: imageIds,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _ImageDetailDialogState extends ConsumerState<ImageDetailDialog> {
  int _selectedTab = 0;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// 現在の画像ID
  String get _currentImageId => widget.imageIds[_currentIndex];

  /// 前の画像があるかどうか
  bool get _hasPrevious => _currentIndex > 0;

  /// 次の画像があるかどうか
  bool get _hasNext => _currentIndex < widget.imageIds.length - 1;

  /// ナビゲーションを表示するかどうか（画像が2枚以上の場合）
  bool get _showNavigation => widget.imageIds.length > 1;

  /// 前の画像へ遷移
  void _goPrevious() {
    if (_hasPrevious) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  /// 次の画像へ遷移
  void _goNext() {
    if (_hasNext) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  /// キーボードイベントハンドラ
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // 左矢印キー: 前の画像へ
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goPrevious();
      return KeyEventResult.handled;
    }

    // 右矢印キー: 次の画像へ
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goNext();
      return KeyEventResult.handled;
    }

    // Escapeキー: ダイアログを閉じる
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(imageListProvider);
    final image = imageState.images.where((img) => img.id == _currentImageId).firstOrNull;

    if (image == null) {
      return ContentDialog(
        title: const Text('エラー'),
        content: const Text('画像が見つかりません'),
        actions: [
          FilledButton(
            child: const Text('閉じる'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: ContentDialog(
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
        content: SizedBox(
          width: 1100,
          height: 650,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左側: 画像プレビュー
              Expanded(
                flex: 3,
                child: _buildImagePreview(image),
              ),
              const SizedBox(width: 16),
              // 右側: 情報パネル
              SizedBox(
                width: 350,
                child: _buildInfoPanel(image),
              ),
            ],
          ),
        ),
        actions: _buildActions(image),
      ),
    );
  }

  /// アクションボタンを構築
  List<Widget> _buildActions(ImageWithDetails image) {
    return [
      // ナビゲーションボタン（2枚以上の場合のみ表示）
      if (_showNavigation) ...[
        Button(
          onPressed: _hasPrevious ? _goPrevious : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.chevron_left, size: 12),
              const SizedBox(width: 4),
              const Text('前へ'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${_currentIndex + 1} / ${widget.imageIds.length}',
            style: TextStyle(color: NaiTheme.text1, fontSize: 13),
          ),
        ),
        Button(
          onPressed: _hasNext ? _goNext : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('次へ'),
              const SizedBox(width: 4),
              Icon(FluentIcons.chevron_right, size: 12),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
      Button(
        child: const Text('閉じる'),
        onPressed: () => Navigator.pop(context),
      ),
      FilledButton(
        child: const Text('エクスプローラーで開く'),
        onPressed: () => _openInExplorer(image.filePath),
      ),
    ];
  }

  Widget _buildImagePreview(ImageWithDetails image) {
    final file = File(image.filePath);

    return Container(
      decoration: BoxDecoration(
        color: NaiTheme.bg0,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 画像本体
            file.existsSync()
                ? InteractiveViewer(
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FluentIcons.photo2, size: 64, color: NaiTheme.text2),
                        const SizedBox(height: 16),
                        Text(
                          'ファイルが見つかりません',
                          style: TextStyle(color: NaiTheme.text2),
                        ),
                      ],
                    ),
                  ),
            
            // オーバーレイナビゲーションボタン（2枚以上の場合のみ）
            if (_showNavigation) ...[
              // 前へボタン（左端）
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _buildOverlayNavButton(
                  icon: FluentIcons.chevron_left,
                  onPressed: _hasPrevious ? _goPrevious : null,
                  alignment: Alignment.centerLeft,
                ),
              ),
              // 次へボタン（右端）
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _buildOverlayNavButton(
                  icon: FluentIcons.chevron_right,
                  onPressed: _hasNext ? _goNext : null,
                  alignment: Alignment.centerRight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// オーバーレイナビゲーションボタンを構築
  Widget _buildOverlayNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Alignment alignment,
  }) {
    return _HoverNavButton(
      icon: icon,
      onPressed: onPressed,
      alignment: alignment,
    );
  }

  Widget _buildInfoPanel(ImageWithDetails image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ファイル名
        Text(
          image.filename ?? 'Unknown',
          style: TextStyle(
            color: NaiTheme.text0,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        
        // アクションボタン
        Row(
          children: [
            // お気に入りボタン
            IconButton(
              icon: Icon(
                image.rating?.isFavorite == true
                    ? FluentIcons.heart_fill
                    : FluentIcons.heart,
                size: 18,
                color: image.rating?.isFavorite == true
                    ? NaiTheme.error
                    : NaiTheme.text1,
              ),
              onPressed: () {
                ref.read(imageListProvider.notifier)
                    .toggleFavorite(image.id);
              },
            ),
            const SizedBox(width: 8),
            // タグ追加ボタン
            IconButton(
              icon: Icon(FluentIcons.tag, size: 16, color: NaiTheme.text1),
              onPressed: () => _showAddTagDialog(image),
            ),
            const SizedBox(width: 8),
            // フォルダ移動ボタン
            IconButton(
              icon: Icon(FluentIcons.folder_open, size: 16, color: NaiTheme.text1),
              onPressed: () => _showMoveToFolderDialog(image),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // タブ
        Expanded(
          child: TabView(
            currentIndex: _selectedTab,
            onChanged: (index) => setState(() => _selectedTab = index),
            tabWidthBehavior: TabWidthBehavior.sizeToContent,
            closeButtonVisibility: CloseButtonVisibilityMode.never,
            tabs: [
              Tab(
                text: const Text('プロンプト'),
                body: _buildPromptTab(image),
              ),
              Tab(
                text: const Text('情報'),
                body: _buildInfoTab(image),
              ),
              Tab(
                text: const Text('タグ'),
                body: _buildTagsTab(image),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptTab(ImageWithDetails image) {
    final prompt = image.prompt;

    if (prompt == null) {
      return Center(
        child: Text(
          'プロンプト情報がありません',
          style: TextStyle(color: NaiTheme.text2),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Positive Prompt
          _buildPromptSection(
            title: 'Positive Prompt',
            content: prompt.positivePrompt ?? '',
            color: NaiTheme.success,
          ),
          const SizedBox(height: 16),
          
          // Negative Prompt
          _buildPromptSection(
            title: 'Negative Prompt',
            content: prompt.negativePrompt ?? '',
            color: NaiTheme.error,
          ),
          const SizedBox(height: 16),
          
          // 生成設定
          _buildKeyValueGrid([
            ('モデル', prompt.model ?? '-'),
            ('サンプラー', prompt.sampler ?? '-'),
            ('ステップ', prompt.steps?.toString() ?? '-'),
            ('CFG Scale', prompt.cfgScale?.toString() ?? '-'),
            ('シード', prompt.seed?.toString() ?? '-'),
            ('解像度', '${prompt.resolutionWidth ?? '-'} x ${prompt.resolutionHeight ?? '-'}'),
          ]),
        ],
      ),
    );
  }

  Widget _buildPromptSection({
    required String title,
    required String content,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: NaiTheme.text1,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Tooltip(
              message: 'クリップボードにコピー',
              child: IconButton(
                icon: Icon(FluentIcons.copy, size: 12, color: NaiTheme.text2),
                onPressed: () {
                  if (content.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: content));
                    _showCopyNotification('コピーしました');
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: NaiTheme.bg2,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            content.isEmpty ? '-' : content,
            style: TextStyle(
              color: NaiTheme.text0,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _showCopyNotification(String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(message),
        severity: InfoBarSeverity.success,
      ),
      duration: const Duration(seconds: 2),
    );
  }

  Widget _buildInfoTab(ImageWithDetails image) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: _buildKeyValueGrid([
        ('ファイル名', image.filename ?? '-'),
        ('ファイルサイズ', _formatFileSize(image.fileSize)),
        ('画像サイズ', '${image.width ?? '-'} x ${image.height ?? '-'}'),
        ('ファイルパス', image.filePath),
        ('作成日時', image.createdAt.toString()),
        ('ソースタイプ', image.prompt?.sourceType.displayName ?? 'Unknown'),
        ('NSFWスコア', image.nsfwScore?.toStringAsFixed(2) ?? '-'),
      ]),
    );
  }

  Widget _buildTagsTab(ImageWithDetails image) {
    final danbooruState = ref.watch(danbooruServiceProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Danbooruタグ取得ボタン
        if (danbooruState.available)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Button(
              onPressed: () => _fetchDanbooruTags(image),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.sync, size: 14, color: NaiTheme.accent),
                  const SizedBox(width: 6),
                  const Text('Danbooruタグを取得'),
                ],
              ),
            ),
          ),
        
        // タグ一覧
        Expanded(
          child: image.tags.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'タグがありません',
                        style: TextStyle(color: NaiTheme.text2),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        child: const Text('タグを追加'),
                        onPressed: () => _showAddTagDialog(image),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: image.tags.map((tag) {
                      return Button(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tag.color != null)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: Color(int.parse(tag.color!.replaceFirst('#', '0xFF'))),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            Text(tag.name),
                          ],
                        ),
                        onPressed: () {
                          // TODO: タグで絞り込み
                        },
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  /// Danbooruからタグを取得して付与
  Future<void> _fetchDanbooruTags(ImageWithDetails image) async {
    final db = ref.read(databaseProvider);
    final imageRepository = ImageRepository(db);
    final tagRepository = TagRepository(db);
    
    final service = DanbooruTaggingService(
      imageRepository: imageRepository,
      tagRepository: tagRepository,
    );

    // 処理中のインジケーターを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ContentDialog(
        title: const Text('Danbooruタグ取得中'),
        content: Row(
          children: [
            const ProgressRing(),
            const SizedBox(width: 16),
            Text('MD5ハッシュで検索しています...', style: TextStyle(color: NaiTheme.text1)),
          ],
        ),
      ),
    );

    try {
      final tags = await service.tagImage(image.id);
      
      if (mounted) {
        Navigator.pop(context); // ダイアログを閉じる
        
        if (tags.isEmpty) {
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Danbooruに一致する画像が見つかりませんでした'),
              severity: InfoBarSeverity.warning,
            ),
            duration: const Duration(seconds: 3),
          );
        } else {
          // 画像リストを更新
          ref.read(imageListProvider.notifier).refreshImages();
          
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: Text('${tags.length}件のタグを付与しました'),
              severity: InfoBarSeverity.success,
            ),
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: Text('エラー: $e'),
            severity: InfoBarSeverity.error,
          ),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Widget _buildKeyValueGrid(List<(String, String)> items) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  item.$1,
                  style: TextStyle(
                    color: NaiTheme.text2,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  item.$2,
                  style: TextStyle(
                    color: NaiTheme.text0,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showAddTagDialog(ImageWithDetails image) {
    final tagState = ref.read(tagListProvider);
    String? selectedTagId;

    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('タグを追加'),
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
            onPressed: () => Navigator.pop(ctx),
          ),
          FilledButton(
            onPressed: selectedTagId == null
                ? null
                : () {
                    final tag = tagState.tags.firstWhere((t) => t.id == selectedTagId);
                    ref.read(imageListProvider.notifier).addTagToImage(image.id, tag);
                    Navigator.pop(ctx);
                  },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderDialog(ImageWithDetails image) {
    final folderState = ref.read(folderListProvider);
    String? selectedFolderId;

    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('フォルダに移動'),
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
                {image.id},
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

  Future<void> _openInExplorer(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final uri = Uri.file(file.parent.path);
      await launchUrl(uri);
    }
  }
}

/// ホバー時に表示されるナビゲーションボタン
class _HoverNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Alignment alignment;

  const _HoverNavButton({
    required this.icon,
    required this.onPressed,
    required this.alignment,
  });

  @override
  State<_HoverNavButton> createState() => _HoverNavButtonState();
}

class _HoverNavButtonState extends State<_HoverNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isHovered ? 1.0 : 0.0,
          child: Container(
            width: 60,
            alignment: widget.alignment,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: widget.alignment == Alignment.centerLeft
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                end: widget.alignment == Alignment.centerLeft
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                colors: [
                  NaiTheme.bg0.withAlpha(180),
                  Colors.transparent,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? NaiTheme.bg2.withAlpha(150)
                      : NaiTheme.bg1.withAlpha(220),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDisabled ? NaiTheme.bg3 : NaiTheme.accent,
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: isDisabled ? NaiTheme.text2 : NaiTheme.text0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
