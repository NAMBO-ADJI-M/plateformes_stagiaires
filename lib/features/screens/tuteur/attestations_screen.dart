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

  @override
  void initState() {
    super.initState();
    _loadStagiaires();
  }

  Future<void> _loadStagiaires() async {
    try {
      final res = await _api.getEntrepriseStagiaires();
      final Map<String, dynamic> data = res;
      setState(() {
        _stagiaires = data['rattaches'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _genererAttestation() async {
    if (_selectedStagiaire == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci de sélectionner un stagiaire.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final evals = await _api.getEvaluations(_selectedStagiaire!['id']);
      if (evals.isEmpty) {
        throw 'Veuillez d\'abord évaluer les compétences de ce stagiaire pour générer une attestation.';
      }
      final evalId = evals.first['id'];

      await _api.genererAttestation(evalId.toString());

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Attestation officielle générée avec succès !'),
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
    return Container(
      color: ColorConstants.paper,
      child: Column(
        children: [
          const ScreenTopBar(
            eyebrow: 'Documents officiels',
            title: 'Attestations',
            showProfile: false,
          ),
          Expanded(
            child: _isLoading && _stagiaires.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      const Text(
                        'Générez les attestations de fin de stage certifiées par StageLink pour vos stagiaires.',
                        style: TextStyle(fontSize: 13, color: ColorConstants.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stagiaire à certifier', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Map<String, dynamic>>(
                              initialValue: _selectedStagiaire,
                              items: _stagiaires.map((s) {
                                final stagiaire = s['stagiaire'] ?? {};
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: s,
                                  child: Text('${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedStagiaire = val),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: ColorConstants.background,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        'Note : L\'attestation inclura le bilan des compétences validées et l\'assiduité certifiée par GPS.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: ColorConstants.textMuted),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      PrimaryButton(
                        label: 'Générer l\'Attestation PDF',
                        isLoading: _isLoading,
                        onPressed: _genererAttestation,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
