import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';

class AttestationsScreen extends StatefulWidget {
  const AttestationsScreen({super.key});

  @override
  State<AttestationsScreen> createState() => _AttestationsScreenState();
}

class _AttestationsScreenState extends State<AttestationsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _stagiaires = [];
  Map<String, dynamic>? _selectedStagiaire;

  final _entrepriseFutureCtrl = TextEditingController();
  final _emailFutureCtrl = TextEditingController();
  final _appreciationCtrl = TextEditingController(text: 'Stagiaire sérieux et motivé.');

  @override
  void initState() {
    super.initState();
    _loadStagiaires();
  }

  Future<void> _loadStagiaires() async {
    try {
      final data = await _api.getEntrepriseStagiaires();
      setState(() {
        _stagiaires = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _genererEtEnvoyer() async {
    if (_selectedStagiaire == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci de sélectionner un stagiaire.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. On récupère les évaluations pour ce carnet
      final evals = await _api.getEvaluations(_selectedStagiaire!['id']);
      if (evals.isEmpty) {
        throw 'Aucune évaluation de compétences trouvée pour ce stagiaire. Veuillez l\'évaluer d\'abord.';
      }

      final evalId = evals.first['id'];

      // 2. Générer l'attestation officielle
      await _api.genererAttestation(evalId);

      // 3. Générer et envoyer la carte d'appui à la future entreprise
      await _api.genererCarteAppui(evalId, {
        'entreprise_destinataire_nom': _entrepriseFutureCtrl.text.trim(),
        'entreprise_destinataire_email': _emailFutureCtrl.text.trim(),
        'recommandation': _appreciationCtrl.text.trim(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Attestation et recommandation envoyées avec succès !'),
          backgroundColor: ColorConstants.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _stagiaires.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: ColorConstants.paper,
      child: Column(
        children: [
          const ScreenTopBar(
            eyebrow: 'Documents',
            title: 'Attestations',
            showProfile: false,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                const Text(
                    'Générez des attestations officielles et envoyez des recommandations aux futures entreprises.',
                    style: TextStyle(
                        fontSize: 13, color: ColorConstants.textSecondary)),
                const SizedBox(height: 20),

                // Sélection du stagiaire
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('1. Sélectionner le stagiaire',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        initialValue: _selectedStagiaire,
                        items: _stagiaires.map((s) {
                          final stagiaire = s['stagiaire'] ?? {};
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: s,
                            child: Text(
                                '${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedStagiaire = val),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: ColorConstants.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Infos Future Entreprise
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2. Coordonnées de la future entreprise',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _LabeledField(
                          label: "Nom de l'entreprise destinataire",
                          controller: _entrepriseFutureCtrl,
                          hint: 'Ex: Orange, Decathlon...'),
                      const SizedBox(height: 12),
                      _LabeledField(
                          label: 'Email du destinataire (RH ou Tuteur)',
                          controller: _emailFutureCtrl,
                          hint: 'Ex: rh@entreprise.com'),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Recommandation
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3. Votre recommandation',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _LabeledField(
                          label: 'Commentaire libre',
                          controller: _appreciationCtrl,
                          maxLines: 4),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                PrimaryButton(
                  label: 'Générer et envoyer le dossier',
                  isLoading: _isLoading,
                  onPressed: _genererEtEnvoyer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  const _LabeledField({required this.label, required this.controller, this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: ColorConstants.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: ColorConstants.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
