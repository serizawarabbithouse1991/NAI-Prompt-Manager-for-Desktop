import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../themes/nai_theme.dart';

/// プロンプト分析画面
class PromptAnalysisScreen extends ConsumerWidget {
  const PromptAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageState = ref.watch(imageListProvider);
    final rescanState = ref.watch(rescanProvider);

    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: const Text('プロンプト分析'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('更新'),
              onPressed: imageState.loading || rescanState.isScanning
                  ? null
                  : () => ref.read(imageListProvider.notifier).refreshImages(),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.search),
              label: const Text('再スキャン'),
              onPressed: imageState.loading || rescanState.isScanning
                  ? null
                  : () => _showRescanDialog(context, ref),
            ),
          ],
        ),
      ),
      children: [
        // 再スキャン進捗表示
        if (rescanState.isScanning || rescanState.isComplete)
          _buildRescanProgress(context, ref, rescanState),
        
        if (imageState.loading)
          const Center(child: ProgressRing())
        else if (imageState.images.isEmpty)
          _buildEmptyState()
        else
          _buildAnalysisContent(imageState),
      ],
    );
  }

  void _showRescanDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('メタデータ再スキャン'),
        content: const Text(
          '全画像ファイルからメタデータを再抽出します。\n'
          'この処理には時間がかかる場合があります。\n\n'
          'どの画像を対象にしますか？',
        ),
        actions: [
          Button(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(context),
          ),
          Button(
            child: const Text('プロンプトなしのみ'),
            onPressed: () => Navigator.pop(context, 'without_prompt'),
          ),
          FilledButton(
            child: const Text('すべて'),
            onPressed: () => Navigator.pop(context, 'all'),
          ),
        ],
      ),
    );

    if (result != null) {
      ref.read(rescanProvider.notifier).startRescan(
        onlyWithoutPrompt: result == 'without_prompt',
      );
    }
  }

  Widget _buildRescanProgress(BuildContext context, WidgetRef ref, RescanState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isComplete ? FluentIcons.check_mark : FluentIcons.search,
                  color: state.isComplete ? Colors.green : NaiTheme.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  state.isComplete ? '再スキャン完了' : '再スキャン中...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: NaiTheme.text0,
                  ),
                ),
                const Spacer(),
                if (state.isScanning)
                  Button(
                    child: const Text('キャンセル'),
                    onPressed: () => ref.read(rescanProvider.notifier).cancel(),
                  )
                else if (state.isComplete)
                  IconButton(
                    icon: const Icon(FluentIcons.chrome_close),
                    onPressed: () {
                      ref.read(rescanProvider.notifier).reset();
                      // 完了後にデータを更新
                      ref.read(imageListProvider.notifier).refreshImages();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isScanning) ...[
              ProgressBar(value: state.progress * 100),
              const SizedBox(height: 8),
              Text(
                '${state.currentCount} / ${state.totalCount}',
                style: TextStyle(fontSize: 12, color: NaiTheme.text2),
              ),
              if (state.currentFile != null)
                Text(
                  state.currentFile!,
                  style: TextStyle(fontSize: 12, color: NaiTheme.text2),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _buildStatChip('新規', state.newCount, Colors.green),
                _buildStatChip('更新', state.updatedCount, Colors.blue),
                _buildStatChip('スキップ', state.skippedCount, Colors.grey),
                if (state.failedCount > 0)
                  _buildStatChip('失敗', state.failedCount, Colors.red),
              ],
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(fontSize: 12, color: NaiTheme.text1),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            FluentIcons.chart,
            size: 64,
            color: NaiTheme.text2,
          ),
          const SizedBox(height: 16),
          Text(
            '分析するデータがありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '画像をアップロードすると、プロンプトの統計情報が表示されます。',
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

  Widget _buildAnalysisContent(ImageListState state) {
    // プロンプトデータを集計
    final promptStats = _analyzePrompts(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 概要
        _buildOverviewSection(state, promptStats),
        const SizedBox(height: 24),

        // モデル統計
        _buildSectionHeader('使用モデル'),
        const SizedBox(height: 12),
        _buildModelStats(promptStats.modelCounts),
        const SizedBox(height: 24),

        // サンプラー統計
        _buildSectionHeader('サンプラー'),
        const SizedBox(height: 12),
        _buildSamplerStats(promptStats.samplerCounts),
        const SizedBox(height: 24),

        // パラメータ分布
        _buildSectionHeader('パラメータ分布'),
        const SizedBox(height: 12),
        _buildParameterStats(promptStats),
      ],
    );
  }

  Widget _buildOverviewSection(ImageListState state, _PromptStats stats) {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            icon: FluentIcons.image_search,
            label: '画像数',
            value: state.pagination.totalCount.toString(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _OverviewCard(
            icon: FluentIcons.text_document,
            label: 'プロンプト付き',
            value: stats.withPromptCount.toString(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _OverviewCard(
            icon: FluentIcons.processing,
            label: '使用モデル数',
            value: stats.modelCounts.length.toString(),
          ),
        ),
      ],
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

  Widget _buildModelStats(Map<String, int> modelCounts) {
    if (modelCounts.isEmpty) {
      return _buildNoDataCard('モデル情報がありません');
    }

    final sortedModels = modelCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sortedModels.take(5).map((entry) {
          final total = modelCounts.values.reduce((a, b) => a + b);
          final percentage = (entry.value / total * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: TextStyle(color: NaiTheme.text0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ProgressBar(value: entry.value / total * 100),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: Text(
                    '${entry.value} ($percentage%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: NaiTheme.text1,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSamplerStats(Map<String, int> samplerCounts) {
    if (samplerCounts.isEmpty) {
      return _buildNoDataCard('サンプラー情報がありません');
    }

    final sortedSamplers = samplerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sortedSamplers.take(10).map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: NaiTheme.bg2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${entry.key} (${entry.value})',
              style: TextStyle(
                fontSize: 12,
                color: NaiTheme.text0,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildParameterStats(_PromptStats stats) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildParameterRow('平均ステップ数', stats.avgSteps?.toStringAsFixed(1) ?? '-'),
          const SizedBox(height: 8),
          _buildParameterRow('平均CFG Scale', stats.avgCfgScale?.toStringAsFixed(2) ?? '-'),
          const SizedBox(height: 8),
          _buildParameterRow('最頻解像度', stats.commonResolution ?? '-'),
        ],
      ),
    );
  }

  Widget _buildParameterRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: NaiTheme.text1),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: NaiTheme.text0,
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataCard(String message) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: NaiTheme.text2),
        ),
      ),
    );
  }

  _PromptStats _analyzePrompts(ImageListState state) {
    final modelCounts = <String, int>{};
    final samplerCounts = <String, int>{};
    final resolutionCounts = <String, int>{};
    final steps = <int>[];
    final cfgScales = <double>[];
    var withPromptCount = 0;

    for (final image in state.images) {
      final prompt = image.prompt;
      if (prompt != null) {
        withPromptCount++;

        if (prompt.model != null && prompt.model!.isNotEmpty) {
          modelCounts[prompt.model!] = (modelCounts[prompt.model!] ?? 0) + 1;
        }

        if (prompt.sampler != null && prompt.sampler!.isNotEmpty) {
          samplerCounts[prompt.sampler!] = (samplerCounts[prompt.sampler!] ?? 0) + 1;
        }

        if (prompt.steps != null) {
          steps.add(prompt.steps!);
        }

        if (prompt.cfgScale != null) {
          cfgScales.add(prompt.cfgScale!);
        }

        if (prompt.resolutionWidth != null && prompt.resolutionHeight != null) {
          final res = '${prompt.resolutionWidth}x${prompt.resolutionHeight}';
          resolutionCounts[res] = (resolutionCounts[res] ?? 0) + 1;
        }
      }
    }

    String? commonResolution;
    if (resolutionCounts.isNotEmpty) {
      final sorted = resolutionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      commonResolution = sorted.first.key;
    }

    return _PromptStats(
      withPromptCount: withPromptCount,
      modelCounts: modelCounts,
      samplerCounts: samplerCounts,
      avgSteps: steps.isEmpty ? null : steps.reduce((a, b) => a + b) / steps.length,
      avgCfgScale: cfgScales.isEmpty ? null : cfgScales.reduce((a, b) => a + b) / cfgScales.length,
      commonResolution: commonResolution,
    );
  }
}

class _PromptStats {
  final int withPromptCount;
  final Map<String, int> modelCounts;
  final Map<String, int> samplerCounts;
  final double? avgSteps;
  final double? avgCfgScale;
  final String? commonResolution;

  const _PromptStats({
    required this.withPromptCount,
    required this.modelCounts,
    required this.samplerCounts,
    this.avgSteps,
    this.avgCfgScale,
    this.commonResolution,
  });
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 24, color: NaiTheme.accent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
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
