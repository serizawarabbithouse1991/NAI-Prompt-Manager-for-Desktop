import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/danbooru_tag_service.dart';
import '../../providers/danbooru_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../services/suggestion_service.dart';
import '../themes/nai_theme.dart';

/// プロンプト提案画面
class SuggestionScreen extends ConsumerStatefulWidget {
  const SuggestionScreen({super.key});

  @override
  ConsumerState<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends ConsumerState<SuggestionScreen> {
  String? _lastDanbooruDbPath;

  @override
  void initState() {
    super.initState();
    // 初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final danbooruState = ref.read(danbooruServiceProvider);
      _lastDanbooruDbPath = danbooruState.dbPath;
      ref.read(suggestionProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suggestionProvider);
    
    // Danbooru状態の変化を監視し、DBパスが変わったら再初期化
    final danbooruState = ref.watch(danbooruServiceProvider);
    if (danbooruState.dbPath != _lastDanbooruDbPath && danbooruState.initialized) {
      _lastDanbooruDbPath = danbooruState.dbPath;
      // 次フレームで再初期化を実行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(suggestionProvider.notifier).refresh();
      });
    }

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('プロンプト提案'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('更新'),
              onPressed: state.loading
                  ? null
                  : () => ref.read(suggestionProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
      content: state.loading
          ? const Center(child: ProgressRing())
          : state.error != null
              ? _buildErrorState(state.error!)
              : _buildContent(state),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.error,
            size: 64,
            color: NaiTheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: NaiTheme.text2,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => ref.read(suggestionProvider.notifier).refresh(),
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SuggestionState state) {
    return Column(
      children: [
        // ステータスバナー
        if (!state.danbooruAvailable) _buildDanbooruWarning(),

        // 統計サマリー
        if (state.userAnalysis != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatsSummary(state),
          ),

        // タブとフィルタ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildTabsAndFilter(state),
        ),

        const SizedBox(height: 16),

        // コンテンツ
        Expanded(
          child: state.viewMode == SuggestionViewMode.tags
              ? _buildTagSuggestions(state)
              : _buildCombinationSuggestions(state),
        ),
      ],
    );
  }

  Widget _buildDanbooruWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: NaiTheme.warning.withAlpha(30),
      child: Row(
        children: [
          Icon(FluentIcons.warning, size: 16, color: NaiTheme.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Danbooruデータベースが見つかりません。タグ提案機能は制限されます。',
              style: TextStyle(
                fontSize: 12,
                color: NaiTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(SuggestionState state) {
    final analysis = state.userAnalysis!;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: FluentIcons.text_document,
            label: '総プロンプト数',
            value: analysis.totalPrompts.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: FluentIcons.tag,
            label: '使用タグ数',
            value: analysis.totalUniqueTags.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: FluentIcons.trending12,
            label: '新規提案',
            value: state.tagSuggestions.length.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabsAndFilter(SuggestionState state) {
    return Row(
      children: [
        // タブ切り替え
        ToggleSwitch(
          checked: state.viewMode == SuggestionViewMode.combinations,
          onChanged: (value) {
            ref.read(suggestionProvider.notifier).setViewMode(
                  value ? SuggestionViewMode.combinations : SuggestionViewMode.tags,
                );
          },
          content: Text(
            state.viewMode == SuggestionViewMode.tags ? 'タグ提案' : '組み合わせ提案',
          ),
        ),

        const SizedBox(width: 16),

        // カテゴリフィルタ（タグ提案モード時のみ）
        if (state.viewMode == SuggestionViewMode.tags) ...[
          const Text('カテゴリ: '),
          const SizedBox(width: 8),
          ComboBox<SuggestionCategoryFilter>(
            value: state.categoryFilter,
            items: SuggestionCategoryFilter.values
                .map((filter) => ComboBoxItem<SuggestionCategoryFilter>(
                      value: filter,
                      child: Text(filter.displayName),
                    ))
                .toList(),
            onChanged: (filter) {
              if (filter != null) {
                ref.read(suggestionProvider.notifier).setCategoryFilter(filter);
              }
            },
          ),
        ],

        const Spacer(),

        // ランダム発見ボタン
        if (state.danbooruAvailable)
          Button(
            onPressed: () => ref.read(suggestionProvider.notifier).shuffleRandomDiscovery(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.refresh, size: 14),
                SizedBox(width: 6),
                Text('ランダム発見'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTagSuggestions(SuggestionState state) {
    final tags = state.filteredTagSuggestions;

    if (tags.isEmpty) {
      return _buildEmptyState(
        icon: FluentIcons.search,
        title: '提案するタグがありません',
        subtitle: state.danbooruAvailable
            ? 'フィルタ条件を変更してみてください'
            : 'Danbooruデータベースを設定すると、より多くの提案が表示されます',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ランダム発見セクション
          if (state.randomDiscovery.isNotEmpty) ...[
            _buildSectionHeader('ランダム発見', FluentIcons.refresh),
            const SizedBox(height: 12),
            _buildTagGrid(state.randomDiscovery),
            const SizedBox(height: 24),
          ],

          // メイン提案セクション
          _buildSectionHeader('未使用の人気タグ', FluentIcons.trending12),
          const SizedBox(height: 12),
          _buildTagGrid(tags),
        ],
      ),
    );
  }

  Widget _buildCombinationSuggestions(SuggestionState state) {
    final combinations = state.combinationSuggestions;

    if (combinations.isEmpty) {
      return _buildEmptyState(
        icon: FluentIcons.combine,
        title: '組み合わせ提案がありません',
        subtitle: '画像をアップロードすると、あなたの傾向に合った組み合わせが提案されます',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: combinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final combination = combinations[index];
        return _CombinationCard(
          combination: combination,
          onCopy: () => _copyToClipboard(combination.toPromptString()),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: NaiTheme.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: NaiTheme.text0,
          ),
        ),
      ],
    );
  }

  Widget _buildTagGrid(List<SuggestedTag> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => _TagChip(
        tag: tag,
        onCopy: () => _copyToClipboard(tag.displayName),
      )).toList(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: NaiTheme.text2,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: NaiTheme.text2,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('コピーしました'),
        content: Text(text),
        severity: InfoBarSeverity.success,
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
    );
  }
}

/// 統計カード
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: NaiTheme.accent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NaiTheme.text0,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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

/// タグチップ
class _TagChip extends StatelessWidget {
  final SuggestedTag tag;
  final VoidCallback onCopy;

  const _TagChip({
    required this.tag,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${tag.reason ?? tag.category.displayName}\nクリックでコピー',
      child: GestureDetector(
        onTap: onCopy,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getCategoryColor(tag.category).withAlpha(30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getCategoryColor(tag.category).withAlpha(100),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getCategoryColor(tag.category),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tag.displayName,
                style: TextStyle(
                  fontSize: 13,
                  color: NaiTheme.text0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formatPopularity(tag.popularity),
                style: TextStyle(
                  fontSize: 11,
                  color: NaiTheme.text2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(DanbooruTagCategory category) {
    return Color(category.colorValue);
  }

  String _formatPopularity(int popularity) {
    if (popularity >= 1000000) {
      return '${(popularity / 1000000).toStringAsFixed(1)}M';
    }
    if (popularity >= 1000) {
      return '${(popularity / 1000).toStringAsFixed(1)}K';
    }
    return popularity.toString();
  }
}

/// 組み合わせカード
class _CombinationCard extends StatelessWidget {
  final SuggestedCombination combination;
  final VoidCallback onCopy;

  const _CombinationCard({
    required this.combination,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTypeIcon(combination.combinationType),
                size: 16,
                color: NaiTheme.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  combination.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: NaiTheme.text0,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(FluentIcons.copy, size: 14),
                onPressed: onCopy,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NaiTheme.bg2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              combination.toPromptString(),
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: NaiTheme.text0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: combination.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(tag.category.colorValue).withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag.category.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(tag.category.colorValue),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'character_exploration':
        return FluentIcons.people;
      case 'artist_exploration':
        return FluentIcons.design;
      case 'landscape_theme':
        return FluentIcons.picture;
      case 'clothing_theme':
        return FluentIcons.shirt;
      case 'expression_theme':
        return FluentIcons.emoji2;
      default:
        return FluentIcons.trending12;
    }
  }
}
