# 🚕 Covoiturage & Messagerie - Guide d'Intégration

## 📱 Screens Créés

### 1. **TrajetDetailsScreen**
📍 `lib/features/screens/student/trajet_details_screen.dart`

Affiche les détails complèts d'un trajet :
- Infos du trajet (départ, arrivée, date, prix)
- Profil du chauffeur (photo, note, contact)
- Liste des passagers
- Nombre de places disponibles
- Bouton "Réserver" avec sélecteur de places
- Lien vers "Messages"

**Usage :**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TrajetDetailsScreen(trajet: trajetData),
  ),
);
```

---

### 2. **MessagesScreen**
📍 `lib/features/screens/student/messages_screen.dart`

Chat en temps réel pour un trajet :
- Affiche tous les messages du trajet
- TextField pour envoyer des messages
- Support **offline** : les messages sont queued automatiquement
- Indicateur "⏳" pour les messages en attente
- Timestamps intelligents (aujourd'hui, hier, date)
- Formatage bubble (message reçu vs envoyé)

**Fonctionnalités :**
- Auto-refresh après envoi
- Gestion offline avec file d'attente
- Retry automatique au retour de connexion

**Usage :**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => MessagesScreen(
      trajetId: 42,
      trajetTitre: 'Messages - Jean Dupont',
    ),
  ),
);
```

---

### 3. **ReservationsScreen**
📍 `lib/features/screens/student/reservations_screen.dart`

Gestion des réservations :
- Affiche toutes les réservations de l'utilisateur
- Détails du trajet (lieu, date, prix)
- Nombre de places et tarif total
- Bouton "Annuler la réservation"
- Pull-to-refresh pour mettre à jour
- Message vide avec CTA vers recherche

**Usage :**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ReservationsScreen()),
);
```

---

### 4. **CreateTrajetScreen**
📍 `lib/features/screens/student/create_trajet_screen.dart`

Formulaire de création de trajet :
- Lieux (départ, arrivée)
- Date et heure
- Nombre de places
- Tarif par place
- Description optionnelle
- Validation complète
- Support offline (mise en queue)

**Usage :**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const CreateTrajetScreen()),
);
```

---

## 🔗 Intégration dans CovoiturageHomeScreen

Modifie `covoiturage_home_screen.dart` pour naviguer vers les nouveaux screens :

```dart
import 'trajet_details_screen.dart';
import 'messages_screen.dart';
import 'reservations_screen.dart';
import 'create_trajet_screen.dart';

// Tab "Proposer" → CreateTrajetScreen
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CreateTrajetScreen()),
  );
}

// Chaque trajet → TrajetDetailsScreen
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TrajetDetailsScreen(trajet: trajet),
    ),
  );
}

// Icône profil/réservations → ReservationsScreen
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ReservationsScreen()),
  );
}
```

---

## 📡 API Endpoints Utilisés

| Screen | Méthode | Endpoint | Description |
|--------|---------|----------|-------------|
| TrajetDetailsScreen | POST | `/reservations/{id}/reserver` | Créer une réservation |
| MessagesScreen | GET | `/trajets/{id}/messages` | Récupérer messages |
| MessagesScreen | POST | `/trajets/{id}/messages` | Envoyer message |
| ReservationsScreen | GET | `/reservations/mes-reservations` | Lister mes réservations |
| ReservationsScreen | POST | `/reservations/{id}/annuler` | Annuler une réservation |
| CreateTrajetScreen | POST | `/trajets` | Créer un trajet |

---

## 🔄 Cycle de Vie Offline

### Cas 1 : Réserver un trajet offline
```
User réserve trajet (hors ligne)
    ↓
POST /reservations/{id}/reserver queued en SQLite
    ↓
User voit erreur "Hors ligne. Opération en file d'attente"
    ↓
Connexion revient
    ↓
Auto-retry de la réservation
    ↓
Succès → Supprimé de la queue
```

### Cas 2 : Envoyer un message offline
```
User envoie message (hors ligne)
    ↓
Message queued en SQLite
    ↓
UI affiche message avec icône "⏳" (horloge)
    ↓
Connexion revient
    ↓
Auto-retry du message
    ↓
Succès → Reload et affichage normal
```

### Cas 3 : Créer un trajet offline
```
User crée trajet (hors ligne)
    ↓
POST /trajets queued en SQLite
    ↓
User voit erreur "Hors ligne..."
    ↓
Connexion revient
    ↓
Auto-sync → Trajet créé
```

---

## ✨ Fonctionnalités Clés

### TrajetDetailsScreen
✅ Affichage réactif avec refresh automatique
✅ Sélection du nombre de places
✅ Navigation vers messages
✅ Gestion erreurs (places insuffisantes, etc.)
✅ Support offline (réservation queued)

### MessagesScreen
✅ Chat en temps réel
✅ Indicateurs de temps intelligents
✅ Distinction message envoyé/reçu (couleurs)
✅ Support offline complet
✅ Auto-scroll vers nouveau message
✅ Refresh button

### ReservationsScreen
✅ Pull-to-refresh
✅ Affichage tarif total
✅ Confirmation avant annulation
✅ Message vide avec CTA
✅ Gestion état annulation

### CreateTrajetScreen
✅ Validation formulaire complète
✅ Date/heure picker natif
✅ Support offline
✅ Calcul tarif
✅ Description optionnelle

---

## 🧪 Test Offline

### Pour MessagesScreen
```bash
# Terminal
adb shell settings put global wifi_off 1
# Ou: telnet localhost 5554 → gsm data off

# Dans l'app
1. Ouvrir un chat
2. Envoyer un message
3. Doit voir: "⏳ Message en attente (hors ligne)"
4. Réactiver réseau
5. Doit se synchroniser automatiquement
```

### Pour TrajetDetailsScreen
```bash
# Même process que MessMessagesScreen
1. Cliquer "Réserver"
2. Doit voir: "Hors ligne. Opération en file d'attente..."
3. Réactiver réseau
4. Doit syncer automatiquement
```

---

## 🔧 Customisation

### Changer couleur du chauffeur
Dans `_sectionChauffeur()` :
```dart
CircleAvatar(
  backgroundColor: ColorConstants.success, // changer
)
```

### Ajouter emojis aux messages
Dans `_messageBubble()` :
```dart
final hasEmoji = texte.contains(RegExp(r'[\u{1F600}-\u{1F64F}]'));
```

### Augmenter nombre max places
Dans `_champPosition()` de `TrajetDetailsScreen` :
```dart
if (_nombrePlaces < 7) // changer de 7 à autre valeur
```

---

## 📝 Points Importants

- **Offline First** : Tous les POST/PUT/DELETE sont automatiquement queued si offline
- **Auto-sync** : Quand la connexion revient, tout se resynchronise
- **UX Offline** : Les users voient clairement quel état est offline (icônes, couleurs, messages)
- **Pull-to-refresh** : ReservationsScreen et MessagesScreen supportent le refresh manuel
- **Validation** : Tous les formulaires validés côté client avant envoi

---

## 🐛 Debug

Pour voir la queue offline :
```dart
final queue = OfflineQueueService();
final pending = await queue.getPending();
print('Pending ops: ${pending.length}');
for (final op in pending) {
  print('  - ${op.method} ${op.endpoint}');
}
```

Pour simuler une erreur réseau :
```dart
// Dans ApiService, forcer isOnline() à retourner false
@override
Future<bool> isOnline() async => false; // debug
```

---

## 🚀 Prochaines Étapes (Optional)

1. **Ajouter notifications push** pour nouveaux messages
2. **Tracker position en temps réel** via geolocator
3. **Partager trajet via SMS/WhatsApp**
4. **Historique trajets** (trajet complété vs actif)
5. **Système de notation** (5 étoiles)
6. **Signalement d'utilisateurs problématiques**
7. **Chat de groupe** (plus de 2 participants)
8. **Appels audio/vidéo** (optionnel - complexe)

