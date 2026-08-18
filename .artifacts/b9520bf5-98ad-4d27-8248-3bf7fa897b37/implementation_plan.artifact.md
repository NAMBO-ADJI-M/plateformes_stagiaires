# Plan d'Implémentation : Dynamisation de l'Interface Entreprise

Ce plan vise à rendre fonctionnel le Dashboard et la Liste des Stagiaires pour l'espace Entreprise/Tuteur en connectant le frontend Flutter au backend Laravel.

## Proposed Changes

### [Backend] Laravel (backend-stagiaires-laravel)

#### [MODIFY] [api.php](file:///C:/laragon/www/backend-stagiaires-laravel/routes/api.php)
- Ajouter les routes suivantes dans le groupe `middleware('profil:entreprise')` :
    - `GET /entreprise/stagiaires` : Liste des carnets rattachés à l'entreprise.
    - `GET /entreprise/dashboard-stats` : Statistiques globales pour le tuteur.

#### [MODIFY] [CarnetController.php](file:///C:/laragon/www/backend-stagiaires-laravel/app/Http/Controllers/CarnetController.php)
- Implémenter `listeEntreprise(Request $request)` : Filtre les `CarnetDeStage` par `entreprise_id`.
- Implémenter `statsEntreprise(Request $request)` : Calcule le nombre de stagiaires actifs, le nombre total de missions et la progression moyenne.

---

### [Frontend] Flutter (plateforme_stagiaires)

#### [MODIFY] [api_service.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/services/api_service.dart)
- Ajouter `getEntrepriseStagiaires()` : Appel à `GET /entreprise/stagiaires`.
- Ajouter `getEntrepriseDashboardStats()` : Appel à `GET /entreprise/dashboard-stats`.

#### [MODIFY] [DashboardTuteurScreen.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/features/screens/tuteur/dashboard_tuteur_screen.dart)
- Convertir en `StatefulWidget` pour gérer le chargement des données.
- Remplacer les données statiques par les données de `ApiService`.
- Gérer les états de chargement (Loading) et d'erreur.

#### [MODIFY] [ListeStagiairesScreen.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/features/screens/tuteur/liste_stagiaires_screen.dart)
- Utiliser `ApiService` pour récupérer la liste complète des stagiaires.
- Implémenter le filtrage par statut (Tous, Actifs, Terminés).
- Connecter la barre de recherche.

---

## Verification Plan

### Automated Tests
- Pas de tests automatisés prévus dans cette phase immédiate, mais vérification de la compilation.

### Manual Verification
1. **Connexion en tant qu'Entreprise** : Vérifier que le Dashboard affiche les stats réelles.
2. **Ajout d'un stagiaire** : Vérifier qu'un stagiaire rattaché via code apparaît dans la liste.
3. **Navigation** : Vérifier que cliquer sur un stagiaire mène bien à ses détails (attestations/suivi).
4. **Offline** : Vérifier que les listes sont mises en cache par `SqliteCacheService`.
