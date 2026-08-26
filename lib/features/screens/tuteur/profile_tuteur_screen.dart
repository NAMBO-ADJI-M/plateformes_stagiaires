import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_event_bus.dart';

/// Page de profil de l'espace tuteur/entreprise : infos personnelles,
/// informations entreprise, et déconnexion.
class ProfileTuteurScreen extends StatefulWidget {
  const ProfileTuteurScreen({super.key});

  @override
  State<ProfileTuteurScreen> createState() => _ProfileTuteurScreenState();
}

class _ProfileTuteurScreenState extends State<ProfileTuteurScreen> {
  final ApiService _api = ApiService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoggingOut = false;
  bool _isLoading = true;
  bool _isPhotoLoading = false;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;

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
        _api.getEntrepriseDashboardStats(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0]['profile_data'];
          _stats = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/onboarding',
      (route) => false,
    );
  }

  void _editEntrepriseInfo() {
    final raisonCtrl = TextEditingController(text: _profile?['raison_sociale']);
    final adresseCtrl = TextEditingController(text: _profile?['adresse_libelle']);
    final telCtrl = TextEditingController(text: _profile?['telephone']);
    final siteCtrl = TextEditingController(text: _profile?['site_web']);
    final latCtrl = TextEditingController(text: _profile?['adresse_lat']?.toString());
    final lngCtrl = TextEditingController(text: _profile?['adresse_lng']?.toString());
    final rayonCtrl = TextEditingController(text: (_profile?['rayon_detection_metres'] ?? 100).toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ColorConstants.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.business_rounded, color: ColorConstants.primary),
              SizedBox(width: 10),
              Text('Informations Entreprise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Raison sociale'),
                TextField(controller: raisonCtrl, decoration: _inputDeco('Nom de la société')),
                const SizedBox(height: 16),
                
                _buildFieldLabel('Adresse & Localisation GPS'),
                TextField(controller: adresseCtrl, decoration: _inputDeco('Adresse complète')),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            // 1. Vérifier si le service est activé
                            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                            if (!serviceEnabled) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci d\'activer le GPS.')));
                              }
                              return;
                            }

                            // 2. Vérifier les permissions
                            LocationPermission permission = await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                              if (permission == LocationPermission.denied) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La permission GPS est requise.')));
                                }
                                return;
                              }
                            }

                            if (permission == LocationPermission.deniedForever) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez autoriser le GPS dans les réglages.')));
                              }
                              return;
                            }

                            // 3. Récupérer la position
                            final pos = await Geolocator.getCurrentPosition(
                              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
                            );
                            
                            setDialogState(() {
                              latCtrl.text = pos.latitude.toString();
                              lngCtrl.text = pos.longitude.toString();
                            });
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📍 Position GPS récupérée !'), backgroundColor: ColorConstants.success));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur GPS : $e')));
                            }
                          }
                        },
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('Ma position', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: _inputDeco('Lat.'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: lngCtrl, decoration: _inputDeco('Long.'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildFieldLabel('Rayon de détection (mètres)'),
              TextField(
                controller: rayonCtrl, 
                decoration: _inputDeco('Ex: 100'), 
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('Rayon pris en compte pour le pointage automatique.', style: TextStyle(fontSize: 11, color: ColorConstants.textSecondary)),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Contact'),
              TextField(controller: telCtrl, decoration: _inputDeco('Téléphone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: siteCtrl, decoration: _inputDeco('Site Web (URL)'), keyboardType: TextInputType.url),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _api.completeEntrepriseProfile({
                  'raison_sociale': raisonCtrl.text,
                  'adresse_libelle': adresseCtrl.text,
                  'adresse_lat': double.tryParse(latCtrl.text),
                  'adresse_lng': double.tryParse(lngCtrl.text),
                  'rayon_detection_metres': int.tryParse(rayonCtrl.text),
                  'telephone': telCtrl.text,
                  'site_web': siteCtrl.text,
                });
                Navigator.pop(ctx);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Entreprise mise à jour !'), backgroundColor: ColorConstants.success));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorConstants.textSecondary)),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: ColorConstants.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final name = '${_profile?['prenom'] ?? ''} ${_profile?['nom'] ?? ''}'.trim();
    final entreprise = _profile?['raison_sociale'] ?? 'Mon Entreprise';

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
                        backgroundColor: ColorConstants.border,
                        child: _isPhotoLoading
                            ? const CircularProgressIndicator()
                            : ClipOval(
                                child: _profile?['photo_profil_url'] != null
                                    ? Image.network(
                                        _profile!['photo_profil_url'],
                                        fit: BoxFit.cover,
                                        width: 56,
                                        height: 56,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 30),
                                      )
                                    : const Icon(Icons.person, size: 30),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.isEmpty ? 'Tuteur' : name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ColorConstants.textPrimary)),
                            const SizedBox(height: 2),
                            Text(_profile?['email'] ?? '', style: const TextStyle(fontSize: 12.5, color: ColorConstants.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ColorConstants.border)),
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
                    Expanded(child: _LabelValue(label: 'ENTREPRISE', value: entreprise)),
                    const SizedBox(width: 10),
                    Expanded(child: _LabelValue(label: 'STAGIAIRES SUIVIS', value: _stats?['stagiaires_actifs']?.toString() ?? '0')),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Entreprise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: ColorConstants.textPrimary)),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    children: [
                      _InfoRow(icon: Icons.business_outlined, label: 'Raison sociale', value: entreprise),
                      const Divider(height: 26),
                      _InfoRow(icon: Icons.location_on_outlined, label: 'Adresse', value: _profile?['adresse_libelle'] ?? 'Non renseignée'),
                      const Divider(height: 26),
                      _InfoRow(icon: Icons.track_changes_rounded, label: 'Rayon Pointage', value: '${_profile?['rayon_detection_metres'] ?? 100} mètres'),
                      const Divider(height: 26),
                      _InfoRow(icon: Icons.public_outlined, label: 'Site Web', value: _profile?['site_web'] ?? 'Non renseigné'),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _editEntrepriseInfo,
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: const Text('Modifier les informations entreprise'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isLoggingOut ? null : _handleLogout,
                  icon: _isLoggingOut ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.logout),
                  label: Text(_isLoggingOut ? 'Déconnexion...' : 'Se déconnecter', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConstants.error,
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(color: ColorConstants.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
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
            style: const TextStyle(fontSize: 13.5, color: ColorConstants.textSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: ColorConstants.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}