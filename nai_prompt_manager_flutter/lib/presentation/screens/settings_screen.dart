import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/services.dart';
import '../themes/nai_theme.dart';

/// 設定画面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  TauriDbInfo? _tauriDbInfo;
  bool _checkingTauriDb = false;
  String? _importStatus;

  @override
  void initState() {
    super.initState();
    _checkTauriDb();
  }

  Future<void> _checkTauriDb() async {
    setState(() => _checkingTauriDb = true);
    
    try {
      final dbPath = await DatabaseMigrationService.findTauriDbPath();
      if (dbPath != null) {
        _tauriDbInfo = await DatabaseMigrationService.getTauriDbInfo(dbPath);
      }
    } catch (e) {
      // エラーは無視
    }
    
    setState(() => _checkingTauriDb = false);
  }

  Future<void> _importTauriDb() async {
    if (_tauriDbInfo == null) return;
    
    setState(() => _importStatus = 'インポート中...');
    
    try {
      await DatabaseMigrationService.copyTauriDbToFlutter(_tauriDbInfo!.path);
      setState(() => _importStatus = 'インポート完了。アプリを再起動してください。');
    } catch (e) {
      setState(() => _importStatus = 'エラー: $e');
    }
  }

  Future<void> _selectDbFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite', 'sqlite3'],
    );
    
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final isValid = await DatabaseMigrationService.isValidPromptManagerDb(path);
      
      if (isValid) {
        final info = await DatabaseMigrationService.getTauriDbInfo(path);
        if (info != null) {
          setState(() {
            _tauriDbInfo = info;
            _importStatus = null;
          });
        }
      } else {
        setState(() => _importStatus = '無効なDBファイルです');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('設定')),
      children: [
        _buildSection(
          title: 'データベース移行',
          icon: FluentIcons.database,
          children: [
            _buildTauriDbCard(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: '表示設定',
          icon: FluentIcons.view,
          children: [
            _buildPlaceholderCard('サムネイルサイズ、グリッド/リスト表示の設定'),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'アプリケーション',
          icon: FluentIcons.settings,
          children: [
            _buildPlaceholderCard('テーマ、言語、自動タグ設定など'),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTauriDbCard() {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tauri版からの移行',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '既存のTauri版NAI Prompt Managerのデータをインポートできます。',
            style: TextStyle(
              fontSize: 13,
              color: NaiTheme.text2,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_checkingTauriDb)
            const Row(
              children: [
                ProgressRing(strokeWidth: 2),
                SizedBox(width: 8),
                Text('Tauri版を検索中...'),
              ],
            )
          else if (_tauriDbInfo != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NaiTheme.bg2,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FluentIcons.database, size: 14, color: NaiTheme.success),
                      const SizedBox(width: 8),
                      Text(
                        'Tauri版DBを検出しました',
                        style: TextStyle(
                          color: NaiTheme.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'パス: ${_tauriDbInfo!.path}',
                    style: TextStyle(fontSize: 12, color: NaiTheme.text1),
                  ),
                  Text(
                    'サイズ: ${_tauriDbInfo!.sizeFormatted}',
                    style: TextStyle(fontSize: 12, color: NaiTheme.text1),
                  ),
                  Text(
                    '更新日時: ${_tauriDbInfo!.modified}',
                    style: TextStyle(fontSize: 12, color: NaiTheme.text1),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NaiTheme.bg2,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(FluentIcons.info, size: 14, color: NaiTheme.text2),
                  const SizedBox(width: 8),
                  Text(
                    'Tauri版のDBが見つかりませんでした',
                    style: TextStyle(color: NaiTheme.text2),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Button(
                onPressed: _selectDbFile,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.folder_open, size: 14),
                    SizedBox(width: 6),
                    Text('DBファイルを選択'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_tauriDbInfo != null)
                FilledButton(
                  onPressed: _importTauriDb,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.download, size: 14),
                      SizedBox(width: 6),
                      Text('インポート'),
                    ],
                  ),
                ),
            ],
          ),
          
          if (_importStatus != null) ...[
            const SizedBox(height: 12),
            Text(
              _importStatus!,
              style: TextStyle(
                fontSize: 12,
                color: _importStatus!.contains('エラー')
                    ? NaiTheme.error
                    : NaiTheme.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(String description) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(FluentIcons.settings, size: 24, color: NaiTheme.text2),
          const SizedBox(width: 12),
          Text(
            description,
            style: TextStyle(color: NaiTheme.text2),
          ),
        ],
      ),
    );
  }
}
