import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'sqlite_cache_service.dart';

/// Représente une opération en attente d'envoi (mode hors ligne)
class QueuedOperation {
  final String id;
  final String method; // GET, POST, PUT, DELETE
  final String endpoint; // /api/carnets, etc.
  final Map<String, String>? headers;
  final dynamic body; // Peut être null (GET), String, File, etc.
  final int createdAt;
  int retryCount;

  QueuedOperation({
    required this.id,
    required this.method,
    required this.endpoint,
    this.headers,
    this.body,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'method': method,
        'endpoint': endpoint,
        'headers': headers != null ? jsonEncode(headers) : null,
        'body': body is String ? body : jsonEncode(body),
        'created_at': createdAt,
        'retry_count': retryCount,
      };

  factory QueuedOperation.fromMap(Map<String, dynamic> map) {
    return QueuedOperation(
      id: map['id'] as String,
      method: map['method'] as String,
      endpoint: map['endpoint'] as String,
      headers: map['headers'] != null
          ? Map<String, String>.from(
              jsonDecode(map['headers'] as String) as Map)
          : null,
      body: map['body'] as String?,
      createdAt: map['created_at'] as int,
      retryCount: (map['retry_count'] as int?) ?? 0,
    );
  }
}

/// Service de gestion de la queue d'attente offline
/// Stocke les opérations (POST/PUT/DELETE) quand le réseau n'est pas disponible
class OfflineQueueService {
  OfflineQueueService._internal();
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;

  final SqliteCacheService _cache = SqliteCacheService();
  static Database? _db;
  static const String _tableName = 'offline_queue';

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final cacheDb = await _cache.database;
    // Utilise la même base que le cache
    await cacheDb.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        method TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        headers TEXT,
        body TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');
    return cacheDb;
  }

  /// Enqueue une opération
  Future<void> enqueue(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final db = await database;
    final operation = QueuedOperation(
      id: '${DateTime.now().millisecondsSinceEpoch}_${endpoint.hashCode}',
      method: method,
      endpoint: endpoint,
      headers: headers,
      body: body,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await db.insert(
      _tableName,
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère les opérations en attente
  Future<List<QueuedOperation>> getPending() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => QueuedOperation.fromMap(r)).toList();
  }

  /// Marque une opération comme complétée
  Future<void> remove(String operationId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  /// Incrémente le compteur de retry
  Future<void> incrementRetry(String operationId) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [operationId],
    );
    if (rows.isNotEmpty) {
      final current = (rows.first['retry_count'] as int?) ?? 0;
      await db.update(
        _tableName,
        {'retry_count': current + 1},
        where: 'id = ?',
        whereArgs: [operationId],
      );
    }
  }

  /// Vide la queue
  Future<void> clear() async {
    final db = await database;
    await db.delete(_tableName);
  }

  /// Nombre d'opérations en attente
  Future<int> count() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Ferme la base de données
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
