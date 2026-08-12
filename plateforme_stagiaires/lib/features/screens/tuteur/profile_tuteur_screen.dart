import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/auth_service.dart';

/// Page de profil de l'espace tuteur/entreprise : infos personnelles,
/// informations entreprise, et déconnexion.
class ProfileTuteurScreen extends StatefulWidget {
  const ProfileTuteurScreen({super.key});

  @override
  State<ProfileTuteurScreen> createState() => _ProfileTuteurScreenState();
}

class _ProfileTuteurScreenState extends State<ProfileTuteurScreen> {
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
                    NetworkImage('https://i.pravatar.cc/150?img=12'),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Alice Martin',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: ColorConstants.textPrimary)),
                    SizedBox(height: 2),
                    Text('alice.martin@ubisoft.com',
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
              child: _LabelValue(label: 'ENTREPRISE', value: 'Ubisoft France'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _LabelValue(label: 'STAGIAIRES SUIVIS', value: '6'),
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
                  value: '+33 6 98 76 54 32'),
              Divider(height: 26),
              _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Fonction',
                  value: 'Lead UX Designer'),
              Divider(height: 26),
              _InfoRow(
                  icon: Icons.apartment_outlined,
                  label: 'Service',
                  value: 'Design & Expérience Utilisateur'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Entreprise',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: ColorConstants.textPrimary)),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: const [
              _InfoRow(
                  icon: Icons.business_outlined,
                  label: 'Raison sociale',
                  value: 'Ubisoft France'),
              Divider(height: 26),
              _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Adresse',
                  value: 'Lyon, France'),
              Divider(height: 26),
              _InfoRow(
                  icon: Icons.groups_outlined,
                  label: 'Stagiaires actifs',
                  value: '6'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Préférences',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: ColorConstants.textPrimary)),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_none_rounded,
                    color: ColorConstants.textSecondary),
                title: const Text('Notifications',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                trailing: const Icon(Icons.chevron_right,
                    size: 20, color: ColorConstants.textMuted),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shield_outlined,
                    color: ColorConstants.textSecondary),
                title: const Text('Sécurité & Confidentialité',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                trailing: const Icon(Icons.chevron_right,
                    size: 20, color: ColorConstants.textMuted),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline,
                    color: ColorConstants.textSecondary),
                title: const Text('Centre d\'aide',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                trailing: const Icon(Icons.chevron_right,
                    size: 20, color: ColorConstants.textMuted),
                onTap: () {},
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