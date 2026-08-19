import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';
import '../../widgets/common_widgets.dart';
import 'trajet_details_screen.dart';
import 'messages_screen.dart';

/// Écran de gestion des réservations : affiche les trajets réservés avec possibilité d'annuler.
class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _reservations = [];
  bool _chargement = true;
  String? _erreur;
  String? _reservationEnAnnulation;

  @override
  void initState() {
    super.initState();
    _chargerReservations();
  }

  Future<void> _chargerReservations() async {
    setState(() => _chargement = true);

    try {
      final reservations = await _apiService.getMesReservations();
      setState(() {
        _reservations = List<Map<String, dynamic>>.from(
          reservations.map((r) => r is Map<String, dynamic> ? r : {}),
        );
        _chargement = false;
        _erreur = null;
      });
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.userFriendlyMessage;
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = 'Impossible de charger les réservations';
        _chargement = false;
      });
    }
  }

  Future<void> _annulerReservation(String reservationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Confirmer l\'annulation'),
        content:
            const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Garder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Annuler la réservation'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _reservationEnAnnulation = reservationId);

    try {
      await _apiService.annulerReservation(reservationId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Réservation annulée'),
          backgroundColor: ColorConstants.success,
        ),
      );

      // Rafraîchir la liste
      await _chargerReservations();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _erreur = e.userFriendlyMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erreur = 'Erreur lors de l\'annulation');
      }
    } finally {
      if (mounted) setState(() => _reservationEnAnnulation = null);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.cardBackground,
        foregroundColor: ColorConstants.textPrimary,
        title: const Text('Mes réservations'),
        elevation: 1,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Erreur
                if (_erreur != null)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_outlined,
                            color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _erreur!,
                            style: TextStyle(
                                color: Colors.orange.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Contenu
                _reservations.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available_outlined,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'Aucune réservation',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 14),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.directions_car),
                                label: const Text('Chercher un trajet'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConstants.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Expanded(
                        child: RefreshIndicator(
                          onRefresh: _chargerReservations,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _reservations.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) =>
                                _reservationCard(_reservations[i]),
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _reservationCard(Map<String, dynamic> reservation) {
    final trajetId = reservation['trajet_id'] as String?;
    final trajet = reservation['trajet'] as Map<String, dynamic>? ?? {};
    final chauffeur = trajet['chauffeur'] as Map<String, dynamic>?;
    final chauffeurNom = chauffeur?['nom'] as String? ?? 'Conducteur';

    final depart = trajet['lieu_depart'] as String? ?? '—';
    final arrivee = trajet['lieu_arrivee'] as String? ?? '—';
    final dateDepart = trajet['date_depart'] as String?;
    final places = (reservation['places'] as dynamic)?.toString() ?? '1';
    final prix = (reservation['prix_total'] as dynamic)?.toString() ?? '—';

    final reservationId = reservation['id'] as String?;
    final enAnnulation = _reservationEnAnnulation == reservationId;

    return GestureDetector(
      onTap: trajetId != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrajetDetailsScreen(trajet: trajet),
                ),
              )
          : null,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : trajet principal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(depart,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Icon(Icons.trending_flat,
                              color: Colors.grey.shade400, size: 18),
                          Expanded(
                            child: Text(arrivee,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_formatDate(dateDepart),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Infos du chauffeur + places/prix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            ColorConstants.primary.withValues(alpha: 0.2),
                        child: Text(chauffeurNom.isNotEmpty ? chauffeurNom[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chauffeurNom,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$places place${places != '1' ? 's' : ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    Text('$prix €',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Boutons d'action : Messages et Annuler
            Row(
              children: [
                if (trajetId != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessagesScreen(
                              trajetId: trajetId,
                              trajetTitre: 'Discussion - $chauffeurNom',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorConstants.primary,
                        side: const BorderSide(color: ColorConstants.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: enAnnulation || reservationId == null
                        ? null
                        : () => _annulerReservation(reservationId),
                    icon: enAnnulation
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close, size: 16),
                    label: Text(
                        enAnnulation ? 'Annulation...' : 'Annuler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}