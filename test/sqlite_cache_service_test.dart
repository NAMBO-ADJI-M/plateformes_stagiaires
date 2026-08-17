import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:plateforme_stagiaires/services/sqlite_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SqliteCacheService', () {
    late Directory tempDir;

    setUpAll(() async {
      // Créer un répertoire temporaire pour les tests
      tempDir = await Directory.systemTemp.createTemp('test_cache_');
    });

    tearDownAll(() async {
      // Fermer la base de données avant de supprimer le répertoire
      // sinon le fichier reste verrouillé
      final cache = SqliteCacheService(testDirectory: tempDir);
      await cache.close();

      // Nettoyer le répertoire temporaire
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('sauvegarde et lit une donnée JSON en cache', () async {
      final cache = SqliteCacheService(testDirectory: tempDir);
      await cache.clearAll();

      final payload = {
        'id': 'carnet-1',
        'nom': 'Stage de développement',
      };

      await cache.setJson('profile_test', payload,
          ttl: const Duration(minutes: 5));
      final read = await cache.getJson<Map<String, dynamic>>('profile_test');

      expect(read, isNotNull);
      expect(read!['id'], 'carnet-1');
      expect(read['nom'], 'Stage de développement');
    });

    test('retourne null quand une clé expirée est demandée', () async {
      final cache = SqliteCacheService(testDirectory: tempDir);
      await cache.clearAll();

      await cache.setJson('expired_key', ['a', 'b'],
          ttl: const Duration(milliseconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final read = await cache.getJson<List<dynamic>>('expired_key');
      expect(read, isNull);
    });
  });
}
