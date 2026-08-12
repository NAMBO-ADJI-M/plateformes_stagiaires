import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';

/// Reproduit notifications-screen.png : liste de notifications avec
/// distinction encouragement (bienveillant) / validation / covoiturage / système,
/// conformément à la séparation encouragements vs signalements décidée pour le projet.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        elevation: 0,
        foregroundColor: ColorConstants.textPrimary,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Marquer tout comme lu',
                style: TextStyle(color: ColorConstants.primary, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: const [
          _NotifCard(
            icon: Icons.favorite,
            iconColor: Color(0xFFEC4899),
            title: 'Encouragement de votre tuteur',
            body: "Mme. Martin a laissé un commentaire positif sur votre rapport de stage.",
            time: 'Il y a 10 min',
            unread: true,
          ),
          SizedBox(height: 10),
          _NotifCard(
            icon: Icons.check,
            iconColor: ColorConstants.success,
            title: 'Carnet validé !',
            body: 'Votre carnet pour la semaine 6 a été officiellement approuvé par Ubisoft.',
            time: 'Il y a 2h',
            unread: true,
          ),
          SizedBox(height: 10),
          _NotifCard(
            icon: Icons.directions_car_outlined,
            iconColor: ColorConstants.info,
            title: 'Nouveau trajet covoiturage',
            body: 'Lucas Bernard propose un départ correspondant à vos horaires demain matin.',
            time: 'Hier',
            unread: false,
          ),
          SizedBox(height: 10),
          _NotifCard(
            icon: Icons.notifications_none_rounded,
            iconColor: ColorConstants.textSecondary,
            title: 'Mise à jour plateforme',
            body: "StageConnect s'est refait une beauté ! Découvrez la nouvelle vue calendrier.",
            time: '3 jours',
            unread: false,
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final bool unread;

  const _NotifCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: ColorConstants.textPrimary)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12.5, color: ColorConstants.textSecondary)),
                const SizedBox(height: 6),
                Text(time,
                    style: const TextStyle(
                        fontSize: 11, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
          if (unread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: ColorConstants.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
