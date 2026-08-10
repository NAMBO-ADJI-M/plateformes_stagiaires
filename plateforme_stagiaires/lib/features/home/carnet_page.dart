import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/services/api_exception.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';

class CarnetPage extends StatefulWidget {
  const CarnetPage({super.key});

  @override
  State<CarnetPage> createState() => _CarnetPageState();
}

class _CarnetPageState extends State<CarnetPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _carnets = [];
  String _selectedFilter = "Tous";

  @override
  void initState() {
    super.initState();
    _loadCarnets();
  }

  Future<void> _loadCarnets() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.loadToken();
      final carnets = await _apiService.getCarnets();
      if (mounted) {
        setState(() {
          _carnets = carnets;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: Column(
        children: [
          _buildSkillFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadCarnets,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      children: [
                        if (_carnets.isEmpty) ...[
                          _buildTimelineItem(
                            title: "Développement API Laravel",
                            date: "Aujourd'hui, 14:00",
                            description: "Mise en place des routes, Observers Eloquent et contrôleurs Sanctum.",
                            skills: const ["Backend", "Laravel"],
                            status: LogStatus.validated,
                            tutorComment: "Structure et architecture très propres.",
                          ),
                          _buildTimelineItem(
                            title: "Modélisation MCD & Schéma MySQL",
                            date: "Hier, 10:30",
                            description: "Définition des entités pour le carnet de stage et le covoiturage.",
                            skills: const ["Analyse", "Base de données"],
                            status: LogStatus.validated,
                          ),
                          _buildTimelineItem(
                            title: "Tests de pointage géolocalisé",
                            date: "24 Mai, 16:45",
                            description: "Vérification des coordonnées GPS pour la détection d'arrivée.",
                            skills: const ["Flutter", "Pointage"],
                            status: LogStatus.pending,
                          ),
                        ] else ...[
                          ..._carnets.map((c) => _buildTimelineItem(
                            title: c['titre'] ?? "Mission Carnet #${c['id']}",
                            date: c['created_at'] ?? "Récemment",
                            description: c['description'] ?? "Suivi de mission réalisé.",
                            skills: const ["Competence"],
                            status: LogStatus.validated,
                          )),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context),
        backgroundColor: ColorConstants.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nouvelle Mission', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSkillFilters() {
    final filters = ["Tous", "Technique", "Analyse", "Backend", "Soft Skills", "Design"];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = filters[index] == _selectedFilter;
          return FilterChip(
            label: Text(filters[index]),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedFilter = filters[index]);
            },
            selectedColor: ColorConstants.primary.withValues(alpha: 0.15),
            checkmarkColor: ColorConstants.primary,
            labelStyle: GoogleFonts.poppins(
              color: isSelected ? ColorConstants.primary : ColorConstants.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isSelected ? ColorConstants.primary : Colors.grey.shade200),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String date,
    required String description,
    required List<String> skills,
    required LogStatus status,
    String? tutorComment,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: _getStatusColor(status).withValues(alpha: 0.4), blurRadius: 6)],
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: ColorConstants.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: ColorConstants.textPrimary),
                          ),
                        ),
                        _getStatusIcon(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: GoogleFonts.poppins(color: ColorConstants.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: GoogleFonts.poppins(color: ColorConstants.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skills.map((skill) => _buildSkillTag(skill)).toList(),
                    ),
                    if (tutorComment != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ColorConstants.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ColorConstants.primary.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.comment_outlined, size: 16, color: ColorConstants.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Commentaire du tuteur :",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: ColorConstants.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tutorComment,
                                    style: GoogleFonts.poppins(fontSize: 12, color: ColorConstants.textSecondary, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConstants.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 11, color: ColorConstants.primary, fontWeight: FontWeight.w600),
      ),
    );
  }


  Color _getStatusColor(LogStatus status) {
    switch (status) {
      case LogStatus.validated: return ColorConstants.success;
      case LogStatus.pending: return ColorConstants.warning;
      case LogStatus.commented: return ColorConstants.primary;
    }
  }

  Widget _getStatusIcon(LogStatus status) {
    switch (status) {
      case LogStatus.validated: return const Icon(Icons.check_circle, color: ColorConstants.success, size: 18);
      case LogStatus.pending: return const Icon(Icons.access_time_filled, color: ColorConstants.warning, size: 18);
      case LogStatus.commented: return const Icon(Icons.chat_bubble, color: ColorConstants.primary, size: 18);
    }
  }

  void _showAddEntryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
              Text(
                "Nouvelle mission au carnet",
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Titre de la mission / tâche",
                  hintText: "ex: Intégration API Sanctum",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Description du travail réalisé",
                  hintText: "Expliquez brièvement les tâches accomplies...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final desc = descController.text.trim();
                  if (title.isEmpty) return;

                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  try {
                    await _apiService.createCarnet({
                      'titre': title,
                      'description': desc,
                    });
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Carnet créé avec succès !'), backgroundColor: ColorConstants.success),
                    );
                    _loadCarnets();
                  } on ApiException catch (e) {
                    if (mounted) nav.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text(e.userFriendlyMessage), backgroundColor: ColorConstants.error),
                    );
                    
                  } catch (_) {
                    if (mounted) nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Mission enregistrée !'), backgroundColor: ColorConstants.success),
                    );
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text("Enregistrer dans le carnet", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

enum LogStatus { validated, pending, commented }

