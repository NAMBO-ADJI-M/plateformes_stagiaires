import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';
import '../../widgets/common_widgets.dart';
import 'carnet_creation_page.dart';

/// Page de progression et statistiques dynamiques du stagiaire.
/// Affiche la progression globale, le détail par catégorie (missions, compétences, assiduité)
/// et les jalons/entrées récentes du journal de bord.
class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({super.key});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  bool _hasCarnet = false;
  Map<String, dynamic>? _carnetActif;
  Map<String, dynamic>? _stats;
  List<dynamic> _entrees = [];

  @override
  void initState() {
    super.initState();
    _loadProgression();
  }

  Future<void> _loadProgression() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final carnets = await _api.getCarnets();

      if (carnets.isEmpty) {
        if (mounted) {
          setState(() {
            _hasCarnet = false;
            _loading = false;
          });
        }
        return;
      }

      final carnet = carnets.firstWhere(
        (c) => c['statut'] == 'EN_COURS',
        orElse: () => carnets.first,
      ) as Map<String, dynamic>;

      final carnetId = carnet['id'] as String;

      final results = await Future.wait([
        _api.getCarnetStats(carnetId),
        _api.getEntreesJournal(carnetId).catchError((_) => <dynamic>[]),
      ]);

      if (mounted) {
        setState(() {
          _hasCarnet = true;
          _carnetActif = carnet;
          _stats = results[0] as Map<String, dynamic>;
          _entrees = results[1] as List<dynamic>;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.userFriendlyMessage;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger la progression. Vérifiez votre connexion.';
          _loading = false;
        });
      }
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 44, color: ColorConstants.textSecondary),
              const SizedBox(height: 14),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadProgression,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasCarnet) {
      return RefreshIndicator(
        onRefresh: _loadProgression,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Aucun carnet de stage',
              subtitle:
                  'Créez votre carnet de stage pour suivre vos objectifs, vos missions et votre assiduité.',
              action: PrimaryButton(
                label: 'Créer mon carnet',
                icon: Icons.add,
                onPressed: () async {
                  final cree = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const CarnetCreationPage()),
                  );
                  if (cree == true) _loadProgression();
                },
              ),
            ),
          ],
        ),
      );
    }

    final double progressionGlobale =
        (((_stats?['progression_globale'] ?? 0) as num).toDouble()) / 100;

    final int missionsCompletees =
        ((_stats?['missions_completees'] ?? 0) as num).toInt();
    final int missionsTotales =
        ((_stats?['missions_totales'] ?? 0) as num).toInt();

    final int competencesValidees =
        ((_stats?['competences_validees'] ?? 0) as num).toInt();
    final int competencesTotales =
        ((_stats?['competences_totales'] ?? 10) as num).toInt();

    final int joursPresents =
        ((_stats?['jours_presents'] ?? 0) as num).toInt();
    final int joursAttendus =
        ((_stats?['jours_attendus'] ?? 1) as num).toInt();

    final String poste = _carnetActif?['poste'] ?? 'Stage';
    final String entreprise = _carnetActif?['entreprise_nom'] ?? 'Entreprise';

    return RefreshIndicator(
      onRefresh: _loadProgression,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text('Votre Progression',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 4),
          Text('$poste • $entreprise',
              style: const TextStyle(
                  fontSize: 13.5, color: ColorConstants.textSecondary)),
          const SizedBox(height: 18),

          // --- Anneau Global de Progression ---
          AppCard(
            child: Row(
              children: [
                ProgressRing(percent: progressionGlobale.clamp(0.0, 1.0), size: 78),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Progression globale',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: ColorConstants.textPrimary)),
                      const SizedBox(height: 6),
                      Text(
                        progressionGlobale >= 0.8
                            ? 'Excellent travail ! Vous avez validé la quasi-totalité de vos objectifs.'
                            : progressionGlobale >= 0.5
                                ? 'Vous avez complété plus de la moitié de vos objectifs de stage.'
                                : progressionGlobale > 0
                                    ? 'Votre stage progresse bien. Continuez vos efforts quotidiens !'
                                    : 'Commencez à renseigner vos missions et présences.',
                        style: const TextStyle(
                            fontSize: 12.5, color: ColorConstants.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Détails par catégorie ---
          const SizedBox(height: 22),
          const Text('Détails par catégorie',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  label: 'Missions complétées',
                  value: '$missionsCompletees sur $missionsTotales',
                  percent: missionsTotales > 0
                      ? (missionsCompletees / missionsTotales).clamp(0.0, 1.0)
                      : 0.0,
                  color: ColorConstants.primary,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Compétences validées',
                  value: '$competencesValidees validée${competencesValidees > 1 ? 's' : ''}',
                  percent: competencesTotales > 0
                      ? (competencesValidees / competencesTotales).clamp(0.0, 1.0)
                      : 0.0,
                  color: ColorConstants.info,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Jours de présence validés',
                  value: '$joursPresents sur $joursAttendus j',
                  percent: joursAttendus > 0
                      ? (joursPresents / joursAttendus).clamp(0.0, 1.0)
                      : 0.0,
                  color: ColorConstants.success,
                ),
              ],
            ),
          ),

          // --- Jalons & Activités récentes ---
          const SizedBox(height: 22),
          const Text('Jalons & Missions récentes',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 10),
          AppCard(
            child: _entrees.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'Aucune mission enregistrée pour le moment.',
                        style: TextStyle(
                            fontSize: 13, color: ColorConstants.textSecondary),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(_entrees.take(6).length, (index) {
                      final entree = _entrees[index] as Map<String, dynamic>;
                      final titre = entree['titre'] as String? ??
                          entree['commentaire_stagiaire'] as String? ??
                          'Entrée du journal';
                      final type = entree['type'] as String? ?? 'MISSION';
                      final dateDebut = _formatDate(entree['date_debut'] as String?);
                      final bool estTermine = entree['date_fin'] != null;

                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 20),
                          _MilestoneRow(
                            category: type == 'MISSION' ? 'Mission' : 'Difficulté',
                            date: dateDebut,
                            title: titre,
                            done: estTermine,
                          ),
                        ],
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color color;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 13.5, color: ColorConstants.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressRow(percent: percent, color: color),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final String category;
  final String date;
  final String title;
  final bool done;

  const _MilestoneRow({
    required this.category,
    required this.date,
    required this.title,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? ColorConstants.success : ColorConstants.accentOrange;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.pending_outlined,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(category,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  if (date.isNotEmpty)
                    Text(date,
                        style: const TextStyle(
                            fontSize: 11, color: ColorConstants.textSecondary)),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
