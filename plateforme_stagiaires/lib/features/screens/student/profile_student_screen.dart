import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/auth_service.dart';

/// Reproduit profile-student.png : en-tête profil, infos personnelles,
/// stage actuel, et switch "Partager ma localisation" (covoiturage).
class ProfileStudentScreen extends StatefulWidget {
  const ProfileStudentScreen({super.key});

  @override
  State<ProfileStudentScreen> createState() => _ProfileStudentScreenState();
}

class _ProfileStudentScreenState extends State<ProfileStudentScreen> {
  bool _shareLocation = true;
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/onboarding',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        AppCard(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?img=32'),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Marie Dupont',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: ColorConstants.textPrimary)),
                    SizedBox(height: 2),
                    Text('marie.dupont@etu.univ-lyon1.fr',
                        style: TextStyle(
                            fontSize: 12.5, color: ColorConstants.textSecondary)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorConstants.border),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(
              child: _LabelValue(label: 'ÉTABLISSEMENT', value: 'Univ. Lyon 1'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _LabelValue(label: 'ENTREPRISE', value: 'Ubisoft France'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Informations personnelles',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: ColorConstants.textPrimary)),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: const [
              _InfoRow(
                  icon: Icons.call_outlined,
                  label: 'Téléphone',
                  value: '+33 6 12 34 56 78'),
              Divider(height: 26),
              _InfoRow(
                  icon: Icons.menu_book_outlined,
                  label: 'Filière',
                  value: 'Master Conception UI/UX'),
              Divider(height: 26),
              _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Tuteur académique',
                  value: 'M. Robert (Pr. Associé)'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Stage actuel',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: ColorConstants.textPrimary)),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: const [
              _InfoRow(
                  icon: Icons.work_outline,
                  label: 'Poste',
                  value: 'Stagiaire Product Designer'),
              Divider(height: 26),
              _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Dates',
                  value: '01 Fév. - 31 Juil. 2026'),
              Divider(height: 26),
              _InfoRow(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Maitre de stage',
                  value: 'Alice Martin (Lead UX)'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Covoiturage étudiant',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: ColorConstants.textPrimary)),
        const SizedBox(height: 10),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Partager ma localisation',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: ColorConstants.textPrimary)),
                    SizedBox(height: 4),
                    Text(
                      'Permet aux autres stagiaires de vous trouver pour le trajet vers Ubisoft.',
                      style: TextStyle(
                          fontSize: 12, color: ColorConstants.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _shareLocation,
                activeThumbColor: ColorConstants.primary,
                onChanged: (v) => setState(() => _shareLocation = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _isLoggingOut ? null : _handleLogout,
          icon: _isLoggingOut
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text(
            _isLoggingOut ? 'Déconnexion...' : 'Se déconnecter',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorConstants.error,
            minimumSize: const Size(double.infinity, 54),
            side: const BorderSide(color: ColorConstants.error),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: ColorConstants.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorConstants.textPrimary)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: ColorConstants.textSecondary),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontSize: 13.5, color: ColorConstants.textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: ColorConstants.textPrimary)),
      ],
    );
  }
}