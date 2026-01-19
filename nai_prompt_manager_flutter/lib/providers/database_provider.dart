import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database.dart';

/// データベースインスタンスのプロバイダー
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
