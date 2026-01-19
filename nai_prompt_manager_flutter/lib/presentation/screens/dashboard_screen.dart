import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../themes/nai_theme.dart';
import 'upload_dialog.dart';

/// ダッシュボード画面（ホーム）
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(imageListProvider);
    final folderState = ref.watch(folderListProvider);
    final tagState = ref.watch(tagListProvider);

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('ホーム')),
      children: [
        // 統計カード
        _buildStatsRow(
          imageCount: imageState.pagination.totalCount,
          folderCount: folderState.folders.length,
          tagCount: tagState.tags.length,
        ),
        const SizedBox(height: 24),

        // クイックアクション
        _buildQuickActions(context),
        const SizedBox(height: 24),

        // ようこそメッセージ（画像がない場合）
        if (imageState.images.isEmpty && !imageState.loading)
          _buildWelcomeCard(context),

        // 最近の画像（画像がある場合）
        if (imageState.images.isNotEmpty) ...[
          _buildSectionHeader('最近の画像'),
          const SizedBox(height: 12),
          _buildRecentImages(imageState.images.take(8).toList()),
        ],
      ],
    );
  }

  Widget _buildStatsRow({
    required int imageCount,
    required int folderCount,
    required int tagCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: FluentIcons.photo2,
            label: '画像',
            value: imageCount.toString(),
            color: NaiTheme.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: FluentIcons.folder,
            label: 'フォルダ',
            value: folderCount.toString(),
            color: NaiTheme.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: FluentIcons.tag,
            label: 'タグ',
            value: tagCount.toString(),
            color: NaiTheme.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('クイックアクション'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionButton(
              icon: FluentIcons.upload,
              label: '画像をアップロード',
              onPressed: () => UploadDialog.show(context),
            ),
            _ActionButton(
              icon: FluentIcons.new_folder,
              label: 'フォルダを作成',
              onPressed: () {
                // TODO: フォルダ作成ダイアログ
              },
            ),
            _ActionButton(
              icon: FluentIcons.search,
              label: '画像を検索',
              onPressed: () {
                // ナビゲーションで検索画面へ移動
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            FluentIcons.photo2,
            size: 64,
            color: NaiTheme.accent.withAlpha(150),
          ),
          const SizedBox(height: 16),
          Text(
            'PromptVaultへようこそ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI生成画像とプロンプトを管理するツールです。\n画像をアップロードして始めましょう。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: NaiTheme.text2,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => UploadDialog.show(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.upload, size: 16),
                SizedBox(width: 8),
                Text('画像をアップロード'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: NaiTheme.text0,
      ),
    );
  }

  Widget _buildRecentImages(List images) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final dynamic image = images[index];
          return Container(
            width: 150,
            decoration: BoxDecoration(
              color: NaiTheme.bg2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FluentIcons.photo2, size: 32, color: NaiTheme.text2),
                  const SizedBox(height: 8),
                  Text(
                    image.filename ?? 'No name',
                    style: TextStyle(
                      fontSize: 11,
                      color: NaiTheme.text1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NaiTheme.text0,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: NaiTheme.text2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// アクションボタン
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
