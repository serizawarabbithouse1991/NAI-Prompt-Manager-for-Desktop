import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../themes/nai_theme.dart';
import '../widgets/image_grid.dart';

/// 検索画面
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  
  bool _showFilters = false;
  String? _selectedFolderId;
  Set<String> _selectedTagIds = {};
  DateTimeRange? _dateRange;
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    
    ref.read(imageListProvider.notifier).loadImages(
      ImageFilter(
        searchQuery: query.isEmpty ? null : query,
        folderId: _selectedFolderId,
        favoritesOnly: _favoritesOnly,
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedFolderId = null;
      _selectedTagIds = {};
      _dateRange = null;
      _favoritesOnly = false;
    });
    ref.read(imageListProvider.notifier).loadImages(const ImageFilter());
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(imageListProvider);
    final folderState = ref.watch(folderListProvider);
    final tagState = ref.watch(tagListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 検索バー
        _buildSearchBar(),
        
        // フィルタ
        if (_showFilters)
          _buildFilters(folderState.folders, tagState.tags),
        
        // 検索結果ヘッダー
        _buildResultsHeader(imageState),
        
        // 検索結果
        Expanded(
          child: _buildResults(imageState),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NaiTheme.bg1,
        border: Border(
          bottom: BorderSide(color: NaiTheme.bg2, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 検索入力
          Expanded(
            child: TextBox(
              controller: _searchController,
              focusNode: _focusNode,
              placeholder: 'プロンプト、ファイル名で検索...',
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(FluentIcons.search, size: 16, color: NaiTheme.text2),
              ),
              suffix: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(FluentIcons.cancel, size: 12, color: NaiTheme.text2),
                      onPressed: _clearSearch,
                    )
                  : null,
              onSubmitted: (_) => _performSearch(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          
          // 検索ボタン
          FilledButton(
            onPressed: _performSearch,
            child: const Text('検索'),
          ),
          const SizedBox(width: 8),
          
          // フィルタボタン
          ToggleButton(
            checked: _showFilters,
            onChanged: (v) => setState(() => _showFilters = v),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.filter, size: 14),
                const SizedBox(width: 4),
                const Text('フィルタ'),
                if (_hasActiveFilters())
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: NaiTheme.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _countActiveFilters().toString(),
                      style: TextStyle(
                        color: NaiTheme.bg0,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<Folder> folders, List<Tag> tags) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NaiTheme.bg1,
        border: Border(
          bottom: BorderSide(color: NaiTheme.bg2, width: 1),
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          // フォルダ選択
          _buildFilterDropdown<String?>(
            label: 'フォルダ',
            value: _selectedFolderId,
            items: [
              const ComboBoxItem<String?>(value: null, child: Text('すべて')),
              ...folders.map((f) => ComboBoxItem<String?>(
                value: f.id,
                child: Text(f.name),
              )),
            ],
            onChanged: (v) {
              setState(() => _selectedFolderId = v);
              _performSearch();
            },
          ),
          
          // お気に入りフィルタ
          ToggleSwitch(
            checked: _favoritesOnly,
            onChanged: (v) {
              setState(() => _favoritesOnly = v);
              _performSearch();
            },
            content: const Text('お気に入りのみ'),
          ),
          
          // タグ選択（複数選択可）
          _buildTagFilter(tags),
          
          // クリアボタン
          if (_hasActiveFilters())
            Button(
              onPressed: _clearSearch,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.clear_filter, size: 14),
                  const SizedBox(width: 4),
                  const Text('フィルタをクリア'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T value,
    required List<ComboBoxItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            color: NaiTheme.text1,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        ComboBox<T>(
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTagFilter(List<Tag> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'タグ:',
          style: TextStyle(
            color: NaiTheme.text1,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Wrap(
          spacing: 4,
          children: tags.take(10).map((tag) {
            final isSelected = _selectedTagIds.contains(tag.id);
            return ToggleButton(
              checked: isSelected,
              onChanged: (checked) {
                setState(() {
                  if (checked) {
                    _selectedTagIds.add(tag.id);
                  } else {
                    _selectedTagIds.remove(tag.id);
                  }
                });
                _performSearch();
              },
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
                  Text(tag.name, style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsHeader(ImageListState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${state.pagination.totalCount} 件の結果',
            style: TextStyle(
              color: NaiTheme.text1,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (_searchController.text.isNotEmpty)
            Text(
              '「${_searchController.text}」の検索結果',
              style: TextStyle(
                color: NaiTheme.text2,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults(ImageListState state) {
    if (state.loading) {
      return const Center(child: ProgressRing());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.error, size: 48, color: NaiTheme.error),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: TextStyle(color: NaiTheme.text0, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(color: NaiTheme.text2, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (state.images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.search, size: 64, color: NaiTheme.text2),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? '検索条件を入力してください'
                  : '検索結果がありません',
              style: TextStyle(color: NaiTheme.text0, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'プロンプトやファイル名で画像を検索できます'
                  : '別のキーワードで試してみてください',
              style: TextStyle(color: NaiTheme.text2, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ImageGrid(
      images: state.images,
      hasMore: state.pagination.hasMore,
      loadingMore: state.loadingMore,
      onLoadMore: () {
        ref.read(imageListProvider.notifier).loadMoreImages();
      },
    );
  }

  bool _hasActiveFilters() {
    return _selectedFolderId != null ||
        _selectedTagIds.isNotEmpty ||
        _dateRange != null ||
        _favoritesOnly;
  }

  int _countActiveFilters() {
    var count = 0;
    if (_selectedFolderId != null) count++;
    if (_selectedTagIds.isNotEmpty) count++;
    if (_dateRange != null) count++;
    if (_favoritesOnly) count++;
    return count;
  }
}
