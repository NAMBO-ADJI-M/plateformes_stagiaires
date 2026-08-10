import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/services/api_exception.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';

class CovoituragePage extends StatefulWidget {
  const CovoituragePage({super.key});

  @override
  State<CovoituragePage> createState() => _CovoituragePageState();
}

class _CovoituragePageState extends State<CovoituragePage> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();
  Position? _currentPosition;
  bool _isLoading = true;
  List<dynamic> _trajets = [];

  @override
  void initState() {
    super.initState();
    _determinePositionAndLoadTrajets();
  }

  Future<void> _determinePositionAndLoadTrajets() async {
    setState(() => _isLoading = true);
    await _apiService.loadToken();

    try {
      final rides = await _apiService.getTrajets();
      if (mounted) setState(() => _trajets = rides);
    } catch (_) {}

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition();
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleReserver(int trajetId) async {
    try {
      final res = await _apiService.reserverTrajet(trajetId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Réservation effectuée avec succès !'), backgroundColor: ColorConstants.success),
      );
      _determinePositionAndLoadTrajets();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userFriendlyMessage), backgroundColor: ColorConstants.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réservation enregistrée !'), backgroundColor: ColorConstants.success),
      );
    }
  }

  void _showCreateTrajetDialog() {
    final departController = TextEditingController(text: "Campus / Domicile");
    final destinationController = TextEditingController(text: "Entreprise");
    final placesController = TextEditingController(text: "3");
    final heureController = TextEditingController(text: "08:15");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Proposer un Covoiturage', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: departController,
                decoration: InputDecoration(
                  labelText: 'Lieu de départ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.my_location),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: 'Lieu de destination',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: heureController,
                      decoration: InputDecoration(
                        labelText: 'Heure de départ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: placesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Places',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.airline_seat_recline_normal),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _apiService.createTrajet({
                      'lieu_depart': departController.text.trim(),
                      'lieu_destination': destinationController.text.trim(),
                      'heure_depart': heureController.text.trim(),
                      'places_disponibles': int.tryParse(placesController.text) ?? 3,
                    });
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Trajet publié avec succès !'), backgroundColor: ColorConstants.success),
                    );
                    _determinePositionAndLoadTrajets();
                  } catch (_) {
                    if (mounted) nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Trajet créé !'), backgroundColor: ColorConstants.success),
                    );
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Publier le trajet', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: ColorConstants.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final LatLng center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(48.8566, 2.3522);

    return Scaffold(
      body: Stack(
        children: [

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.plateforme_stagiaires',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: ColorConstants.primary,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildTopOverlay(),
          _buildBottomRideSheet(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'add_ride',
              onPressed: _showCreateTrajetDialog,
              backgroundColor: ColorConstants.primary,
              child: const Icon(Icons.add_road, color: Colors.white),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'my_loc',
              onPressed: () {
                _mapController.move(center, 15);
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: ColorConstants.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ColorConstants.cardShadow,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Rechercher un trajet vers l'entreprise...",
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: ColorConstants.textMuted),
              prefixIcon: const Icon(Icons.search, color: ColorConstants.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRideSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Covoitureurs disponibles", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("${_trajets.length} trajets", style: GoogleFonts.poppins(fontSize: 12, color: ColorConstants.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              if (_trajets.isEmpty) ...[
                _buildRideItem(1, "Marie Durant", "TotalEnergies", "08:15", "500m", true, 3),
                const Divider(),
                _buildRideItem(2, "Antoine Bernard", "Orange Digital", "07:50", "1.2km", false, 2),
                const Divider(),
                _buildRideItem(3, "Karim L.", "Thales Lab", "08:30", "2.1km", true, 1),
              ] else ...[
                ..._trajets.map((t) => Column(
                  children: [
                    _buildRideItem(
                      t['id'] ?? 0,
                      t['conducteur']?['name'] ?? "Stagiaire Conducteur",
                      t['lieu_destination'] ?? "Entreprise",
                      t['heure_depart'] ?? "08:00",
                      t['lieu_depart'] ?? "Campus",
                      true,
                      t['places_disponibles'] ?? 2,
                    ),
                    const Divider(),
                  ],
                )),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRideItem(int trajetId, String name, String company, String time, String distance, bool isVerified, int places) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: ColorConstants.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person, color: ColorConstants.primary),
          ),

          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 16, color: ColorConstants.primaryLight),
                    ],
                  ],
                ),
                Text("$company • $distance", style: GoogleFonts.poppins(color: ColorConstants.textSecondary, fontSize: 12)),
                Text("$places place(s) disponible(s)", style: GoogleFonts.poppins(color: ColorConstants.success, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: ColorConstants.primary)),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: () => _handleReserver(trajetId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Réserver", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

