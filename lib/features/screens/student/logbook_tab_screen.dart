import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';
import 'logbook_screen.dart';
import 'carnet_creation_page.dart';

/// Contenu de l'onglet "Logbook" de la bottom navigation.
/// Ouvre directement le carnet en cours (le plus pertinent),
/// sans passer par la liste — celle-ci reste accessible via
/// la carte "Progression" du dashboard.
class LogbookTabScreen extends StatefulWidget {
  const LogbookTabScreen({super.key});

  @override
  State<LogbookTabScreen> createState() => _LogbookTabScreenState();
}

class _LogbookTabScreenState extends State<LogbookTabScreen> {
  final ApiService _api = ApiService();
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCarnetPrincipal();
  }

  Future<Map<String, dynamic>?> _loadCarnetPrincipal() async {
    final carnets = (await _api.getCarnets()).cast<Map<String, dynamic>>();
    if (carnets.isEmpty) return null;
    return carnets.firstWhere(
      (c) => c['statut'] == 'EN_COURS',
      orElse: () => carnets.first,
    );
  }

  Future<void> _reload() async {
    setState(() => _future = _loadCarnetPrincipal());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : 'Une erreur est survenue.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 36, color: ColorConstants.textSecondary),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _reload, child: const Text('Réessayer')),
                ],
              ),
            ),
          );
        }

        final carnet = snapshot.data;

        if (carnet == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_outlined, size: 40, color: ColorConstants.textSecondary),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucun carnet de stage pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorConstants.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final cree = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const CarnetCreationPage()),
                      );
                      if (cree == true) _reload();
                    },
                    child: const Text('Créer mon carnet'),
                  ),
                ],
              ),
            ),
          );
        }

        final rattache =
            carnet['entreprise_id'] != null && carnet['autorisation_suivi'] == true;

        return LogbookScreen(
          carnetId: carnet['id'] as String,
          estRattache: rattache,
        );
      },
    );
  }
}