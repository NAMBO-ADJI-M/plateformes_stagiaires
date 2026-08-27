import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/internship_service.dart';

class CarnetDeStageTuteurScreen extends StatefulWidget {
  final Map<String, dynamic> carnet;
  const CarnetDeStageTuteurScreen({super.key, required this.carnet});

  @override
  State<CarnetDeStageTuteurScreen> createState() => _CarnetDeStageTuteurScreenState();
}

class _CarnetDeStageTuteurScreenState extends State<CarnetDeStageTuteurScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InternshipService _apiService = InternshipService();
  bool _isLoading = true;
  List<dynamic> _competences = [];
  bool _isFinalEvalSaving = false;
  bool _stageUtile = true;

  Map<String, String> _evalMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final carnetId = widget.carnet['id'].toString();
      final results = await Future.wait([
        _apiService.getCompetences(),
        _apiService.getEvaluations(carnetId),
      ]);

      if (mounted) {
        final comps = results[0];
        final evals = results[1];

        final Map<String, String> evalMapping = {};
        bool? stageUtileVal;

        for (final eval in evals) {
          if (eval is Map<String, dynamic>) {
            if (eval.containsKey('jugee_utile') && eval['jugee_utile'] != null) {
              stageUtileVal = eval['jugee_utile'] == true || eval['jugee_utile'] == 1;
            }
            final details = eval['details'] ?? eval['competences'] ?? [];
            if (details is List) {
              for (final d in details) {
                if (d is Map<String, dynamic>) {
                  final compId = d['competence_id']?.toString() ?? d['id']?.toString();
                  final level = d['niveau_tuteur']?.toString() ?? d['niveau']?.toString();
                  if (compId != null && level != null) {
                    evalMapping[compId] = level;
                  }
                }
              }
            } else if (eval.containsKey('competence_id')) {
              final compId = eval['competence_id']?.toString();
              final level = eval['niveau_tuteur']?.toString() ?? eval['niveau']?.toString();
              if (compId != null && level != null) {
                evalMapping[compId] = level;
              }
            }
          }
        }

        setState(() {
          _competences = comps;
          _evalMap = evalMapping;
          if (stageUtileVal != null) {
            _stageUtile = stageUtileVal;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement : $e')),
      );
    }
  }

  Future<void> _saveFinalEvaluation() async {
    setState(() => _isFinalEvalSaving = true);
    try {
      final response = await _apiService.evaluerCompetence({
        'carnet_id': widget.carnet['id'],
        'jugee_utile': _stageUtile,
      });

      if (!mounted) return;
      setState(() => _isFinalEvalSaving = false);
      _showRecommandationDialog(response['id'].toString());
    } catch (e) {
      if (mounted) {
        setState(() => _isFinalEvalSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  void _showRecommandationDialog(String evaluationId) {
    final entrepriseCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final messageCtrl = TextEditingController(text: 'Je recommande vivement ce stagiaire pour son sérieux et sa progression.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Générer une Carte d\'Appui'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('L\'évaluation a été enregistrée. Souhaitez-vous envoyer une recommandation officielle à une future entreprise ?'),
              const SizedBox(height: 16),
              TextField(controller: entrepriseCtrl, decoration: const InputDecoration(labelText: 'Nom de l\'entreprise')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email du destinataire')),
              TextField(controller: messageCtrl, decoration: const InputDecoration(labelText: 'Message de recommandation'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Plus tard')),
          ElevatedButton(
            onPressed: () async {
              if (entrepriseCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
              try {
                await _apiService.genererCarteAppui(evaluationId, {
                  'entreprise_destinataire_nom': entrepriseCtrl.text.trim(),
                  'entreprise_destinataire_email': emailCtrl.text.trim(),
                  'recommandation': messageCtrl.text.trim(),
                });
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Carte d\'appui générée et envoyée !'),
                    backgroundColor: ColorConstants.success));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
              }
            },
            child: const Text('Générer et envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stagiaire = widget.carnet['stagiaire'] ?? {};
    final name = '${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}';

    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        title: Text('Carnet de Stage : $name'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorConstants.primary,
          unselectedLabelColor: ColorConstants.textSecondary,
          indicatorColor: ColorConstants.primary,
          tabs: const [
            Tab(text: 'Évaluation'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEvaluationTab(),
                _buildDocumentsTab(),
              ],
            ),
    );
  }

  Widget _buildEvaluationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Évaluer les compétences techniques', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (_competences.isEmpty)
          const Text('Aucune compétence définie dans le référentiel.')
        else
          ..._competences.map((c) {
            final compId = c['id']?.toString() ?? '';
            final initialLevel = _evalMap[compId];
            return _CompetenceEvalCard(
              competence: c,
              carnetId: widget.carnet['id'].toString(),
              initialLevel: initialLevel,
            );
          }),
        const SizedBox(height: 24),
        const Text('Appréciation globale', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Le stage est-il jugé utile pour l\'étudiant ?'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _stageUtile = true),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _stageUtile ? ColorConstants.primary.withValues(alpha: 0.1) : null,
                        side: BorderSide(color: _stageUtile ? ColorConstants.primary : ColorConstants.border),
                      ),
                      child: const Text('Oui'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _stageUtile = false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !_stageUtile ? ColorConstants.error.withValues(alpha: 0.1) : null,
                        side: BorderSide(color: !_stageUtile ? ColorConstants.error : ColorConstants.border),
                      ),
                      child: const Text('Non'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Enregistrer l\'évaluation finale', isLoading: _isFinalEvalSaving, onPressed: _saveFinalEvaluation),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Documents Administratifs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              _documentRow(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Convention de stage',
                subtitle: 'Générée à partir du cadre de liaison',
                onTap: () async {
                  final id = widget.carnet['id']; 
                  final url = _apiService.urlTelechargementConvention(id.toString());
                  if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le document.')));
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _documentRow({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: ColorConstants.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: ColorConstants.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: ColorConstants.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.download_rounded, color: ColorConstants.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CompetenceEvalCard extends StatefulWidget {
  final Map<String, dynamic> competence;
  final String carnetId;
  final String? initialLevel;
  const _CompetenceEvalCard({
    required this.competence,
    required this.carnetId,
    this.initialLevel,
  });

  @override
  State<_CompetenceEvalCard> createState() => _CompetenceEvalCardState();
}

class _CompetenceEvalCardState extends State<_CompetenceEvalCard> {
  String? _selectedLevel;
  final InternshipService _api = InternshipService();
  bool _isSaving = false;

  final Map<String, String> _levels = {
    'NON_ABORDEE': 'Non abordée',
    'DECOUVERTE': 'Découverte',
    'EN_COURS': 'En cours',
    'MAITRISEE': 'Maîtrisée',
  };

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
  }

  @override
  void didUpdateWidget(covariant _CompetenceEvalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLevel != widget.initialLevel && widget.initialLevel != null) {
      _selectedLevel = widget.initialLevel;
    }
  }

  Future<void> _saveEval(String level) async {
    setState(() {
      _selectedLevel = level;
      _isSaving = true;
    });

    try {
      await _api.evaluerCompetence({
        'carnet_id': widget.carnetId,
        'jugee_utile': true,
        'competences': [
          {'competence_id': widget.competence['id'], 'niveau_tuteur': level}
        ]
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Évaluation mise à jour')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.competence['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            if (_isSaving)
              const LinearProgressIndicator()
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _levels.entries.map((e) {
                  final bool isSelected = _selectedLevel == e.key;
                  return ChoiceChip(
                    label: Text(e.value, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                    selected: isSelected,
                    selectedColor: ColorConstants.primary,
                    onSelected: (val) {
                      if (val) _saveEval(e.key);
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
