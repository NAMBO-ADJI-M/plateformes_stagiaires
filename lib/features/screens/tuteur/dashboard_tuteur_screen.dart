import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';
import 'widgets/add_stagiaire_dialog.dart';
import 'suivi_stagiaire_screen.dart';

/// Version dynamisée du Dashboard Tuteur.
class DashboardTuteurScreen extends StatefulWidget {
  const DashboardTuteurScreen({super.key});

  @override
  State<DashboardTuteurScreen> createState() => _DashboardTuteurScreenState();
}

class _DashboardTuteurScreenState extends State<DashboardTuteurScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  List<dynamic>? _stagiaires;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getEntrepriseDashboardStats(),
        _apiService.getEntrepriseStagiaires(),
        _apiService.getProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _stagiaires = results[1] as List<dynamic>;
        _profile = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des données : $e')),
      );
    }
  }

  void _showEncouragerDialog(Map<String, dynamic> carnet) {
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
                  DropdownMenuItem(
                      value: 'ENCOURAGEMENT', child: Text('Encouragement')),
                  DropdownMenuItem(
                      value: 'FELICITATION', child: Text('Félicitation')),
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
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (contenuCtrl.text.isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _apiService.envoyerEncouragement(
                      carnet['id'], type, contenuCtrl.text);
                  if (!mounted) {
                    return;
                  }
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message envoyé !')));
                } catch (e) {
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : $e')));
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final profileData = _profile?['profile_data'] ?? {};
    final userName =
        '${profileData['prenom'] ?? ''} ${profileData['nom'] ?? ''}'.trim();
    final entrepriseName = profileData['raison_sociale'] ?? 'Mon Entreprise';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          GreetingHeader(
            title: 'Bonjour, ${userName.isEmpty ? 'M. Laurent' : userName} 👋',
            subtitle: '$entrepriseName • Tuteur Principal',
          ),
          const SizedBox(height: 16),
          // Alertes réelles de baisse d'activité
          if (_stats?['alertes'] != null && (_stats!['alertes'] as List).isNotEmpty)
            ...(_stats!['alertes'] as List).map((alerte) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildAlertBox(context, alerte),
                )),
          const SizedBox(height: 14),
          Row(
            children: [
              StatMiniCard(
                  icon: Icons.people_alt_outlined,
                  iconColor: ColorConstants.primary,
                  value: _stats?['stagiaires_actifs']?.toString() ?? '0',
                  label: 'Stagiaires actifs'),
              const SizedBox(width: 10),
              StatMiniCard(
                  icon: Icons.bolt_outlined,
                  iconColor: ColorConstants.accent,
                  value: _stats?['missions_assignees']?.toString() ?? '0',
                  label: 'Missions assignées'),
              const SizedBox(width: 10),
              StatMiniCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: ColorConstants.success,
                  value: '${_stats?['progression_moyenne'] ?? 0}%',
                  label: 'Complétion moy.'),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButtons(context),
          const SizedBox(height: 22),
          const Text('Vos Stagiaires',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 10),
          if (_stagiaires == null || _stagiaires!.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child: Text('Aucun stagiaire rattaché pour le moment.',
                      style: TextStyle(color: ColorConstants.textSecondary))),
            )
          else
            ..._stagiaires!.take(3).map((s) {
              final stagiaire = s['stagiaire'] ?? {};
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: StagiaireTile(
                  name: '${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}',
                  role: s['poste'] ?? 'Stagiaire',
                  progress: 0.5, // À dynamiser via une nouvelle route si besoin
                  status: s['statut'] == 'TERMINE' ? 'Terminé' : 'En cours',
                  statusColor: s['statut'] == 'TERMINE'
                      ? ColorConstants.success
                      : ColorConstants.accentOrange,
                  avatarUrl: 'https://i.pravatar.cc/150?u=${stagiaire['id']}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SuiviStagiaireScreen(carnet: s),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAlertBox(BuildContext context, Map<String, dynamic> alerte) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorConstants.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: ColorConstants.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Baisse d\'activité détectée chez ${alerte['stagiaire_nom']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: ColorConstants.error)),
                const SizedBox(height: 3),
                Text('Dernière activité : ${alerte['derniere_activite']}',
                    style: const TextStyle(
                        fontSize: 12, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final carnet = _stagiaires?.firstWhere(
                (s) => s['id'] == alerte['carnet_id'],
                orElse: () => null,
              );
              if (carnet != null) {
                _showEncouragerDialog(carnet);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.error,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Encourager', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddStagiaireDialog(),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.person_add_alt_outlined, size: 18),
            label: const Text('Ajouter un stagiaire'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.primary,
              backgroundColor: ColorConstants.primary.withValues(alpha: 0.08),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddStagiaireDialog(),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.vpn_key_outlined, size: 18),
            label: const Text('Générer un code'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.textPrimary,
              side: const BorderSide(color: ColorConstants.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Réutilisée sur le dashboard et sur la liste complète des stagiaires.
class StagiaireTile extends StatelessWidget {
  final String name;
  final String role;
  final double progress;
  final String status;
  final Color statusColor;
  final String avatarUrl;
  final VoidCallback? onTap;

  const StagiaireTile({
    super.key,
    required this.name,
    required this.role,
    required this.progress,
    required this.status,
    required this.statusColor,
    required this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: ColorConstants.textPrimary)),
                    StatusPill(label: status, color: statusColor),
                  ],
                ),
                const SizedBox(height: 2),
                Text(role,
                    style: const TextStyle(
                        fontSize: 12, color: ColorConstants.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressRow(
                          percent: progress, color: statusColor),
                    ),
                    const SizedBox(width: 8),
                    Text('${(progress * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
