import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';
import 'package:intl/intl.dart';

class SuiviStagiaireScreen extends StatefulWidget {
  final Map<String, dynamic> carnet;
  const SuiviStagiaireScreen({super.key, required this.carnet});

  @override
  State<SuiviStagiaireScreen> createState() => _SuiviStagiaireScreenState();
}

class _SuiviStagiaireScreenState extends State<SuiviStagiaireScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _journal = [];
  List<dynamic> _encouragements = [];
  List<dynamic> _competences = [];
  bool _isFinalEvalSaving = false;
  bool _stageUtile = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final carnetId = widget.carnet['id'];
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getEntreesJournal(carnetId),
        _apiService.getEncouragements(carnetId),
        _apiService.getCompetences(),
      ]);
      if (mounted) {
        setState(() {
          _journal = results[0];
          _encouragements = results[1];
          _competences = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
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

      // Succès : proposer la carte d'appui
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
                // Appel API avec les bonnes données
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
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Erreur : $e')));
              }
            },
            child: const Text('Générer et envoyer'),
          ),
        ],
      ),
    );
  }

  void _showEncouragerDialog() {
    final contenuCtrl = TextEditingController();
    String type = 'ENCOURAGEMENT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Envoyer un encouragement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'ENCOURAGEMENT', child: Text('Encouragement')),
                  DropdownMenuItem(value: 'FELICITATION', child: Text('Félicitation')),
                ],
                onChanged: (v) => setDialogState(() => type = v!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contenuCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Votre message',
                  hintText: 'Bravo pour tes efforts...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (contenuCtrl.text.isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _apiService.envoyerEncouragement(widget.carnet['id'], type, contenuCtrl.text);
                  if (!mounted) {
                    return;
                  }
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message envoyé !')));
                } catch (e) {
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                }
              },
              child: const Text('Envoyer'),
            ),
          ],
        ),
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
        title: Text(name),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorConstants.primary,
          unselectedLabelColor: ColorConstants.textSecondary,
          indicatorColor: ColorConstants.primary,
          tabs: const [
            Tab(text: 'Journal'),
            Tab(text: 'Évaluation'),
            Tab(text: 'Encouragements'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJournalTab(),
                _buildEvaluationTab(),
                _buildEncouragementsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEncouragerDialog,
        backgroundColor: ColorConstants.primary,
        icon: const Icon(Icons.favorite_border),
        label: const Text('Encourager'),
      ),
    );
  }

  Widget _buildEvaluationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Évaluer les compétences techniques',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (_competences.isEmpty)
          const Text('Aucune compétence définie dans le référentiel.')
        else
          ..._competences.map((c) => _CompetenceEvalCard(competence: c, carnetId: widget.carnet['id'])),
        const SizedBox(height: 24),
        const Text(
          'Appréciation globale',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
                        backgroundColor: _stageUtile ? ColorConstants.primary.withOpacity(0.1) : null,
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
                        backgroundColor: !_stageUtile ? ColorConstants.error.withOpacity(0.1) : null,
                        side: BorderSide(color: !_stageUtile ? ColorConstants.error : ColorConstants.border),
                      ),
                      child: const Text('Non'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Enregistrer l\'évaluation finale',
                isLoading: _isFinalEvalSaving,
                onPressed: _saveFinalEvaluation,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJournalTab() {
    if (_journal.isEmpty) {
      return const Center(child: Text('Aucune entrée dans le journal.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _journal.length,
      itemBuilder: (context, index) {
        final entry = _journal[index];
        final bool isMission = entry['type'] == 'MISSION';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isMission ? Icons.assignment_outlined : Icons.warning_amber_rounded,
                      color: isMission ? ColorConstants.primary : ColorConstants.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isMission ? 'Mission' : 'Difficulté',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMission ? ColorConstants.primary : ColorConstants.error,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry['date_debut'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(entry['date_debut'])) : '',
                      style: const TextStyle(fontSize: 12, color: ColorConstants.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry['titre'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  entry['commentaire_stagiaire'] ?? 'Pas de commentaire.',
                  style: const TextStyle(fontSize: 14, color: ColorConstants.textPrimary),
                ),
                if (entry['commentaire_tuteur'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConstants.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ColorConstants.primary.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Votre commentaire :',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.primary)),
                        const SizedBox(height: 4),
                        Text(entry['commentaire_tuteur'],
                            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _showCommentaireDialog(entry['id']),
                  icon: const Icon(Icons.comment_outlined, size: 16),
                  label: Text(entry['commentaire_tuteur'] == null ? 'Commenter' : 'Modifier le commentaire'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: ColorConstants.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommentaireDialog(String entreeId) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Commenter cette mission'),
        content: TextField(
          controller: commentCtrl,
          decoration: const InputDecoration(
            labelText: 'Votre retour pédagogique',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (commentCtrl.text.isEmpty) return;
              try {
                await _apiService.commenterEntree(entreeId, commentCtrl.text);
                if (!mounted) {
                  return;
                }
                Navigator.pop(ctx);
                _loadData();
              } catch (e) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEncouragementsTab() {
    if (_encouragements.isEmpty) {
      return const Center(child: Text('Aucun encouragement envoyé.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _encouragements.length,
      itemBuilder: (context, index) {
        final enc = _encouragements[index];
        final isFeli = enc['type'] == 'FELICITATION';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isFeli ? ColorConstants.success.withOpacity(0.05) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(
              isFeli ? Icons.workspace_premium : Icons.favorite,
              color: isFeli ? ColorConstants.success : ColorConstants.error,
            ),
            title: Text(
              enc['type'] == 'FELICITATION' ? 'Félicitation' : 'Encouragement',
              style: TextStyle(fontWeight: FontWeight.bold, color: isFeli ? ColorConstants.success : ColorConstants.error),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(enc['contenu'] ?? ''),
                const SizedBox(height: 4),
                Text(
                  enc['date_envoi'] != null ? DateFormat('dd/MM HH:mm').format(DateTime.parse(enc['date_envoi'])) : '',
                  style: const TextStyle(fontSize: 11, color: ColorConstants.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompetenceEvalCard extends StatefulWidget {
  final Map<String, dynamic> competence;
  final String carnetId;
  const _CompetenceEvalCard({required this.competence, required this.carnetId});

  @override
  State<_CompetenceEvalCard> createState() => _CompetenceEvalCardState();
}

class _CompetenceEvalCardState extends State<_CompetenceEvalCard> {
  String? _selectedLevel;
  final ApiService _api = ApiService();
  bool _isSaving = false;

  final Map<String, String> _levels = {
    'NON_ABORDEE': 'Non abordée',
    'DECOUVERTE': 'Découverte',
    'EN_COURS': 'En cours',
    'MAITRISEE': 'Maîtrisée',
  };

  Future<void> _saveEval(String level) async {
    setState(() {
      _selectedLevel = level;
      _isSaving = true;
    });

    try {
      await _api.evaluerCompetence({
        'carnet_id': widget.carnetId,
        'jugee_utile': true, // Par défaut à true ici
        'competences': [
          {
            'competence_id': widget.competence['id'],
            'niveau_tuteur': level,
          }
        ]
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Évaluation mise à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
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
            Text(
              widget.competence['nom'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
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
