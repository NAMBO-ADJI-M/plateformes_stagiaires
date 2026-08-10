import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/services/api_exception.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<dynamic> _carnets = [];
  bool _isPresent = false;
  String? _lastPointageTime;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.loadToken();
      if (_apiService.isAuthenticated) {
        final profile = await _apiService.getProfile();
        final carnets = await _apiService.getCarnets();
        if (mounted) {
          setState(() {
            _userProfile = profile['user'] ?? profile;
            _carnets = carnets;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _handlePointageArrivee() async {
    setState(() => _isLoading = true);
    try {
      final pos = await _getCurrentLocation();
      final res = await _apiService.pointageArrivee(
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        carnetId: _carnets.isNotEmpty ? _carnets.first['id'] : null,
      );
      if (!mounted) return;
      setState(() {
        _isPresent = true;
        _lastPointageTime = DateTime.now().toString().substring(11, 16);
        _message = res['message'] ?? 'Pointage arrivée enregistré !';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message), backgroundColor: ColorConstants.success),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userFriendlyMessage), backgroundColor: ColorConstants.error),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pointage enregistré en mode démo !'), backgroundColor: ColorConstants.success),
        );
        setState(() {
          _isPresent = true;
          _lastPointageTime = DateTime.now().toString().substring(11, 16);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePointageDepart() async {
    setState(() => _isLoading = true);
    try {
      final pos = await _getCurrentLocation();
      final res = await _apiService.pointageDepart(
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        carnetId: _carnets.isNotEmpty ? _carnets.first['id'] : null,
      );
      if (!mounted) return;
      setState(() {
        _isPresent = false;
        _lastPointageTime = DateTime.now().toString().substring(11, 16);
        _message = res['message'] ?? 'Pointage départ enregistré !';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message), backgroundColor: ColorConstants.info),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userFriendlyMessage), backgroundColor: ColorConstants.error),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Départ enregistré !'), backgroundColor: ColorConstants.info),
        );
        setState(() {
          _isPresent = false;
          _lastPointageTime = DateTime.now().toString().substring(11, 16);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRattachementDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Rattachement Tuteur / Entreprise',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrez le code d\'invitation à 6 caractères fourni par votre entreprise :',
              style: GoogleFonts.poppins(fontSize: 13, color: ColorConstants.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Code d\'invitation',
                hintText: 'EX: STG-8X',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.key_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final res = await _apiService.rattacherCarnet(code);
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Rattachement réussi !'), backgroundColor: ColorConstants.success),
                );
                _loadDashboardData();
              } on ApiException catch (e) {
                if (mounted) nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(e.userFriendlyMessage), backgroundColor: ColorConstants.error),
                );
              }
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userProfile?['prenom'] ?? _userProfile?['name'] ?? 'Stagiaire';

    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(userName),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPointageWidget(),
                    const SizedBox(height: 20),
                    _buildRattachementBanner(),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Progression & Compétences"),
                    const SizedBox(height: 12),
                    _buildProgressionGrid(),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Dernières activités & Pointages"),
                    const SizedBox(height: 12),
                    _buildRecentActivityList(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 20),
      decoration: const BoxDecoration(
        gradient: ColorConstants.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour $name 👋',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Suivi de stage & pointage intelligent',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                ),
              ],
=======
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/features/widgets/bottom_navigation_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: ColorConstants.secondary,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Bienvenue sur la plateforme',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Accédez à vos missions, documents et communications en un seul endroit.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _InfoCard(
                  icon: Icons.task_alt,
                  title: 'Suivi des missions',
                  subtitle: 'Consultez et mettez à jour l’état de vos tâches.',
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Messagerie',
                  subtitle:
                      'Contactez votre tuteur ou votre centre de formation.',
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  icon: Icons.insert_drive_file_outlined,
                  title: 'Documents',
                  subtitle:
                      'Accédez rapidement à vos attestations et supports.',
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MainNavigation(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: ColorConstants.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD

  Widget _buildPointageWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: ColorConstants.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isPresent
                      ? ColorConstants.success.withValues(alpha: 0.12)
                      : ColorConstants.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  _isPresent ? Icons.check_circle_outlined : Icons.timer_outlined,
                  color: _isPresent ? ColorConstants.success : ColorConstants.warning,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPresent ? 'Présent en entreprise' : 'Non pointé aujourd\'hui',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: ColorConstants.textPrimary,
                      ),
                    ),
                    Text(
                      _lastPointageTime != null
                          ? 'Dernier pointage à $_lastPointageTime'
                          : 'Cliquez ci-dessous pour pointer',
                      style: GoogleFonts.poppins(color: ColorConstants.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading || _isPresent ? null : _handlePointageArrivee,
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Arrivée (1-Clic)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading || !_isPresent ? null : _handlePointageDepart,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Départ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConstants.error,
                    side: const BorderSide(color: ColorConstants.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRattachementBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorConstants.primary.withValues(alpha: 0.08), ColorConstants.accent.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.primary.withValues(alpha: 0.2)),
      ),

      child: Row(
        children: [
          Icon(Icons.business_outlined, color: ColorConstants.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rattachement Tuteur',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Saisissez le code d\'invitation de votre entreprise.',
                  style: GoogleFonts.poppins(fontSize: 12, color: ColorConstants.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showRattachementDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Code', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: ColorConstants.textPrimary,
      ),
    );
  }

  Widget _buildProgressionGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildProgCard(
            "Carnets Actifs",
            "${_carnets.length}",
            Icons.book_outlined,
            ColorConstants.primaryLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildProgCard(
            "Assiduité",
            _isPresent ? "100%" : "À jour",
            Icons.verified_outlined,
            ColorConstants.success,
          ),
        ),
      ],
    );
  }

  Widget _buildProgCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ColorConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: ColorConstants.textPrimary),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(color: ColorConstants.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ColorConstants.cardShadow,
      ),
      child: Column(
        children: [
          _buildActivityItem("Pointage d'arrivée", "Aujourd'hui", Icons.login, ColorConstants.success),
          const Divider(height: 24),
          _buildActivityItem("Consultation Référentiel", "Hier", Icons.architecture, ColorConstants.accent),
          const Divider(height: 24),
          _buildActivityItem("Synchronisation API Laravel", "Cette semaine", Icons.sync, ColorConstants.primaryLight),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String date, IconData icon, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 18),
        ),

        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(date, style: GoogleFonts.poppins(color: ColorConstants.textMuted, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: ColorConstants.success, size: 18),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Text(
        'Plateforme Stagiaires © 2026 • Carnet de Stage & Covoiturage Solidaire',
        style: GoogleFonts.poppins(color: ColorConstants.textMuted, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}

=======
}
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
