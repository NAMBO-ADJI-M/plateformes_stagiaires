import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/internship_service.dart';
import '../../../services/carpool_service.dart';
import '../../../services/api_exception.dart';
import '../../../services/pointage_event_bus.dart';
import '../../../services/geofencing_service.dart';
import '../../widgets/common_widgets.dart';
import 'trajet_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToPointage;
  final VoidCallback onNavigateToCarnet;
  final VoidCallback onNavigateToTrajet;
  final VoidCallback onNavigateToProfil;

  const HomeScreen({
    super.key,
    required this.onNavigateToPointage,
    required this.onNavigateToCarnet,
    required this.onNavigateToTrajet,
    required this.onNavigateToProfil,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final InternshipService _internshipService = InternshipService();
  final CarpoolService _carpoolService = CarpoolService();

  bool _isLoading = true;
  String _prenom = 'Stagiaire';
  String? _photoUrl;
  Map<String, dynamic>? _stats;
  List<dynamic> _activites = [];
  Map<String, dynamic>? _prochaineReservation;
  String? _activeCarnetId;

  // Liaison Entreprise
  String _autorisationStatut = 'INACTIVE';
  String? _entrepriseNom;
  LatLng? _currentPos;
  bool _isValidatingCode = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final profile = await _authService.getProfile();
      final carnets = await _internshipService.getCarnets();

      if (mounted) {
        setState(() {
          _prenom = profile['profile_data']?['prenom'] ?? 'Stagiaire';
          _photoUrl = profile['profile_data']?['photo_profil_url'];

          final auto = profile['autorisation_pointage'];
          if (auto != null) {
            _autorisationStatut = auto['statut'];
            _entrepriseNom = auto['entreprise_nom'];
          }
        });
      }

      if (carnets.isNotEmpty) {
        final carnet = carnets.firstWhere((c) => c['statut'] == 'EN_COURS', orElse: () => carnets.first);
        _activeCarnetId = carnet['id'];

        final results = await Future.wait([
          _internshipService.getCarnetStats(_activeCarnetId!),
          _carpoolService.getMesReservations(),
        ]);

        if (mounted) {
          setState(() {
            _stats = results[0] as Map<String, dynamic>;

            final reservations = results[1] as List<dynamic>;
            final aVenir = reservations.where((r) => r['statut'] != 'ANNULEE' && r['statut'] != 'TERMINEE').toList();
            _prochaineReservation = aVenir.isNotEmpty ? aVenir.first : null;

            _activites = _stats?['activites_recentes'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCodePopup() {
    final TextEditingController codeCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPopupState) => AlertDialog(
          backgroundColor: ColorConstants.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: ColorConstants.primary),
              const SizedBox(width: 10),
              const Text('Code de liaison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Saisissez le code d\'invitation ou de liaison envoyé par votre tuteur.',
                style: TextStyle(fontSize: 13, color: ColorConstants.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                maxLength: 8,
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  hintText: 'CODE8CH',
                  hintStyle: TextStyle(color: ColorConstants.textMuted.withValues(alpha: 0.3), letterSpacing: 4),
                  fillColor: ColorConstants.paper,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: _isValidatingCode ? null : () async {
                final code = codeCtrl.text.trim();
                if (code.isEmpty) return;
                setPopupState(() => _isValidatingCode = true);
                try {
                  // Étape 1 : Vérifier le code et récupérer les conditions
                  final info = await _internshipService.verifierCodeSuivi(code, carnetId: _activeCarnetId);
                  if (mounted) {
                    Navigator.pop(ctx);
                    _showReviewConditionsPopup(code, info);
                  }
                } catch (e) {
                  String msg = 'Code incorrect ou expiré.';
                  if (e is ApiException) msg = e.message;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                } finally {
                  setPopupState(() => _isValidatingCode = false);
                }
              },
              child: _isValidatingCode 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewConditionsPopup(String code, Map<String, dynamic> info) {
    final TextEditingController nomCtrl = TextEditingController(text: info['stagiaire_nom'] ?? '');
    final TextEditingController prenomCtrl = TextEditingController(text: info['stagiaire_prenom'] ?? '');
    final TextEditingController naissanceCtrl = TextEditingController();
    final TextEditingController adresseCtrl = TextEditingController();
    final TextEditingController telCtrl = TextEditingController(text: info['stagiaire_telephone'] ?? '');
    final TextEditingController ecoleCtrl = TextEditingController(text: info['etablissement_nom'] ?? '');
    final TextEditingController cursusCtrl = TextEditingController(text: info['cursus_rattachement'] ?? '');
    final TextEditingController anneeAcadCtrl = TextEditingController(text: info['stagiaire_annee_academique'] ?? '');
    final TextEditingController refNomCtrl = TextEditingController(text: info['referent_pedagogique_nom'] ?? '');
    final TextEditingController refContactCtrl = TextEditingController(text: info['referent_pedagogique_contact'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setPopupState) => AlertDialog(
          backgroundColor: ColorConstants.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Convention de stage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Offre de ${info['entreprise_nom']}', style: const TextStyle(fontSize: 13, color: ColorConstants.textSecondary)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('1. Informations Personnelles'),
                  _editableField('Nom', nomCtrl, Icons.person_outline),
                  const SizedBox(height: 12),
                  _editableField('Prénom', prenomCtrl, Icons.person_outline),
                  const SizedBox(height: 12),
                  _editableField('Téléphone personnel', telCtrl, Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _datePickerField('Date de naissance', naissanceCtrl, context, (date) => setPopupState(() => naissanceCtrl.text = date)),
                  const SizedBox(height: 12),
                  _editableField('Adresse personnelle', adresseCtrl, Icons.home_outlined),
                  
                  const SizedBox(height: 20),
                  _sectionTitle('2. Parcours Scolaire'),
                  _editableField('Établissement actuel', ecoleCtrl, Icons.school_outlined),
                  const SizedBox(height: 12),
                  _editableField('Cursus / Filière', cursusCtrl, Icons.layers_outlined),
                  const SizedBox(height: 12),
                  _editableField('Année académique (ex: 2024-2025)', anneeAcadCtrl, Icons.calendar_today_outlined),
                  
                  const SizedBox(height: 20),
                  _sectionTitle('3. Encadrement École'),
                  _editableField('Référent pédagogique (Nom)', refNomCtrl, Icons.person_search_outlined),
                  const SizedBox(height: 12),
                  _editableField('Contact référent (Email/Tel)', refContactCtrl, Icons.contact_mail_outlined),

                  const SizedBox(height: 20),
                  _sectionTitle('4. Détails du Poste (Lecture seule)'),
                  _readOnlyTile('Poste', info['poste']),
                  _readOnlyTile('Tuteur entreprise', info['tuteur_designe']),
                  Row(
                    children: [
                      Expanded(child: _readOnlyTile('Du', info['date_debut'])),
                      const SizedBox(width: 10),
                      Expanded(child: _readOnlyTile('Au', info['date_fin'])),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showTermsModal(info, naissanceCtrl.text, adresseCtrl.text, ecoleCtrl.text),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Voir les termes de la convention'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstants.primary,
                      side: const BorderSide(color: ColorConstants.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (nomCtrl.text.isEmpty || prenomCtrl.text.isEmpty || telCtrl.text.isEmpty || naissanceCtrl.text.isEmpty || ecoleCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir toutes les informations obligatoires.')));
                      return;
                    }
                    try {
                      final res = await _internshipService.validerLiaisonDefinitive(code, {
                        'entreprise_id': info['entreprise_id'],
                        'nom': nomCtrl.text.trim(),
                        'prenom': prenomCtrl.text.trim(),
                        'stagiaire_date_naissance': naissanceCtrl.text,
                        'stagiaire_adresse': adresseCtrl.text,
                        'stagiaire_telephone': telCtrl.text,
                        'etablissement_nom': ecoleCtrl.text,
                        'cursus_rattachement': cursusCtrl.text,
                        'stagiaire_annee_academique': anneeAcadCtrl.text.trim(),
                        'referent_pedagogique_nom': refNomCtrl.text,
                        'referent_pedagogique_contact': refContactCtrl.text,
                      }, carnetId: _activeCarnetId);

                      final String? autoId = res['autorisation_id']?.toString() ?? info['autorisation_id']?.toString();

                      if (mounted) {
                        Navigator.pop(ctx);
                        setState(() {
                          _autorisationStatut = 'ACTIVE';
                          _entrepriseNom = info['entreprise_nom'] ?? _entrepriseNom;
                        });
                        PointageEventBus().notifyPointageUpdate();

                        final autoId = res['autorisation_id']?.toString() ?? info['autorisation_id']?.toString();

                        if (autoId != null && _activeCarnetId != null && lat != null && lng != null) {
                          GeofencingService().start(
                            autorisationId: autoId,
                            carnetId: _activeCarnetId!,
                            lat: (lat as num).toDouble(),
                            lng: (lng as num).toDouble(),
                            rayonMetres: 100,
                          );
                        }

                        _loadDashboardData(silent: true);
                        _showConventionSignedSuccessDialog(autoId, info['entreprise_nom']);
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Accepter et signer la convention', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final confirm = await _showConfirmDecline();
                          if (confirm == true) {
                            try {
                              await _internshipService.declinerLiaison(code, info['entreprise_id']);
                              Navigator.pop(ctx);
                              _loadDashboardData(silent: true);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                            }
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: ColorConstants.error),
                        child: const Text('Décliner l\'offre'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler', style: TextStyle(color: ColorConstants.textSecondary)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConventionSignedSuccessDialog(String? autoId, String? entrepriseNom) {
    bool isDownloading = false;
    String? downloadedPath;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: ColorConstants.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: ColorConstants.success, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Convention signée !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre convention avec ${entrepriseNom ?? "l'entreprise"} a été validée et enregistrée avec succès.',
                style: const TextStyle(fontSize: 13.5, color: ColorConstants.textPrimary),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstants.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorConstants.teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: ColorConstants.teal, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Le dispositif de pointage automatique est désormais activé.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ColorConstants.teal),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (autoId != null) ...[
                if (downloadedPath != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorConstants.paper,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ColorConstants.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.file_download_done_rounded, color: ColorConstants.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conservé localement :\n$downloadedPath',
                            style: const TextStyle(fontSize: 11, color: ColorConstants.textSecondary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isDownloading
                          ? null
                          : () async {
                              setDlgState(() => isDownloading = true);
                              try {
                                final file = await _internshipService.telechargerEtSauvegarderConvention(autoId);
                                setDlgState(() {
                                  isDownloading = false;
                                  downloadedPath = file.path;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✅ Convention enregistrée : ${file.path}'),
                                      backgroundColor: ColorConstants.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setDlgState(() => isDownloading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erreur lors du téléchargement : $e')),
                                  );
                                }
                              }
                            },
                      icon: isDownloading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_rounded, color: ColorConstants.primary, size: 18),
                      label: Text(isDownloading ? 'Téléchargement...' : 'Télécharger la convention (PDF)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorConstants.primary,
                        side: const BorderSide(color: ColorConstants.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dlgCtx),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Terminer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDecline() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Décliner l\'offre ?'),
        content: const Text('Voulez-vous vraiment refuser cette offre de stage ? Le tuteur en sera informé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui, décliner', style: TextStyle(color: ColorConstants.error))),
        ],
      ),
    );
  }

  void _showTermsModal(Map<String, dynamic> info, String naissance, String adresse, String ecole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('TERMES DE LA CONVENTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _generateConventionText(info, naissance, adresse, ecole),
                  style: GoogleFonts.merriweather(fontSize: 13, height: 1.6, color: Colors.black87),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: PrimaryButton(label: 'J\'ai lu les termes', onPressed: () => Navigator.pop(ctx)),
            ),
          ],
        ),
      ),
    );
  }

  String _generateConventionText(Map<String, dynamic> info, String naissance, String adresse, String ecole) {
    final String duree = info['duree_hebdomadaire'] ?? '...';
    final String jours = info['jours_presence'] ?? '...';
    final String tuteur = info['tuteur_designe'] ?? '...';
    final String referent = info['referent_pedagogique_nom'] ?? '...';
    final String contactRef = info['referent_pedagogique_contact'] ?? '...';
    final String objet = info['objet_stage'] ?? 'Stage de formation professionnelle';
    final String cursus = info['cursus_rattachement'] ?? 'Cursus scolaire/universitaire';
    final String teletravail = info['teletravail_modalites'] ?? 'Non défini';
    final String suivi = info['modalites_suivi_detail'] ?? 'Points réguliers avec le tuteur';

    return """
CONVENTION DE STAGE PROFESSIONNEL
Réf : CONV-${info['entreprise_id'].toString().substring(0, 8).toUpperCase()}

1. CADRE ADMINISTRATIF ET LÉGAL

IDENTITÉ DES PARTIES :
• L'ENTREPRISE : ${info['entreprise_nom']}
• LE STAGIAIRE : $_prenom, né(e) le ${naissance.isEmpty ? '...' : naissance}, demeurant au ${adresse.isEmpty ? '...' : adresse}.
• L'ÉTABLISSEMENT : ${ecole.isEmpty ? '...' : ecole}.

OBJET ET RATTACHEMENT :
Le présent stage a pour objet : $objet.
Il s'inscrit dans le cadre du cursus suivant : $cursus.

DURÉE DU STAGE :
Le stage est conclu pour une période allant du ${info['date_debut']} au ${info['date_fin']}.

2. CONDITIONS MATÉRIELLES D'EXÉCUTION

LIEU DU STAGE :
Le stage s'exécutera principalement à l'adresse suivante : ${info['lieu_execution'] ?? 'Locaux de l\'entreprise'}.

ORGANISATION DU TEMPS DE TRAVAIL :
• Durée hebdomadaire : $duree.
• Jours de présence : $jours.
• Modalités de télétravail : $teletravail.

3. ENCADREMENT ET SUIVI

MAÎTRE DE STAGE (Tuteur Entreprise) :
Le stagiaire est placé sous la responsabilité directe de M/Mme $tuteur.

RÉFÉRENT PÉDAGOGIQUE (Côté Formation) :
Le suivi académique est assuré par M/Mme $referent (Contact : $contactRef).

MODALITÉS DE SUIVI :
$suivi.

4. ENGAGEMENTS ET POINTAGE

ASSIDUITÉ ET DISCIPLINE :
Le stagiaire s'engage à respecter le règlement intérieur de l'entreprise. Sa présence sera certifiée en temps réel par le système de pointage GPS "StageLink". Toute absence doit être justifiée auprès du tuteur.

CONFIDENTIALITÉ :
Le stagiaire est tenu au secret professionnel absolu pour toutes les informations internes dont il pourrait avoir connaissance.

SIGNATURE :
En validant cette convention via l'application StageLink, les parties reconnaissent avoir pris connaissance de l'ensemble des articles ci-dessus et s'engagent à les respecter.
""";
  }

  Widget _readOnlyTile(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: ColorConstants.textSecondary, fontWeight: FontWeight.bold)),
          Text(value ?? '—', style: const TextStyle(fontSize: 14, color: ColorConstants.textPrimary)),
        ],
      ),
    );
  }

  Widget _editableField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: ColorConstants.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _datePickerField(String label, TextEditingController ctrl, BuildContext context, Function(String) onPicked) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
        if (d != null) onPicked(DateFormat('yyyy-MM-dd').format(d));
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.cake_outlined, size: 18),
        filled: true,
        fillColor: ColorConstants.paper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ColorConstants.primary, letterSpacing: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: ColorConstants.paper,
        body: Center(child: CircularProgressIndicator(color: ColorConstants.primary)),
      );
    }

    return Container(
      color: ColorConstants.paper,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: ColorConstants.primary,
          backgroundColor: ColorConstants.cardBackground,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              GreetingHeader(
                title: 'Bonjour, $_prenom',
                subtitle: 'SESSION ACTIVE',
                avatarUrl: _photoUrl,
                onAvatarTap: widget.onNavigateToProfil,
              ),
              const SizedBox(height: 22),
              
              // Widget de liaison Entreprise
              _LiaisonPanel(
                statut: _autorisationStatut,
                entrepriseNom: _entrepriseNom,
                pos: _currentPos,
                onToggle: (val) {
                  if (val && _autorisationStatut != 'ACTIVE') {
                    _showCodePopup();
                  }
                },
              ),

              const SizedBox(height: 16),
              _CarnetCard(
                stats: _stats,
                onAdd: widget.onNavigateToCarnet,
              ),
              const SizedBox(height: 14),
              _CovoiturageCard(
                reservation: _prochaineReservation,
                onTap: () {
                  if (_prochaineReservation != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrajetDetailsScreen(trajet: _prochaineReservation!['trajet']),
                      ),
                    );
                  } else {
                    widget.onNavigateToTrajet();
                  }
                },
              ),
              const SizedBox(height: 22),
              _sectionLabel('Activité récente'),
              const SizedBox(height: 10),
              if (_activites.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "Aucune activité récente",
                      style: TextStyle(color: ColorConstants.textSecondary, fontSize: 12),
                    ),
                  ),
                )
              else
                ..._activites.take(3).map((a) => _ActivityItem(
                      icon: _getActivityIcon(a['type']),
                      iconBg: _getActivityColor(a['type']).withValues(alpha: 0.14),
                      iconColor: _getActivityColor(a['type']),
                      title: a['title'] ?? '',
                      time: _formatActivityDate(a['date']),
                      showDivider: _activites.indexOf(a) != _activites.take(3).length - 1,
                    )),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'presence':
        return Icons.check_circle;
      case 'mission':
        return Icons.menu_book_rounded;
      case 'trajet':
        return Icons.directions_car_filled_rounded;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'presence':
        return ColorConstants.teal;
      case 'mission':
        return ColorConstants.clay;
      case 'trajet':
        return ColorConstants.amber;
      default:
        return ColorConstants.primary;
    }
  }

  String _formatActivityDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return DateFormat('dd/MM, HH:mm').format(d);
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        color: ColorConstants.textSecondary,
      ),
    );
  }
}

class _LiaisonPanel extends StatelessWidget {
  final String statut;
  final String? entrepriseNom;
  final LatLng? pos;
  final Function(bool) onToggle;

  const _LiaisonPanel({
    required this.statut,
    this.entrepriseNom,
    this.pos,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = statut == 'ACTIVE';
    final bool pending = statut == 'EN_ATTENTE';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? ColorConstants.success : (pending ? ColorConstants.warning : Colors.grey),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      active ? 'LIAISON ÉTABLIE' : (pending ? 'LIAISON EN ATTENTE' : 'LIAISON ENTREPRISE'),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: active ? ColorConstants.success : ColorConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  active ? (entrepriseNom ?? 'Entreprise') : 'Confirmez votre présence',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          if (active && pos != null)
            Container(
              width: 80,
              height: 45,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorConstants.line),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: pos!,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(flags: MultiFingerGesture.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pos!,
                          width: 10,
                          height: 10,
                          child: const Icon(Icons.circle, color: Colors.blue, size: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Switch(
            value: active || pending,
            activeThumbColor: ColorConstants.success,
            onChanged: active ? null : onToggle,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColorConstants.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.line),
      ),
      child: child,
    );
  }
}

class _CarnetCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final VoidCallback onAdd;

  const _CarnetCard({this.stats, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final double progress = ((stats?['progression_globale'] ?? 0) as num).toDouble();
    final int jours = ((stats?['jours_presents'] ?? 0) as num).toInt();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('CARNET DE STAGE'),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const CircularProgressIndicator(value: 1, strokeWidth: 6, color: ColorConstants.line),
                    CircularProgressIndicator(
                      value: progress / 100,
                      strokeWidth: 6,
                      color: ColorConstants.warning,
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _infoRow('Progression globale', '${progress.round()}%'),
                    _infoRow('Jours de présence', '$jours'),
                    _infoRow('Missions complétées', '${stats?['missions_completees'] ?? 0}', showDivider: false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                '+ Ouvrir le carnet',
                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool showDivider = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: ColorConstants.line)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: ColorConstants.textSecondary)),
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: ColorConstants.textPrimary)),
        ],
      ),
    );
  }
}

class _CovoiturageCard extends StatelessWidget {
  final Map<String, dynamic>? reservation;
  final VoidCallback onTap;

  const _CovoiturageCard({this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final trajet = reservation?['trajet'] as Map<String, dynamic>?;
    final String destination = trajet?['lieu_arrivee'] ?? 'Covoiturage';
    final String heure = trajet?['date_depart'] != null
        ? _formatHeure(trajet!['date_depart'])
        : '--:--';

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _eyebrow('COVOITURAGE'),
              if (reservation != null) const Icon(Icons.verified_rounded, color: ColorConstants.warning, size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ColorConstants.line),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      heure,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.warning,
                      ),
                    ),
                    const Text('DÉPART', style: TextStyle(fontSize: 10, color: ColorConstants.textSecondary)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(width: 1, height: 32, color: ColorConstants.line),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ColorConstants.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reservation != null ? 'Trajet réservé' : 'Aucun trajet prévu',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, color: ColorConstants.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.textPrimary,
                side: const BorderSide(color: ColorConstants.line),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                reservation != null ? 'Voir le trajet' : 'Trouver un trajet',
                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String time;
  final bool showDivider;

  const _ActivityItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.time,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: ColorConstants.line)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: ColorConstants.textPrimary),
                ),
                const SizedBox(height: 1),
                Text(time, style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: ColorConstants.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _eyebrow(String text) {
  return Text(
    text,
    style: GoogleFonts.jetBrainsMono(
      fontSize: 10,
      letterSpacing: 1.1,
      color: ColorConstants.textSecondary,
    ),
  );
}

String _formatHeure(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '--:--';
  return DateFormat('HH:mm').format(d);
}
