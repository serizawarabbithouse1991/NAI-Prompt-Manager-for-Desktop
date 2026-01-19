import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Tauri版アプリからのDBマイグレーションサービス
class DatabaseMigrationService {
  /// Tauri版アプリのDBパスを取得
  /// Windows: C:\Users\{user}\AppData\Roaming\com.nai-prompt-manager.desktop\
  /// macOS: ~/Library/Application Support/com.nai-prompt-manager.desktop/
  /// Linux: ~/.local/share/com.nai-prompt-manager.desktop/
  static Future<String?> findTauriDbPath() async {
    final possiblePaths = await _getPossibleTauriPaths();
    final possibleDbNames = [
      'nai_prompt_manager.db',
      'prompt-manager.db',
      'nai-prompt-manager.db',
    ];
    
    for (final basePath in possiblePaths) {
      for (final dbName in possibleDbNames) {
        final dbPath = p.join(basePath, dbName);
        if (File(dbPath).existsSync()) {
          return dbPath;
        }
      }
    }
    
    return null;
  }

  static Future<List<String>> _getPossibleTauriPaths() async {
    final paths = <String>[];
    
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        // Tauri v2のデフォルトパス (identifier)
        paths.add(p.join(appData, 'com.nai-prompt-manager.desktop'));
        // 旧バージョン互換
        paths.add(p.join(appData, 'com.promptvault.app'));
        paths.add(p.join(appData, 'nai-prompt-manager'));
        paths.add(p.join(appData, 'NAI Prompt Manager'));
      }
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        paths.add(p.join(home, 'Library', 'Application Support', 'com.nai-prompt-manager.desktop'));
        paths.add(p.join(home, 'Library', 'Application Support', 'com.promptvault.app'));
        paths.add(p.join(home, 'Library', 'Application Support', 'nai-prompt-manager'));
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        paths.add(p.join(home, '.local', 'share', 'com.nai-prompt-manager.desktop'));
        paths.add(p.join(home, '.local', 'share', 'com.promptvault.app'));
        paths.add(p.join(home, '.local', 'share', 'nai-prompt-manager'));
      }
    }
    
    return paths;
  }

  /// 指定されたDBファイルが有効なPrompt ManagerのDBかどうかを確認
  static Future<bool> isValidPromptManagerDb(String dbPath) async {
    final file = File(dbPath);
    if (!file.existsSync()) return false;
    
    // SQLiteヘッダーを確認（最初の16バイト）
    try {
      final bytes = await file.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes.take(6));
      if (header != 'SQLite') return false;
      
      // TODO: テーブル構造の確認も追加可能
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 既存DBの情報を取得
  static Future<TauriDbInfo?> getTauriDbInfo(String dbPath) async {
    if (!await isValidPromptManagerDb(dbPath)) return null;
    
    final file = File(dbPath);
    final stat = await file.stat();
    
    return TauriDbInfo(
      path: dbPath,
      size: stat.size,
      modified: stat.modified,
    );
  }

  /// Flutter用のDBディレクトリを取得
  static Future<Directory> getFlutterDbDirectory() async {
    final appDocDir = await getApplicationSupportDirectory();
    final dbDir = Directory(p.join(appDocDir.path, 'databases'));
    
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    
    return dbDir;
  }

  /// Tauri DBをFlutter DBディレクトリにコピー
  static Future<String> copyTauriDbToFlutter(String tauriDbPath) async {
    final flutterDbDir = await getFlutterDbDirectory();
    final flutterDbPath = p.join(flutterDbDir.path, 'prompt-manager.db');
    
    // バックアップを作成（既存のFlutter DBがある場合）
    final flutterDbFile = File(flutterDbPath);
    if (await flutterDbFile.exists()) {
      final backupPath = '$flutterDbPath.backup.${DateTime.now().millisecondsSinceEpoch}';
      await flutterDbFile.copy(backupPath);
    }
    
    // コピー
    await File(tauriDbPath).copy(flutterDbPath);
    
    return flutterDbPath;
  }

  /// サムネイルディレクトリを取得（Tauri版）
  static Future<String?> findTauriThumbnailPath() async {
    final possiblePaths = await _getPossibleTauriPaths();
    
    for (final basePath in possiblePaths) {
      final thumbPath = p.join(basePath, 'thumbnails');
      if (Directory(thumbPath).existsSync()) {
        return thumbPath;
      }
    }
    
    return null;
  }

  /// Flutter用のサムネイルディレクトリを取得
  static Future<Directory> getFlutterThumbnailDirectory() async {
    final appDocDir = await getApplicationSupportDirectory();
    final thumbDir = Directory(p.join(appDocDir.path, 'thumbnails'));
    
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    
    return thumbDir;
  }
}

/// Tauri版DBの情報
class TauriDbInfo {
  final String path;
  final int size;
  final DateTime modified;

  const TauriDbInfo({
    required this.path,
    required this.size,
    required this.modified,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'TauriDbInfo(path: $path, size: $sizeFormatted, modified: $modified)';
  }
}
