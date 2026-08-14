import 'package:flutter/material.dart';
import '../../core/constants/constants_colors.dart';

/// Carte blanche arrondie standard utilisée sur presque tous les écrans.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}

/// Petite carte statistique (chiffre + label) utilisée dans les dashboards.
class StatMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const StatMiniCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: ColorConstants.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Anneau de progression circulaire avec pourcentage au centre.
class ProgressRing extends StatelessWidget {
  final double percent; // 0..1
  final double size;
  final Color color;

  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 70,
    this.color = ColorConstants.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 7,
              backgroundColor: ColorConstants.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '${(percent * 100).round()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size / 4.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre de progression linéaire fine avec pourcentage.
class LinearProgressRow extends StatelessWidget {
  final double percent; // 0..1
  final Color color;

  const LinearProgressRow({super.key, required this.percent, this.color = ColorConstants.primary});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: percent,
        minHeight: 7,
        backgroundColor: ColorConstants.border,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Badge de statut coloré (En cours / Terminé / etc.)
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// En-tête de section commun ("Bonjour, X" + sous-titre + avatar optionnel).
///
/// L'avatar devient tappable dès que [onAvatarTap] est fourni : un petit
/// badge "appareil photo" apparaît alors en bas à droite, et [avatarLoading]
/// permet d'afficher un indicateur de chargement par-dessus pendant un
/// upload (photo de profil en cours d'envoi, par exemple).
class GreetingHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;
  final bool avatarLoading;

  const GreetingHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.avatarUrl,
    this.onAvatarTap,
    this.avatarLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.textPrimary)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13.5, color: ColorConstants.textSecondary)),
            ],
          ),
        ),
        if (avatarUrl != null) _avatar(),
      ],
    );
  }

  Widget _avatar() {
    final cercle = Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: avatarLoading ? 0.5 : 1,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: ColorConstants.border,
            backgroundImage: NetworkImage(avatarUrl!),
          ),
        ),
        if (avatarLoading)
          const Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          ),
        if (onAvatarTap != null && !avatarLoading)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: ColorConstants.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 11, color: Colors.white),
            ),
          ),
      ],
    );

    if (onAvatarTap == null) return cercle;

    return GestureDetector(
      onTap: avatarLoading ? null : onAvatarTap,
      child: cercle,
    );
  }
}

/// Bouton principal plein-largeur (indigo) utilisé pour les CTA.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
