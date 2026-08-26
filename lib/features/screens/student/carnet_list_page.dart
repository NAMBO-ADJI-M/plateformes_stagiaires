import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';
import '../../widgets/common_widgets.dart';
import 'carnet_creation_page.dart';
import 'carnet_screen.dart';

class CarnetListPage extends StatefulWidget {
  const CarnetListPage({super.key});

  @override
  State<CarnetListPage> createState() => _CarnetListPageState();
}

class _CarnetListPageState extends State<CarnetListPage> {
  final ApiService _api = ApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCarnets();
  }

  Future<List<Map<String, dynamic>>> _loadCarnets() async {
    final carnets = await _api.getCarnets();
    return carnets.cast<Map<String, dynamic>>();
  }

  Future<void> _reload() async {
    setState(() => _future = _loadCarnets());
    await _future;
  }

  void _ouvrirCarnet(Map<String, dynamic> carnet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarnetScreen(carnetId: carnet['id']?.toString()),
      ),
    ).then((_) => _reload());
  }

  Future<void> _creerCarnet() async {
    final cree = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CarnetCreationPage()),
    );
    if (cree == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        title: const Text('Mes carnets de stage'),
        backgroundColor: Colors.white,
        foregroundColor: ColorConstants.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Une erreur est survenue.';
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.wifi_off_rounded, size: 36, color: ColorConstants.textSecondary),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Center(child: TextButton(onPressed: _reload, child: const Text('Réessayer'))),
                ],
              );
            }

            final carnets = snapshot.data ?? [];

            if (carnets.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.menu_book_outlined, size: 40, color: ColorConstants.textSecondary),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucun carnet de stage pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorConstants.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: _creerCarnet,
                      child: const Text('Créer mon premier carnet'),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: carnets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = carnets[i];
                final rattache =
                    c['entreprise_id'] != null && c['autorisation_suivi'] == true;
                final poste = c['poste'] as String? ?? '';
                final entreprise = c['entreprise_nom'] as String? ?? '';
                final statut = c['statut'] as String? ?? '';
                final dateCreation = _formatDateHeureCreation(c['date_creation'] as String?);

                return AppCard(
                  onTap: () => _ouvrirCarnet(c),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: (rattache ? ColorConstants.success : ColorConstants.accentOrange)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: rattache ? ColorConstants.success : ColorConstants.accentOrange,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              poste.isNotEmpty ? poste : 'Stage',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: ColorConstants.textPrimary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              entreprise.isNotEmpty ? entreprise : 'Entreprise non renseignée',
                              style: const TextStyle(fontSize: 12, color: ColorConstants.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rattache ? 'Rattaché' : 'En attente de rattachement',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: rattache ? ColorConstants.success : ColorConstants.accentOrange,
                              ),
                            ),
                            if (dateCreation != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 12, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Créé le $dateCreation',
                                    style: TextStyle(
                                        fontSize: 10.5, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (statut == 'ARCHIVE')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Archivé',
                              style: TextStyle(fontSize: 10.5, color: ColorConstants.textSecondary)),
                        )
                      else
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        onPressed: _creerCarnet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// Formatage "date à heure" pour l'affichage de la date de création
// (ex. "12 août 2026 à 14h30")
// ============================================================
String? _formatDateHeureCreation(String? iso) {
  if (iso == null) return null;
  final d = DateTime.tryParse(iso);
  if (d == null) return null;

  const mois = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  final heure = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${mois[d.month - 1]} ${d.year} à ${heure}h$minute';
}
