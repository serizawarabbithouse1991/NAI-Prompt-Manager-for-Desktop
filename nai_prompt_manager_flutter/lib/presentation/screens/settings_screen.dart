import 'package:fluent_ui/fluent_ui.dart' hide ThemeMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../themes/nai_theme.dart';
import 'bulk_tagging_dialog.dart';

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

  // 自動タグ付け設定
  bool _autoTagEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkTauriDb();
    // Providerを使うため、フレーム後に実行
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initDanbooruFromProvider();
      _loadAutoTagSetting();
    });
  }

  /// 自動タグ付け設定を読み込む
  Future<void> _loadAutoTagSetting() async {
    final repository = ref.read(settingsRepositoryProvider);
    final enabled = await repository.getAutoTagEnabled();
    if (mounted) {
      setState(() => _autoTagEnabled = enabled);
    }
  }

  /// 自動タグ付け設定を保存
  Future<void> _saveAutoTagSetting(bool enabled) async {
    setState(() => _autoTagEnabled = enabled);
    final repository = ref.read(settingsRepositoryProvider);
    await repository.setAutoTagEnabled(enabled);
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

  /// Providerを通じてDanbooru DBを初期化し、統計を取得
  Future<void> _initDanbooruFromProvider() async {
    // Providerの状態を取得（これによりProviderが初期化される）
    final danbooruState = ref.read(danbooruServiceProvider);
    
    // Providerがまだ初期化中の場合は少し待つ
    if (!danbooruState.initialized) {
      // 初期化完了を待つ（最大3秒）
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        final state = ref.read(danbooruServiceProvider);
        if (state.initialized) break;
      }
    }
    
    // 再度状態を取得
    final state = ref.read(danbooruServiceProvider);
    
    // Providerが利用可能ならシングルトンも初期化済み
    if (state.available) {
      final service = DanbooruService();
      final stats = await service.getStats();
      if (mounted) {
        setState(() => _danbooruStats = stats);
      }
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
      
      // Provider経由でDBを設定（永続化も行われる）
      final success = await ref.read(danbooruServiceProvider.notifier).setDatabasePath(path);

      if (success) {
        // 統計情報を取得
        final service = DanbooruService();
        final stats = await service.getStats();
        setState(() {
          _danbooruStats = stats;
          _danbooruStatus = 'Danbooru DBを読み込みました（設定を保存しました）';
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

  Future<void> _closeDanbooruDb() async {
    // Provider経由でDBを閉じる（設定からも削除される）
    await ref.read(danbooruServiceProvider.notifier).closeDatabase();
    
    setState(() {
      _danbooruStats = null;
      _danbooruStatus = 'Danbooru DBを閉じました（設定を削除しました）';
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
            _buildDisplaySettingsCard(),
          ],
        ),
        const SizedBox(height: 24),
        _buildSection(
          title: 'アプリケーション',
          icon: FluentIcons.settings,
          children: [
            _buildApplicationSettingsCard(),
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
    // Providerの状態をwatchしてリアクティブに更新
    final danbooruState = ref.watch(danbooruServiceProvider);
    final isAvailable = danbooruState.available;
    final isInitialized = danbooruState.initialized;

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

          if (_loadingDanbooru || !isInitialized)
            const Row(
              children: [
                ProgressRing(strokeWidth: 2),
                SizedBox(width: 8),
                Text('読み込み中...'),
              ],
            )
          else if (isAvailable || _danbooruStats != null)
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
                  if (danbooruState.dbPath != null)
                    Text(
                      'パス: ${danbooruState.dbPath}',
                      style: TextStyle(fontSize: 11, color: NaiTheme.text2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (_danbooruStats != null) ...[
                    Text(
                      '投稿数: ${_danbooruStats!.postCountFormatted}',
                      style: TextStyle(fontSize: 12, color: NaiTheme.text1),
                    ),
                    Text(
                      'タグ数: ${_danbooruStats!.tagCountFormatted}',
                      style: TextStyle(fontSize: 12, color: NaiTheme.text1),
                    ),
                  ],
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
              if (isAvailable || _danbooruStats != null) ...[
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

  /// 表示設定カード
  Widget _buildDisplaySettingsCard() {
    final viewOptions = ref.watch(appSettingsProvider).viewOptions;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 表示モード（グリッド/リスト）
          Text(
            '表示モード',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildViewModeButton(
                icon: FluentIcons.grid_view_medium,
                label: 'グリッド',
                isSelected: viewOptions.mode == ViewMode.grid,
                onPressed: () {
                  ref.read(appSettingsProvider.notifier).updateViewOptions(
                    (opts) => opts.copyWith(mode: ViewMode.grid),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildViewModeButton(
                icon: FluentIcons.list,
                label: 'リスト',
                isSelected: viewOptions.mode == ViewMode.list,
                onPressed: () {
                  ref.read(appSettingsProvider.notifier).updateViewOptions(
                    (opts) => opts.copyWith(mode: ViewMode.list),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(style: DividerThemeData(decoration: BoxDecoration(color: NaiTheme.bg2))),
          const SizedBox(height: 20),

          // サムネイルサイズ
          Text(
            'サムネイルサイズ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '現在: ${_getThumbnailSizeLabel(viewOptions.thumbnailSize)} (${viewOptions.thumbnailSize.pixels}px)',
            style: TextStyle(
              fontSize: 12,
              color: NaiTheme.text2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ThumbnailSize.values.map((size) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildThumbnailSizeButton(
                  size: size,
                  isSelected: viewOptions.thumbnailSize == size,
                  onPressed: () {
                    ref.read(appSettingsProvider.notifier).updateViewOptions(
                      (opts) => opts.copyWith(thumbnailSize: size),
                    );
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Divider(style: DividerThemeData(decoration: BoxDecoration(color: NaiTheme.bg2))),
          const SizedBox(height: 20),

          // ソート設定
          Text(
            'ソート設定',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 12),

          // ソート基準
          Row(
            children: [
              Text(
                'ソート基準:',
                style: TextStyle(
                  fontSize: 13,
                  color: NaiTheme.text1,
                ),
              ),
              const SizedBox(width: 12),
              ComboBox<SortBy>(
                value: viewOptions.sortBy,
                items: SortBy.values.map((sortBy) {
                  return ComboBoxItem<SortBy>(
                    value: sortBy,
                    child: Text(_getSortByLabel(sortBy)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(appSettingsProvider.notifier).updateViewOptions(
                      (opts) => opts.copyWith(sortBy: value),
                    );
                  }
                },
              ),
              const SizedBox(width: 24),
              Text(
                'ソート順:',
                style: TextStyle(
                  fontSize: 13,
                  color: NaiTheme.text1,
                ),
              ),
              const SizedBox(width: 12),
              ComboBox<SortOrder>(
                value: viewOptions.sortOrder,
                items: SortOrder.values.map((order) {
                  return ComboBoxItem<SortOrder>(
                    value: order,
                    child: Text(_getSortOrderLabel(order)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(appSettingsProvider.notifier).updateViewOptions(
                      (opts) => opts.copyWith(sortOrder: value),
                    );
                  }
                },
              ),
            ],
          ),

          // リスト表示時のみ：行サイズ設定
          if (viewOptions.mode == ViewMode.list) ...[
            const SizedBox(height: 20),
            Divider(style: DividerThemeData(decoration: BoxDecoration(color: NaiTheme.bg2))),
            const SizedBox(height: 20),

            Text(
              'リスト行サイズ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: NaiTheme.text0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ListRowSize.values.map((size) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildListRowSizeButton(
                    size: size,
                    isSelected: viewOptions.listRowSize == size,
                    onPressed: () {
                      ref.read(appSettingsProvider.notifier).updateViewOptions(
                        (opts) => opts.copyWith(listRowSize: size),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Button(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          isSelected ? NaiTheme.accent.withAlpha(30) : NaiTheme.bg2,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isSelected ? NaiTheme.accent : Colors.transparent,
              width: 1,
            ),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? NaiTheme.accent : NaiTheme.text1),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? NaiTheme.accent : NaiTheme.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailSizeButton({
    required ThumbnailSize size,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Button(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          isSelected ? NaiTheme.accent.withAlpha(30) : NaiTheme.bg2,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isSelected ? NaiTheme.accent : Colors.transparent,
              width: 1,
            ),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          _getThumbnailSizeLabel(size),
          style: TextStyle(
            color: isSelected ? NaiTheme.accent : NaiTheme.text1,
          ),
        ),
      ),
    );
  }

  Widget _buildListRowSizeButton({
    required ListRowSize size,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Button(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          isSelected ? NaiTheme.accent.withAlpha(30) : NaiTheme.bg2,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isSelected ? NaiTheme.accent : Colors.transparent,
              width: 1,
            ),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          _getListRowSizeLabel(size),
          style: TextStyle(
            color: isSelected ? NaiTheme.accent : NaiTheme.text1,
          ),
        ),
      ),
    );
  }

  String _getThumbnailSizeLabel(ThumbnailSize size) {
    switch (size) {
      case ThumbnailSize.small:
        return '小';
      case ThumbnailSize.medium:
        return '中';
      case ThumbnailSize.large:
        return '大';
      case ThumbnailSize.xlarge:
        return '特大';
    }
  }

  String _getSortByLabel(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.date:
        return '日付';
      case SortBy.name:
        return '名前';
      case SortBy.size:
        return 'サイズ';
    }
  }

  String _getSortOrderLabel(SortOrder order) {
    switch (order) {
      case SortOrder.asc:
        return '昇順';
      case SortOrder.desc:
        return '降順';
    }
  }

  String _getListRowSizeLabel(ListRowSize size) {
    switch (size) {
      case ListRowSize.compact:
        return 'コンパクト';
      case ListRowSize.normal:
        return '標準';
      case ListRowSize.comfortable:
        return 'ゆったり';
    }
  }

  /// アプリケーション設定カード
  Widget _buildApplicationSettingsCard() {
    final appSettings = ref.watch(appSettingsProvider).settings;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // テーマ設定
          Text(
            'テーマ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ThemeMode.values.map((mode) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildThemeModeButton(
                  mode: mode,
                  isSelected: appSettings.theme == mode,
                  onPressed: () {
                    ref.read(appSettingsProvider.notifier).setTheme(mode);
                  },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Divider(style: DividerThemeData(decoration: BoxDecoration(color: NaiTheme.bg2))),
          const SizedBox(height: 20),

          // 言語設定
          Text(
            '言語',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLanguageButton(
                languageCode: 'ja',
                label: '日本語',
                isSelected: appSettings.language == 'ja',
                onPressed: () {
                  ref.read(appSettingsProvider.notifier).setLanguage('ja');
                },
              ),
              const SizedBox(width: 8),
              _buildLanguageButton(
                languageCode: 'en',
                label: 'English',
                isSelected: appSettings.language == 'en',
                onPressed: () {
                  ref.read(appSettingsProvider.notifier).setLanguage('en');
                },
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(style: DividerThemeData(decoration: BoxDecoration(color: NaiTheme.bg2))),
          const SizedBox(height: 20),

          // 自動タグ設定（Danbooru関連）
          Text(
            '自動タグ設定',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NaiTheme.text0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Danbooruデータベースを使用した自動タグ付け機能の詳細設定です。',
            style: TextStyle(
              fontSize: 12,
              color: NaiTheme.text2,
            ),
          ),
          const SizedBox(height: 16),

          // Danbooru DBの状態表示（Providerから取得）
          Builder(
            builder: (context) {
              final danbooruState = ref.watch(danbooruServiceProvider);
              final isAvailable = danbooruState.available;
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NaiTheme.bg2,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAvailable
                          ? FluentIcons.check_mark
                          : FluentIcons.status_circle_error_x,
                      size: 14,
                      color: isAvailable
                          ? NaiTheme.success
                          : NaiTheme.text2,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAvailable
                            ? 'Danbooru DB: 有効${_danbooruStats != null ? " (${_danbooruStats!.postCountFormatted} posts)" : ""}'
                            : 'Danbooru DB: 未設定',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAvailable
                              ? NaiTheme.success
                              : NaiTheme.text2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (ref.watch(danbooruServiceProvider).available) ...[
            const SizedBox(height: 16),

            // 自動タグ機能の有効/無効
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'インポート時に自動タグ付け',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: NaiTheme.text0,
                        ),
                      ),
                      Text(
                        '画像インポート時にMD5ハッシュでDanbooruタグを自動取得',
                        style: TextStyle(
                          fontSize: 11,
                          color: NaiTheme.text2,
                        ),
                      ),
                    ],
                  ),
                ),
                ToggleSwitch(
                  checked: _autoTagEnabled,
                  onChanged: (value) => _saveAutoTagSetting(value),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(style: DividerThemeData(decoration: BoxDecoration(color: NaiTheme.bg2))),
            const SizedBox(height: 20),

            // 手動タグ付け
            Text(
              '手動タグ付け',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: NaiTheme.text0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '既存の画像にDanbooruタグを一括で付与します。全画像または、タグがない画像のみを対象にできます。',
              style: TextStyle(
                fontSize: 12,
                color: NaiTheme.text2,
              ),
            ),
            const SizedBox(height: 12),
            Button(
              onPressed: () => BulkTaggingDialog.show(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.tag, size: 14, color: NaiTheme.text1),
                  const SizedBox(width: 8),
                  Text(
                    '手動タグ付けを開始',
                    style: TextStyle(color: NaiTheme.text1),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeModeButton({
    required ThemeMode mode,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Button(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          isSelected ? NaiTheme.accent.withAlpha(30) : NaiTheme.bg2,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isSelected ? NaiTheme.accent : Colors.transparent,
              width: 1,
            ),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getThemeModeIcon(mode),
              size: 14,
              color: isSelected ? NaiTheme.accent : NaiTheme.text1,
            ),
            const SizedBox(width: 6),
            Text(
              _getThemeModeLabel(mode),
              style: TextStyle(
                color: isSelected ? NaiTheme.accent : NaiTheme.text1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeModeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => FluentIcons.clear_night,
    ThemeMode.light => FluentIcons.sunny,
    ThemeMode.system => FluentIcons.pc1,
  };

  String _getThemeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => 'ダーク',
    ThemeMode.light => 'ライト',
    ThemeMode.system => 'システム',
  };

  Widget _buildLanguageButton({
    required String languageCode,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Button(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          isSelected ? NaiTheme.accent.withAlpha(30) : NaiTheme.bg2,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isSelected ? NaiTheme.accent : Colors.transparent,
              width: 1,
            ),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? NaiTheme.accent : NaiTheme.text1,
          ),
        ),
      ),
    );
  }
}
