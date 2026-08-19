import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';
import '../../widgets/common_widgets.dart';
import 'covoiturage_home_screen.dart';
import 'notifications_screen.dart';
import 'conversations_screen.dart';
import 'carnet_creation_page.dart';
import 'carnet_list_page.dart';

class DashboardStudentScreen extends StatefulWidget {
  const DashboardStudentScreen({super.key});

  @override
  State<DashboardStudentScreen> createState() => _DashboardStudentScreenState();
}

class _DashboardStudentScreenState extends State<DashboardStudentScreen>
    with WidgetsBindingObserver {
  final ApiService _api = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _loading = true;
  String? _error;

  // Profil
  String _prenom = '';
  String _ecole = '';
  String _filiere = '';
  String? _photoUrl;
  bool _photoUploading = false;
  int _notifCount = 0;

  // Carnet
  bool _hasCarnet = false;
  
  Map<String, dynamic>? _stats;

  // Rattachement tuteur
  bool _rattache = false;
  String? _tuteurNom;

  // Pointage du jour
  String _pointageStatut = 'AUCUN'; // AUCUN | ARRIVE | TERMINE
  String? _heureArrivee;
  String? _heureDepart;

  // Covoiturage
  Map<String, dynamic>? _prochaineReservation;

  // Geofencing
  bool _geofencingActive = false;
  bool _checkingGeofencing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkGeofencingStatus();
    _loadDashboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // L'utilisateur peut revenir des réglages système après avoir activé
    // la localisation : on revérifie l'état au retour au premier plan.
    if (state == AppLifecycleState.resumed) {
      _checkGeofencingStatus();
    }
  }

  Future<void> _checkGeofencingStatus() async {
    setState(() => _checkingGeofencing = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      // Le geofencing en arrière-plan nécessite explicitement
      // "always" (Android/iOS) et pas seulement "whileInUse".
      final active = serviceEnabled && permission == LocationPermission.always;

      if (mounted) {
        setState(() {
          _geofencingActive = active;
          _checkingGeofencing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _geofencingActive = false;
          _checkingGeofencing = false;
        });
      }
    }
  }

  Future<void> _activerGeofencing() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Refus définitif : le dialogue système ne peut plus être redéclenché,
    // il faut renvoyer l'utilisateur vers les réglages de l'application.
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La localisation a été refusée. Activez-la manuellement dans les réglages de l\'application.',
            ),
          ),
        );
      }
      await Geolocator.openAppSettings();
      await _checkGeofencingStatus();
      return;
    }

    if (permission == LocationPermission.whileInUse) {
      // Sur Android/iOS récents, l'autorisation "toujours" doit souvent
      // être accordée séparément depuis les réglages de l'app.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pour le pointage automatique, choisissez "Toujours autoriser" dans les réglages.',
            ),
          ),
        );
      }
      await Geolocator.openAppSettings();
      await _checkGeofencingStatus();
      return;
    }

    await _checkGeofencingStatus();
  }

  Future<void> _loadDashboard({bool silentRefresh = false}) async {
    // Si on a déjà des données, on évite le spinner plein écran pour une sensation d'instantanéité
    final hasData = _prenom.isNotEmpty || _hasCarnet;

    if (!silentRefresh && !hasData) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // 1. Charger le profil (sera instantané si en cache SQLite)
      final profileResponse = await _api.getProfile();
      final stagiaire = profileResponse['profile_data'] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _prenom = (stagiaire?['prenom'] as String?) ?? '';
          _ecole = (stagiaire?['ecole'] as String?) ?? '';
          _filiere = (stagiaire?['filiere'] as String?) ?? '';
          _photoUrl = stagiaire?['photo_profil_url'] as String?;
          _notifCount = (profileResponse['notifications_non_lues'] as int?) ?? 0;
          // Si on n'avait pas de données, on peut déjà arrêter le chargement du header
          if (!hasData) _loading = false;
        });
      }

      // 2. Charger les carnets
      final carnets = await _api.getCarnets();

      if (carnets.isEmpty) {
        if (mounted) setState(() { _hasCarnet = false; _loading = false; });
        return;
      }

      final carnet = carnets.firstWhere(
        (c) => c['statut'] == 'EN_COURS',
        orElse: () => carnets.first,
      ) as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _rattache = carnet['entreprise_id'] != null && carnet['autorisation_suivi'] == true;
          _tuteurNom = carnet['tuteur_nom'] as String?;
          _hasCarnet = true;
        });
      }

      final carnetId = carnet['id'] as String;

      // 3. Charger les détails en parallèle (Stats, Pointage, Réservations)
      final secondaryResults = await Future.wait([
        _api.getCarnetStats(carnetId),
        _api.getHistoriquePointage(carnetId).catchError((_) => []),
        _api.getMesReservations().catchError((_) => []),
      ]);

      if (mounted) {
        setState(() {
          _stats = secondaryResults[0] as Map<String, dynamic>;
          _computePointageDuJour(secondaryResults[1] as List<dynamic>);

          final reservations = secondaryResults[2] as List<dynamic>;
          final aVenir = reservations
              .cast<Map<String, dynamic>>()
              .where((r) => r['statut'] != 'ANNULEE' && r['statut'] != 'TERMINEE')
              .toList();
          _prochaineReservation = aVenir.isNotEmpty ? aVenir.first : null;

          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted && !hasData) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !hasData) {
        setState(() {
          _error = 'Une erreur est survenue. Vérifiez votre connexion.';
          _loading = false;
        });
      }
    }
  }
    }
  }

  void _computePointageDuJour(List<dynamic> historique) {
    final today = DateTime.now();
    final entriesToday = historique.cast<Map<String, dynamic>>().where((e) {
      final debut = DateTime.tryParse(e['date_debut'] as String? ?? '');
      return debut != null &&
          debut.year == today.year &&
          debut.month == today.month &&
          debut.day == today.day;
    }).toList();

    if (entriesToday.isEmpty) {
      _pointageStatut = 'AUCUN';
      return;
    }

    final entree = entriesToday.first;
    final debut = DateTime.tryParse(entree['date_debut'] as String? ?? '');
    final fin = entree['date_fin'] != null
        ? DateTime.tryParse(entree['date_fin'] as String)
        : null;

    _heureArrivee = debut != null ? _formatHeure(debut) : null;

    if (fin != null) {
      _heureDepart = _formatHeure(fin);
      _pointageStatut = 'TERMINE';
    } else {
      _pointageStatut = 'ARRIVE';
    }
  }

  String _formatHeure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}/${date.year}';
  }

  ({IconData icon, Color color}) _activityStyle(String type) {
    switch (type) {
      case 'mission':
        return (
          icon: Icons.assignment_turned_in_outlined,
          color: ColorConstants.primary
        );
      case 'presence':
        return (icon: Icons.check_circle, color: ColorConstants.success);
      case 'difficulte':
        return (icon: Icons.error_outline, color: ColorConstants.accentOrange);
      case 'felicitation':
        return (
          icon: Icons.star_outline_rounded,
          color: const Color(0xFF7F77DD)
        );
      case 'trajet':
        return (
          icon: Icons.directions_car_outlined,
          color: ColorConstants.accentOrange
        );
      default:
        return (
          icon: Icons.notes_outlined,
          color: ColorConstants.textSecondary
        );
    }
  }

  // Navigue vers la liste des carnets. L'ouverture directe du logbook
  // (LogbookScreen) est réservée à l'onglet "Logbook" du BottomNavigationBar
  // (cf. LogbookTabScreen), pas à cette carte du dashboard.
  void _openCarnetList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CarnetListPage()),
    );
  }

  // ============================================================
  // Photo de profil : choix de la source, upload, suppression
  // ============================================================

  /// Ouvre le bottom sheet de choix (appareil photo / galerie / suppression).
  void _choisirPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Photo de profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              _PhotoActionTile(
                icon: Icons.camera_alt_outlined,
                iconColor: ColorConstants.primary,
                title: 'Prendre une photo',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _selectionnerImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _PhotoActionTile(
                icon: Icons.photo_library_outlined,
                iconColor: ColorConstants.primary,
                title: 'Choisir depuis la galerie',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _selectionnerImage(ImageSource.gallery);
                },
              ),
              if (_photoUrl != null) ...[
                const SizedBox(height: 12),
                _PhotoActionTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: ColorConstants.error,
                  title: 'Supprimer la photo',
                  titleColor: ColorConstants.error,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _supprimerPhoto();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectionnerImage(ImageSource source) async {
    try {
      final fichier = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1000,
        imageQuality: 85,
      );
      if (fichier == null) return; // sélection annulée par l'utilisateur
      await _uploaderPhoto(File(fichier.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'accéder à la photo.")),
      );
    }
  }

  Future<void> _uploaderPhoto(File fichier) async {
    setState(() => _photoUploading = true);
    try {
      // NOTE : suppose une méthode ApiService.updatePhotoProfil(File) qui
      // envoie un POST multipart et renvoie l'URL de la nouvelle photo.
      final nouvelleUrl = await _api.updatePhotoProfil(fichier);
      if (!mounted) return;
      setState(() {
        _photoUrl = nouvelleUrl;
        _photoUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _photoUploading = false);
      final message = e is ApiException
          ? e.userFriendlyMessage
          : "Échec de l'envoi de la photo. Réessayez.";
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _supprimerPhoto() async {
    setState(() => _photoUploading = true);
    try {
      // NOTE : suppose une méthode ApiService.supprimerPhotoProfil().
      await _api.supprimerPhotoProfil();
      if (!mounted) return;
      setState(() {
        _photoUrl = null;
        _photoUploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _photoUploading = false);
      final message = e is ApiException
          ? e.userFriendlyMessage
          : 'Échec de la suppression. Réessayez.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 40, color: ColorConstants.textSecondary),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadDashboard, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_checkGeofencingStatus(), _loadDashboard()]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // ---------- En-tête ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GreetingHeader(
                  title: 'Bonjour, $_prenom',
                  subtitle:
                      [_ecole, _filiere].where((s) => s.isNotEmpty).join(' • '),
                  avatarUrl: _photoUrl ?? 'https://i.pravatar.cc/150?img=32',
                  onAvatarTap: _choisirPhoto,
                  avatarLoading: _photoUploading,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        color: ColorConstants.textPrimary),
                    tooltip: 'Messagerie',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ConversationsScreen())),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded,
                            color: ColorConstants.textPrimary),
                        tooltip: 'Notifications',
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen())),
                      ),
                      if (_notifCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: ColorConstants.error,
                                shape: BoxShape.circle),
                            constraints:
                                const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$_notifCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ---------- Bannière geofencing ----------
          if (!_checkingGeofencing && !_geofencingActive) ...[
            const SizedBox(height: 14),
            _GeofencingBanner(onActivate: _activerGeofencing),
          ],

          if (!_hasCarnet) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aucun carnet de stage',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: ColorConstants.textPrimary)),
                  const SizedBox(height: 6),
                  const Text(
                    'Créez votre carnet de stage pour commencer à suivre votre progression.',
                    style: TextStyle(
                        fontSize: 12.5, color: ColorConstants.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final cree = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CarnetCreationPage()),
                      );
                      if (cree == true) _loadDashboard();
                    },
                    child: const Text('Créer mon carnet'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ---------- Statut du jour ----------
            const SizedBox(height: 22),
            const Text('Statut du jour',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorConstants.textPrimary)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StatusMiniCard(
                    icon: Icons.people_alt_rounded,
                    iconBg: ColorConstants.primary,
                    title: 'Rattachement',
                    value: _rattache ? 'Rattaché' : 'En attente',
                    subtitle: _rattache ? (_tuteurNom ?? '') : null,
                    valueColor: _rattache
                        ? ColorConstants.success
                        : ColorConstants.accentOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusMiniCard(
                    icon: Icons.access_time_filled_rounded,
                    iconBg: ColorConstants.accentOrange,
                    title: 'Pointage',
                    value: _pointageStatut == 'TERMINE'
                        ? 'Terminé'
                        : _pointageStatut == 'ARRIVE'
                            ? 'Présent depuis $_heureArrivee'
                            : 'Pas encore',
                    valueColor: _pointageStatut == 'AUCUN'
                        ? ColorConstants.textSecondary
                        : ColorConstants.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusMiniCard(
                    icon: Icons.flag_rounded,
                    iconBg: ColorConstants.success,
                    title: 'Fin de journée',
                    value: _pointageStatut == 'TERMINE'
                        ? (_heureDepart ?? '—')
                        : 'En cours',
                    valueColor: ColorConstants.textPrimary,
                  ),
                ),
              ],
            ),

            // ---------- Progression ----------
            const SizedBox(height: 22),
            const Text('Progression du carnet de stage',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorConstants.textPrimary)),
            const SizedBox(height: 10),
            AppCard(
              onTap: _openCarnetList,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      ProgressRing(
                        percent:
                            (((_stats?['progression_globale'] ?? 0) as num).toDouble()) /
                                100,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Progression\nglobale',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10.5,
                            color: ColorConstants.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _ProgressRow(
                          icon: Icons.calendar_today_rounded,
                          iconColor: ColorConstants.primary,
                          label: 'Jours de présence',
                          current: ((_stats?['jours_presents'] ?? 0) as num).toInt(),
                          total: ((_stats?['jours_attendus'] ?? 1) as num).toInt(),
                        ),
                        const SizedBox(height: 10),
                        _ProgressRow(
                          icon: Icons.checklist_rounded,
                          iconColor: ColorConstants.success,
                          label: 'Missions complétées',
                          current: ((_stats?['missions_completees'] ?? 0) as num).toInt(),
                          total: ((_stats?['missions_totales'] ?? 1) as num).toInt(),
                        ),
                        const SizedBox(height: 10),
                        _ProgressRow(
                          icon: Icons.workspace_premium_outlined,
                          iconColor: const Color(0xFF7F77DD),
                          label: 'Compétences validées',
                          current:
                              ((_stats?['competences_validees'] ?? 0) as num).toInt(),
                          total: ((_stats?['competences_totales'] ?? 1) as num).toInt(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Covoiturage ----------
            const SizedBox(height: 22),
            const Text('Covoiturage',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorConstants.textPrimary)),
            const SizedBox(height: 10),
            _CovoiturageCard(
              reservation: _prochaineReservation,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CovoiturageHomeScreen())),
            ),
          ],

          // ---------- Raccourcis ----------
          const SizedBox(height: 22),
          const Text('Raccourcis',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 10),
          Row(
            children: [
              _ShortcutTile(
                icon: Icons.menu_book_outlined,
                label: ' Carnets',
                onTap: () async {
                  if (!_hasCarnet) {
                    final cree = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CarnetCreationPage()),
                    );
                    if (cree == true) _loadDashboard();
                  } else {
                    _openCarnetList();
                  }
                },
              ),
              const SizedBox(width: 10),
              _ShortcutTile(
                icon: Icons.directions_car_outlined,
                label: 'Covoiturage',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CovoiturageHomeScreen())),
              ),
              const SizedBox(width: 10),
              _ShortcutTile(
                icon: Icons.chat_bubble_outline,
                label: 'Messages',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConversationsScreen())),
              ),
            ],
          ),

          // ---------- Activités récentes ----------
          if (_hasCarnet) ...[
            const SizedBox(height: 22),
            const Text('Activités récentes',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorConstants.textPrimary)),
            const SizedBox(height: 10),
            if ((_stats?['activites_recentes'] as List?)?.isEmpty ?? true)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucune activité pour le moment.',
                    style: TextStyle(
                        fontSize: 12.5, color: ColorConstants.textSecondary)),
              )
            else
              ...List.generate((_stats!['activites_recentes'] as List).length,
                  (i) {
                final a = (_stats!['activites_recentes'] as List)[i]
                    as Map<String, dynamic>;
                final style = _activityStyle(a['type'] as String? ?? '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ActivityTile(
                    icon: style.icon,
                    iconColor: style.color,
                    bg: style.color,
                    title: a['title'] as String? ?? '',
                    subtitle: (a['subtitle'] as String?)?.isNotEmpty == true
                        ? a['subtitle'] as String
                        : '—',
                    time: _timeAgo(a['date'] as String?),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Item d'action du bottom sheet "Photo de profil"
// ============================================================
class _PhotoActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  const _PhotoActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: titleColor ?? ColorConstants.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Bannière geofencing
// ============================================================
class _GeofencingBanner extends StatelessWidget {
  final VoidCallback onActivate;
  const _GeofencingBanner({required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColorConstants.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ColorConstants.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorConstants.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off_rounded,
                color: ColorConstants.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Géolocalisation en arrière-plan inactive',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: ColorConstants.error)),
                const SizedBox(height: 3),
                const Text(
                    'Activez la localisation pour permettre le pointage automatique.',
                    style: TextStyle(
                        fontSize: 11.5, color: ColorConstants.textSecondary)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: onActivate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.error,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.my_location_rounded, size: 16),
                  label:
                      const Text('Activer', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Carte de statut (rattachement / pointage / fin de journée)
// ============================================================
class _StatusMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String value;
  final String? subtitle;
  final Color valueColor;

  const _StatusMiniCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.valueColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                    color: iconBg.withValues(alpha: 0.14),
                    shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: iconBg),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 11, color: ColorConstants.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.bold, color: valueColor),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 10.5, color: ColorConstants.textSecondary)),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Ligne de progression (icône + label + barre + %)
// ============================================================
class _ProgressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int current;
  final int total;

  const _ProgressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11.5, color: ColorConstants.textSecondary)),
              const SizedBox(height: 2),
              Text('$current / $total',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.textPrimary)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor:
                  ColorConstants.textSecondary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(ratio * 100).round()}%',
            style: const TextStyle(
                fontSize: 11.5, color: ColorConstants.textSecondary)),
      ],
    );
  }
}

// ============================================================
// Carte covoiturage
// ============================================================
class _CovoiturageCard extends StatelessWidget {
  final Map<String, dynamic>? reservation;
  final VoidCallback onTap;

  const _CovoiturageCard({required this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (reservation == null) {
      return AppCard(
        onTap: onTap,
        child: const Row(
          children: [
            Icon(Icons.directions_car_outlined, color: ColorConstants.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text('Aucun trajet réservé — voir les trajets disponibles',
                  style: TextStyle(
                      fontSize: 13, color: ColorConstants.textSecondary)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: ColorConstants.textSecondary),
          ],
        ),
      );
    }

    final trajet = reservation!['trajet'] as Map<String, dynamic>?;
    final depart = trajet?['depart'] as String? ?? '';
    final arrivee = trajet?['arrivee'] as String? ?? '';
    final heure = trajet?['heure_depart'] as String? ?? '';

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ColorConstants.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_car_rounded,
                    color: ColorConstants.success, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prochain trajet réservé',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: ColorConstants.success)),
                    const SizedBox(height: 2),
                    Text(heure.isNotEmpty ? heure : 'Réservation confirmée',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: ColorConstants.textPrimary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: ColorConstants.textSecondary),
            ],
          ),
          if (depart.isNotEmpty || arrivee.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 50),
                Icon(Icons.circle,
                    size: 8,
                    color: ColorConstants.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('$depart  →  $arrivee',
                      style: const TextStyle(
                          fontSize: 12, color: ColorConstants.textSecondary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Raccourci
// ============================================================
class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ShortcutTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: ColorConstants.primary),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.primary)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Activité récente
// ============================================================
class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback? onTap;

  // ✅ CORRECTION : Utiliser 'required' pour tous les paramètres
  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.time,
  }) : onTap = null;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: ColorConstants.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
          Text(time,
              style: const TextStyle(
                  fontSize: 11, color: ColorConstants.textSecondary)),
        ],
      ),
    );
  }
}
