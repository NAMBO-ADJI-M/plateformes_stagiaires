import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../services/pointage_event_bus.dart';
import 'trajet_details_screen.dart';

/// Écran d'accueil — direction "poste de contrôle" (maquette v2 dynamisée).
class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToPointage;
  final VoidCallback onNavigateToCarnet;
  final VoidCallback onNavigateToTrajet;

  const HomeScreen({
    super.key,
    required this.onNavigateToPointage,
    required this.onNavigateToCarnet,
    required this.onNavigateToTrajet,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String _prenom = 'Stagiaire';
  Map<String, dynamic>? _stats;
  List<dynamic> _activites = [];
  String _presenceDuree = "0h00";
  String _heureArrivee = "--:--";
  bool _enStage = false;
  StreamSubscription? _pointageSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _loadDashboardData();
    _pointageSub = PointageEventBus().onPointageUpdate.listen((_) => _loadDashboardData(silent: true));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pointageSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final profile = await _api.getProfile();
      final carnets = await _api.getCarnets();

      if (mounted) {
        setState(() {
          _prenom = profile['profile_data']?['prenom'] ?? 'Stagiaire';
        });
      }

      if (carnets.isNotEmpty) {
        final carnet = carnets.firstWhere((c) => c['statut'] == 'EN_COURS', orElse: () => carnets.first);
        final carnetId = carnet['id'];

        final results = await Future.wait([
          _api.getCarnetStats(carnetId),
          _api.getHistoriquePointage(carnetId),
          _api.getMesReservations(),
        ]);

        if (mounted) {
          setState(() {
            _stats = results[0] as Map<String, dynamic>;
            _computePresence(results[1] as List<dynamic>);

            final reservations = results[2] as List<dynamic>;
            final aVenir = reservations.where((r) => r['statut'] != 'ANNULEE' && r['statut'] != 'TERMINEE').toList();
            _prochaineReservation = aVenir.isNotEmpty ? aVenir.first : null;

            _activites = _stats?['activites_recentes'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _prochaineReservation;

  void _computePresence(List<dynamic> historique) {
    final today = DateTime.now();
    final entriesToday = historique.where((e) {
      final d = DateTime.tryParse(e['date_debut'] ?? '');
      return d != null && d.year == today.year && d.month == today.month && d.day == today.day;
    }).toList();

    if (entriesToday.isEmpty) {
      _enStage = false;
      _presenceDuree = "0h00";
      _heureArrivee = "--:--";
      return;
    }

    final latest = entriesToday.first;
    _enStage = latest['date_fin'] == null;
    _heureArrivee = DateFormat('HH:mm').format(DateTime.parse(latest['date_debut']));

    Duration total = Duration.zero;
    for (var entry in entriesToday) {
      final start = DateTime.parse(entry['date_debut']);
      final end = entry['date_fin'] != null ? DateTime.parse(entry['date_fin']) : DateTime.now();
      total += end.difference(start);
    }
    _presenceDuree = "${total.inHours}h${(total.inMinutes % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: ColorConstants.paper, body: Center(child: CircularProgressIndicator(color: ColorConstants.primary)));

    return Scaffold(
      backgroundColor: ColorConstants.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: ColorConstants.primary,
          backgroundColor: ColorConstants.cardBackground,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              _buildHeader(),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: widget.onNavigateToPointage,
                child: _PointageCard(
                  pulseController: _pulseController,
                  enStage: _enStage,
                  duree: _presenceDuree,
                  arrivee: _heureArrivee
                ),
              ),
              const SizedBox(height: 14),
              _CarnetCard(
                stats: _stats,
                onAdd: widget.onNavigateToCarnet
              ),
              const SizedBox(height: 14),
              _CovoiturageCard(
                reservation: _prochaineReservation,
                onTap: () {
                  if (_prochaineReservation != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TrajetDetailsScreen(trajet: _prochaineReservation!['trajet'])));
                  } else {
                    widget.onNavigateToTrajet();
                  }
                }
              ),
              const SizedBox(height: 10),
              _sectionLabel('Activité récente'),
              const SizedBox(height: 4),
              if (_activites.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("Aucune activité récente", style: TextStyle(color: ColorConstants.textSecondary, fontSize: 12))),
                )
              else
                ..._activites.take(3).map((a) => _ActivityItem(
                  icon: _getActivityIcon(a['type']),
                  iconBg: _getActivityColor(a['type']).withValues(alpha: 0.14),
                  iconColor: _getActivityColor(a['type']),
                  title: a['title'] ?? '',
                  time: _formatActivityDate(a['date']),
                  showDivider: _activites.indexOf(a) != 2,
                )),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String? type) {
    switch(type) {
      case 'presence': return Icons.check_circle;
      case 'mission': return Icons.menu_book_rounded;
      case 'trajet': return Icons.directions_car_filled_rounded;
      default: return Icons.notifications;
    }
  }

  Color _getActivityColor(String? type) {
    switch(type) {
      case 'presence': return ColorConstants.teal;
      case 'mission': return ColorConstants.clay;
      case 'trajet': return ColorConstants.amber;
      default: return ColorConstants.primary;
    }
  }
  }

  String _formatActivityDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return DateFormat('dd/MM, HH:mm').format(d);
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SESSION ACTIVE · ${_enStage ? "EN STAGE" : "PAUSE"}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w500,
                color: ColorConstants.teal,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Bonjour, $_prenom',
              style: GoogleFonts.sora(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: ColorConstants.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ColorConstants.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstants.line),
          ),
          alignment: Alignment.center,
          child: Text(
            _prenom.isNotEmpty ? _prenom[0].toUpperCase() : 'S',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ColorConstants.teal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          letterSpacing: 1.2,
          color: ColorConstants.textSecondary,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.line),
      ),
      child: child,
    );
  }
}

class _PointageCard extends StatelessWidget {
  final AnimationController pulseController;
  final bool enStage;
  final String duree;
  final String arrivee;

  const _PointageCard({
    required this.pulseController,
    required this.enStage,
    required this.duree,
    required this.arrivee,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _eyebrow('POINTAGE AUTOMATIQUE'),
              Row(
                children: [
                  if (enStage) _PulseDot(controller: pulseController),
                  const SizedBox(width: 6),
                  Text(
                    enStage ? 'EN STAGE' : 'HORS ZONE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: enStage ? const Color(0xFF5EEAD4) : const Color(0xFF7E93A3),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _RadarWidget(controller: pulseController, active: enStage),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Présence aujourd\'hui',
                    style: TextStyle(fontSize: 13, color: ColorConstants.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    duree,
                    style: GoogleFonts.sora(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: ColorConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'ARRIVÉE', value: arrivee)),
              const SizedBox(width: 10),
              const Expanded(child: _MiniStat(label: 'ZONE', value: 'Détectée')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  final AnimationController controller;
  const _PulseDot({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (1 - t).clamp(0.0, 1.0) * 0.5,
              child: Transform.scale(
                scale: 1 + t * 1.8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: Color(0xFF5EEAD4), shape: BoxShape.circle),
                ),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: Color(0xFF5EEAD4), shape: BoxShape.circle),
            ),
          ],
        );
      },
    );
  }
}

class _RadarWidget extends StatelessWidget {
  final AnimationController controller;
  final bool active;
  const _RadarWidget({required this.controller, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF5EEAD4) : const Color(0xFF7E93A3);
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(78, 0.15, color),
          _ring(54, 0.25, color),
          _ring(30, 0.4, color),
          if (active)
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35 + 0.25 * controller.value),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withValues(alpha: 0.5), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _ring(double size, double opacity, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: opacity)),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ColorConstants.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 10, letterSpacing: 0.5, color: ColorConstants.textSecondary)),
          const SizedBox(height: 3),
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 16, color: ColorConstants.textPrimary)),
        ],
      ),
    );
  }
}

class _CarnetCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final VoidCallback onAdd;

  const _CarnetCard({this.stats, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final double progress = ((stats?['progression_globale'] ?? 0) as num).toDouble();
    final int jours = ((stats?['jours_presents'] ?? 0) as num).toInt();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('CARNET DE STAGE'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const CircularProgressIndicator(value: 1, strokeWidth: 6, color: Color(0x2494B2C7)),
                    CircularProgressIndicator(
                      value: progress / 100,
                      strokeWidth: 6,
                      color: const Color(0xFFFDBA74),
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _miniStat('Progression globale', '${progress.round()}%'),
                    _miniStat('Jours de présence', '$jours'),
                    _miniStat('Missions complétées', '${stats?['missions_completees'] ?? 0}', showDivider: false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5EEAD4),
                foregroundColor: const Color(0xFF08151A),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('+ Ouvrir le carnet', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, {bool showDivider = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: ColorConstants.line)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: ColorConstants.textSecondary)),
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: ColorConstants.textPrimary)),
        ],
      ),
    );
  }
}

class _CovoiturageCard extends StatelessWidget {
  final Map<String, dynamic>? reservation;
  final VoidCallback onTap;

  const _CovoiturageCard({this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final trajet = reservation?['trajet'] as Map<String, dynamic>?;
    final String destination = trajet?['lieu_arrivee'] ?? 'Covoiturage';
    final String heure = trajet?['date_depart'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(trajet!['date_depart']))
        : '--:--';

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _eyebrow('COVOITURAGE'),
              if (reservation != null)
                const Icon(Icons.verified_rounded, color: Color(0xFFFDBA74), size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ColorConstants.line),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(heure, style: GoogleFonts.jetBrainsMono(fontSize: 17, fontWeight: FontWeight.w600, color: ColorConstants.amber)),
                    const Text('DÉPART', style: TextStyle(fontSize: 10, color: ColorConstants.textSecondary)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(width: 1, height: 32, color: ColorConstants.line),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(destination, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ColorConstants.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(reservation != null ? 'Trajet réservé' : 'Aucun trajet prévu', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: ColorConstants.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.textPrimary,
                side: const BorderSide(color: ColorConstants.line),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(reservation != null ? 'Voir le trajet' : 'Trouver un trajet', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String time;
  final bool showDivider;

  const _ActivityItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.time,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: ColorConstants.line)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: ColorConstants.textPrimary)),
                const SizedBox(height: 1),
                Text(time, style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _eyebrow(String text) {
  return Text(
    text,
    style: GoogleFonts.jetBrainsMono(
      fontSize: 10,
      letterSpacing: 1.1,
      color: const Color(0xFF7E93A3),
    ),
  );
}
