import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';
import '../../../services/pointage_event_bus.dart';
import 'package:intl/intl.dart';

class PointageScreen extends StatefulWidget {
  const PointageScreen({super.key});

  @override
  State<PointageScreen> createState() => _PointageScreenState();
}

class _PointageScreenState extends State<PointageScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _carnetActif;
  List<dynamic> _historique = [];
  String? _tempsStageAujourdhui;
  StreamSubscription? _pointageSub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pointageSub = PointageEventBus().onPointageUpdate.listen((_) => _loadData(silent: true));

    // Timer pour rafraîchir le temps écoulé en direct
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _tempsStageAujourdhui = _calculerTempsTotal(_historique);
        });
      }
    });
  }

  @override
  void dispose() {
    _pointageSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final carnets = await _api.getCarnets();
      if (carnets.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final carnet = carnets.firstWhere(
        (c) => c['statut'] == 'EN_COURS',
        orElse: () => carnets.first,
      );

      final historique = await _api.getHistoriquePointage(carnet['id']);

      if (mounted) {
        setState(() {
          _carnetActif = carnet;
          _historique = historique;
          _tempsStageAujourdhui = _calculerTempsTotal(historique);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _calculerTempsTotal(List<dynamic> historique) {
    final today = DateTime.now();
    Duration total = Duration.zero;

    for (var entry in historique) {
      final debut = DateTime.tryParse(entry['date_debut'] ?? '');
      final fin = entry['date_fin'] != null ? DateTime.tryParse(entry['date_fin']) : null;

      if (debut != null && debut.year == today.year && debut.month == today.month && debut.day == today.day) {
        final dateFinEffective = fin ?? DateTime.now();
        total += dateFinEffective.difference(debut);
      }
    }

    if (total.inMinutes == 0) return "0 min";
    final h = total.inHours;
    final m = total.inMinutes % 60;
    return h > 0 ? "${h}h${m.toString().padLeft(2, '0')}" : "${m}min";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_carnetActif == null) {
      return const Scaffold(body: Center(child: Text("Aucun carnet de stage actif.")));
    }

    final bool enStage = _historique.isNotEmpty && _historique.first['date_fin'] == null;
    final bool enSortieEnAttente = _historique.isNotEmpty &&
        _historique.first['date_fin'] != null &&
        _historique.first['statut_cloture'] == 'EN_ATTENTE';
    final bool enPauseConfirmee = _historique.isNotEmpty &&
        _historique.first['date_fin'] != null &&
        _historique.first['statut_cloture'] == 'PAUSE_CONFIRMEE';

    final String heureDebut = _historique.isNotEmpty
        ? DateFormat('HH:mm').format(DateTime.parse(_historique.first['date_debut']))
        : '--:--';
    final String heureSortie = _historique.isNotEmpty && _historique.first['date_fin'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(_historique.first['date_fin']))
        : '--:--';

    return Container(
      color: ColorConstants.paper,
      child: Column(
        children: [
          const ScreenTopBar(
            eyebrow: "Aujourd'hui · Lieu de stage",
            title: 'Pointage',
            showProfile: false,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadData(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _StatutGeofencingCard(
                    enStage: enStage,
                    enPause: enPauseConfirmee || enSortieEnAttente,
                    heureDebut: heureDebut,
                    heureSortie: heureSortie,
                    adresse: _carnetActif?['entreprise_nom'] ?? 'Lieu de stage',
                    rayon: (_carnetActif?['geofence_rayon'] ?? 100).toString(),
                  ),
                  if (enSortieEnAttente) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.help_outline_rounded, size: 18, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              Text(
                                "Sortie de zone à $heureSortie",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Précisez votre statut pour mettre à jour votre suivi :",
                            style: TextStyle(fontSize: 12, color: ColorConstants.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.coffee_rounded, size: 16),
                                  label: const Text("Pause"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.brown,
                                    side: BorderSide(color: Colors.brown.shade300),
                                  ),
                                  onPressed: () async {
                                    if (_carnetActif != null) {
                                      await _api.confirmerPause(_carnetActif!['id']);
                                      _loadData(silent: true);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.home_rounded, size: 16),
                                  label: const Text("Fin de journée"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorConstants.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    if (_carnetActif != null) {
                                      await _api.confirmerDepart(_carnetActif!['id']);
                                      _loadData(silent: true);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Historique de la journée',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorConstants.inkSoft)),
                  const SizedBox(height: 8),
                  _HistoriqueCard(historique: _historique),
                  const SizedBox(height: 16),
                  DashedActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Corriger un horaire — validation du tuteur requise',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité de correction bientôt disponible.'))
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text('$_tempsStageAujourdhui cumulés aujourd\'hui',
                        style: const TextStyle(fontSize: 12, color: ColorConstants.inkSoft)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatutGeofencingCard extends StatelessWidget {
  final bool enStage;
  final bool enPause;
  final String heureDebut;
  final String heureSortie;
  final String adresse;
  final String rayon;

  const _StatutGeofencingCard({
    required this.enStage,
    required this.enPause,
    required this.heureDebut,
    required this.heureSortie,
    required this.adresse,
    required this.rayon,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = enStage
        ? ColorConstants.teal
        : (enPause ? Colors.amber.shade700 : ColorConstants.textSecondary.withValues(alpha: 0.1));
    final Color textColor = (enStage || enPause) ? Colors.white : ColorConstants.textPrimary;
    final Color subtextColor = (enStage || enPause) ? Colors.white.withValues(alpha: 0.9) : ColorConstants.textSecondary;

    String tag = 'HORS ZONE';
    IconData tagIcon = Icons.navigation_rounded;
    String title = 'Non détecté';
    String desc = "Le pointage démarrera automatiquement quand vous entrerez dans la zone de l'entreprise.";

    if (enStage) {
      tag = 'GEOFENCING ACTIF';
      tagIcon = Icons.check_circle_rounded;
      title = 'En stage depuis $heureDebut';
      desc = "Détecté automatiquement à l'entrée de la zone — $adresse";
    } else if (enPause) {
      tag = 'PAUSE EN COURS';
      tagIcon = Icons.coffee_rounded;
      title = 'En pause depuis $heureSortie';
      desc = "Le temps reprendra automatiquement dès votre retour dans la zone — $adresse";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tagIcon, size: 14, color: (enStage || enPause) ? Colors.white : ColorConstants.textSecondary),
              const SizedBox(width: 6),
              Text(tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: subtextColor,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.5,
              )),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (enStage || enPause) ? Colors.white.withValues(alpha: 0.15) : ColorConstants.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 6,
                  width: 6,
                  decoration: BoxDecoration(
                    color: (enStage || enPause) ? Colors.white : ColorConstants.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('Rayon : ${rayon}m',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: (enStage || enPause) ? Colors.white : ColorConstants.textSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoriqueCard extends StatelessWidget {
  final List<dynamic> historique;

  const _HistoriqueCard({required this.historique});

  @override
  Widget build(BuildContext context) {
    if (historique.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorConstants.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ColorConstants.line),
        ),
        child: const Text("Aucun pointage aujourd'hui.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: ColorConstants.textSecondary)),
      );
    }

    // On ne garde que les pointages d'aujourd'hui
    final today = DateTime.now();
    final rowsToday = historique.where((e) {
      final d = DateTime.tryParse(e['date_debut'] ?? '');
      return d != null && d.year == today.year && d.month == today.month && d.day == today.day;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Column(
        children: List.generate(rowsToday.length, (i) {
          final r = rowsToday[i];
          final debut = DateTime.parse(r['date_debut']);
          final fin = r['date_fin'] != null ? DateTime.parse(r['date_fin']) : null;
          final statutCloture = r['statut_cloture'];

          String labelDepart = 'Départ détecté';
          IconData iconDepart = Icons.logout_rounded;
          Color colorDepart = ColorConstants.accentOrange;

          if (statutCloture == 'PAUSE_CONFIRMEE') {
            labelDepart = 'Pause enregistrée';
            iconDepart = Icons.coffee_rounded;
            colorDepart = Colors.amber.shade700;
          } else if (statutCloture == 'DEPART_CONFIRME') {
            labelDepart = 'Fin de journée';
            iconDepart = Icons.home_rounded;
            colorDepart = ColorConstants.primary;
          }

          return Column(
            children: [
              _buildRow(
                icon: Icons.check_circle_rounded,
                color: ColorConstants.teal,
                label: i == 0 ? 'Arrivée détectée' : 'Reprise de stage',
                tag: r['source_validation'] ?? 'Automatique',
                time: DateFormat('HH:mm').format(debut),
              ),
              if (fin != null)
                _buildRow(
                  icon: iconDepart,
                  color: colorDepart,
                  label: labelDepart,
                  tag: statutCloture == 'EN_ATTENTE' ? 'En attente de confirmation' : 'Automatique',
                  time: DateFormat('HH:mm').format(fin),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required Color color,
    required String label,
    required String tag,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorConstants.textPrimary)),
                Text(tag, style: const TextStyle(fontSize: 11, color: ColorConstants.inkSoft)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ColorConstants.textPrimary)),
        ],
      ),
    );
  }
}
