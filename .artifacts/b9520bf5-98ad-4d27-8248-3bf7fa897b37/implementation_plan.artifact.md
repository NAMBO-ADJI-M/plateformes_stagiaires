# Plan de Démonstration Finale et Correction SMTP - StageLink

Ce plan a été mis à jour pour inclure la correction critique du système d'envoi d'emails OTP, suite au rapport d'échec de réception.

## [URGENT] Correction du Système Email (OTP)

L'absence de réception de l'email est probablement due à un décalage entre l'adresse d'expédition (`From`) codée en dur et l'authentification SMTP Gmail.

### [Backend] Laravel

#### [MODIFY] [AuthController.php](file:///C:/laragon/www/backend-stagiaires-laravel/app/Http/Controllers/Auth/AuthController.php)
- Remplacer `->from('noreply@stagelink.com', 'StageLink')` par `->from(config('mail.from.address'), config('mail.from.name'))`.
- Ajouter un log détaillé dans le `catch` de `sendVerificationEmail` pour capturer l'exception exacte si l'envoi échoue à nouveau.

#### [MODIFY] [TestEmailController.php](file:///C:/laragon/www/backend-stagiaires-laravel/app/Http/Controllers/TestEmailController.php)
- Mettre à jour le texte de test (supprimer la mention "Brevo" qui prête à confusion avec la config Gmail).
- Permettre de passer l'email de destination en paramètre pour faciliter le test.

---

## Scénarios de Test de Démonstration

### 1. Validation SMTP & Authentification
- **Test Technique** : Appeler `GET /api/test-email?email=votre@email.com` et vérifier la réception.
- **Connexion Marie** : Tester le flux `login` -> `verify` avec un email réel.

### 2. Flux Stagiaire (Marie Dupont)
- **Pointage** : Arrivée géolocalisée.
- **Journal** : Ajout d'une mission.
- **Bilan** : Rédaction d'un bilan réflexif.
- **Documents** : Téléchargement PDF de l'attestation.

### 3. Flux Tuteur / Entreprise (TechCorp)
- **Encadrement** : Évaluation d'une compétence et envoi d'une félicitation.
- **Commentaires** : Annotation d'une entrée du journal de Marie.

### 4. Flux Covoiturage
- **Carte** : Création et réservation d'un trajet via l'interface interactive.
- **Messagerie** : Test du polling 5s.

---

## Points de Contrôle Techniques
- **Certificat SSL Aiven** : S'assurer que `MYSQL_ATTR_SSL_CA` pointe vers le bon chemin absolu ou relatif fonctionnel sur Laragon.
- **Offline-first** : Validation de la queue de synchronisation SQLite en mode avion.

## Verification Plan

### Automated Verification
- Vérification des logs `storage/logs/laravel.log` après une tentative d'envoi.

### Manual Validation
- Confirmation par l'utilisateur de la réception effective du code OTP sur son adresse email.
