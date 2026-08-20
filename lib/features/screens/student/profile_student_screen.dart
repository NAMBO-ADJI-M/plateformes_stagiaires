import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/geofencing_service.dart';
import '../../../services/profile_event_bus.dart';

/// Version dynamisée du profil stagiaire.
class ProfileStudentScreen extends StatefulWidget {
  const ProfileStudentScreen({super.key});

  @override
  State<ProfileStudentScreen> createState() => _ProfileStudentScreenState();
}

class _ProfileStudentScreenState extends State<ProfileStudentScreen> {
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _shareLocation = true;
  bool _isLoggingOut = false;
  bool _isLoading = true;
  bool _isPhotoLoading = false;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _activeCarnet;
  bool _autorisationPointage = false;
  String? _autorisationStatut;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getProfile(),
        _api.getCarnets(),
      ]);

      final profileRes = results[0] as Map<String, dynamic>;
      final carnets = results[1] as List<dynamic>;

      if (mounted) {
        setState(() {
          _profile = profileRes['profile_data'];

          final autoPointage = profileRes['autorisation_pointage'];
          if (autoPointage != null) {
            _autorisationStatut = autoPointage['statut'];
            _autorisationPointage = _autorisationStatut == 'ACTIVE';
          }

          if (carnets.isNotEmpty) {
            _activeCarnet = carnets.firstWhere(
              (c) => c['statut'] == 'EN_COURS',
              orElse: () => carnets.first,
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAutorisationPointage(bool val) async {
    if (_activeCarnet == null || _activeCarnet!['entreprise_id'] == null) return;

    setState(() {
      _autorisationPointage = val;
    });

    try {
      await _api.updateAutorisationPointage(_activeCarnet!['entreprise_id'], val);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(val ? 'Suivi de présence activé' : 'Suivi de présence désactivé'))
        );
      }
    } catch (e) {
      setState(() {
        _autorisationPointage = !val; // rollback
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    setState(() => _isPhotoLoading = true);
    try {
      await _api.updatePhotoProfil(File(image.path));
      await _loadData();
      ProfileEventBus().notifyProfileUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo mise à jour !')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _isPhotoLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    await GeofencingService().stop();
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/onboarding',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final name = '${_profile?['prenom'] ?? ''} ${_profile?['nom'] ?? ''}'.trim();
    final email = _profile?['email'] ?? 'Non renseigné';
    final ecole = _profile?['ecole'] ?? 'Non renseignée';
    final photo = _profile?['photo_profil_url'];

    return Container(
      color: ColorConstants.paper,
      child: Column(
        children: [
          const ScreenTopBar(
            eyebrow: 'Paramètres',
            title: 'Mon Profil',
            showProfile: false, // On est déjà sur le profil
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: photo != null ? NetworkImage(photo) : null,
                        child: photo == null || _isPhotoLoading
                            ? (_isPhotoLoading ? const CircularProgressIndicator() : const Icon(Icons.person, size: 30))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.isEmpty ? 'Étudiant' : name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: ColorConstants.textPrimary)),
                            const SizedBox(height: 2),
                            Text(email,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: ColorConstants.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ColorConstants.border),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          onPressed: _pickAndUploadPhoto,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LabelValue(
                          label: 'ÉTABLISSEMENT',
                          value: ecole.length > 15 ? '${ecole.substring(0, 12)}...' : ecole),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LabelValue(
                          label: 'ENTREPRISE',
                          value: _activeCarnet?['entreprise_nom'] ?? 'Aucune'),
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
                    children: [
                      _InfoRow(
                          icon: Icons.call_outlined,
                          label: 'Téléphone',
                          value: _profile?['telephone'] ?? 'Non renseigné'),
                      const Divider(height: 26),
                      _InfoRow(
                          icon: Icons.menu_book_outlined,
                          label: 'Filière',
                          value: _profile?['filiere'] ?? 'Non renseignée'),
                      const Divider(height: 26),
                      _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Niveau',
                          value: _profile?['niveau'] ?? 'Non renseigné'),
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
                    children: [
                      _InfoRow(
                          icon: Icons.work_outline,
                          label: 'Poste',
                          value: _activeCarnet?['poste'] ?? 'Pas de stage actif'),
                      const Divider(height: 26),
                      _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Dates',
                          value: _formatDates(_activeCarnet)),
                      const Divider(height: 26),
                      _InfoRow(
                          icon: Icons.workspace_premium_outlined,
                          label: 'Tuteur',
                          value: _activeCarnet?['tuteur_nom'] ?? 'Non rattaché'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Confidentialité & Suivi',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: ColorConstants.textPrimary)),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    children: [
                      _buildSwitchRow(
                        title: 'Partager ma présence',
                        subtitle: 'Autoriser votre tuteur à voir vos heures d\'arrivée et de départ.',
                        value: _autorisationPointage,
                        onChanged: _toggleAutorisationPointage,
                        enabled: _activeCarnet?['entreprise_id'] != null,
                      ),
                      const Divider(height: 26),
                      _buildSwitchRow(
                        title: 'Partager ma localisation',
                        subtitle: 'Permet aux autres stagiaires de vous trouver pour le trajet.',
                        value: _shareLocation,
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
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _isLoggingOut ? null : _confirmDeleteAccount,
                  icon: const Icon(Icons.delete_forever_outlined, size: 18),
                  label: const Text('Supprimer mon compte'),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstants.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: const Text(
            'Cette action est irréversible. Toutes vos données seront effacées.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: ColorConstants.error),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoggingOut = true);
      try {
        await _api.deleteAccount();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (r) => false);
      } catch (e) {
        if (!mounted) {
          return;
        }
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  String _formatDates(Map<String, dynamic>? carnet) {
    if (carnet == null) return '—';
    final debut = carnet['date_debut'];
    final fin = carnet['date_fin'];
    if (debut == null || fin == null) return '—';
    return '${_shortDate(debut)} - ${_shortDate(fin)}';
  }

  String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}';
    } catch (_) {
      return '?';
    }
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: ColorConstants.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: ColorConstants.primary,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            style: const TextStyle(
                fontSize: 13.5, color: ColorConstants.textSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
