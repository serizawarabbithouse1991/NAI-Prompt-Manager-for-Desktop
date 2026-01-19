import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/repositories.dart';
import 'database_provider.dart';

/// ImageRepositoryのプロバイダー
final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ImageRepository(db);
});

/// FolderRepositoryのプロバイダー
final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FolderRepository(db);
});

/// TagRepositoryのプロバイダー
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TagRepository(db);
});
