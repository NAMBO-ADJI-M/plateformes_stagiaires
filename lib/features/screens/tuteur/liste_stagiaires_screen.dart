import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import 'dashboard_tuteur_screen.dart';
import '../../../services/api_service.dart';
import 'widgets/liaison_stagiaire_dialog.dart';
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
      final data = await _apiService.getEntrepriseStagiaires();
      if (!mounted) return;
      setState(() {
        _allStagiaires = data;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement : $e')),
      );
    }
  }

  Future<void> _demanderSuivi(Map<String, dynamic> item) async {
    final stagiaire = item['stagiaire'] ?? {};
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
                        if (_filteredStagiaires.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Aucun stagiaire trouvé',
                              subtitle: 'Essayez de modifier vos critères de recherche.',
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
                                progress: 0.5,
                                status: item['statut'] == 'TERMINE'
                                    ? 'Terminé'
                                    : 'En cours',
                                statusColor: item['statut'] == 'TERMINE'
                                    ? ColorConstants.success
                                    : ColorConstants.accentOrange,
                                avatarUrl:
                                    'https://i.pravatar.cc/150?u=${stagiaire['id']}',
                                autoStatut: autoStatut,
                                onDemanderSuivi: () => _demanderSuivi(item),
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
