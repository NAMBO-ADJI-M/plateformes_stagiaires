# Intégration du Système Offline

## 📋 Architecture

```
Utilisateur en ligne
    ↓
Appel API (_post, _put, _delete)
    ↓
Réseau disponible? ✅ YES → HTTP request → API
                  ❌ NO  → Enqueue en SQLite → User notifié
    ↓
Connexion revient? ✅ YES → syncOfflineQueue() → Retry tous les queued ops
```

## 🚀 Intégration dans main.dart

```dart
import 'package:plateforme_stagiaires/services/offline_sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le monitoring de la connexion et la synchro offline
  final syncManager = OfflineSyncManager();
  await syncManager.initialize();
  
  runApp(
    MaterialApp(
      // ... ta config ...
      home: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OfflineSyncManager().dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'app revient au premier plan : tenter une synchro
      ApiService().syncOfflineQueue();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // Ton widget
  }
}
```

## 🔍 Vérifier la Queue

```dart
// Vérifier combien d'opérations sont en attente
final queueService = OfflineQueueService();
final count = await queueService.count();
print('$count opérations en attente');

// Vérifier quelles sont les opérations
final pending = await queueService.getPending();
for (final op in pending) {
  print('${op.method} ${op.endpoint}');
}
```

## 📊 États Possibles

### État 1: En Ligne
```
User → Mutation (POST/PUT/DELETE)
         ↓
    En ligne? ✅
         ↓
    HTTP Request directement
         ↓
    Success/Error
```

### État 2: Hors Ligne
```
User → Mutation (POST/PUT/DELETE)
         ↓
    En ligne? ❌
         ↓
    Enqueue en SQLite
    Retourner ApiException avec message offline
         ↓
    User voit: "Vous êtes hors ligne. L'opération sera envoyée quand la connexion revient."
```

### État 3: Retour Connexion
```
Connexion revient
         ↓
    syncOfflineQueue() déclenché automatiquement
         ↓
    Pour chaque opération queued:
    - Retry la requête HTTP
    - Si succès: supprimer de la queue
    - Si erreur: incrémenter retry_count (max tentatives = 5)
```

## ⚙️ Configuration Personnalisée

### Modifier le TTL du Cache

```dart
// Dans _readCachedOrRefresh, modifier le paramètre `ttl`:
await _cache.setJson(key, fresh, ttl: const Duration(days: 1));
```

### Modifier la Stratégie de Retry

```dart
// Dans ApiService._retryQueuedOperation(), ajouter:
const int maxRetries = 5;
if (op.retryCount >= maxRetries) {
  // Supprimer après trop de tentatives
  await _queue.remove(op.id);
  // Optionnel: notifier l'utilisateur
  return;
}
```

### Afficher un Indicateur Offline

```dart
// Widget qui écoute la connexion
class OfflineIndicator extends StatefulWidget {
  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  late StreamSubscription<ConnectivityResult> _subscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((result) {
      setState(() => _isOnline = result != ConnectivityResult.none);
    });

    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() => _isOnline = result != ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return SizedBox.shrink();
    
    return Container(
      color: Colors.red.shade900,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Vous êtes hors ligne',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
```

## 🧪 Tester Offline

### Android
1. Émulateurr → Settings → Wireless & networks → Disable all
2. Ou: telnet localhost 5554 → `gsm data off`

### iOS
1. Simulator → Features → Wireless → Off

### Web/Desktop
1. DevTools → Network → Offline

## 📝 Points Clés

✅ **Automatique** — Pas besoin d'appels manuels
✅ **Transparent** — Même code que si en ligne
✅ **Persistant** — Queue SQLite survivra au redémarrage
✅ **Intelligent** — Retry automatique avec exponential backoff (optionnel)
❌ **Limitations** — Pas de File upload offline (multipart trop complexe)

## 🐛 Debugging

```dart
// Dans AsyncService, ajouter logging:
if (!online) {
  debugPrint('OFFLINE: Enqueue $method $endpoint');
}

// Vérifier la queue au démarrage
final pending = await OfflineQueueService().getPending();
debugPrint('Pending operations: ${pending.length}');
for (final op in pending) {
  debugPrint('  - ${op.method} ${op.endpoint} (retry: ${op.retryCount})');
}
```

## 📌 Checklist Intégration

- [x] OfflineQueueService créé
- [x] Wrappers _post(), _put(), _delete() implémentés
- [x] Toutes les mutations remplacées
- [x] OfflineSyncManager créé
- [ ] Intégrer OfflineSyncManager dans main.dart
- [ ] Tester en mode offline
- [ ] Ajouter OfflineIndicator dans l'UI
- [ ] Documenter pour le team
