import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';

/// Reproduit recherche-trajet.png : formulaire départ/destination/date/heure,
/// filtres rapides et résultats correspondants.
class RechercheTrajetScreen extends StatefulWidget {
  const RechercheTrajetScreen({super.key});

  @override
  State<RechercheTrajetScreen> createState() => _RechercheTrajetScreenState();
}

class _RechercheTrajetScreenState extends State<RechercheTrajetScreen> {
  int _filter = 0; // 0 = Aujourd'hui, 1 = Cette semaine, 2 = Proximité

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        elevation: 0,
        foregroundColor: ColorConstants.textPrimary,
        title: const Text('Rechercher un trajet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          AppCard(
            child: Column(
              children: [
                const _FieldLabel('Départ'),
                _FieldBox(icon: Icons.location_on_outlined, value: 'Gare de Lyon, Paris'),
                const SizedBox(height: 14),
                const _FieldLabel('Destination'),
                _FieldBox(icon: Icons.flag_outlined, value: 'Campus Ubisoft France', iconColor: ColorConstants.primary),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Date'),
                          _FieldBox(icon: Icons.calendar_today_outlined, value: '12 Mar. 2026'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Heure'),
                          _FieldBox(icon: Icons.access_time, value: '08:00'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _FilterChip(label: "Aujourd'hui", selected: _filter == 0, onTap: () => setState(() => _filter = 0)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Cette semaine', selected: _filter == 1, onTap: () => setState(() => _filter = 1)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Proximité', selected: _filter == 2, onTap: () => setState(() => _filter = 2)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Résultats correspondants (3)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 12),
          _ResultCard(
            name: 'Lucas Bernard',
            avatarUrl: 'https://i.pravatar.cc/150?img=12',
            depart: '08:00',
            placesRestantes: '2 places restantes',
            price: 'Gratuit',
            priceColor: ColorConstants.success,
          ),
          const SizedBox(height: 10),
          _ResultCard(
            name: 'Sarah Laurent',
            avatarUrl: 'https://i.pravatar.cc/150?img=45',
            depart: '08:15',
            placesRestantes: '3 places restantes',
            price: '2.00 €',
            priceColor: ColorConstants.primary,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(fontSize: 12.5, color: ColorConstants.textSecondary)),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color iconColor;
  const _FieldBox(
      {required this.icon, required this.value, this.iconColor = ColorConstants.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: ColorConstants.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(fontSize: 13.5, color: ColorConstants.textPrimary)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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

class _ResultCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String depart;
  final String placesRestantes;
  final String price;
  final Color priceColor;

  const _ResultCard({
    required this.name,
    required this.avatarUrl,
    required this.depart,
    required this.placesRestantes,
    required this.price,
    required this.priceColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 12),
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
                    style: const TextStyle(fontSize: 12, color: ColorConstants.textSecondary)),
                const SizedBox(height: 2),
                Text(placesRestantes,
                    style: const TextStyle(fontSize: 11.5, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: priceColor)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Message envoyé à $name')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Contacter', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
