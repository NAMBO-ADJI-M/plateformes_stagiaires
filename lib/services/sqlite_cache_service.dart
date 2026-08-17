import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqliteCacheService {
  SqliteCacheService._internal({Directory? testDirectory})
      : _testDirectory = testDirectory;
  static final SqliteCacheService _instance = SqliteCacheService._internal();
  factory SqliteCacheService({Directory? testDirectory}) {
    if (testDirectory != null) {
      return SqliteCacheService._internal(testDirectory: testDirectory);
    }
    return _instance;
  }

  static Database? _db;
  final Directory? _testDirectory;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dir = _testDirectory ?? await getApplicationDocumentsDirectory();
    final path = '${dir.path}/plateforme_stagiaires_cache.db';
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE cache_entries (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            expires_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> setJson<T>(String key, T value,
      {Duration ttl = const Duration(hours: 12)}) async {
    final db = await database;
    final payload = jsonEncode(value);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'cache_entries',
      {
        'key': key,
        'value': payload,
        'expires_at': now + ttl.inMilliseconds,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<T?> getJson<T>(String key) async {
    final db = await database;
    final row = await db.query(
      'cache_entries',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (row.isEmpty) return null;

    final data = row.first;
    final expiresAt = data['expires_at'] as int? ?? 0;
    if (expiresAt <= DateTime.now().millisecondsSinceEpoch) {
      await db.delete('cache_entries', where: 'key = ?', whereArgs: [key]);
      return null;
    }

    final raw = data['value'] as String?;
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is T) return decoded;
    return decoded as T;
  }

  Future<void> delete(String key) async {
    final db = await database;
    await db.delete('cache_entries', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('cache_entries');
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
