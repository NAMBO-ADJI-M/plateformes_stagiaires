import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    await _apiService.loadToken();
    try {
      if (_apiService.isAuthenticated) {
        final profile = await _apiService.getProfile();
        if (mounted) setState(() => _userProfile = profile['user'] ?? profile);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleLogout(BuildContext context) async {
    await _apiService.logout();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: ColorConstants.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final fbUser = FirebaseAuth.instance.currentUser;
    final name = _userProfile?['prenom'] ?? _userProfile?['name'] ?? fbUser?.displayName ?? "Stagiaire";
    final email = _userProfile?['email'] ?? fbUser?.email ?? "email@exemple.com";

    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(name, email),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMenuSection(context),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProfileHeader(String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 36),
      decoration: const BoxDecoration(
        gradient: ColorConstants.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            email,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ColorConstants.cardShadow,
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.edit_outlined, "Modifier mon profil"),
          const Divider(height: 1),
          _buildMenuItem(Icons.history_outlined, "Historique d'activités & Pointages"),
          const Divider(height: 1),
          _buildMenuItem(Icons.shield_outlined, "Sécurité & Confidentialité RGPD"),
          const Divider(height: 1),
          _buildMenuItem(Icons.help_outline, "Centre d'aide & Documentation"),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: ColorConstants.primary),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: ColorConstants.textMuted),
      onTap: () {},
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _handleLogout(context),
      icon: const Icon(Icons.logout),
      label: Text("Se déconnecter", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorConstants.error,
        minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: ColorConstants.error),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

