import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:google_fonts/google_fonts.dart';
=======
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/modeles/user_type.dart';

class ChooseUserTypePage extends StatefulWidget {
  const ChooseUserTypePage({super.key});

  @override
  State<ChooseUserTypePage> createState() => _ChooseUserTypePageState();
}

class _ChooseUserTypePageState extends State<ChooseUserTypePage> {
  void _goToCodeLogin(UserType userType) {
    Navigator.of(context).pushNamed('/login-code', arguments: userType);
  }

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: ColorConstants.textPrimary),
      ),
=======
  void _showChooseProfileMessage(UserType userType) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Choisissez votre profil pour continuer vers votre espace',
        ),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _goToCodeLogin(userType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: false,
        leading: const BackButton(color: Colors.black),
      ),
      extendBodyBehindAppBar: true,
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
<<<<<<< HEAD
              const SizedBox(height: 12),
              Text(
                'Bienvenue sur\nPlateforme Stagiaires',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sélectionnez votre rôle pour accéder à votre espace personnalisé.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: ColorConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 36),
              _buildRoleCard(
                type: UserType.stagiaire,
                icon: Icons.school_outlined,
                badgeText: 'Stage & Covoiturage',
                gradient: ColorConstants.primaryGradient,
              ),
              const SizedBox(height: 20),
              _buildRoleCard(
                type: UserType.entreprise,
                icon: Icons.business_outlined,
                badgeText: 'Tuteur & Suivi',
                gradient: ColorConstants.accentGradient,
              ),
=======
              const SizedBox(height: 16),
              const Text(
                'Sélectionnez votre profil',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisissez votre profil pour continuer vers votre espace.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              _buildCard(UserType.stagiaire, Icons.person_outline),
              const SizedBox(height: 16),
              _buildCard(UserType.entreprise, Icons.business_center_outlined),
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
            ],
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildRoleCard({
    required UserType type,
    required IconData icon,
    required String badgeText,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ColorConstants.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _goToCodeLogin(type),
          splashColor: ColorConstants.primary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: ColorConstants.glowShadow(ColorConstants.primary),
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 20),
=======
  Widget _buildCard(UserType type, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showChooseProfileMessage(type),
        splashColor: ColorConstants.primary.withValues(alpha: 0.1),
        highlightColor: ColorConstants.primary.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 28, color: ColorConstants.primary),
                const SizedBox(width: 16),
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< HEAD
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorConstants.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),

                        child: Text(
                          badgeText,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type.label,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: ColorConstants.textSecondary,
                        ),
=======
                      Text(
                        type.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        type.subtitle,
                        style: const TextStyle(color: Colors.black54),
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
                      ),
                    ],
                  ),
                ),
                const Icon(
<<<<<<< HEAD
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: ColorConstants.textMuted,
=======
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.black54,
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
<<<<<<< HEAD

=======
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
