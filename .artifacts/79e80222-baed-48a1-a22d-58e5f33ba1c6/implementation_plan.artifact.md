# Plan d'implémentation - Correction du rattachement de carnet et nettoyage des codes d'invitation

Ce plan vise à résoudre les problèmes de validation des codes d'invitation lors du rattachement d'un carnet de stage, en assurant un nettoyage rigoureux des entrées (trim, suppression des espaces internes) et en garantissant que le `carnet_id` correct est transmis au backend.

## User Review Required

> [!IMPORTANT]
> L'instruction "pas de changement de casse" sera respectée côté client (Flutter). Cependant, pour garantir la compatibilité et éviter les erreurs de saisie, le backend continuera (ou commencera) à traiter les codes en majuscules de manière insensible à la casse (`strtoupper`), car les codes générés sont nativement en majuscules.

## Proposed Changes

### Backend (Laravel)

#### [MODIFY] [AutorisationPointageController.php](file:///C:/laragon/www/backend-stagiaires-laravel/app/Http/Controllers/AutorisationPointageController.php)
- Nettoyer le code avec `trim` et `strtoupper` dans toutes les méthodes concernées.
- Supprimer le résidu textuel "Broadway" identifié en fin de fichier.
- Mettre à jour `validerLiaison` pour accepter un `carnet_id` optionnel et effectuer le rattachement du carnet si présent (mise à jour de `entreprise_id`, `statut`, etc.).

#### [MODIFY] [RattachementController.php](file:///C:/laragon/www/backend-stagiaires-laravel/app/Http/Controllers/RattachementController.php)
- Ajouter le nettoyage `strtoupper(trim(...))` sur le `code_invitation` pour assurer la correspondance avec la base de données.

---

### Frontend (Flutter)

#### [MODIFY] [api_service.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/services/api_service.dart)
- Mettre à jour `verifierCodeSuivi` et `validerLiaisonDefinitive` pour inclure le paramètre `carnetId`.
- S'assurer que `rattacherCarnet` utilise les mêmes principes de nettoyage.

#### [MODIFY] [home_screen.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/features/screens/student/home_screen.dart)
- Extraire et stocker l'`id` du carnet actif lors du chargement des données.
- Dans `_showCodePopup` :
    - Ajouter un `inputFormatter` au `TextField` pour empêcher la saisie/collage d'espaces.
    - Supprimer `TextCapitalization.characters` et `.toUpperCase()` selon les instructions.
    - Utiliser `trim()` sur la valeur envoyée.
    - Passer l'ID du carnet actif aux appels API.
- Améliorer l'affichage des erreurs en utilisant le message renvoyé par le backend.

#### [MODIFY] [notifications_screen.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/features/screens/student/notifications_screen.dart)
- Appliquer un `trim()` sur le code avant de le placer dans le presse-papier lors du clic sur "Copier".

#### [MODIFY] [add_stagiaire_dialog.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/features/screens/tuteur/widgets/add_stagiaire_dialog.dart)
- Utiliser `SelectableText` pour le code affiché.
- Ajouter un bouton "Copier le code" explicite utilisant `Clipboard`.

#### [MODIFY] [liaison_stagiaire_dialog.dart](file:///C:/laragon/www/plateforme_stagiaires/lib/features/screens/tuteur/widgets/liaison_stagiaire_dialog.dart)
- Utiliser `SelectableText` pour le code affiché.
- Ajouter un bouton "Copier le code" explicite.

## Verification Plan

### Automated Tests
- N/A (Tests manuels privilégiés pour le flux UI/UX de copie-colle).

### Manual Verification
1. **Flux Tuteur** : Générer une invitation, cliquer sur le nouveau bouton "Copier".
2. **Flux Stagiaire (Notification)** : Cliquer sur "Copier le code" dans une notification.
3. **Flux Stagiaire (Accueil)** : Coller le code dans le popup de liaison. Vérifier que le carnet est bien mis à jour côté backend et que la liaison s'établit sans erreur de casse ou d'espace.
4. **Validation Backend** : Vérifier en base de données que le `carnet_id` a bien été associé à l'entreprise après la validation du code sur l'accueil.
