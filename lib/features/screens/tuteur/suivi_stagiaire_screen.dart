import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/internship_service.dart';

class SuiviStagiaireScreen extends StatefulWidget {
  final Map<String, dynamic> carnet;
  const SuiviStagiaireScreen({super.key, required this.carnet});

  @override
  State<SuiviStagiaireScreen> createState() => _SuiviStagiaireScreenState();
}

class _SuiviStagiaireScreenState extends State<SuiviStagiaireScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InternshipService _apiService = InternshipService();
  bool _isLoading = true;
  List<dynamic> _presence = [];
  List<dynamic> _encouragements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final carnetId = widget.carnet['id'];
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getHistoriquePointage(carnetId),
        _apiService.getEncouragements(carnetId),
      ]);
      if (mounted) {
        setState(() {
          _presence = results[0];
          _encouragements = results[1];
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
                if (contenuCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _apiService.envoyerEncouragement(widget.carnet['id'], type, contenuCtrl.text);
                  if (!mounted) return;
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message envoyé !')));
                } catch (e) {
                  if (!mounted) return;
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
            Tab(text: 'Présence'),
            Tab(text: 'Encouragements'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPresenceTab(),
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

  Widget _buildPresenceTab() {
    if (_presence.isEmpty) return const Center(child: Text('Aucun pointage enregistré.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _presence.length,
      itemBuilder: (context, index) {
        final entry = _presence[index];
        final debut = DateTime.tryParse(entry['date_debut'] ?? '');
        final fin = entry['date_fin'] != null ? DateTime.tryParse(entry['date_fin']) : null;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorConstants.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.access_time_rounded, color: ColorConstants.teal, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debut != null ? DateFormat('dd MMMM yyyy').format(debut) : 'Date inconnue',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Arrivée : ${debut != null ? DateFormat('HH:mm').format(debut) : '--:--'}',
                        style: const TextStyle(fontSize: 13, color: ColorConstants.textSecondary),
                      ),
                      if (fin != null)
                        Text(
                          'Départ : ${DateFormat('HH:mm').format(fin)}',
                          style: const TextStyle(fontSize: 13, color: ColorConstants.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (fin == null)
                  const StatusPill(label: 'En cours', color: ColorConstants.teal)
                else
                  const Icon(Icons.check_circle_rounded, color: ColorConstants.success, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEncouragementsTab() {
    if (_encouragements.isEmpty) return const Center(child: Text('Aucun encouragement envoyé.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _encouragements.length,
      itemBuilder: (context, index) {
        final enc = _encouragements[index];
        final isFeli = enc['type'] == 'FELICITATION';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isFeli ? ColorConstants.success.withValues(alpha: 0.05) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(isFeli ? Icons.workspace_premium : Icons.favorite, color: isFeli ? ColorConstants.success : ColorConstants.error),
            title: Text(enc['type'] == 'FELICITATION' ? 'Félicitation' : 'Encouragement', style: TextStyle(fontWeight: FontWeight.bold, color: isFeli ? ColorConstants.success : ColorConstants.error)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(enc['contenu'] ?? ''),
                const SizedBox(height: 4),
                Text(enc['date_envoi'] != null && DateTime.tryParse(enc['date_envoi'].toString()) != null 
                    ? DateFormat('dd/MM HH:mm').format(DateTime.tryParse(enc['date_envoi'].toString())!) 
                    : '', 
                    style: const TextStyle(fontSize: 11, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }
}
