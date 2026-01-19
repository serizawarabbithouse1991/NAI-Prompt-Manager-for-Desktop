import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../providers/providers.dart';
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

  // Danbooru DB
  DanbooruDbStats? _danbooruStats;
  bool _loadingDanbooru = false;
  String? _danbooruStatus;

  @override
  void initState() {
    super.initState();
    _checkTauriDb();
    _checkDanbooruDb();
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

  Future<void> _checkDanbooruDb() async {
    final service = DanbooruService();
    if (service.isConfigured) {
      final stats = await service.getStats();
      setState(() => _danbooruStats = stats);
    }
  }

  Future<void> _selectDanbooruDb() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite', 'sqlite3'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _loadingDanbooru = true;
        _danbooruStatus = null;
      });

      final path = result.files.single.path!;
      final service = DanbooruService();
      final success = await service.openDatabase(path);

      if (success) {
        final stats = await service.getStats();
        setState(() {
          _danbooruStats = stats;
          _danbooruStatus = 'Danbooru DBを読み込みました';
          _loadingDanbooru = false;
        });
      } else {
        setState(() {
          _danbooruStatus = '無効なDanbooru DBファイルです';
          _loadingDanbooru = false;
        });
      }
    }
  }

  void _closeDanbooruDb() {
    final service = DanbooruService();
    service.close();
    setState(() {
      _danbooruStats = null;
      _danbooruStatus = 'Danbooru DBを閉じました';
    });
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
          title: 'Danbooru自動タグ付け',
          icon: FluentIcons.tag,
          children: [
            _buildDanbooruCard(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'NSFW表示設定',
          icon: FluentIcons.shield,
          children: [
            _buildNsfwSettingsCard(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'NSFW自動判定',
          icon: FluentIcons.processing,
          children: [
            _buildNsfwDetectionCard(),
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

  Widget _buildDanbooruCard() {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danbooru DBによる自動タグ付け',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'danbooru.dbをインポートすると、画像のMD5ハッシュに基づいてDanbooruタグが自動的に付与されます。',
            style: TextStyle(
              fontSize: 13,
              color: NaiTheme.text2,
            ),
          ),
          const SizedBox(height: 16),

          if (_loadingDanbooru)
            const Row(
              children: [
                ProgressRing(strokeWidth: 2),
                SizedBox(width: 8),
                Text('読み込み中...'),
              ],
            )
          else if (_danbooruStats != null)
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
                      Icon(FluentIcons.tag, size: 14, color: NaiTheme.success),
                      const SizedBox(width: 8),
                      Text(
                        'Danbooru DBが設定されています',
                        style: TextStyle(
                          color: NaiTheme.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '投稿数: ${_danbooruStats!.postCountFormatted}',
                    style: TextStyle(fontSize: 12, color: NaiTheme.text1),
                  ),
                  Text(
                    'タグ数: ${_danbooruStats!.tagCountFormatted}',
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
                    'Danbooru DBが設定されていません',
                    style: TextStyle(color: NaiTheme.text2),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          Row(
            children: [
              Button(
                onPressed: _selectDanbooruDb,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.folder_open, size: 14),
                    SizedBox(width: 6),
                    Text('DBファイルを選択'),
                  ],
                ),
              ),
              if (_danbooruStats != null) ...[
                const SizedBox(width: 8),
                Button(
                  onPressed: _closeDanbooruDb,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.cancel, size: 14),
                      SizedBox(width: 6),
                      Text('解除'),
                    ],
                  ),
                ),
              ],
            ],
          ),

          if (_danbooruStatus != null) ...[
            const SizedBox(height: 12),
            Text(
              _danbooruStatus!,
              style: TextStyle(
                fontSize: 12,
                color: _danbooruStatus!.contains('無効')
                    ? NaiTheme.error
                    : NaiTheme.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNsfwSettingsCard() {
    final appSettings = ref.watch(appSettingsProvider).settings;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NSFW画像の表示制御',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NSFW（Not Safe For Work）としてマークされた画像の表示方法を設定します。',
            style: TextStyle(
              fontSize: 13,
              color: NaiTheme.text2,
            ),
          ),
          const SizedBox(height: 16),

          // NSFW画像を表示するかどうか
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NSFW画像を表示',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: NaiTheme.text0,
                      ),
                    ),
                    Text(
                      'オフにするとNSFW画像がギャラリーに表示されなくなります',
                      style: TextStyle(
                        fontSize: 11,
                        color: NaiTheme.text2,
                      ),
                    ),
                  ],
                ),
              ),
              ToggleSwitch(
                checked: appSettings.showNSFW,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).setNsfwSettings(
                    showNSFW: value,
                  );
                  // 画像リストを再読み込み
                  ref.read(imageListProvider.notifier).refreshImages();
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(style: DividerThemeData(decoration: BoxDecoration(color: NaiTheme.bg2))),
          const SizedBox(height: 16),

          // NSFWサムネイルをぼかす
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NSFWサムネイルをぼかす',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: NaiTheme.text0,
                      ),
                    ),
                    Text(
                      'NSFW画像のサムネイルにぼかし効果を適用します',
                      style: TextStyle(
                        fontSize: 11,
                        color: NaiTheme.text2,
                      ),
                    ),
                  ],
                ),
              ),
              ToggleSwitch(
                checked: appSettings.blurNSFW,
                onChanged: appSettings.showNSFW
                    ? (value) {
                        ref.read(appSettingsProvider.notifier).setNsfwSettings(
                          blurNSFW: value,
                        );
                      }
                    : null,
              ),
            ],
          ),

          if (!appSettings.showNSFW) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NaiTheme.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: NaiTheme.warning.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(FluentIcons.info, size: 14, color: NaiTheme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NSFW画像が非表示のため、ぼかし設定は無効です',
                      style: TextStyle(
                        fontSize: 11,
                        color: NaiTheme.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNsfwDetectionCard() {
    final nsfwState = ref.watch(nsfwServiceProvider);
    final appSettings = ref.watch(appSettingsProvider).settings;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'プロンプトベースNSFW判定',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '画像のプロンプトを分析してNSFWコンテンツを自動検出します。',
            style: TextStyle(
              fontSize: 13,
              color: NaiTheme.text2,
            ),
          ),
          const SizedBox(height: 16),

          // NSFW自動判定を有効化
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NSFW自動判定を有効にする',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: NaiTheme.text0,
                      ),
                    ),
                    Text(
                      '新規インポート時にプロンプトからNSFWレベルを判定',
                      style: TextStyle(
                        fontSize: 11,
                        color: NaiTheme.text2,
                      ),
                    ),
                  ],
                ),
              ),
              ToggleSwitch(
                checked: appSettings.nsfwDetectionEnabled,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).setNsfwSettings(
                    nsfwDetectionEnabled: value,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(style: DividerThemeData(decoration: BoxDecoration(color: NaiTheme.bg2))),
          const SizedBox(height: 16),

          // しきい値設定
          Text(
            'NSFWしきい値: ${(nsfwState.nsfwThreshold * 100).toInt()}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'このスコア以上でNSFWと判定されます',
            style: TextStyle(
              fontSize: 11,
              color: NaiTheme.text2,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: nsfwState.nsfwThreshold * 100,
            min: 10,
            max: 90,
            divisions: 8,
            onChanged: appSettings.nsfwDetectionEnabled
                ? (value) {
                    ref.read(nsfwServiceProvider.notifier)
                        .setNsfwThreshold(value / 100);
                  }
                : null,
            label: '${(nsfwState.nsfwThreshold * 100).toInt()}%',
          ),

          const SizedBox(height: 16),
          Divider(style: DividerThemeData(decoration: BoxDecoration(color: NaiTheme.bg2))),
          const SizedBox(height: 16),

          // Ollama設定
          Text(
            'ローカルLLM判定（Ollama）',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ollama + llavaを使用して画像を直接分析します。プロンプトがない画像も判定可能です。',
            style: TextStyle(
              fontSize: 13,
              color: NaiTheme.text2,
            ),
          ),
          const SizedBox(height: 12),

          // Ollama接続状態
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NaiTheme.bg2,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  nsfwState.ollamaAvailable
                      ? FluentIcons.check_mark
                      : FluentIcons.status_circle_error_x,
                  size: 14,
                  color: nsfwState.ollamaAvailable
                      ? NaiTheme.success
                      : NaiTheme.text2,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nsfwState.ollamaAvailable
                        ? 'Ollamaに接続済み'
                        : 'Ollamaが利用できません（起動していないか、接続できません）',
                    style: TextStyle(
                      fontSize: 12,
                      color: nsfwState.ollamaAvailable
                          ? NaiTheme.success
                          : NaiTheme.text2,
                    ),
                  ),
                ),
                Button(
                  onPressed: () {
                    ref.read(nsfwServiceProvider.notifier).recheckOllama();
                  },
                  child: const Text('再確認'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Ollama URL設定
          Row(
            children: [
              Expanded(
                child: TextBox(
                  placeholder: 'Ollama URL',
                  controller: TextEditingController(text: nsfwState.ollamaUrl),
                  onSubmitted: (value) {
                    ref.read(nsfwServiceProvider.notifier).setOllamaUrl(value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Ollamaモデル選択
          if (nsfwState.availableModels.isNotEmpty) ...[
            Text(
              '使用するモデル',
              style: TextStyle(
                fontSize: 12,
                color: NaiTheme.text1,
              ),
            ),
            const SizedBox(height: 4),
            ComboBox<String>(
              value: nsfwState.ollamaModel,
              items: nsfwState.availableModels
                  .map((model) => ComboBoxItem<String>(
                        value: model,
                        child: Text(model),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(nsfwServiceProvider.notifier).setOllamaModel(value);
                }
              },
            ),
          ],

          const SizedBox(height: 12),

          // Ollama使用設定
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ollamaを判定に使用',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: NaiTheme.text0,
                      ),
                    ),
                    Text(
                      'プロンプト判定に加えて画像分析も実行（時間がかかります）',
                      style: TextStyle(
                        fontSize: 11,
                        color: NaiTheme.text2,
                      ),
                    ),
                  ],
                ),
              ),
              ToggleSwitch(
                checked: nsfwState.useOllamaForDetection,
                onChanged: nsfwState.ollamaAvailable
                    ? (value) {
                        ref.read(nsfwServiceProvider.notifier).setUseOllama(value);
                      }
                    : null,
              ),
            ],
          ),
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
