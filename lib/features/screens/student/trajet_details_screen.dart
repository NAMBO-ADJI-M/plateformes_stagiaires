import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/carpool_service.dart';
import '../../../services/api_exception.dart';
import '../../widgets/common_widgets.dart';
import 'messages_screen.dart';

/// Écran de détails d'un trajet : affiche les infos complètes, liste des passagers,
/// et boutons pour réserver ou voir les messages.
class TrajetDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> trajet;

  const TrajetDetailsScreen({
    super.key,
    required this.trajet,
  });

  @override
  State<TrajetDetailsScreen> createState() => _TrajetDetailsScreenState();
}

class _TrajetDetailsScreenState extends State<TrajetDetailsScreen> {
  final CarpoolService _apiService = CarpoolService();
  bool _reserving = false;
  String? _erreur;
  int _nombrePlaces = 1;

  // Les identifiants du backend sont des UUID (String), pas des int.
  String get trajetId => widget.trajet['id'] as String;
  String get chauffeur =>
      widget.trajet['chauffeur']?['nom'] ?? 'Conducteur inconnu';
  String get depart => widget.trajet['lieu_depart'] ?? '—';
  String get arrivee => widget.trajet['lieu_arrivee'] ?? '—';
  DateTime? get dateDepart {
    final date = widget.trajet['date_depart'];
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  int? get placesDisponibles => widget.trajet['places_disponibles'] as int?;
  List<dynamic> get passagers =>
      (widget.trajet['passagers'] ?? []) as List<dynamic>;
  String? get description => widget.trajet['description'] as String?;
  double? get tarif => (widget.trajet['tarif'] as dynamic)?.toDouble();

  Future<void> _reserver() async {
    setState(() => _erreur = null);

    if (_nombrePlaces <= 0) {
      setState(() => _erreur = 'Merci de sélectionner au moins 1 place');
      return;
    }

    if (placesDisponibles != null && _nombrePlaces > placesDisponibles!) {
      setState(() => _erreur = 'Pas assez de places disponibles');
      return;
    }

    setState(() => _reserving = true);

    try {
      await _apiService.reserverTrajet(trajetId, nombrePlaces: _nombrePlaces);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Réservation confirmée !'),
          backgroundColor: ColorConstants.success,
        ),
      );

      // Refresh et fermer
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context, true);
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _erreur = e.userFriendlyMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erreur = 'Erreur lors de la réservation');
      }
    } finally {
      if (mounted) setState(() => _reserving = false);
    }
  }

  void _ouvrirMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesScreen(
            trajetId: trajetId, trajetTitre: 'Messages - $chauffeur'),
      ),
    );
  }

  void _signalerTrajet() {
    final motifCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler ce trajet'),
        content: TextField(
          controller: motifCtrl,
          decoration: const InputDecoration(
            labelText: 'Motif du signalement',
            hintText: 'Comportement, trajet suspect...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (motifCtrl.text.isEmpty) return;
              try {
                await _apiService.signalerTrajet(trajetId, motifCtrl.text);
                if (!mounted) {
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signalement envoyé. Merci.')),
                );
              } catch (e) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColorConstants.error),
            child: const Text('Signaler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.cardBackground,
        foregroundColor: ColorConstants.textPrimary,
        title: const Text('Détails du trajet'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: ColorConstants.error),
            onPressed: _signalerTrajet,
            tooltip: 'Signaler ce trajet',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête du trajet (trajet card stylisée)
            _headerTrajet(),

            const SizedBox(height: 16),

            // Sections détails
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _sectionChauffeur(),
                  const SizedBox(height: 16),
                  _sectionPassagers(),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionDescription(),
                  ],
                  const SizedBox(height: 16),
                  _sectionDetails(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Erreurs
            if (_erreur != null) _bandeauErreur(),

            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sélecteur nombre de places
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nombre de places',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _nombrePlaces > 1
                            ? () => setState(() => _nombrePlaces--)
                            : null,
                        iconSize: 24,
                        color: ColorConstants.primary,
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(_nombrePlaces.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: (placesDisponibles == null ||
                                _nombrePlaces < placesDisponibles!)
                            ? () => setState(() => _nombrePlaces++)
                            : null,
                        iconSize: 24,
                        color: ColorConstants.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reserving ? null : _ouvrirMessages,
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Messages'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: ColorConstants.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _reserving ? null : _reserver,
                    icon: _reserving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_reserving ? 'En cours...' : 'Réserver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _headerTrajet() {
    return Container(
      color: ColorConstants.cardBackground,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trajet principal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(depart,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(_formatTime(dateDepart),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.trending_flat, color: Colors.grey.shade400, size: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(arrivee,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('arrivée',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date complète + places
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(dateDepart),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              if (placesDisponibles != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: placesDisponibles! > 0
                        ? ColorConstants.success.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    placesDisponibles! > 0
                        ? '$placesDisponibles places'
                        : 'Complet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: placesDisponibles! > 0
                          ? ColorConstants.success
                          : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionChauffeur() {
    final chauffeurData = widget.trajet['chauffeur'] as Map<String, dynamic>?;
    final photo = chauffeurData?['photo_profil'] as String?;
    final note = (chauffeurData?['note_moyenne'] as dynamic)?.toDouble() ?? 5.0;

    return AppCard(
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: ColorConstants.primary.withValues(alpha: 0.2),
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? Icon(Icons.person, color: ColorConstants.primary, size: 28)
                : null,
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chauffeur,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      note.toStringAsFixed(1),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bouton contacter (optionnel, pour future impl)
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Appelez via l\'app de messagerie')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionPassagers() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Passagers',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 10),
          if (passagers.isEmpty)
            Text('Aucun passager pour l\'instant',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: passagers.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (_, i) {
                final p = passagers[i] as Map<String, dynamic>;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          ColorConstants.primary.withValues(alpha: 0.2),
                      child:
                          Text((p['nom'] as String? ?? '?')[0].toUpperCase()),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['nom'] as String? ?? 'Anonyme',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
                          Text((p['places'] as dynamic)?.toString() ?? '1',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _sectionDescription() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            description!,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _sectionDetails() {
    return Column(
      children: [
        _detailRow('Prix par place',
            tarif != null ? '${tarif!.toStringAsFixed(2)} €' : 'À discuter'),
        _detailRow('Lieu de départ', depart),
        _detailRow('Lieu d\'arrivée', arrivee),
      ],
    );
  }

  Widget _detailRow(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valeur,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bandeauErreur() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_erreur!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}