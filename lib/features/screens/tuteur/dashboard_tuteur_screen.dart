import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/internship_service.dart';
import 'liste_stagiaires_screen.dart';
import 'widgets/add_stagiaire_dialog.dart';
import 'suivi_stagiaire_screen.dart';

class DashboardTuteurScreen extends StatefulWidget {
  const DashboardTuteurScreen({super.key});

  @override
  State<DashboardTuteurScreen> createState() => _DashboardTuteurScreenState();
}

class _DashboardTuteurScreenState extends State<DashboardTuteurScreen> {
  final InternshipService _api = InternshipService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _demandes = [];
  List<dynamic> _stagiaires = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getEntrepriseDashboardStats(),
        _api.getDemandesRattachement(),
        _api.getEntrepriseStagiaires(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _demandes = results[1] as List<dynamic>;
          final stagiairesData = results[2] as Map<String, dynamic>;
          _stagiaires = stagiairesData['rattaches'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    if (_demandes.isNotEmpty) ...[
                      _buildSectionTitle("Demandes de rattachement", 
                          count: _demandes.length, color: ColorConstants.warning),
                      const SizedBox(height: 16),
                      _buildDemandesList(),
                      const SizedBox(height: 32),
                    ],
                    _buildSectionTitle(
                      "Mes Stagiaires",
                      count: _stagiaires.length,
                      color: ColorConstants.primary,
                      trailing: _stagiaires.length > 3
                          ? TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ListeStagiairesScreen()),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text("Voir tout", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildStagiairesList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tableau de bord",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ColorConstants.textPrimary,
          ),
        ),
        Text(
          "Gérez vos stagiaires et conventions",
          style: TextStyle(
            fontSize: 14,
            color: ColorConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          label: "Stagiaires",
          value: "${_stats['total_stagiaires'] ?? _stagiaires.length}",
          icon: Icons.groups_rounded,
          color: ColorConstants.primary,
        ),
        StatCard(
          label: "En attente",
          value: "${_demandes.length}",
          icon: Icons.hourglass_empty_rounded,
          color: ColorConstants.warning,
        ),
        StatCard(
          label: "Conventions",
          value: "${_stats['conventions_signees'] ?? 0}",
          icon: Icons.description_rounded,
          color: ColorConstants.success,
        ),
        StatCard(
          label: "Pointages",
          value: "${_stats['pointages_aujourdhui'] ?? 0}",
          icon: Icons.location_on_rounded,
          color: ColorConstants.secondary,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {int? count, Color? color, Widget? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorConstants.textPrimary,
          ),
        ),
        if (count != null && count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color?.withValues(alpha: 0.1) ?? Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$count",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.grey[700],
              ),
            ),
          ),
        ],
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  Widget _buildDemandesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _demandes.length,
      itemBuilder: (context, index) {
        final demande = _demandes[index];
        final stagiaire = demande['stagiaire'] ?? {};
        
        final prenom = stagiaire['prenom'] ?? '';
        final nom = stagiaire['nom'] ?? '';
        final String displayName = (prenom.isEmpty && nom.isEmpty) 
            ? 'Profil incomplet' 
            : '$prenom $nom';
            
        final email = stagiaire['email'] ?? 'Email non renseigné';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: ColorConstants.primary.withValues(alpha: 0.1),
                  backgroundImage: stagiaire['photo_profil'] != null
                      ? NetworkImage(stagiaire['photo_profil'])
                      : null,
                  child: stagiaire['photo_profil'] == null
                      ? const Icon(Icons.person, color: ColorConstants.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 14,
                          fontStyle: (prenom.isEmpty && nom.isEmpty) ? FontStyle.italic : FontStyle.normal,
                          color: (prenom.isEmpty && nom.isEmpty) ? ColorConstants.textSecondary : ColorConstants.textPrimary,
                        )
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: ColorConstants.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18, color: ColorConstants.textSecondary),
                  tooltip: 'Infos du compte',
                  onPressed: () => showCompteInfoDialog(context, stagiaire),
                ),
                ElevatedButton(
                  onPressed: () => _ouvrirFormulaireConvention(stagiaire),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Demander l'accès", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _ouvrirFormulaireConvention(Map<String, dynamic> stagiaire) {
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

  Widget _buildStagiairesList() {
    if (_stagiaires.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              "Aucun stagiaire rattaché pour le moment.",
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorConstants.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _stagiaires.length > 3 ? 3 : _stagiaires.length,
      itemBuilder: (context, index) {
        final carnet = _stagiaires[index];
        final stagiaire = carnet['stagiaire'] ?? {};
        
        final prenom = stagiaire['prenom'] ?? '';
        final nom = stagiaire['nom'] ?? '';
        final String displayName = (prenom.isEmpty && nom.isEmpty) 
            ? 'Profil incomplet' 
            : '$prenom $nom';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ColorConstants.secondary.withValues(alpha: 0.1),
              backgroundImage: stagiaire['photo_profil'] != null 
                  ? NetworkImage(stagiaire['photo_profil']) 
                  : null,
              child: stagiaire['photo_profil'] == null 
                  ? const Icon(Icons.person, color: ColorConstants.secondary) 
                  : null,
            ),
            title: Text(
              displayName, 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: (prenom.isEmpty && nom.isEmpty) ? FontStyle.italic : FontStyle.normal,
              )
            ),
            subtitle: Text(stagiaire['filiere'] ?? 'Stage en cours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SuiviStagiaireScreen(carnet: carnet),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
