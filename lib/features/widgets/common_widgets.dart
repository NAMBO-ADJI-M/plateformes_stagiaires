import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/constants_colors.dart';
import '../screens/student/notifications_screen.dart';
import '../screens/student/conversations_screen.dart';

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
            color: Colors.black.withValues(alpha: 0.04),
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

/// Carte de statistique pleine-largeur pour les dashboards (Dashboard Tuteur).
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorConstants.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: ColorConstants.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Tuile stagiaire avec barre de progression, statut et bouton "Suivre".
/// Utilisée dans le dashboard tuteur et la liste des stagiaires.
class StagiaireTile extends StatelessWidget {
  final String name;
  final String role;
  final double progress;
  final String status;
  final Color statusColor;
  final String avatarUrl;
  final String autoStatut;
  final double roleFontSize;
  final VoidCallback? onDemanderSuivi;
  final VoidCallback? onTap;

  const StagiaireTile({
    super.key,
    required this.name,
    required this.role,
    required this.progress,
    required this.status,
    required this.statusColor,
    required this.avatarUrl,
    required this.autoStatut,
    this.roleFontSize = 12,
    this.onDemanderSuivi,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: statusColor.withValues(alpha: 0.1),
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty ? Icon(Icons.person, color: statusColor) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: roleFontSize, color: ColorConstants.textSecondary),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: ColorConstants.border,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(label: status, color: statusColor),
              if (autoStatut == 'CONVENTION_SIGNEE')
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Accès accordé', 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ColorConstants.success)),
                ),
              if (onDemanderSuivi != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onDemanderSuivi,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: ColorConstants.primary,
                  ),
                  child: const Text('Suivre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Affiche un dialog d'info compte stagiaire (email + date de création).
/// Fonction utilitaire partagée entre dashboard et liste des stagiaires.
void showCompteInfoDialog(BuildContext context, Map<String, dynamic> stagiaire) {
  final createdAt = stagiaire['created_at'] as String?;
  String dateStr = 'Non disponible';
  String heureStr = '';
  if (createdAt != null) {
    final dt = DateTime.tryParse(createdAt);
    if (dt != null) {
      dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      heureStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Informations du compte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email : ${stagiaire['email'] ?? 'Non renseigné'}'),
          const SizedBox(height: 8),
          Text('Créé le : $dateStr${heureStr.isNotEmpty ? ' à $heureStr' : ''}'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
      ],
    ),
  );
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
        color: color.withValues(alpha: 0.12),
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
            child: ClipOval(
              child: Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                width: 48,
                height: 48,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: ColorConstants.border,
                    child: const Icon(Icons.person, color: ColorConstants.textSecondary),
                  );
                },
              ),
            ),
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

/// Widget Skeleton pour l'effet de chargement "shimmer" (scintillement).
class Skeleton extends StatefulWidget {
  final double? height;
  final double? width;
  final double borderRadius;

  const Skeleton({super.key, this.height, this.width, this.borderRadius = 12});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// État vide (Empty State) illustré et élégant.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: ColorConstants.primary.withValues(alpha:0.4)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: ColorConstants.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: ColorConstants.textSecondary),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Bouton principal plein-largeur (indigo) utilisé pour les CTA.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
      ),
    );
  }
}

/// Barre de titre d'écran avec "eyebrow" (petit texte au-dessus) et accès profil.
class ScreenTopBar extends StatelessWidget {
  final String eyebrow;
  final String title;
  final bool showProfile;
  final bool showMessages;

  const ScreenTopBar({
    super.key,
    required this.eyebrow,
    required this.title,
    this.showProfile = true,
    this.showMessages = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: ColorConstants.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: ColorConstants.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (showMessages)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  color: ColorConstants.textPrimary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConversationsScreen()),
              ),
            ),
          if (showProfile) ...[
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: ColorConstants.textPrimary),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bouton d'action avec bordure en pointillés.
class DashedActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DashedActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorConstants.border,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: ColorConstants.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
