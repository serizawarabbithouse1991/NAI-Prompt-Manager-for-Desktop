import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repositories.dart';
import '../../providers/providers.dart';
import '../../services/danbooru_tagging_service.dart';
import '../themes/nai_theme.dart';

/// 一括タグ付けダイアログ
class BulkTaggingDialog extends ConsumerStatefulWidget {
  const BulkTaggingDialog({super.key});

  @override
  ConsumerState<BulkTaggingDialog> createState() => _BulkTaggingDialogState();

  /// ダイアログを表示
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BulkTaggingDialog(),
    );
  }
}

class _BulkTaggingDialogState extends ConsumerState<BulkTaggingDialog> {
  TaggingMode _selectedMode = TaggingMode.untaggedOnly;
  bool _isProcessing = false;
  TaggingProgress? _progress;
  String? _error;
  bool _isComplete = false;

  Future<void> _startTagging() async {
    setState(() {
      _isProcessing = true;
      _error = null;
      _isComplete = false;
    });

    final db = ref.read(databaseProvider);
    final imageRepository = ImageRepository(db);
    final tagRepository = TagRepository(db);
    
    final service = DanbooruTaggingService(
      imageRepository: imageRepository,
      tagRepository: tagRepository,
    );

    try {
      await for (final progress in service.tagImages(mode: _selectedMode)) {
        if (!mounted) return;
        
        setState(() {
          _progress = progress;
          if (progress.isComplete) {
            _isComplete = true;
            _isProcessing = false;
          }
          if (progress.error != null && progress.total == 0) {
            _error = progress.error;
            _isProcessing = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(
        _isProcessing || _isComplete ? 'タグ付け中...' : 'Danbooruタグ一括付与',
        style: TextStyle(color: NaiTheme.text0),
      ),
      content: SizedBox(
        width: 400,
        child: _isProcessing || _isComplete
            ? _buildProgressContent()
            : _buildModeSelectionContent(),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildModeSelectionContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MD5ハッシュを使ってDanbooruからタグを取得し、画像に付与します。',
          style: TextStyle(color: NaiTheme.text1, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Text(
          'タグ付けの対象を選択してください：',
          style: TextStyle(
            color: NaiTheme.text0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _buildModeOption(
          mode: TaggingMode.untaggedOnly,
          title: 'タグがない画像のみ',
          description: 'まだタグが付いていない画像だけを対象にします',
          icon: FluentIcons.tag,
        ),
        const SizedBox(height: 8),
        _buildModeOption(
          mode: TaggingMode.all,
          title: '全画像',
          description: 'すべての画像を対象にします（既存のタグは保持）',
          icon: FluentIcons.photo2,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NaiTheme.error.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: NaiTheme.error.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(FluentIcons.error_badge, size: 16, color: NaiTheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: NaiTheme.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModeOption({
    required TaggingMode mode,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? NaiTheme.accent.withAlpha(20) : NaiTheme.bg2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? NaiTheme.accent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? NaiTheme.accent : NaiTheme.text2,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? NaiTheme.accent : NaiTheme.text0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(color: NaiTheme.text2, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(FluentIcons.check_mark, size: 16, color: NaiTheme.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContent() {
    final progress = _progress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (progress != null) ...[
          // 進捗バー
          ProgressBar(
            value: progress.progress * 100,
          ),
          const SizedBox(height: 12),

          // 現在処理中のファイル
          if (progress.currentImageName != null && !_isComplete)
            Text(
              '処理中: ${progress.currentImageName}',
              style: TextStyle(color: NaiTheme.text1, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 16),

          // 統計情報
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NaiTheme.bg2,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  '進捗',
                  '${progress.current} / ${progress.total} 画像',
                ),
                const SizedBox(height: 4),
                _buildStatRow(
                  'タグ付け済み',
                  '${progress.imagesTagged} 画像',
                  color: NaiTheme.success,
                ),
                const SizedBox(height: 4),
                _buildStatRow(
                  'スキップ',
                  '${progress.imagesSkipped} 画像',
                  color: NaiTheme.text2,
                ),
                const SizedBox(height: 4),
                _buildStatRow(
                  '付与タグ数',
                  '${progress.tagsApplied} タグ',
                  color: NaiTheme.accent,
                ),
              ],
            ),
          ),

          if (_isComplete) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NaiTheme.success.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(FluentIcons.check_mark, size: 16, color: NaiTheme.success),
                  const SizedBox(width: 8),
                  Text(
                    '完了しました',
                    style: TextStyle(
                      color: NaiTheme.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NaiTheme.error.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(FluentIcons.error_badge, size: 16, color: NaiTheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: NaiTheme.error),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const Center(child: ProgressRing()),
        ],
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: NaiTheme.text2, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? NaiTheme.text0,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_isComplete) {
      return [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ];
    }

    if (_isProcessing) {
      return [
        Button(
          onPressed: null,
          child: const Text('キャンセル'),
        ),
      ];
    }

    return [
      Button(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('キャンセル'),
      ),
      FilledButton(
        onPressed: _startTagging,
        child: const Text('開始'),
      ),
    ];
  }
}
