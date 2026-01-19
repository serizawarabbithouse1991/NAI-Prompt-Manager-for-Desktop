import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../providers/providers.dart';
import '../../services/zip_extract_service.dart';
import '../themes/nai_theme.dart';
import 'upload_history_screen.dart';

/// 画像アップロードダイアログ
class UploadDialog extends ConsumerStatefulWidget {
  const UploadDialog({super.key});

  @override
  ConsumerState<UploadDialog> createState() => _UploadDialogState();

  /// ダイアログを表示
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UploadDialog(),
    );
  }
}

class _UploadDialogState extends ConsumerState<UploadDialog> {
  final List<PendingFile> _files = [];
  bool _uploading = false;
  bool _dragActive = false;
  String? _errorMessage;
  bool _extractingZip = false;
  String? _extractStatus;

  Future<void> _selectFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'zip'],
        allowMultiple: true,
      );

      if (result != null) {
        final zipFiles = <PlatformFile>[];
        final imageFiles = <PlatformFile>[];

        for (final file in result.files) {
          if (file.path == null) continue;
          final ext = p.extension(file.name).toLowerCase();
          if (ext == '.zip') {
            zipFiles.add(file);
          } else {
            imageFiles.add(file);
          }
        }

        // 画像ファイルを追加
        final newImageFiles = imageFiles
            .map((f) => PendingFile(
                  path: f.path!,
                  name: f.name,
                  size: f.size,
                  type: PendingFileType.image,
                ))
            .toList();

        setState(() {
          _files.addAll(newImageFiles);
        });

        // ZIPファイルを解凍
        if (zipFiles.isNotEmpty) {
          await _extractZipFiles(zipFiles);
        }
      }
    } catch (e) {
      debugPrint('Failed to select files: $e');
      setState(() {
        _errorMessage = 'ファイル選択エラー: $e';
      });
    }
  }

  Future<void> _extractZipFiles(List<PlatformFile> zipFiles) async {
    setState(() {
      _extractingZip = true;
      _extractStatus = 'ZIP解凍中...';
    });

    try {
      for (var i = 0; i < zipFiles.length; i++) {
        final zipFile = zipFiles[i];
        setState(() {
          _extractStatus = '解凍中: ${zipFile.name} (${i + 1}/${zipFiles.length})';
        });

        final result = await ZipExtractService.extractImages(zipFile.path!);

        if (result.isSuccess) {
          final extractedFiles = result.imagePaths
              .map((path) => PendingFile(
                    path: path,
                    name: p.basename(path),
                    size: 0, // 解凍後のサイズは不明
                    type: PendingFileType.image,
                    sourceZip: zipFile.name,
                  ))
              .toList();

          setState(() {
            _files.addAll(extractedFiles);
          });
        } else {
          setState(() {
            _errorMessage = 'ZIP解凍エラー: ${result.error}';
          });
        }
      }
    } finally {
      setState(() {
        _extractingZip = false;
        _extractStatus = null;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  void _clearFiles() {
    setState(() {
      _files.clear();
    });
  }

  /// バックグラウンドアップロードを開始
  Future<void> _upload() async {
    if (_files.isEmpty) return;

    setState(() {
      _uploading = true;
      _errorMessage = null;
    });

    try {
      final uploadNotifier = ref.read(backgroundUploadNotifierProvider.notifier);
      final explorerState = ref.read(explorerProvider);
      final folderId = explorerState.selectedFolderId;
      final historyRepo = ref.read(uploadHistoryRepositoryProvider);

      // ファイルパスのリストを作成
      final filePaths = _files.map((f) => f.path).toList();

      // ZIPソース別にグループ化して履歴を記録
      final zipGroups = <String, List<PendingFile>>{};
      final directFiles = <PendingFile>[];
      
      for (final file in _files) {
        if (file.sourceZip != null) {
          zipGroups.putIfAbsent(file.sourceZip!, () => []).add(file);
        } else {
          directFiles.add(file);
        }
      }

      // アップロード履歴を保存（開始時点で）
      const uuid = Uuid();
      
      // 直接選択されたファイルの履歴
      if (directFiles.isNotEmpty) {
        await historyRepo.addHistory(
          id: uuid.v4(),
          type: 'image',
          sourcePath: directFiles.first.path,
          filename: directFiles.length == 1 
              ? directFiles.first.name 
              : '${directFiles.length}ファイル',
          fileCount: directFiles.length,
          successCount: 0,
          failCount: 0,
          status: 'processing',
        );
      }

      // ZIPファイルの履歴
      for (final entry in zipGroups.entries) {
        final zipFilesList = entry.value;
        await historyRepo.addHistory(
          id: uuid.v4(),
          type: 'zip',
          sourcePath: entry.key,
          filename: entry.key,
          fileCount: zipFilesList.length,
          successCount: 0,
          failCount: 0,
          status: 'processing',
        );
      }

      // バックグラウンドアップロードを開始
      uploadNotifier.startUpload(
        filePaths: filePaths,
        folderId: folderId,
      );

      // ダイアログを閉じる（バックグラウンドで処理継続）
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      setState(() {
        _uploading = false;
        _errorMessage = 'アップロードの開始に失敗しました: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
      title: Row(
        children: [
          Icon(FluentIcons.upload, size: 20, color: NaiTheme.accent),
          const SizedBox(width: 8),
          const Text('画像をアップロード'),
          const Spacer(),
          IconButton(
            icon: Icon(FluentIcons.cancel, size: 16, color: NaiTheme.text2),
            onPressed: _uploading ? null : () => Navigator.pop(context),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ドロップゾーン
          _buildDropZone(),
          const SizedBox(height: 16),

          // 選択されたファイルリスト
          if (_files.isNotEmpty) ...[
            _buildFileList(),
            const SizedBox(height: 16),
          ],

          // ZIP解凍中
          if (_extractingZip) ...[
            _buildExtractProgress(),
            const SizedBox(height: 16),
          ],

          // プログレスバー
          if (_uploading) ...[
            _buildProgress(),
            const SizedBox(height: 16),
          ],

          // エラーメッセージ
          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: 16),
          ],
        ],
      ),
      actions: [
        Button(
          onPressed: _uploading ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        if (_files.isNotEmpty && !_uploading)
          Button(
            onPressed: _clearFiles,
            child: const Text('クリア'),
          ),
        FilledButton(
          onPressed: _files.isEmpty || _uploading || _extractingZip ? null : _upload,
          child: Text(
            _uploading
                ? 'アップロード開始中...'
                : 'アップロード (${_files.length})',
          ),
        ),
      ],
    );
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _uploading ? null : _selectFiles,
      child: MouseRegion(
        onEnter: (_) => setState(() => _dragActive = true),
        onExit: (_) => setState(() => _dragActive = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(
              color: _dragActive ? NaiTheme.accent : NaiTheme.bg3,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _dragActive ? NaiTheme.accent.withAlpha(20) : NaiTheme.bg1,
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: NaiTheme.bg2,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  FluentIcons.cloud_upload,
                  size: 28,
                  color: NaiTheme.text2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'クリックしてファイルを選択',
                style: TextStyle(
                  color: NaiTheme.text0,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PNG, JPG, WEBP, GIF, ZIP（複数選択可）',
                style: TextStyle(
                  color: NaiTheme.text2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtractProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NaiTheme.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: NaiTheme.accent),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: ProgressRing(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _extractStatus ?? 'ZIP解凍中...',
              style: TextStyle(
                fontSize: 12,
                color: NaiTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '選択されたファイル (${_files.length})',
              style: TextStyle(
                color: NaiTheme.text1,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              _formatTotalSize(),
              style: TextStyle(
                color: NaiTheme.text2,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: NaiTheme.bg1,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: NaiTheme.bg2),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(4),
            itemCount: _files.length,
            itemBuilder: (context, index) {
              final file = _files[index];
              return _buildFileItem(file, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(PendingFile file, int index) {
    final icon = file.type == PendingFileType.zip
        ? FluentIcons.open_folder_horizontal
        : FluentIcons.photo2;
    final subtitle = file.sourceZip != null
        ? 'from: ${file.sourceZip}'
        : _formatFileSize(file.size);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NaiTheme.bg2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: NaiTheme.text2),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    color: NaiTheme.text0,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: NaiTheme.text2,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (!_uploading)
            IconButton(
              icon: Icon(FluentIcons.cancel, size: 12, color: NaiTheme.text2),
              onPressed: () => _removeFile(index),
            ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NaiTheme.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: NaiTheme.accent),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: ProgressRing(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'バックグラウンドアップロードを開始中...',
              style: TextStyle(
                fontSize: 12,
                color: NaiTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTotalSize() {
    final total = _files.fold<int>(0, (sum, f) => sum + f.size);
    return '合計: ${_formatFileSize(total)}';
  }

  Widget _buildErrorMessage() {
    final isError = _errorMessage?.startsWith('エラー') ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError 
            ? NaiTheme.error.withAlpha(20) 
            : NaiTheme.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isError ? NaiTheme.error : NaiTheme.warning,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? FluentIcons.error : FluentIcons.warning,
            size: 16,
            color: isError ? NaiTheme.error : NaiTheme.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 12,
                color: isError ? NaiTheme.error : NaiTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ファイルタイプ
enum PendingFileType {
  image,
  zip,
}

/// アップロード待機中のファイル
class PendingFile {
  final String path;
  final String name;
  final int size;
  final PendingFileType type;
  final String? sourceZip;

  const PendingFile({
    required this.path,
    required this.name,
    required this.size,
    this.type = PendingFileType.image,
    this.sourceZip,
  });
}
