import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../providers/providers.dart';
import '../themes/nai_theme.dart';

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
  double _progress = 0;
  String? _currentFile;
  bool _dragActive = false;

  Future<void> _selectFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
        allowMultiple: true,
      );

      if (result != null) {
        final newFiles = result.files
            .where((f) => f.path != null)
            .map((f) => PendingFile(
                  path: f.path!,
                  name: f.name,
                  size: f.size,
                ))
            .toList();

        setState(() {
          _files.addAll(newFiles);
        });
      }
    } catch (e) {
      // エラー処理
      debugPrint('Failed to select files: $e');
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

  Future<void> _upload() async {
    if (_files.isEmpty) return;

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    try {
      final uploadNotifier = ref.read(uploadProvider.notifier);
      final explorerState = ref.read(explorerProvider);
      final folderId = explorerState.selectedFolderId;

      for (var i = 0; i < _files.length; i++) {
        final file = _files[i];
        setState(() {
          _currentFile = file.name;
        });

        try {
          await uploadNotifier.uploadFile(
            filePath: file.path,
            folderId: folderId,
          );
        } catch (e) {
          debugPrint('Failed to upload ${file.name}: $e');
        }

        setState(() {
          _progress = (i + 1) / _files.length;
        });
      }

      // 画像リストをリロード
      await ref.read(imageListProvider.notifier).refreshImages();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
    } finally {
      setState(() {
        _uploading = false;
        _currentFile = null;
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

          // プログレスバー
          if (_uploading) ...[
            _buildProgress(),
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
          onPressed: _files.isEmpty || _uploading ? null : _upload,
          child: Text(
            _uploading
                ? 'アップロード中...'
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
                'PNG, JPG, WEBP, GIF（複数選択可）',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NaiTheme.bg2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(FluentIcons.photo2, size: 16, color: NaiTheme.text2),
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
                  _formatFileSize(file.size),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _currentFile != null ? '処理中: $_currentFile' : 'アップロード中...',
                style: TextStyle(
                  color: NaiTheme.text1,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(_progress * 100).toInt()}%',
              style: TextStyle(
                color: NaiTheme.text0,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ProgressBar(value: _progress * 100),
      ],
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
}

/// アップロード待機中のファイル
class PendingFile {
  final String path;
  final String name;
  final int size;

  const PendingFile({
    required this.path,
    required this.name,
    required this.size,
  });
}
