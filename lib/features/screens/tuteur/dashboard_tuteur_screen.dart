import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/internship_service.dart';
import 'widgets/add_stagiaire_dialog.dart';

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
  List<dynamic> _enAttente = [];
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
          _enAttente = stagiairesData['en_attente'] ?? [];
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
                    if (_demandes.isNotEmpty || _enAttente.isNotEmpty) ...[
                      _buildSectionTitle("Demandes en cours", 
                          count: _demandes.length + _enAttente.length, color: ColorConstants.warning),
                      const SizedBox(height: 16),
                      _buildDemandesList(),
                      const SizedBox(height: 32),
                    ],
                    // "Mes Stagiaires" supprimé du dashboard car ils doivent migrer vers 
                    // l'onglet dédié une fois la convention signée.
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
    final List<dynamic> combined = [
      ..._demandes.map((d) => {...d, 'is_invitation': false}),
      ..._enAttente.map((e) => {...e, 'is_invitation': true}),
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: combined.length,
      itemBuilder: (context, index) {
        final item = combined[index];
        final bool isInvitation = item['is_invitation'] == true;
        final stagiaire = item['stagiaire'] ?? {};
        
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
                  backgroundImage: (stagiaire['photo_profil'] != null || stagiaire['photo_profil_url'] != null)
                      ? NetworkImage(stagiaire['photo_profil'] ?? stagiaire['photo_profil_url'])
                      : null,
                  child: (stagiaire['photo_profil'] == null && stagiaire['photo_profil_url'] == null)
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
                        isInvitation ? "Code transmis - En attente" : email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11, 
                          color: isInvitation ? ColorConstants.warning : ColorConstants.textSecondary,
                          fontWeight: isInvitation ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18, color: ColorConstants.textSecondary),
                  tooltip: 'Infos du compte',
                  onPressed: () => showCompteInfoDialog(context, stagiaire),
                ),
                if (!isInvitation)
                  ElevatedButton(
                    onPressed: () => _ouvrirFormulaireConvention(stagiaire),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Demander l'accès", style: TextStyle(fontSize: 12)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ColorConstants.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("En attente", 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorConstants.warning)),
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
}
