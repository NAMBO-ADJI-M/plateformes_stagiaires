import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/modeles/user_type.dart';

class ChooseUserTypePage extends StatefulWidget {
  const ChooseUserTypePage({super.key});

  @override
  State<ChooseUserTypePage> createState() => _ChooseUserTypePageState();
}

class _ChooseUserTypePageState extends State<ChooseUserTypePage> {
  void _goToRegisterCode(UserType userType) {
    Navigator.of(context).pushNamed(
      '/register-code',
      arguments: {'userType': userType},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: ColorConstants.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

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
          onTap: () => _goToRegisterCode(type),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: ColorConstants.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}