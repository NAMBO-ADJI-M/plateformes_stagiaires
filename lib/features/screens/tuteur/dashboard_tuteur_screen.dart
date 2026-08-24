import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';
import 'liste_stagiaires_screen.dart';

class DashboardTuteurScreen extends StatefulWidget {
  const DashboardTuteurScreen({super.key});

  @override
  State<DashboardTuteurScreen> createState() => _DashboardTuteurScreenState();
}

class _DashboardTuteurScreenState extends State<DashboardTuteurScreen> {
  final ApiService _api = ApiService();
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
                    _buildSectionTitle("Mes Stagiaires", 
                        count: _stagiaires.length, color: ColorConstants.primary),
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
      childAspectRatio: 1.5,
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

  Widget _buildSectionTitle(String title, {int? count, Color? color}) {
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
        final name = "${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}";

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: ColorConstants.primary.withValues(alpha: 0.1),
              backgroundImage: stagiaire['photo_profil'] != null 
                  ? NetworkImage(stagiaire['photo_profil']) 
                  : null,
              child: stagiaire['photo_profil'] == null 
                  ? const Icon(Icons.person, color: ColorConstants.primary) 
                  : null,
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(stagiaire['ecole'] ?? stagiaire['filiere'] ?? 'Stagiaire en attente'),
            trailing: ElevatedButton(
              onPressed: () {
                // Naviguer vers le formulaire de convention (existant)
                // Note: La logique exacte d'ouverture dépend du flux existant
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ouverture du formulaire de convention...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Demander l'accès"),
            ),
          ),
        );
      },
    );
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
        final name = "${stagiaire['prenom'] ?? ''} ${stagiaire['nom'] ?? ''}";

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
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(stagiaire['filiere'] ?? 'Stage en cours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               // Navigation vers ListeStagiairesScreen ou détail
            },
          ),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: ColorConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StagiaireTile extends StatelessWidget {
  final String name;
  final String role;
  final double progress;
  final String status;
  final Color statusColor;
  final String avatarUrl;
  final String autoStatut;
  final VoidCallback? onDemanderSuivi;
  final VoidCallback? onTap;

  const StagiaireTile({
    super.key,
    required this.name,
    required this.role,
    required this.progress,
    required this.status,
    required this.statusColor,
    required this.avatarUrl,
    required this.autoStatut,
    this.onDemanderSuivi,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: statusColor.withValues(alpha: 0.1),
            backgroundImage: NetworkImage(avatarUrl),
            child: avatarUrl.isEmpty ? Icon(Icons.person, color: statusColor) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  role,
                  style: const TextStyle(fontSize: 12, color: ColorConstants.textSecondary),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: ColorConstants.border,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(label: status, color: statusColor),
              if (autoStatut == 'DISPONIBLE' && onDemanderSuivi != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onDemanderSuivi,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: ColorConstants.primary,
                  ),
                  child: const Text('Suivre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
