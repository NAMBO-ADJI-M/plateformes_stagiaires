import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';
import 'add_logbook_entry_screen.dart';
import 'package:intl/intl.dart';

enum _CarnetTab { journal, progression, encouragements, documents }

class CarnetScreen extends StatefulWidget {
  const CarnetScreen({super.key});

  @override
  State<CarnetScreen> createState() => _CarnetScreenState();
}

class _CarnetScreenState extends State<CarnetScreen> {
  _CarnetTab _tab = _CarnetTab.journal;
  final ApiService _api = ApiService();

  bool _isLoading = true;
  Map<String, dynamic>? _carnetActif;
  Map<String, dynamic>? _stats;
  List<dynamic> _entrees = [];
  List<dynamic> _encouragements = [];
  List<dynamic> _attestations = [];

  static const _labels = {
    _CarnetTab.journal: 'Journal',
    _CarnetTab.progression: 'Progression',
    _CarnetTab.encouragements: 'Tuteur',
    _CarnetTab.documents: 'Docs',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
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
      final carnetId = carnet['id'];

      // Chargement séquentiel pour Render
      final stats = await _api.getCarnetStats(carnetId);
      final entrees = await _api.getEntreesJournal(carnetId);
      final encouragements = await _api.getEncouragements(carnetId);
      final attestations = await _api.getMesAttestations();

      if (mounted) {
        setState(() {
          _carnetActif = carnet;
          _stats = stats;
          _entrees = entrees;
          _encouragements = encouragements;
          _attestations = attestations;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouterEntree() async {
    if (_carnetActif == null) return;

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddLogbookEntryScreen(carnetId: _carnetActif!['id']),
      ),
    );

    if (success == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_carnetActif == null) {
      return const Scaffold(body: Center(child: Text("Aucun carnet de stage trouvé.")));
    }

    return Scaffold(
      backgroundColor: ColorConstants.paper,
      body: Column(
        children: [
          ScreenTopBar(
              eyebrow: 'Carnet · ${_carnetActif?['entreprise_nom'] ?? 'Stage'}',
              title: 'Mon stage',
              showProfile: false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _CarnetTab.values.map((t) {
                  final active = t == _tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _tab = t),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? ColorConstants.textPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: active ? ColorConstants.textPrimary : ColorConstants.line),
                        ),
                        child: Text(
                          _labels[t]!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? ColorConstants.paper : ColorConstants.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: _buildContent(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _tab == _CarnetTab.journal || _tab == _CarnetTab.progression
          ? FloatingActionButton(
              onPressed: _ajouterEntree,
              backgroundColor: ColorConstants.clay,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  List<Widget> _buildContent() {
    switch (_tab) {
      case _CarnetTab.journal:
        if (_entrees.isEmpty) {
          return [const Center(child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text("Votre journal est vide.", style: TextStyle(color: ColorConstants.textSecondary)),
          ))];
        }
        return [
          const Text('Rempli automatiquement à partir de vos présences et missions',
              style: TextStyle(fontSize: 12, color: ColorConstants.textSecondary)),
          const SizedBox(height: 12),
          ..._entrees.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _JournalEntry(
              day: _formatDate(e['date_debut']),
              txt: e['titre'] ?? (e['type'] == 'PRESENCE' ? 'Présence détectée' : 'Mission'),
              h: _formatHeure(e['date_debut']),
              type: e['type'],
            ),
          )),
        ];
      case _CarnetTab.progression:
        final double progress = ((_stats?['progression_globale'] ?? 0) as num).toDouble();
        return [
          _ProgressionCard(
            totalMissions: ((_stats?['missions_totales'] ?? 0) as num).toInt(),
            completeMissions: ((_stats?['missions_completees'] ?? 0) as num).toInt(),
            percent: progress / 100,
          ),
          const SizedBox(height: 16),
          const Text('Compétences acquises', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (_entrees.where((e) => e['type'] == 'MISSION').isEmpty)
            const Text("Aucune mission encore validée.", style: TextStyle(fontSize: 13, color: ColorConstants.textSecondary))
          else
            ..._entrees.where((e) => e['type'] == 'MISSION').map((e) => _CompetenceRow(label: e['titre'] ?? 'Mission sans titre')),
        ];
      case _CarnetTab.encouragements:
        if (_encouragements.isEmpty) {
          return [const Center(child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text("Aucun encouragement reçu.", style: TextStyle(color: ColorConstants.textSecondary)),
          ))];
        }
        return _encouragements
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EncouragementCard(txt: e['contenu'], who: _carnetActif?['tuteur_nom'] ?? 'Tuteur'),
                ))
            .toList();
      case _CarnetTab.documents:
        if (_attestations.isEmpty) {
          return [
            const _DocumentRow(name: 'Convention de stage.pdf'),
            const Center(child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text("Aucune attestation disponible pour le moment.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: ColorConstants.textSecondary)),
            ))
          ];
        }
        return [
          const _DocumentRow(name: 'Convention de stage.pdf'),
          ..._attestations.map((a) => _DocumentRow(
            name: a['nom'] ?? 'Attestation sans titre',
            onTap: () {
              final url = _api.urlTelechargementAttestation(a['id'].toString());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Téléchargement : $url'))
              );
            },
          )),
        ];
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '--';
    final d = DateTime.parse(iso);
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return "Aujourd'hui";
    if (d.year == now.year && d.month == now.month && d.day == now.day - 1) return "Hier";
    return DateFormat('dd MMM').format(d);
  }

  String _formatHeure(String? iso) {
    if (iso == null) return '--:--';
    return DateFormat('HH:mm').format(DateTime.parse(iso));
  }
}

class _JournalEntry extends StatelessWidget {
  final String day;
  final String txt;
  final String h;
  final String? type;

  const _JournalEntry({required this.day, required this.txt, required this.h, this.type});

  @override
  Widget build(BuildContext context) {
    final bool isPresence = type == 'PRESENCE';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(day, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isPresence ? ColorConstants.teal : ColorConstants.clay)),
              Text(h, style: const TextStyle(fontSize: 12, color: ColorConstants.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPresence ? Icons.location_on_outlined : Icons.assignment_outlined, size: 14, color: ColorConstants.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text(txt, style: const TextStyle(fontSize: 14, color: ColorConstants.textPrimary, height: 1.4))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressionCard extends StatelessWidget {
  final int totalMissions;
  final int completeMissions;
  final double percent;

  const _ProgressionCard({required this.totalMissions, required this.completeMissions, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 18, color: ColorConstants.teal),
              const SizedBox(width: 8),
              const Text('Missions validées', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: '$completeMissions', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: ColorConstants.textPrimary)),
              TextSpan(text: ' / $totalMissions', style: const TextStyle(fontSize: 16, color: ColorConstants.textSecondary)),
            ]),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: ColorConstants.line,
              valueColor: const AlwaysStoppedAnimation(ColorConstants.teal),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetenceRow extends StatelessWidget {
  final String label;
  const _CompetenceRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: ColorConstants.teal),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: ColorConstants.textPrimary))),
        ],
      ),
    );
  }
}

class _EncouragementCard extends StatelessWidget {
  final String txt;
  final String who;
  const _EncouragementCard({required this.txt, required this.who});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.clay.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorConstants.clay.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: ColorConstants.clay),
              const SizedBox(width: 8),
              const Text('ENCOURAGEMENT',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: ColorConstants.clay)),
            ],
          ),
          const SizedBox(height: 10),
          Text(txt, style: const TextStyle(fontSize: 14, color: ColorConstants.textPrimary, height: 1.4)),
          const SizedBox(height: 12),
          Text('— $who', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: ColorConstants.textSecondary)),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;
  const _DocumentRow({required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: ColorConstants.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorConstants.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 20, color: ColorConstants.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ColorConstants.textPrimary))),
            const Icon(Icons.chevron_right_rounded, size: 20, color: ColorConstants.textSecondary),
          ],
        ),
      ),
    );
  }
}
