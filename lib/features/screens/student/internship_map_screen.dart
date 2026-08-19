import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class InternshipMapScreen extends StatefulWidget {
  const InternshipMapScreen({super.key});

  @override
  State<InternshipMapScreen> createState() => _InternshipMapScreenState();
}

class _InternshipMapScreenState extends State<InternshipMapScreen> {
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();

  List<dynamic> _stages = [];
  bool _isLoading = true;
  String? _error;
  LatLng _myPos = const LatLng(48.8566, 2.3522); // Paris par défaut
  bool _hasPos = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Obtenir ma position
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        );
        if (mounted) {
          setState(() {
            _myPos = LatLng(pos.latitude, pos.longitude);
            _hasPos = true;
          });
          _mapController.move(_myPos, 12);
        }
      } catch (_) {}

      // 2. Charger les stages
      final data = await _api.getCarteStages();
      if (mounted) {
        setState(() {
          _stages = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger la carte';
          _isLoading = false;
        });
      }
    }
  }

  void _showStageInfo(Map<String, dynamic> stage) {
    final name = '${stage['prenom'] ?? ''} ${stage['nom'] ?? ''}'.trim();
    final ecole = stage['ecole'] ?? 'Établissement inconnu';
    final photo = stage['photo_url'];

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
                  radius: 28,
                  backgroundImage: photo != null ? NetworkImage(photo) : null,
                  child: photo == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(ecole, style: const TextStyle(color: ColorConstants.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorConstants.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('EN STAGE',
                    style: TextStyle(color: ColorConstants.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoRow(Icons.location_on_outlined, stage['lieu_stage_adresse'] ?? 'Lieu non précisé'),
            const SizedBox(height: 12),
            _infoRow(Icons.school_outlined, stage['filiere'] ?? 'Filière non précisée'),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Contacter pour entraide',
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Messagerie directe bientôt disponible !')),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ColorConstants.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: ColorConstants.textPrimary))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des Stagiaires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: ColorConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_hasPos) _mapController.move(_myPos, 14);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myPos,
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.stagelink.app',
              ),
              MarkerLayer(
                markers: [
                  if (_hasPos)
                    Marker(
                      point: _myPos,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 36),
                    ),
                  ..._stages.map((s) {
                    final lat = (s['lieu_stage_lat'] as num).toDouble();
                    final lng = (s['lieu_stage_lng'] as num).toDouble();
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 45,
                      height: 45,
                      child: GestureDetector(
                        onTap: () => _showStageInfo(s),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: ColorConstants.primary, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.work, color: ColorConstants.primary, size: 20),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white70,
              child: Text(_error!, style: const TextStyle(color: ColorConstants.error)))),
        ],
      ),
    );
  }
}
