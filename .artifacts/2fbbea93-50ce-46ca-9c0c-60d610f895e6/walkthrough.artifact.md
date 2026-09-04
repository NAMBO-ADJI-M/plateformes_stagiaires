# Walkthrough - Stabilisation Flux Stagiaire & Tuteur

Les corrections apportées fiabilisent le processus de liaison, le pointage automatique et l'expérience utilisateur globale.

## Changements Backend

- **Migrations** :
  - Ajout du champ `heure_fin_journee` (par défaut `17:30:00`) à la table `entreprises`.
  - Migration de backfill pour peupler `autorisation_pointage_id` sur les anciens pointages, assurant la visibilité immédiate des données passées pour le tuteur.
- **Pointage & Cron** :
  - La sortie de zone (`EXIT`) est désormais une "sortie silencieuse". Elle ne clôture plus la session immédiatement mais attend le Cron Job ou le retour du stagiaire.
  - Le Cron Job compare l'heure de sortie à `heure_fin_journee` pour décider d'une clôture rétroactive.
- **API** :
  - `checkStatus` inclut désormais les invitations pendantes, évitant les boucles de redirection infinies.
  - Invalidation explicite du cache dashboard lors de la signature des conventions.

## Changements Flutter

- **Navigation Stagiaire** : `HomeRouter` retourne directement le widget de recherche d'entreprise si aucun rattachement n'est trouvé, éliminant les transitions buggées et les écrans noirs.
- **Géofencing Silencieux** : Suppression des notifications interactives à la sortie de zone. Le suivi est totalement automatisé et non intrusif.
- **Vérification Initiale** : Le service GPS vérifie la position au démarrage de l'app. Si le stagiaire est déjà sur son lieu de stage, le pointage d'arrivée est déclenché immédiatement.
- **UI Tuteur** :
  - Blocage de la navigation vers le suivi si la convention n'est pas signée, avec message informatif.
  - Feedback visuel "Pause ?" dans l'historique de pointage tuteur pour les sessions en attente de clôture.

## Vérification effectuée

- [x] Migration de backfill testée (simulation Tinker).
- [x] Navigation conditionnelle `HomeRouter` validée par structure de code.
- [x] Logique silencieuse de sortie de zone implémentée dans `GeofencingService`.
- [x] Invalidation du cache confirmée dans `InternshipService`.
