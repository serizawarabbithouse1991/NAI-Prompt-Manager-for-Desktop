import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/upload_history_repository.dart';
import '../../providers/database_provider.dart';
import '../themes/nai_theme.dart';

/// アップロード履歴プロバイダー
final uploadHistoryRepositoryProvider = Provider<UploadHistoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return UploadHistoryRepository(db);
});

/// 履歴リストプロバイダー
final uploadHistoryListProvider = FutureProvider.family<List<UploadHistoryModel>, String?>((ref, type) async {
  final repo = ref.watch(uploadHistoryRepositoryProvider);
  if (type == null) {
    return repo.getAllHistories();
  }
  return repo.getHistoriesByType(type);
});

/// アップロード履歴画面
class UploadHistoryScreen extends ConsumerStatefulWidget {
  const UploadHistoryScreen({super.key});

  @override
  ConsumerState<UploadHistoryScreen> createState() => _UploadHistoryScreenState();
}

class _UploadHistoryScreenState extends ConsumerState<UploadHistoryScreen> {
  int _selectedTab = 0;
  final _dateFormat = DateFormat('yyyy/MM/dd HH:mm');

  String? get _currentFilter {
    switch (_selectedTab) {
      case 1:
        return 'image';
      case 2:
        return 'zip';
      case 3:
        return 'folder';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(uploadHistoryListProvider(_currentFilter));

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('アップロード履歴'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.delete),
              label: const Text('履歴をクリア'),
              onPressed: () => _showClearDialog(context),
            ),
          ],
        ),
      ),
      content: Column(
        children: [
          // タブバー
          _buildTabBar(),
          const SizedBox(height: 16),
          
          // 履歴リスト
          Expanded(
            child: historyAsync.when(
              data: (histories) => _buildHistoryList(histories),
              loading: () => const Center(child: ProgressRing()),
              error: (e, _) => Center(
                child: Text(
                  'エラー: $e',
                  style: TextStyle(color: NaiTheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton(0, 'すべて', FluentIcons.history),
          const SizedBox(width: 8),
          _buildTabButton(1, '画像', FluentIcons.photo2),
          const SizedBox(width: 8),
          _buildTabButton(2, 'ZIP', FluentIcons.open_folder_horizontal),
          const SizedBox(width: 8),
          _buildTabButton(3, 'フォルダ', FluentIcons.folder),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return ToggleButton(
      checked: isSelected,
      onChanged: (_) {
        setState(() => _selectedTab = index);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<UploadHistoryModel> histories) {
    if (histories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.history, size: 64, color: NaiTheme.text2),
            const SizedBox(height: 16),
            Text(
              '履歴がありません',
              style: TextStyle(
                fontSize: 18,
                color: NaiTheme.text0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '画像をアップロードすると履歴が表示されます',
              style: TextStyle(
                fontSize: 14,
                color: NaiTheme.text2,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: histories.length,
      itemBuilder: (context, index) {
        final history = histories[index];
        return _buildHistoryItem(history);
      },
    );
  }

  Widget _buildHistoryItem(UploadHistoryModel history) {
    final icon = _getTypeIcon(history.type);
    final statusColor = _getStatusColor(history.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // アイコン
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NaiTheme.bg2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: NaiTheme.text1),
          ),
          const SizedBox(width: 12),
          
          // 情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.filename,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: NaiTheme.text0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      history.typeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: NaiTheme.text2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${history.successCount}/${history.fileCount}件成功',
                      style: TextStyle(
                        fontSize: 11,
                        color: NaiTheme.text2,
                      ),
                    ),
                    if (history.failCount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${history.failCount}件失敗',
                        style: TextStyle(
                          fontSize: 11,
                          color: NaiTheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // ステータス
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  history.statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dateFormat.format(history.uploadedAt),
                style: TextStyle(
                  fontSize: 10,
                  color: NaiTheme.text2,
                ),
              ),
            ],
          ),
          
          // 削除ボタン
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(FluentIcons.delete, size: 14, color: NaiTheme.text2),
            onPressed: () => _deleteHistory(history.id),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'image':
        return FluentIcons.photo2;
      case 'zip':
        return FluentIcons.open_folder_horizontal;
      case 'folder':
        return FluentIcons.folder;
      default:
        return FluentIcons.document;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return NaiTheme.success;
      case 'failed':
        return NaiTheme.error;
      case 'partial':
        return NaiTheme.warning;
      default:
        return NaiTheme.text1;
    }
  }

  Future<void> _deleteHistory(String id) async {
    final repo = ref.read(uploadHistoryRepositoryProvider);
    await repo.deleteHistory(id);
    ref.invalidate(uploadHistoryListProvider(_currentFilter));
  }

  Future<void> _showClearDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('履歴をクリア'),
        content: Text(
          _currentFilter == null
              ? 'すべての履歴を削除しますか？'
              : '${_getFilterName(_currentFilter!)}の履歴を削除しますか？',
        ),
        actions: [
          Button(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            child: const Text('削除'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      final repo = ref.read(uploadHistoryRepositoryProvider);
      if (_currentFilter == null) {
        await repo.clearAllHistories();
      } else {
        await repo.clearHistoriesByType(_currentFilter!);
      }
      ref.invalidate(uploadHistoryListProvider(_currentFilter));
    }
  }

  String _getFilterName(String type) {
    switch (type) {
      case 'image':
        return '画像';
      case 'zip':
        return 'ZIP';
      case 'folder':
        return 'フォルダ';
      default:
        return type;
    }
  }
}
