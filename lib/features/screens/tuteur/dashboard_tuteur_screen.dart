import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';
import '../../../services/profile_event_bus.dart';
import 'widgets/liaison_stagiaire_dialog.dart';
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

  StreamSubscription? _profileSub;

  @override
  void initState() {
    super.initState();
    _loadData();

    // ✅ Écouter les mises à jour du profil pour rafraîchir l'en-tête
    _profileSub = ProfileEventBus().onProfileUpdate.listen((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
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
        _stats = results[0];
        
        // On récupère uniquement les stagiaires déjà rattachés pour le dashboard
        final stagiairesRes = results[1];
        _stagiaires = (stagiairesRes['rattaches'] as List<dynamic>);
        
        _profile = results[2];
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

  Future<void> _demanderSuivi(Map<String, dynamic> stagiaireData) async {
    final stagiaire = stagiaireData['stagiaire'] ?? {};
    final String name = '${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}';
    
    showDialog(
      context: context,
      builder: (_) => LiaisonStagiaireDialog(
        stagiaireId: stagiaire['id'],
        stagiaireNom: name,
      ),
    ).then((success) {
      if (success == true) _loadData();
    });
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

    return Container(
      color: ColorConstants.paper,
      child: Column(
        children: [
          ScreenTopBar(
            eyebrow: entrepriseName,
            title: userName.isEmpty ? 'Espace Tuteur' : 'Bonjour, $userName',
            showProfile: false,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
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
                          icon: Icons.trending_up_rounded,
                          iconColor: ColorConstants.success,
                          value: '${_stats?['progression_moyenne'] ?? 0}%',
                          label: 'Assiduité moyenne'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Vos Stagiaires',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: ColorConstants.textPrimary)),
                  const SizedBox(height: 12),
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
                      final autoStatut = s['autorisation_pointage_statut'] ?? 'INACTIVE';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StagiaireTile(
                          name: '${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}',
                          role: s['poste'] ?? 'Stagiaire',
                          progress: ((s['presence_progress'] ?? 0) as num).toDouble(),
                          status: s['statut'] == 'TERMINE' ? 'Terminé' : 'En cours',
                          statusColor: s['statut'] == 'TERMINE'
                              ? ColorConstants.success
                              : ColorConstants.accentOrange,
                          avatarUrl: 'https://i.pravatar.cc/150?u=${stagiaire['id']}',
                          autoStatut: autoStatut,
                          onDemanderSuivi: () => _demanderSuivi(s),
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
            ),
          ),
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
}

/// Réutilisée sur le dashboard et sur la liste complète des stagiaires.
class StagiaireTile extends StatelessWidget {
  final String name;
  final String role;
  final double progress;
  final String status;
  final Color statusColor;
  final String avatarUrl;
  final String autoStatut; // ACTIVE | INACTIVE | EN_ATTENTE | REFUSEE
  final VoidCallback? onTap;
  final VoidCallback? onDemanderSuivi;

  const StagiaireTile({
    super.key,
    required this.name,
    required this.role,
    required this.progress,
    required this.status,
    required this.statusColor,
    required this.avatarUrl,
    this.autoStatut = 'INACTIVE',
    this.onTap,
    this.onDemanderSuivi,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
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
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: ColorConstants.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusPill(label: status, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(role,
                        style: const TextStyle(
                            fontSize: 12, color: ColorConstants.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          autoStatut == 'ACTIVE' ? Icons.visibility : Icons.visibility_off,
                          size: 12,
                          color: autoStatut == 'ACTIVE' ? ColorConstants.success : ColorConstants.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          autoStatut == 'ACTIVE' ? 'Suivi actif' : 'Suivi privé',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: autoStatut == 'ACTIVE' ? ColorConstants.success : ColorConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressRow(percent: progress, color: statusColor),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (autoStatut == 'INACTIVE' || autoStatut == 'REFUSEE')
                TextButton(
                  onPressed: onDemanderSuivi,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: ColorConstants.primary.withValues(alpha: 0.08),
                  ),
                  child: const Text('Demander l\'accès', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                )
              else if (autoStatut == 'EN_ATTENTE')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: const Text('En attente...', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                )
              else
                Text('${(progress * 100).round()}%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
