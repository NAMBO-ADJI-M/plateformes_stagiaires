import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';
import '../../widgets/common_widgets.dart';
import 'recherche_trajet_screen.dart';
import 'create_trajet_screen.dart';
import 'trajet_details_screen.dart';
import 'reservations_screen.dart';

/// Reproduit covoiturage-home.png : toggle géolocalisation, mini-carte,
/// barre de recherche (pousse vers RechercheTrajetScreen), tabs
/// Proposer/Rejoindre, liste des trajets disponibles.
class CovoiturageHomeScreen extends StatefulWidget {
  const CovoiturageHomeScreen({super.key});

  @override
  State<CovoiturageHomeScreen> createState() => _CovoiturageHomeScreenState();
}

class _CovoiturageHomeScreenState extends State<CovoiturageHomeScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  bool _geoloc = false;
  bool _rejoindre = true;
  bool _locatingInProgress = false;

  List<dynamic> _trajets = [];
  bool _chargement = true;
  String? _erreur;
  LatLng _myPos = const LatLng(45.764043, 4.835659); // Lyon par défaut
  bool _hasPrecisePos = false; // true = position GPS réelle obtenue

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _chargerTrajets();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// Active/désactive le suivi GPS en temps réel
  Future<void> _toggleGeoloc(bool enabled) async {
    if (enabled) {
      // Vérifier / demander la permission
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activez la localisation dans les paramètres de votre appareil.'),
            ),
          );
          await Geolocator.openLocationSettings();
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de localisation refusée. Activez-la dans les réglages.'),
            ),
          );
        }
        return;
      }

      setState(() {
        _geoloc = true;
        _locatingInProgress = true;
      });

      // Position initiale rapide
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _myPos = LatLng(pos.latitude, pos.longitude);
            _hasPrecisePos = true;
            _locatingInProgress = false;
          });
          _mapController.move(_myPos, 15);
        }
      } catch (_) {
        if (mounted) setState(() => _locatingInProgress = false);
      }

      // Flux de mises à jour continues
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // mise à jour tous les 10 mètres
        ),
      ).listen((Position pos) {
        if (mounted) {
          setState(() {
            _myPos = LatLng(pos.latitude, pos.longitude);
            _hasPrecisePos = true;
          });
          // Centrer la carte sur la nouvelle position
          _mapController.move(_myPos, _mapController.camera.zoom);
        }
      });
    } else {
      // Désactiver
      await _positionStream?.cancel();
      _positionStream = null;
      setState(() {
        _geoloc = false;
        _hasPrecisePos = false;
        _myPos = const LatLng(45.764043, 4.835659);
      });
    }
  }

  void _showTrajetPopup(Map<String, dynamic> trajet) {
    final chauffeur = trajet['chauffeur'] as Map<String, dynamic>?;
    final name = chauffeur?['nom'] as String? ?? 'Conducteur';
    final priceVal = (trajet['tarif'] as dynamic)?.toDouble() ?? 0.0;
    final price = priceVal == 0 ? 'Gratuit' : '${priceVal.toStringAsFixed(2)} €';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(chauffeur?['photo_profil'] ?? 'https://i.pravatar.cc/150?u=$name'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(trajet['lieu_depart'] ?? '', style: const TextStyle(color: ColorConstants.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: ColorConstants.primary, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Voir le trajet complet',
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => TrajetDetailsScreen(trajet: trajet)));
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _chargerTrajets() async {
    setState(() => _chargement = true);
    try {
      final trajets = await _apiService.getTrajets();
      if (!mounted) return;
      setState(() {
        _trajets = trajets;
        _chargement = false;
        _erreur = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.userFriendlyMessage;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Impossible de charger les trajets';
        _chargement = false;
      });
    }
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RechercheTrajetScreen()),
    );
  }

  void _openCreateTrajet() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTrajetScreen()),
    );
    if (created == true) {
      _chargerTrajets();
    }
  }

  void _openReservations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReservationsScreen()),
    );
  }

  Widget _buildSkeletonList() {
    return Column(
      children: List.generate(
          3,
          (index) => const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Skeleton(height: 36, width: 36, borderRadius: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Skeleton(height: 14, width: 100),
                                SizedBox(height: 4),
                                Skeleton(height: 10, width: 60),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Skeleton(height: 12, width: double.infinity),
                      SizedBox(height: 6),
                      Skeleton(height: 12, width: double.infinity),
                    ],
                  ),
                ),
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.background,
        elevation: 0,
        foregroundColor: ColorConstants.textPrimary,
        title: const Text('Covoiturage Étudiant',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Messages & Réservations',
            onPressed: _openReservations,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Mes réservations',
            onPressed: _openReservations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _chargerTrajets,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _geoloc ? Icons.location_on : Icons.location_off_outlined,
                      color: _geoloc ? ColorConstants.primary : ColorConstants.textSecondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _geoloc ? 'Géolocalisation activée' : 'Autoriser la géolocalisation',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: _geoloc
                                ? ColorConstants.textPrimary
                                : ColorConstants.textSecondary,
                            fontWeight: _geoloc ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (_locatingInProgress)
                          const Text(
                            'Localisation en cours...',
                            style: TextStyle(fontSize: 11, color: ColorConstants.primary),
                          )
                        else if (_geoloc && _hasPrecisePos)
                          Text(
                            '${_myPos.latitude.toStringAsFixed(5)}, ${_myPos.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 10.5, color: ColorConstants.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  if (_locatingInProgress)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch(
                      value: _geoloc,
                      activeThumbColor: ColorConstants.primary,
                      onChanged: _toggleGeoloc,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Carte interactive avec suivi GPS temps réel
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _myPos,
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.stagelink.app',
                      ),
                      MarkerLayer(
                        markers: [
                          // Ma position (visible uniquement si géoloc activée avec précision)
                          if (_geoloc && _hasPrecisePos)
                            Marker(
                              point: _myPos,
                              width: 48,
                              height: 48,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Halo de précision
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue.withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: Colors.blue.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  // Point GPS
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.blue,
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Marqueurs des trajets disponibles
                          ..._trajets
                              .where((t) => t['depart_lat'] != null)
                              .map((t) => Marker(
                                    point: LatLng(
                                      (t['depart_lat'] as num).toDouble(),
                                      (t['depart_lng'] as num).toDouble(),
                                    ),
                                    width: 50,
                                    height: 50,
                                    child: GestureDetector(
                                      onTap: () => _showTrajetPopup(t),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: ColorConstants.primary, width: 2),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black26, blurRadius: 4)
                                          ],
                                        ),
                                        child: const Icon(Icons.directions_car,
                                            color: ColorConstants.primary, size: 24),
                                      ),
                                    ),
                                  )),
                        ],
                      ),
                    ],
                  ),
                  // Bouton "Centrer sur ma position"
                  if (_geoloc && _hasPrecisePos)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => _mapController.move(_myPos, 15),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: const Icon(Icons.my_location_rounded,
                              color: ColorConstants.primary, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _openSearch,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: ColorConstants.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ColorConstants.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search,
                        color: ColorConstants.textSecondary, size: 20),
                    SizedBox(width: 10),
                    Text('Rechercher un trajet...',
                        style: TextStyle(
                            fontSize: 13.5,
                            color: ColorConstants.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ColorConstants.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _SegmentButton(
                    label: 'Proposer',
                    selected: !_rejoindre,
                    onTap: () => setState(() => _rejoindre = false),
                  ),
                  _SegmentButton(
                    label: 'Rejoindre',
                    selected: _rejoindre,
                    onTap: () => setState(() => _rejoindre = true),
                  ),
                ],
              ),
            ),
              const SizedBox(height: 18),

            if (!_rejoindre) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: EmptyState(
                    icon: Icons.directions_car_filled_outlined,
                    title: 'Vous avez un véhicule ?',
                    subtitle: 'Proposez vos places libres aux autres étudiants.',
                    action: PrimaryButton(
                      label: 'Créer un trajet',
                      icon: Icons.add_circle_outline,
                      onPressed: _openCreateTrajet,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Text('Trajets disponibles',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ColorConstants.textPrimary)),
              const SizedBox(height: 10),

              if (_chargement)
                _buildSkeletonList()
              else if (_erreur != null)
                Center(child: Text(_erreur!))
              else if (_trajets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: EmptyState(
                    icon: Icons.no_sim_outlined,
                    title: 'Aucun trajet',
                    subtitle: 'Il n\'y a pas encore de trajet disponible pour cette destination.',
                  ),
                )
              else
                ..._trajets.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TrajetCard(
                        trajet: t,
                        onTap: () async {
                          final reserved = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrajetDetailsScreen(trajet: t),
                            ),
                          );
                          if (reserved == true) {
                            _chargerTrajets();
                          }
                        },
                      ),
                    )),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                selected ? ColorConstants.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: selected
                    ? ColorConstants.primary
                    : ColorConstants.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _TrajetCard extends StatelessWidget {
  final Map<String, dynamic> trajet;
  final VoidCallback onTap;

  const _TrajetCard({required this.trajet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chauffeur = trajet['chauffeur'] as Map<String, dynamic>?;
    final name = chauffeur?['nom'] as String? ?? 'Conducteur';
    final avatarUrl = chauffeur?['photo_profil'] as String? ??
        'https://i.pravatar.cc/150?u=$name';

    final dateDepartStr = trajet['date_depart'] as String?;
    DateTime? dateDepart;
    if (dateDepartStr != null) {
      dateDepart = DateTime.tryParse(dateDepartStr);
    }
    final departHeure =
        dateDepart != null ? DateFormat('HH:mm').format(dateDepart) : '--:--';

    final from = trajet['lieu_depart'] as String? ?? '—';
    final to = trajet['lieu_arrivee'] as String? ?? '—';
    final places = trajet['places_disponibles']?.toString() ?? '0';
    final priceVal = (trajet['tarif'] as dynamic)?.toDouble() ?? 0.0;
    final price = priceVal == 0 ? 'Gratuit' : '${priceVal.toStringAsFixed(2)} €';
    final isFree = priceVal == 0;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrl)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: ColorConstants.textPrimary)),
                    Text('Départ à $departHeure',
                        style: const TextStyle(
                            fontSize: 12, color: ColorConstants.textSecondary)),
                  ],
                ),
              ),
              StatusPill(label: 'Disponible', color: ColorConstants.info),
            ],
          ),
          const SizedBox(height: 12),
          _RouteLine(label: from, dotColor: ColorConstants.primary),
          const SizedBox(height: 6),
          _RouteLine(label: to, dotColor: ColorConstants.accentOrange),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$places places disponibles',
                  style: const TextStyle(
                      fontSize: 12.5, color: ColorConstants.textSecondary)),
              Text(price,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isFree
                          ? ColorConstants.success
                          : ColorConstants.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String label;
  final Color dotColor;
  const _RouteLine({required this.label, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: ColorConstants.textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
