import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';

class RecommanderScreen extends StatefulWidget {
  const RecommanderScreen({super.key});

  @override
  State<RecommanderScreen> createState() => _RecommanderScreenState();
}

class _RecommanderScreenState extends State<RecommanderScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _stagiaires = [];
  Map<String, dynamic>? _selectedStagiaire;

  final _entrepriseFutureCtrl = TextEditingController();
  final _emailFutureCtrl = TextEditingController();
  final _appreciationCtrl = TextEditingController(
      text: 'Je recommande vivement ce stagiaire pour son professionnalisme et sa capacité d\'apprentissage.');

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

  Future<void> _envoyerRecommandation() async {
    if (_selectedStagiaire == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci de sélectionner un stagiaire.')));
      return;
    }

    if (_entrepriseFutureCtrl.text.isEmpty || _emailFutureCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci de remplir les coordonnées du destinataire.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Récupérer l'évaluation
      final evals = await _api.getEvaluations(_selectedStagiaire!['id']);
      if (evals.isEmpty) {
        throw 'Ce stagiaire doit d\'abord être évalué (onglet Évaluation du suivi) pour générer une carte d\'appui.';
      }
      final evalId = evals.first['id'];

      // 2. Générer et envoyer
      await _api.genererCarteAppui(evalId.toString(), {
        'entreprise_destinataire_nom': _entrepriseFutureCtrl.text.trim(),
        'entreprise_destinataire_email': _emailFutureCtrl.text.trim(),
        'recommandation': _appreciationCtrl.text.trim(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Carte d\'appui envoyée avec succès !'),
          backgroundColor: ColorConstants.success,
        ));
        
        // Reset form
        _entrepriseFutureCtrl.clear();
        _emailFutureCtrl.clear();
        setState(() => _selectedStagiaire = null);
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
            eyebrow: 'Appui Carrière',
            title: 'Recommander',
            showProfile: false,
          ),
          Expanded(
            child: _isLoading && _stagiaires.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      const Text(
                        'Aidez vos meilleurs stagiaires à trouver leur prochain poste en envoyant une carte d\'appui officielle.',
                        style: TextStyle(fontSize: 13, color: ColorConstants.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      
                      // Étape 1 : Choix du stagiaire
                      _sectionTitle('1. Choisir le stagiaire'),
                      AppCard(
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          initialValue: _selectedStagiaire,
                          items: _stagiaires.map((s) {
                            final stagiaire = s['stagiaire'] ?? {};
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: s,
                              child: Text('${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}'),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedStagiaire = val),
                          decoration: const InputDecoration(
                            hintText: 'Sélectionner...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Étape 2 : Destinataire
                      _sectionTitle('2. Entreprise destinataire'),
                      AppCard(
                        child: Column(
                          children: [
                            _buildField('Nom de l\'entreprise', _entrepriseFutureCtrl, Icons.business_outlined),
                            const Divider(height: 24),
                            _buildField('Email (RH ou Tuteur)', _emailFutureCtrl, Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Étape 3 : Message
                      _sectionTitle('3. Votre recommandation'),
                      AppCard(
                        child: TextField(
                          controller: _appreciationCtrl,
                          maxLines: 5,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                          decoration: const InputDecoration(
                            hintText: 'Décrivez les points forts du stagiaire...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      PrimaryButton(
                        label: 'Envoyer la carte d\'appui',
                        isLoading: _isLoading,
                        onPressed: _envoyerRecommandation,
                      ),
                      
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Le stagiaire recevra une copie de cette recommandation.',
                          style: TextStyle(fontSize: 11, color: ColorConstants.textMuted),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: ColorConstants.textSecondary)),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: ColorConstants.textSecondary),
        prefixIcon: Icon(icon, size: 18),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
