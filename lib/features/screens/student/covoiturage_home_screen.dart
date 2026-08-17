import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import 'recherche_trajet_screen.dart';

/// Reproduit covoiturage-home.png : toggle géolocalisation, mini-carte,
/// barre de recherche (pousse vers RechercheTrajetScreen), tabs
/// Proposer/Rejoindre, liste des trajets disponibles.
class CovoiturageHomeScreen extends StatefulWidget {
  const CovoiturageHomeScreen({super.key});

  @override
  State<CovoiturageHomeScreen> createState() => _CovoiturageHomeScreenState();
}

class _CovoiturageHomeScreenState extends State<CovoiturageHomeScreen> {
  bool _geoloc = true;
  bool _rejoindre = true;

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RechercheTrajetScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        elevation: 0,
        foregroundColor: ColorConstants.textPrimary,
        title: const Text('Covoiturage Étudiant',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: ColorConstants.primary, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Autoriser la géolocalisation',
                      style: TextStyle(
                          fontSize: 13.5, color: ColorConstants.textPrimary)),
                ),
                Switch(
                  value: _geoloc,
                  activeThumbColor: ColorConstants.primary,
                  onChanged: (v) => setState(() => _geoloc = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Mini-carte stylisée (placeholder visuel).
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('4 conducteurs à proximité',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ),
                const Center(
                  child: Icon(Icons.map_outlined,
                      size: 44, color: ColorConstants.primaryLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _openSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: ColorConstants.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ColorConstants.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: ColorConstants.textSecondary, size: 20),
                  SizedBox(width: 10),
                  Text('Rechercher un trajet...',
                      style: TextStyle(
                          fontSize: 13.5, color: ColorConstants.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ColorConstants.border.withValues(alpha:0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _SegmentButton(
                  label: 'Proposer',
                  selected: !_rejoindre,
                  onTap: () => setState(() => _rejoindre = false),
                ),
                _SegmentButton(
                  label: 'Rejoindre',
                  selected: _rejoindre,
                  onTap: () => setState(() => _rejoindre = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Trajets disponibles',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 10),
          _TrajetCard(
            name: 'Lucas Bernard',
            avatarUrl: 'https://i.pravatar.cc/150?img=12',
            depart: '08:00',
            distance: 'À 1.2 km',
            from: 'Gare de Lyon, Paris',
            to: 'Campus Ubisoft France',
            places: '2 places disponibles',
            price: 'Gratuit',
            onTap: _openSearch,
          ),
          const SizedBox(height: 10),
          _TrajetCard(
            name: 'Chloé Dubois',
            avatarUrl: 'https://i.pravatar.cc/150?img=47',
            depart: '08:30',
            distance: 'À 2.5 km',
            from: 'Place de la Bastille',
            to: 'Campus Ubisoft France',
            places: '1 place disponible',
            price: '1.50 €',
            onTap: _openSearch,
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? ColorConstants.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: selected ? ColorConstants.primary : ColorConstants.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _TrajetCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String depart;
  final String distance;
  final String from;
  final String to;
  final String places;
  final String price;
  final VoidCallback onTap;

  const _TrajetCard({
    required this.name,
    required this.avatarUrl,
    required this.depart,
    required this.distance,
    required this.from,
    required this.to,
    required this.places,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = price.toLowerCase() == 'gratuit';
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrl)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: ColorConstants.textPrimary)),
                    Text('Départ à $depart',
                        style: const TextStyle(
                            fontSize: 12, color: ColorConstants.textSecondary)),
                  ],
                ),
              ),
              StatusPill(label: distance, color: ColorConstants.info),
            ],
          ),
          const SizedBox(height: 12),
          _RouteLine(label: from, dotColor: ColorConstants.primary),
          const SizedBox(height: 6),
          _RouteLine(label: to, dotColor: ColorConstants.accentOrange),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(places,
                  style: const TextStyle(
                      fontSize: 12.5, color: ColorConstants.textSecondary)),
              Text(price,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isFree ? ColorConstants.success : ColorConstants.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String label;
  final Color dotColor;
  const _RouteLine({required this.label, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontSize: 13, color: ColorConstants.textPrimary)),
      ],
    );
  }
}
