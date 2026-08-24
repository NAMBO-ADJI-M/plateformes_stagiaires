# Plan d'implémentation : Module Demande de Rattachement (Suite)

Ce plan vise à finaliser l'intégration du module de demande de rattachement en connectant le frontend Flutter aux nouveaux endpoints Laravel et en restaurant l'écran Dashboard Tuteur.

## User Review Required

> [!IMPORTANT]
> L'application pointe actuellement vers Render (`onrender.com`). Si vos modifications Laravel sont locales, il faudra basculer l'URL dans `ApiService.dart` vers `http://10.0.2.2:8000/api` pour les tests sur émulateur.

## Proposed Changes

### [Frontend] Flutter Application

#### [MODIFY] [api_service.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/services/api_service.dart)
- Ajouter `rechercherEntreprises(String query)` : Appel à `GET /entreprises/recherche?q=...`
- Ajouter `demanderRattachement(String entrepriseId)` : Appel à `POST /rattachement/demander`
- Ajouter `getDemandesRattachement()` : Appel à `GET /entreprise/demandes-rattachement`

#### [MODIFY] [dashboard_tuteur_screen.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/features/screens/tuteur/dashboard_tuteur_screen.dart)
- [RESTAURATION] Réécrire l'écran complet.
- Affichage des statistiques (Stagiaires actifs, demandes en attente, etc.).
- Liste horizontale ou section dédiée pour les "Demandes de rattachement" avec le bouton "Demander l'accès".
- Intégration du rafraîchissement (Pull-to-refresh).

## Verification Plan

### Automated Tests
- N/A pour cette phase (UI/Intégration manuelle).

### Manual Verification
1. **Flux Stagiaire** :
   - Créer un nouveau compte stagiaire.
   - Vérifier la redirection vers `EntrepriseSearchScreen`.
   - Rechercher une entreprise et envoyer la demande.
2. **Flux Tuteur** :
   - Se connecter en tant que tuteur.
   - Vérifier l'apparition de la carte de demande sur le Dashboard.
   - Cliquer sur "Demander l'accès".
