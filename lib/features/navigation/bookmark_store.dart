import 'dart:io';

import 'package:signals/signals.dart';

import '../../core/database/app_database.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';

class BookmarkStore {
  static final BookmarkStore instance = BookmarkStore._();

  BookmarkStore._();

  final bookmarks = signal<List<Bookmark>>([]);

  AppDatabase get _db => SettingsStore.instance.db;

  Future<void> load() async {
    bookmarks.value = await _db.getBookmarks();
  }

  Future<void> addPath(String path) async {
    final normalized = PlatformPaths.normalize(path);
    if (!Directory(normalized).existsSync()) return;
    final existing = await _db.getBookmarkByPath(normalized);
    if (existing != null) return;
    await _db.addBookmark(PlatformPaths.fileName(normalized), normalized);
    await load();
  }

  Future<void> rename(Bookmark bookmark, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty || trimmed == bookmark.label) return;
    await _db.renameBookmark(bookmark.id, trimmed);
    await load();
  }

  Future<void> remove(Bookmark bookmark) async {
    await _db.deleteBookmark(bookmark.id);
    await load();
  }
}
