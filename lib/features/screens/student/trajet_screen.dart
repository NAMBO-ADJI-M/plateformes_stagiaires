import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';
import 'covoiturage_home_screen.dart';
import 'create_trajet_screen.dart';
import 'trajet_details_screen.dart';

class TrajetScreen extends StatefulWidget {
  const TrajetScreen({super.key});

  @override
  State<TrajetScreen> createState() => _TrajetScreenState();
}

class _TrajetScreenState extends State<TrajetScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _reservations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _api.getMesReservations();
      if (mounted) {
        setState(() {
          // On ne garde que les trajets à venir (pas annulés, pas terminés)
          _reservations = res
              .where((r) => r['statut'] != 'ANNULEE' && r['statut'] != 'TERMINEE')
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorConstants.paper,
      child: Column(
        children: [
          const ScreenTopBar(
            eyebrow: "Mobilité · Communauté StageLink",
            title: 'Covoiturage',
            showMessages: true,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _QuickSearchCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CovoiturageHomeScreen())
                    ).then((_) => _loadData()),
                  ),
                  const SizedBox(height: 24),
                  const Text('Vos trajets prévus',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorConstants.inkSoft)),
                  const SizedBox(height: 12),

                  if (_isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_reservations.isEmpty)
                    _buildEmptyState()
                  else
                    ..._reservations.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TrajetPreviewCard(
                        reservation: r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TrajetDetailsScreen(trajet: r['trajet'])),
                        ).then((_) => _loadData()),
                      ),
                    )),

                  const SizedBox(height: 16),
                  DashedActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Proposer un nouveau trajet',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateTrajetScreen())
                    ).then((_) => _loadData()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorConstants.line),
      ),
      child: const Text(
        "Vous n'avez aucun trajet prévu pour le moment.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: ColorConstants.textSecondary),
      ),
    );
  }
}

class _QuickSearchCard extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickSearchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorConstants.amber,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Besoin d\'un trajet ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Trouvez un stagiaire qui fait le même chemin que vous.',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: ColorConstants.amber.withOpacity(0.7), size: 20),
                  const SizedBox(width: 12),
                  const Text('Rechercher une destination...',
                    style: TextStyle(color: ColorConstants.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrajetPreviewCard extends StatelessWidget {
  final Map<String, dynamic> reservation;
  final VoidCallback onTap;

  const _TrajetPreviewCard({
    required this.reservation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trajet = reservation['trajet'] as Map<String, dynamic>? ?? {};
    final String status = reservation['statut'] ?? 'INCONNU';

    final dateStr = trajet['date_depart'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final heure = date != null ? DateFormat('HH:mm').format(date) : '--:--';

    final depart = trajet['lieu_depart'] ?? 'Lieu de départ';
    final arrivee = trajet['lieu_arrivee'] ?? 'Destination';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorConstants.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ColorConstants.line),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: status == 'CONFIRMEE' ? ColorConstants.success : ColorConstants.accentOrange,
                    letterSpacing: 1
                  )
                ),
                Text(heure, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            _RouteLine(label: depart, isStart: true),
            const SizedBox(height: 8),
            _RouteLine(label: arrivee, isStart: false),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String label;
  final bool isStart;
  const _RouteLine({required this.label, required this.isStart});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(isStart ? Icons.circle : Icons.location_on_rounded,
             size: 14,
             color: isStart ? ColorConstants.amber : ColorConstants.clay),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: ColorConstants.textPrimary)
        )),
      ],
    );
  }
}
