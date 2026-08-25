import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import 'dashboard_tuteur_screen.dart';
import '../../../services/api_service.dart';
import '../../../services/stagiaire_event_bus.dart';
import 'widgets/add_stagiaire_dialog.dart';
import 'suivi_stagiaire_screen.dart';

/// Version dynamisée de la liste des stagiaires pour l'entreprise.
class ListeStagiairesScreen extends StatefulWidget {
  const ListeStagiairesScreen({super.key});

  @override
  State<ListeStagiairesScreen> createState() => _ListeStagiairesScreenState();
}

class _ListeStagiairesScreenState extends State<ListeStagiairesScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  int _tab = 0; // 0 Tous, 1 Actifs, 2 Terminés
  List<dynamic> _allStagiaires = [];
  List<dynamic> _filteredStagiaires = [];
  List<dynamic> _disponibles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getEntrepriseStagiaires();
      if (!mounted) return;
      
      final Map<String, dynamic> data = res;
      
      setState(() {
        _allStagiaires = data['rattaches'] ?? [];
        _disponibles = data['disponibles'] ?? [];
        _isLoading = false;
        _applyFilters();
        
        // Notification du nombre de stagiaires disponibles pour le badge
        StagiaireEventBus().updateAvailableCount(_disponibles.length);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement : $e')),
      );
    }
  }

  Future<void> _demanderAcces(Map<String, dynamic> item) async {
    final stagiaire = item['stagiaire'] ?? {};
    
    // Ouvre directement le formulaire de convention pré-rempli
    showDialog(
      context: context,
      builder: (_) => AddStagiaireDialog(
        initialNom: stagiaire['nom'],
        initialPrenom: stagiaire['prenom'],
        initialEmail: stagiaire['email'],
      ),
    ).then((success) {
      if (success == true) _loadData();
    });
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredStagiaires = _allStagiaires.where((item) {
        final stagiaire = item['stagiaire'] ?? {};
        final fullName =
            '${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}'
                .toLowerCase();
        final matchesSearch = fullName.contains(query);

        if (_tab == 0) return matchesSearch;
        if (_tab == 1) return matchesSearch && item['statut'] == 'EN_COURS';
        if (_tab == 2) return matchesSearch && item['statut'] == 'TERMINE';
        return matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorConstants.paper,
      child: Column(
        children: [
          ScreenTopBar(
            eyebrow: 'Gestion',
            title: 'Stagiaires',
            showProfile: false,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _isLoading
                  ? _buildSkeletonList()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 14),
                        _buildTabs(),
                        const SizedBox(height: 16),
                        
                        // SECTION DECOUVERTE (Nouveaux stagiaires sans entreprise)
                        if (_disponibles.isNotEmpty && _tab == 0) ...[
                          const Text('Stagiaires disponibles',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: ColorConstants.primary)),
                          const SizedBox(height: 12),
                          ..._disponibles.map((item) {
                            final stagiaire = item['stagiaire'] ?? {};
                            final String email = stagiaire['email'] ?? 'Sans email';
                            final String displayName = '${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}';
                            final String school = stagiaire['ecole'] ?? '';
                            final String field = stagiaire['filiere'] ?? '';
                            final String roleText = (school.isNotEmpty && field.isNotEmpty)
                                ? '$school - $field'
                                : email; // <- remplace 'Inscrit sur StageLink'

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Stack(
                                children: [
                                  StagiaireTile(
                                    name: displayName,
                                    role: roleText,
                                    roleFontSize: 11, // <- police réduite pour cette carte
                                    progress: 0.0,
                                    status: 'Disponible',
                                    statusColor: ColorConstants.primary,
                                    avatarUrl: stagiaire['photo_profil_url'] ?? 'https://i.pravatar.cc/150?u=$email',
                                    autoStatut: 'DISPONIBLE',
                                    onDemanderSuivi: () => _demanderAcces(item),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () => _showCompteInfoDialog(stagiaire),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
                                          ],
                                        ),
                                        child: const Icon(Icons.info_outline, size: 14, color: ColorConstants.textSecondary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                        ],

                        const Text('Mes Stagiaires',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: ColorConstants.textPrimary)),
                        const SizedBox(height: 12),
                        
                        if (_filteredStagiaires.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Aucun stagiaire trouvé',
                              subtitle: 'Faites défiler pour voir les nouveaux inscrits.',
                            ),
                          )
                        else
                          ..._filteredStagiaires.map((item) {
                            final stagiaire = item['stagiaire'] ?? {};
                            final autoStatut = item['autorisation_pointage_statut'] ?? 'INACTIVE';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: StagiaireTile(
                                name:
                                    '${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}',
                                role: '${item['poste'] ?? 'Stagiaire'}',
                                progress: ((item['presence_progress'] ?? 0) as num).toDouble(),
                                status: item['statut'] == 'TERMINE'
                                    ? 'Terminé'
                                    : 'En cours',
                                statusColor: item['statut'] == 'TERMINE'
                                    ? ColorConstants.success
                                    : ColorConstants.accentOrange,
                                avatarUrl:
                                    'https://i.pravatar.cc/150?u=${stagiaire['id']}',
                                autoStatut: autoStatut,
                                onDemanderSuivi: () => _demanderAcces(item),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SuiviStagiaireScreen(carnet: item),
                                  ),
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
                        const Text('Historique',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: ColorConstants.textPrimary)),
                        const SizedBox(height: 12),
                        _buildHistoryPlaceholder(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const AppCard(
        child: Row(
          children: [
            Skeleton(height: 44, width: 44, borderRadius: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(height: 16, width: 120),
                  SizedBox(height: 6),
                  Skeleton(height: 12, width: 180),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorConstants.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: ColorConstants.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Rechercher un stagiaire...',
                hintStyle: TextStyle(
                    fontSize: 13.5, color: ColorConstants.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _TabChip(
            label: 'Tous',
            selected: _tab == 0,
            onTap: () {
              setState(() => _tab = 0);
              _applyFilters();
            }),
        const SizedBox(width: 8),
        _TabChip(
            label: 'Actifs',
            selected: _tab == 1,
            onTap: () {
              setState(() => _tab = 1);
              _applyFilters();
            }),
        const SizedBox(width: 8),
        _TabChip(
            label: 'Terminés',
            selected: _tab == 2,
            onTap: () {
              setState(() => _tab = 2);
              _applyFilters();
            }),
      ],
    );
  }

  Widget _buildHistoryPlaceholder() {
    return AppCard(
      onTap: () {},
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: ColorConstants.border,
            child: Icon(Icons.person_outline, color: ColorConstants.textSecondary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Historique archivé',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: ColorConstants.textPrimary)),
                Text('Consultez les dossiers clôturés.',
                    style: TextStyle(
                        fontSize: 12, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: ColorConstants.textSecondary, size: 18),
        ],
      ),
    );
  }

  void _showCompteInfoDialog(Map<String, dynamic> stagiaire) {
    final createdAt = stagiaire['created_at'] as String?;
    String dateStr = 'Non disponible';
    String heureStr = '';
    if (createdAt != null) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        heureStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Informations du compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email : ${stagiaire['email'] ?? 'Non renseigné'}'),
            const SizedBox(height: 8),
            Text('Créé le : $dateStr${heureStr.isNotEmpty ? ' à $heureStr' : ''}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color:
              selected ? ColorConstants.primary : ColorConstants.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? ColorConstants.primary : ColorConstants.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : ColorConstants.textSecondary)),
      ),
    );
  }
}
