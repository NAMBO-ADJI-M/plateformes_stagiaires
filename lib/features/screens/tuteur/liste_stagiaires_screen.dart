import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import 'dashboard_tuteur_screen.dart';
import 'attestations_screen.dart';

/// Reproduit liste-stagiaires.png : recherche, tabs Tous/Actifs/Terminés,
/// liste des stagiaires en cours et historique des précédents stages.
class ListeStagiairesScreen extends StatefulWidget {
  const ListeStagiairesScreen({super.key});

  @override
  State<ListeStagiairesScreen> createState() => _ListeStagiairesScreenState();
}

class _ListeStagiairesScreenState extends State<ListeStagiairesScreen> {
  int _tab = 0; // 0 Tous, 1 Actifs, 2 Terminés

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        elevation: 0,
        foregroundColor: ColorConstants.textPrimary,
        title: const Text('Stagiaires',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ColorConstants.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ColorConstants.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 18, color: ColorConstants.textSecondary),
                SizedBox(width: 8),
                Text('Rechercher un stagiaire...',
                    style: TextStyle(fontSize: 13.5, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _TabChip(label: 'Tous', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
              const SizedBox(width: 8),
              _TabChip(label: 'Actifs', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
              const SizedBox(width: 8),
              _TabChip(label: 'Terminés', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
            ],
          ),
          const SizedBox(height: 16),
          StagiaireTile(
            name: 'Marie Dupont',
            role: 'R&D UI/UX • 1 Fév. - 31 Juil.',
            progress: 0.62,
            status: 'En cours',
            statusColor: ColorConstants.accentOrange,
            avatarUrl: 'https://i.pravatar.cc/150?img=32',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AttestationsScreen())),
          ),
          const SizedBox(height: 10),
          StagiaireTile(
            name: 'Lucas Bernard',
            role: 'Product Design • 1 Fév. - 31 Juil.',
            progress: 1.0,
            status: 'Terminé',
            statusColor: ColorConstants.success,
            avatarUrl: 'https://i.pravatar.cc/150?img=12',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AttestationsScreen())),
          ),
          const SizedBox(height: 10),
          StagiaireTile(
            name: 'Chloé Petit',
            role: 'Front-end Dev • 1 Mar. - 31 Août',
            progress: 0.35,
            status: 'En cours',
            statusColor: ColorConstants.accentOrange,
            avatarUrl: 'https://i.pravatar.cc/150?img=48',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AttestationsScreen())),
          ),
          const SizedBox(height: 22),
          const Text('Historique (Précédents stages)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AttestationsScreen())),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: ColorConstants.border,
                  child: Icon(Icons.person_outline, color: ColorConstants.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Thomas Martin',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: ColorConstants.textPrimary)),
                      Text('Stage de fin d\'études • Terminé en 2025',
                          style: TextStyle(fontSize: 12, color: ColorConstants.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.description_outlined, color: ColorConstants.textSecondary, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? ColorConstants.primary : ColorConstants.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? ColorConstants.primary : ColorConstants.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : ColorConstants.textSecondary)),
      ),
    );
  }
}
