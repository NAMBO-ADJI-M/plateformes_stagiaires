import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/geofencing_service.dart';
import 'home_screen.dart';
import 'pointage_screen.dart';
import 'carnet_screen.dart';
import 'trajet_screen.dart';
import 'profile_student_screen.dart';

/// Coquille de navigation de l'espace stagiaire.
/// Onglets : Accueil / Pointage / Carnet / Trajet / Profil.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(
        onNavigateToPointage: () => setState(() => _index = 1),
        onNavigateToCarnet: () => setState(() => _index = 2),
        onNavigateToTrajet: () => setState(() => _index = 3),
        onNavigateToProfil: () => setState(() => _index = 4),
      ),
      const PointageScreen(),
      const CarnetScreen(),
      const TrajetScreen(),
      const ProfileStudentScreen(),
    ];
    _initGeofencing();
  }

  static const _items = [
    _NavItem(
        icon: Icons.home_rounded,
        label: 'Accueil',
        color: ColorConstants.primaryLight),
    _NavItem(
        icon: Icons.access_time_rounded,
        label: 'Pointage',
        color: ColorConstants.primaryLight),
    _NavItem(
        icon: Icons.menu_book_rounded,
        label: 'Carnet',
        color: ColorConstants.primaryLight),
    _NavItem(
        icon: Icons.directions_car_rounded,
        label: 'Trajet',
        color: ColorConstants.amber),
    _NavItem(
        icon: Icons.person_rounded,
        label: 'Profil',
        color: ColorConstants.primaryLight),
  ];

  Future<void> _initGeofencing() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) return;

      final carnets = await ApiService().getCarnets();
      if (carnets.isEmpty) return;

      final carnet = carnets.firstWhere(
        (c) => c['statut'] == 'EN_COURS',
        orElse: () => carnets.first,
      ) as Map<String, dynamic>;

      final lat = carnet['geofence_lat'];
      final lng = carnet['geofence_lng'];
      if (lat == null || lng == null) return;

      await GeofencingService().start(
        carnetId: carnet['id'] as String,
        lat: (lat as num).toDouble(),
        lng: (lng as num).toDouble(),
        rayonMetres: ((carnet['geofence_rayon'] ?? 100) as num).toInt(),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: ColorConstants.cardBackground,
            border: Border(top: BorderSide(color: ColorConstants.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == _index;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _index = i),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: active
                              ? item.color.withValues(alpha: 0.10)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          size: 19,
                          color: active ? item.color : ColorConstants.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: active ? item.color : ColorConstants.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;
  const _NavItem({required this.icon, required this.label, required this.color});
}
