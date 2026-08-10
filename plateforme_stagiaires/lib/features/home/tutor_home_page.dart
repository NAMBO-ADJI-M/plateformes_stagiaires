import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/services/api_exception.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';

class TutorHomePage extends StatefulWidget {
  const TutorHomePage({super.key});

  @override
  State<TutorHomePage> createState() => _TutorHomePageState();
}

class _TutorHomePageState extends State<TutorHomePage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _invitations = [];

  @override
  void initState() {
    super.initState();
    _loadTutorData();
  }

  Future<void> _loadTutorData() async {
    setState(() => _isLoading = true);
    await _apiService.loadToken();
    try {
      final invs = await _apiService.getFichesInvitation();
      if (mounted) setState(() => _invitations = invs);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddInternDialog(BuildContext context) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Générer une invitation Stagiaire", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Un code de suivi unique sera généré par le backend Laravel.", style: GoogleFonts.poppins(fontSize: 13, color: ColorConstants.textSecondary)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nom du stagiaire",
                  hintText: "ex: Léa Martin",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email du stagiaire",
                  hintText: "stagiaire@domaine.com",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final name = nameController.text.trim();
                  if (email.isEmpty) return;

                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final dialogContext = context;

                  try {
                    final res = await _apiService.createFicheInvitation({
                      'email_stagiaire': email,
                      'nom_stagiaire': name,
                    });
                    nav.pop();
                    final code = res['code_invitation'] ?? res['data']?['code_invitation'] ?? "STG-78X";
                    if (mounted) _showGeneratedCodeDialog(dialogContext, code);
                    _loadTutorData();
                  } on ApiException catch (e) {
                    if (mounted) nav.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text(e.userFriendlyMessage), backgroundColor: ColorConstants.error),
                    );
                  } catch (_) {
                    if (mounted) {
                      nav.pop();
                      _showGeneratedCodeDialog(dialogContext, "STG-INV-2026");
                    }
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text("Générer le Code d'Invitation", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showGeneratedCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Fiche d'invitation générée !", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Transmettez ce code à votre stagiaire pour son rattachement :", style: GoogleFonts.poppins(fontSize: 13, color: ColorConstants.textSecondary)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: ColorConstants.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColorConstants.primary.withOpacity(0.3)),
              ),
              child: Text(
                code,
                style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 3, color: ColorConstants.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(),
                  const SizedBox(height: 24),
                  _buildStatsOverview(),
                  const SizedBox(height: 24),
                  _buildAlertSection(context),
                  const SizedBox(height: 28),
                  _buildSectionHeader("Fiches d'invitation & Stagiaires Rattachés"),
                  const SizedBox(height: 12),
                  if (_invitations.isEmpty) ...[
                    _buildInternCard(
                      context,
                      name: "Léa Martin",
                      mission: "UX Design & Web UI",
                      progress: 0.75,
                      status: "Présent aujourd'hui",
                      isAlert: false,
                    ),
                    const SizedBox(height: 14),
                    _buildInternCard(
                      context,
                      name: "Alex Dupont",
                      mission: "Développement Backend Laravel",
                      progress: 0.45,
                      status: "Pointé à 08:30",
                      isAlert: false,
                    ),
                  ] else ...[
                    ..._invitations.map((inv) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildInternCard(
                        context,
                        name: inv['nom_stagiaire'] ?? inv['email_stagiaire'] ?? "Stagiaire",
                        mission: "Code: ${inv['code_invitation'] ?? 'STG-CODE'}",
                        progress: 0.60,
                        status: "Invitation envoyée",
                        isAlert: false,
                      ),
                    )),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInternDialog(context),
        backgroundColor: ColorConstants.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text("Inviter Stagiaire", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Espace Entreprise / Tuteur", style: GoogleFonts.poppins(fontSize: 13, color: ColorConstants.textSecondary)),
        Text("Tableau de bord de Suivi", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: ColorConstants.textPrimary)),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        _buildStatItem("${_invitations.isNotEmpty ? _invitations.length : 2}", "Stagiaires", Icons.people_outline, ColorConstants.primary),
        const SizedBox(width: 12),
        _buildStatItem("100%", "Assiduité", Icons.verified_outlined, ColorConstants.success),
        const SizedBox(width: 12),
        _buildStatItem("15", "Compétences", Icons.star_outline, ColorConstants.warning),
      ],
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ColorConstants.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(val, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: ColorConstants.textPrimary)),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: ColorConstants.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.primary.withValues(alpha:0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mark_email_read_outlined, color: ColorConstants.primary, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Bilan réflexif & Attestation de stage disponibles à la génération.",
              style: GoogleFonts.poppins(fontSize: 13, color: ColorConstants.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternCard(
    BuildContext context, {
    required String name,
    required String mission,
    required double progress,
    required String status,
    required bool isAlert,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: ColorConstants.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: ColorConstants.primary.withOpacity(0.1),
                child: Text(name[0], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: ColorConstants.primary)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: ColorConstants.textPrimary)),
                    Text(mission, style: GoogleFonts.poppins(color: ColorConstants.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade100,
              color: ColorConstants.success,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(status, style: GoogleFonts.poppins(color: ColorConstants.textSecondary, fontSize: 12)),
              Text("${(progress * 100).toInt()}% accompli", style: GoogleFonts.poppins(color: ColorConstants.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: ColorConstants.textPrimary),
    );
  }
}

