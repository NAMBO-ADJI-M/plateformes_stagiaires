# API Audit — Champs Retournés

## ✅ Endpoints Vérifiés

### 1. **POST /auth/login**
**Requis par le frontend :** `email`, `role`
**Retourné :** 
```json
{
  "message": "Code envoyé",
  "email": "string"
}
```
**Cache :** ❌ Pas de cache (requête publique)

---

### 2. **POST /auth/verify**
**Requis :** `email`, `code`
**Retourné :**
```json
{
  "token": "string",
  "role": "stagiaire|entreprise",
  "message": "Authentifié"
}
```
**Cache :** ⚠️ Token stocké en SharedPreferences (pas SQLite)

---

### 3. **GET /auth/profile**
**Requis :** Token JWT
**Retourné (Frontend attend) :**
```json
{
  "profile_data": {
    "id": "uuid",
    "email": "string",
    "prenom": "string",
    "nom": "string",
    "ecole": "string",
    "filiere": "string",
    "photo_profil": "url",
    "profil_complet": boolean
  },
  "notifications_non_lues": integer
}
```
**Cache :** ✅ Oui (clé: `profile`)

---

### 4. **POST /carnets**
**Requis :**
```json
{
  "domaine_formation_id": "uuid",
  "metier_id": "uuid",
  "niveau_formation_id": "uuid",
  "poste": "string",
  "entreprise_nom": "string",
  "date_debut": "date",
  "date_fin": "date",
  "lieu_stage_adresse": "string",
  "lieu_stage_lat": "float",
  "lieu_stage_lng": "float",
  "rayon_geofence": "optional integer"
}
```
**Retourné :**
```json
{
  "message": "Carnet créé avec succès",
  "carnet": {
    "id": "uuid",
    "stagiaire_id": "uuid",
    "domaine_formation_id": "uuid",
    "metier_id": "uuid",
    "niveau_formation_id": "uuid",
    "poste": "string",
    "entreprise_nom": "string",
    "statut": "EN_ATTENTE|EN_COURS|TERMINE",
    "date_debut": "date",
    "date_fin": "date",
    "date_creation": "datetime",
    "geofence_lat": "float",
    "geofence_lng": "float",
    "geofence_rayon": "integer"
  }
}
```
**Cache :** ✅ Oui (clé: `carnets`)

---

### 5. **GET /carnets**
**Requis :** Token JWT
**Retourné :**
```json
{
  "data": [
    {
      "id": "uuid",
      "stagiaire_id": "uuid",
      "domaine_formation_id": "uuid",
      "metier_id": "uuid",
      "niveau_formation_id": "uuid",
      "poste": "string",
      "entreprise_nom": "string",
      "statut": "EN_ATTENTE|EN_COURS|TERMINE",
      "date_debut": "date",
      "date_fin": "date",
      "date_creation": "datetime",
      "geofence_lat": "float",
      "geofence_lng": "float",
      "geofence_rayon": "integer",
      "entreprise_id": "uuid",
      "autorisation_suivi": boolean,
      "tuteur_nom": "string|null"
    }
  ]
}
```
**Cache :** ✅ Oui (clé: `carnets`, TTL: 10 min)

---

### 6. **GET /carnets/{carnetId}/stats**
**Requis :** Token JWT
**Retourné :**
```json
{
  "progression_globale": integer (0-100),
  "jours_presents": integer,
  "jours_attendus": integer,
  "missions_completees": integer,
  "missions_totales": integer,
  "competences_validees": integer,
  "competences_totales": integer,
  "activites_recentes": [
    {
      "type": "mission|presence|difficulte|felicitation|trajet",
      "title": "string",
      "subtitle": "string",
      "date": "datetime"
    }
  ]
}
```
**Cache :** ✅ Oui (clé: `carnet_stats_{carnetId}`, TTL: 5 min)

---

### 7. **GET /pointage-historique/{carnetId}**
**Requis :** Token JWT
**Retourné :**
```json
[
  {
    "id": "uuid",
    "date_debut": "datetime",
    "date_fin": "datetime|null",
    "statut": "ARRIVE|PARTI"
  }
]
```
**Cache :** ✅ Oui (clé: `pointage_historique_{carnetId}`, TTL: 5 min)

---

### 8. **GET /referentiel/domaines**
**Requis :** Token JWT
**Retourné :**
```json
[
  {
    "id": "uuid",
    "nom": "string",
    "libelle": "string"
  }
]
```
**Cache :** ✅ Oui (clé: `referentiel_domaines`, TTL: 24 h)

---

### 9. **GET /referentiel/metiers**
**Requis :** Token JWT, optionnel `?domaineId=uuid`
**Retourné :**
```json
[
  {
    "id": "uuid",
    "domaine_formation_id": "uuid",
    "nom": "string",
    "libelle": "string"
  }
]
```
**Cache :** ✅ Oui (clé: `referentiel_metiers_all` ou `referentiel_metiers_{domaineId}`, TTL: 24 h)

---

### 10. **GET /referentiel/niveaux-formation**
**Requis :** Token JWT
**Retourné :**
```json
[
  {
    "id": "uuid",
    "ordre": integer,
    "nom": "string",
    "libelle": "string"
  }
]
```
**Cache :** ✅ Oui (clé: `referentiel_niveaux_formation`, TTL: 24 h)

---

### 11. **POST /stagiaire/photo**
**Requis :** File (multipart/form-data)
**Retourné :**
```json
{
  "message": "Photo mise à jour",
  "photo_url": "string"
}
```
**Cache :** ❌ Non (invalidate cache après)
**Offline :** 🔄 Queued

---

### 12. **DELETE /stagiaire/photo**
**Requis :** Token JWT
**Retourné :**
```json
{
  "message": "Photo supprimée"
}
```
**Cache :** ❌ Non (invalidate cache après)
**Offline :** 🔄 Queued

---

### 13. **GET /mes-reservations**
**Requis :** Token JWT
**Retourné :**
```json
[
  {
    "id": "uuid",
    "statut": "CONFIRMEE|ANNULEE|TERMINEE",
    "trajet": {
      "id": "uuid",
      "depart": "string",
      "arrivee": "string",
      "heure_depart": "time"
    }
  }
]
```
**Cache :** ✅ Oui (clé: `mes_reservations`, TTL: 10 min)

---

## 🛠️ Améliorations Proposées

### ✅ Déjà Implémentées
- [x] Cache SQLite avec TTL
- [x] Queue d'attente offline
- [x] Synchronisation automatique

### 📋 À Faire
- [ ] Ajouter un champ `Cache-Control` aux réponses API
- [ ] Ajouter un champ `ETag` pour la validation
- [ ] Documenter les erreurs possibles par endpoint
- [ ] Ajouter des timestamps à toutes les réponses

---

## 📊 Récapitulatif Cache

| Endpoint | Cacheable | TTL | Queued |
|----------|-----------|-----|--------|
| POST /auth/login | ❌ | — | ❌ |
| POST /auth/verify | ⚠️ | — | ❌ |
| GET /auth/profile | ✅ | 10m | ❌ |
| POST /carnets | ❌ | — | ✅ |
| GET /carnets | ✅ | 10m | ❌ |
| GET /carnets/{id}/stats | ✅ | 5m | ❌ |
| GET /pointage-historique | ✅ | 5m | ❌ |
| GET /referentiel/* | ✅ | 24h | ❌ |
| POST /stagiaire/photo | ❌ | — | ✅ |
| DELETE /stagiaire/photo | ❌ | — | ✅ |
| GET /mes-reservations | ✅ | 10m | ❌ |
