# Plan d'implémentation - Corrections Flux Stagiaire & Tuteur

Ce plan vise à stabiliser le flux de rattachement, corriger les erreurs de génération de documents et fiabiliser le pointage automatique par géofencing.

## User Review Required

> [!IMPORTANT]
> La modification du `HomeRouter` supprimera la redirection forcée par `Navigator` au profit d'un affichage conditionnel direct. Cela rendra la navigation plus fluide et évitera les écrans noirs, mais changera légèrement la pile de navigation (l'écran de recherche ne sera plus une route séparée dans ce flux).

## Proposed Changes

---

### [Backend] Correction des Dates et Cache

#### [MODIFY] [FicheStagiaireInvite.php](file:///C:/laragon/www/backend-stagiaires-laravel/app/Models/FicheStagiaireInvite.php)
- Ajouter `date_debut` et `date_fin` dans le tableau `$casts` en tant que `date`.

#### [MODIFY] [DemandeRattachementController.php](file:///C:/laragon/www/backend-stagiaires-laravel/app/Http/Controllers/DemandeRattachementController.php)
- Mettre à jour `checkStatus` pour retourner `has_rattachement => true` si le stagiaire a :
  - Une `DemandeRattachement` en cours.
  - **OU** Une `AutorisationPointage` existante.
  - **OU** Une invitation pendante (`FicheStagiaireInvite`) correspondant à son email.

#### [MODIFY] [AutorisationPointageController.php](file:///C:/laragon/www/backend-stagiaires-laravel/app/Http/Controllers/AutorisationPointageController.php)
- Invalider le cache des statistiques du dashboard entreprise lors de la signature finale (`validerLiaison`).

---

### [Flutter] Navigation et Géofencing

#### [MODIFY] [HomeRouter.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/features/screens/home_router.dart)
- Remplacer la redirection `Navigator.pushNamedAndRemoveUntil` par le retour direct du widget `EntrepriseSearchScreen(isMandatory: true)` au sein du `FutureBuilder`. Cela supprime les boucles de redirection asynchrones.

#### [MODIFY] [GeofencingService.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/services/geofencing_service.dart)
- Ajouter une vérification manuelle de la position actuelle au démarrage du service. Si le stagiaire est déjà dans le rayon, déclencher `pointageArrivee` immédiatement.

#### [MODIFY] [internship_service.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/services/internship_service.dart)
- Réduire le TTL du cache des statistiques dashboard entreprise (`entreprise_dashboard_stats_v2`) à 1 minute ou le supprimer pour garantir la fraîcheur des données.

---

### [Flutter] UI Carnet

#### [MODIFY] [carnet_list_page.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/features/screens/student/carnet_list_page.dart)
- Supprimer la mention "Rattaché" ou la remplacer par "Convention Active".

#### [MODIFY] [carnet_screen.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/features/screens/student/carnet_screen.dart)
- Vérifier et supprimer tout blocage d'accès aux missions basé sur un ancien statut de rattachement.

## Verification Plan

### Automated Tests
- Lancer les tests unitaires Laravel pour vérifier les casts des dates.
- Vérifier l'invalidation du cache via une commande `artisan tinker` simulée.

### Manual Verification
1. **Flux Stagiaire** : Créer un compte, choisir une entreprise, vérifier qu'il n'y a plus d'écran noir et que la navigation vers `HomeScreen` est directe.
2. **Convention** : Cliquer sur "Voir la convention" et vérifier que l'aperçu s'affiche sans erreur 500.
3. **Géofencing** : Se positionner dans la zone de stage fictive, signer, et vérifier que le pointage d'arrivée est créé même sans mouvement.
4. **Dashboard Tuteur** : Signer une convention côté stagiaire et vérifier que le compteur s'incrémente sur le dashboard tuteur après un rafraîchissement rapide.
