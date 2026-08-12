import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import 'liste_stagiaires_screen.dart';

/// Reproduit dashboard-tuteur.png : alerte de baisse d'activité (bouton
/// "Encourager"), 3 stats, actions (Ajouter un stagiaire / Générer un code),
/// et liste "Vos Stagiaires" avec accès à la fiche complète.
class DashboardTuteurScreen extends StatelessWidget {
  const DashboardTuteurScreen({super.key});

  void _openStagiaires(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ListeStagiairesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const GreetingHeader(
          title: 'Bonjour, M. Laurent 👋',
          subtitle: 'Ubisoft France • Tuteur Principal',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ColorConstants.error.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorConstants.error.withValues(alpha:0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: ColorConstants.error, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Baisse d\'activité détectée chez Marie Dupont',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: ColorConstants.error)),
                    SizedBox(height: 3),
                    Text('Dernière entrée de carnet il y a 5 jours.',
                        style: TextStyle(
                            fontSize: 12, color: ColorConstants.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Encouragement envoyé à Marie Dupont')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.error,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Encourager', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            StatMiniCard(
                icon: Icons.people_alt_outlined,
                iconColor: ColorConstants.primary,
                value: '3',
                label: 'Stagiaires actifs'),
            SizedBox(width: 10),
            StatMiniCard(
                icon: Icons.bolt_outlined,
                iconColor: ColorConstants.accent,
                value: '12',
                label: 'Missions assignées'),
            SizedBox(width: 10),
            StatMiniCard(
                icon: Icons.trending_up_rounded,
                iconColor: ColorConstants.success,
                value: '74%',
                label: 'Complétion moy.'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openStagiaires(context),
                icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                label: const Text('Ajouter un stagiaire'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstants.primary,
                  backgroundColor: ColorConstants.primary.withValues( alpha:0.08),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Code d\'invitation'),
                      content: const Text('Code généré : ST-7F2Q9K'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fermer')),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.vpn_key_outlined, size: 18),
                label: const Text('Générer un code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstants.textPrimary,
                  side: const BorderSide(color: ColorConstants.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text('Vos Stagiaires',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: ColorConstants.textPrimary)),
        const SizedBox(height: 10),
        StagiaireTile(
          name: 'Marie Dupont',
          role: 'R&D UI/UX',
          progress: 0.62,
          status: 'En cours',
          statusColor: ColorConstants.accentOrange,
          avatarUrl: 'https://i.pravatar.cc/150?img=32',
          onTap: () => _openStagiaires(context),
        ),
        const SizedBox(height: 10),
        StagiaireTile(
          name: 'Lucas Bernard',
          role: 'Product Design',
          progress: 1.0,
          status: 'Terminé',
          statusColor: ColorConstants.success,
          avatarUrl: 'https://i.pravatar.cc/150?img=12',
          onTap: () => _openStagiaires(context),
        ),
        const SizedBox(height: 10),
        StagiaireTile(
          name: 'Chloé Petit',
          role: 'Front-end Dev',
          progress: 0.35,
          status: 'En cours',
          statusColor: ColorConstants.accentOrange,
          avatarUrl: 'https://i.pravatar.cc/150?img=48',
          onTap: () => _openStagiaires(context),
        ),
      ],
    );
  }
}

/// Réutilisée sur le dashboard et sur la liste complète des stagiaires.
class StagiaireTile extends StatelessWidget {
  final String name;
  final String role;
  final double progress;
  final String status;
  final Color statusColor;
  final String avatarUrl;
  final VoidCallback? onTap;

  const StagiaireTile({
    super.key,
    required this.name,
    required this.role,
    required this.progress,
    required this.status,
    required this.statusColor,
    required this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: ColorConstants.textPrimary)),
                    StatusPill(label: status, color: statusColor),
                  ],
                ),
                const SizedBox(height: 2),
                Text(role,
                    style: const TextStyle(
                        fontSize: 12, color: ColorConstants.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressRow(percent: progress, color: statusColor),
                    ),
                    const SizedBox(width: 8),
                    Text('${(progress * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
