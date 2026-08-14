import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';

/// Écran de création du carnet de stage — version "wizard".
///
/// Le formulaire est découpé en 3 étapes affichées dans un [PageView],
/// avec transitions animées et une barre de progression en tête d'écran :
///   1. Mon profil        (nom, prénom, établissement, filière, téléphone)
///   2. Mon stage          (domaine/métier/niveau, poste, entreprise, dates)
///   3. Lieu de stage       (adresse + géolocalisation)
///
/// La logique métier (appels API, validations, geofencing) est identique
/// à la version précédente ; seule la présentation change.
class CarnetCreationPage extends StatefulWidget {
  const CarnetCreationPage({super.key});

  @override
  State<CarnetCreationPage> createState() => _CarnetCreationPageState();
}

class _CarnetCreationPageState extends State<CarnetCreationPage> {
  // Une clé de formulaire par étape, pour valider indépendamment
  final _formKeyProfil = GlobalKey<FormState>();
  final _formKeyStage = GlobalKey<FormState>();
  final _formKeyLieu = GlobalKey<FormState>();

  final ApiService _apiService = ApiService();

  final PageController _pageController = PageController();
  int _etapeActuelle = 0;
  static const int _nombreEtapes = 3;

  // --- Champs profil ---
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _etablissementCtrl = TextEditingController();
  final _filiereCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();

  // --- Champs carnet ---
  final _adresseCtrl = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;
  double? _lieuStageLat;
  double? _lieuStageLng;

  final _posteCtrl = TextEditingController();
  final _entrepriseNomCtrl = TextEditingController();

  String? _domaineFormationId;
  String? _metierId;
  String? _niveauFormationId;

  List<DropdownMenuItem<String>> _domaineItems = [];
  List<DropdownMenuItem<String>> _metierItems = [];
  List<DropdownMenuItem<String>> _niveauItems = [];

  bool _loadingListes = true;
  bool _loadingMetiers = false;
  bool _submitting = false;
  bool _localisationEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _apiService.loadToken();
    _chargerListes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _etablissementCtrl.dispose();
    _filiereCtrl.dispose();
    _telephoneCtrl.dispose();
    _posteCtrl.dispose();
    _entrepriseNomCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // Chargement des référentiels
  // ============================================================
  Future<void> _chargerListes() async {
    try {
      final domaines = await _apiService.getDomaines();
      final niveaux = await _apiService.getNiveauxFormation();

      setState(() {
        _domaineItems = domaines.map<DropdownMenuItem<String>>((d) {
          final label = d['nom']?.toString() ?? d['libelle']?.toString() ?? 'Sans nom';
          return DropdownMenuItem<String>(value: d['id'] as String, child: Text(label));
        }).toList();

        _niveauItems = niveaux.map<DropdownMenuItem<String>>((n) {
          final label = n['nom']?.toString() ?? n['libelle']?.toString() ?? 'Sans nom';
          return DropdownMenuItem<String>(value: n['id'] as String, child: Text(label));
        }).toList();

        _loadingListes = false;
      });
    } catch (e) {
      setState(() {
        _erreur = "Impossible de charger les listes (domaines/niveaux).\n${_formaterErreur(e)}";
        _loadingListes = false;
      });
    }
  }

  Future<void> _chargerMetiers(String domaineId) async {
    setState(() {
      _loadingMetiers = true;
      _metierItems = [];
      _metierId = null;
    });

    try {
      final metiers = await _apiService.getMetiers(domaineId: domaineId);
      setState(() {
        _metierItems = metiers.map<DropdownMenuItem<String>>((m) {
          final label = m['nom']?.toString() ??
              m['libelle']?.toString() ??
              m['name']?.toString() ??
              'Sans nom';
          final id = m['id']?.toString() ?? '';
          return DropdownMenuItem<String>(value: id, child: Text(label));
        }).toList();
        _loadingMetiers = false;
      });
    } catch (e) {
      setState(() {
        _erreur = "Impossible de charger les métiers.\n${_formaterErreur(e)}";
        _loadingMetiers = false;
      });
    }
  }

  Future<void> _choisirDate({required bool debut}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;
    setState(() {
      if (debut) {
        _dateDebut = date;
      } else {
        _dateFin = date;
      }
    });
  }

  // ============================================================
  // Localisation automatique du lieu de stage (GPS + reverse geocoding)
  // ============================================================
  Future<void> _localiserAutomatiquement() async {
    setState(() {
      _localisationEnCours = true;
      _erreur = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _erreur = "Activez la localisation pour continuer.");
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _erreur = "Permission de localisation refusée.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() =>
            _erreur = "Localisation bloquée. Activez-la dans les réglages de l'application.");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String adresse = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          adresse = [p.street, p.locality, p.country]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
        }
      } catch (_) {
        // Le reverse geocoding peut échouer sans bloquer la récupération des coordonnées.
      }

      if (!mounted) return;
      setState(() {
        _lieuStageLat = position.latitude;
        _lieuStageLng = position.longitude;
        if (adresse.isNotEmpty) {
          _adresseCtrl.text = adresse;
        }
      });
    } catch (e) {
      setState(() => _erreur = "Impossible de récupérer votre position.");
    } finally {
      if (mounted) setState(() => _localisationEnCours = false);
    }
  }

  Future<void> _choisirPosition() async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (BuildContext context) {
        final latController = TextEditingController(text: _lieuStageLat?.toString() ?? '');
        final lngController = TextEditingController(text: _lieuStageLng?.toString() ?? '');

        return AlertDialog(
          title: const Text('Ajuster le lieu de stage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'Ex: 48.8566',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'Ex: 2.3522',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              const Text(
                '💡 À utiliser seulement si la localisation automatique est imprécise.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                final lat = double.tryParse(latController.text.replaceAll(',', '.'));
                final lng = double.tryParse(lngController.text.replaceAll(',', '.'));
                if (lat != null && lng != null) {
                  Navigator.pop(context, {'lat': lat, 'lng': lng});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer des coordonnées valides'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _lieuStageLat = result['lat'];
        _lieuStageLng = result['lng'];
      });
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Sélectionner une date';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // ============================================================
  // Navigation entre étapes du wizard
  // ============================================================

  /// Valide l'étape courante puis avance, avec une transition animée.
  /// À la dernière étape, déclenche la soumission finale.
  Future<void> _etapeSuivante() async {
    setState(() => _erreur = null);

    if (_etapeActuelle == 0) {
      if (!_formKeyProfil.currentState!.validate()) return;
    } else if (_etapeActuelle == 1) {
      if (!_formKeyStage.currentState!.validate()) return;
      if (_domaineFormationId == null) {
        setState(() => _erreur = "Merci de choisir un domaine de formation.");
        return;
      }
      if (_metierId == null) {
        setState(() => _erreur = "Merci de choisir un métier.");
        return;
      }
      if (_niveauFormationId == null) {
        setState(() => _erreur = "Merci de choisir un niveau de formation.");
        return;
      }
      if (_dateDebut == null || _dateFin == null) {
        setState(() => _erreur = "Merci de renseigner les dates de stage.");
        return;
      }
      if (_dateFin!.isBefore(_dateDebut!)) {
        setState(() => _erreur = "La date de fin doit être après la date de début.");
        return;
      }
    } else if (_etapeActuelle == 2) {
      await _soumettre();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _etapePrecedente() {
    if (_etapeActuelle == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _erreur = null);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _soumettre() async {
    setState(() => _erreur = null);

    if (!_formKeyLieu.currentState!.validate()) return;

    if (_lieuStageLat == null || _lieuStageLng == null) {
      setState(() => _erreur = "Merci de localiser le lieu de stage.");
      return;
    }

    setState(() => _submitting = true);

    try {
      // 1) Complétion du profil stagiaire
      await _apiService.completeStagiaireProfile({
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'etablissement': _etablissementCtrl.text.trim(),
        'filiere': _filiereCtrl.text.trim(),
        'telephone': _telephoneCtrl.text.trim(),
      });

      // 2) Création du carnet
      await _apiService.createCarnet({
        'domaine_formation_id': _domaineFormationId,
        'metier_id': _metierId,
        'niveau_formation_id': _niveauFormationId,
        'poste': _posteCtrl.text.trim(),
        'date_debut': _dateDebut!.toIso8601String().split('T').first,
        'date_fin': _dateFin!.toIso8601String().split('T').first,
        'entreprise_nom': _entrepriseNomCtrl.text.trim(),
        'lieu_stage_adresse': _adresseCtrl.text.trim(),
        'lieu_stage_lat': _lieuStageLat,
        'lieu_stage_lng': _lieuStageLng,
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _erreur = _formaterErreur(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formaterErreur(Object e) {
    if (e is ApiException) {
      if (e.isValidationError && e.validationErrors.isNotEmpty) {
        return e.validationErrors.join('\n');
      }
      return e.userFriendlyMessage;
    }
    return "Erreur inattendue : $e";
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_titreEtape(_etapeActuelle)),
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _submitting ? null : _etapePrecedente,
        ),
      ),
      body: _loadingListes
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _barreProgression(),
                if (_erreur != null) _bandeauErreur(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // navigation via boutons
                    onPageChanged: (i) => setState(() => _etapeActuelle = i),
                    children: [
                      _pageProfil(),
                      _pageStage(),
                      _pageLieu(),
                    ],
                  ),
                ),
                _barreNavigation(),
              ],
            ),
    );
  }

  String _titreEtape(int i) {
    switch (i) {
      case 0:
        return 'Mon profil';
      case 1:
        return 'Mon stage';
      case 2:
      default:
        return 'Lieu de stage';
    }
  }

  // --- Barre de progression avec libellés d'étapes ---
  Widget _barreProgression() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          Row(
            children: List.generate(_nombreEtapes, (i) {
              final actif = i <= _etapeActuelle;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 5,
                        margin: EdgeInsets.only(right: i == _nombreEtapes - 1 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: actif ? ColorConstants.primary : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étape ${_etapeActuelle + 1} sur $_nombreEtapes',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                _titreEtape(_etapeActuelle),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bandeauErreur() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(_erreur),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_erreur!, style: TextStyle(color: Colors.red.shade700)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Boutons de navigation bas d'écran ---
  Widget _barreNavigation() {
    final dernierePage = _etapeActuelle == _nombreEtapes - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          if (_etapeActuelle > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : _etapePrecedente,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: ColorConstants.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Retour', style: TextStyle(color: ColorConstants.primary)),
              ),
            ),
          if (_etapeActuelle > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitting ? null : _etapeSuivante,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      dernierePage ? 'Créer mon carnet' : 'Continuer',
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Wrapper commun : anime l'apparition du contenu de chaque page ---
  Widget _contenuAnime(Widget enfant) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(enfant.hashCode),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, valeur, child) {
        return Opacity(
          opacity: valeur,
          child: Transform.translate(
            offset: Offset(0, (1 - valeur) * 16),
            child: child,
          ),
        );
      },
      child: enfant,
    );
  }

  // ============================================================
  // Étape 1 : Mon profil
  // ============================================================
  Widget _pageProfil() {
    return _contenuAnime(
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKeyProfil,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _introEtape(
                icone: Icons.person_outline,
                texte: 'Ces informations complètent votre profil stagiaire.',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _champTexte(_nomCtrl, 'Nom *')),
                  const SizedBox(width: 12),
                  Expanded(child: _champTexte(_prenomCtrl, 'Prénom *')),
                ],
              ),
              const SizedBox(height: 12),
              _champTexte(_etablissementCtrl, 'Établissement *'),
              const SizedBox(height: 12),
              _champTexte(_filiereCtrl, 'Filière *'),
              const SizedBox(height: 12),
              _champTexte(_telephoneCtrl, 'Téléphone *', keyboardType: TextInputType.phone),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Étape 2 : Mon stage
  // ============================================================
  Widget _pageStage() {
    return _contenuAnime(
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKeyStage,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _introEtape(
                icone: Icons.work_outline,
                texte: 'Décrivez le stage que vous souhaitez suivre.',
              ),
              const SizedBox(height: 20),
              _dropdownDomaine(),
              const SizedBox(height: 12),
              _dropdownMetier(),
              const SizedBox(height: 12),
              _dropdownNiveau(),
              const SizedBox(height: 12),
              _champTexte(_posteCtrl, 'Poste / intitulé du stage *'),
              const SizedBox(height: 12),
              _champTexte(
                _entrepriseNomCtrl,
                "Nom de l'entreprise *",
                helper: 'En attendant le rattachement officiel par code',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _champDate('Date de début *', _dateDebut, () => _choisirDate(debut: true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _champDate('Date de fin *', _dateFin, () => _choisirDate(debut: false)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Étape 3 : Lieu de stage
  // ============================================================
  Widget _pageLieu() {
    return _contenuAnime(
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKeyLieu,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _introEtape(
                icone: Icons.location_on_outlined,
                texte: 'Cette position servira au pointage automatique par géolocalisation.',
              ),
              const SizedBox(height: 20),
              _champTexte(_adresseCtrl, 'Adresse du lieu de stage *'),
              const SizedBox(height: 12),
              _champPosition(),
              const SizedBox(height: 24),
              _recapitulatif(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _introEtape({required IconData icone, required String texte}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icone, color: ColorConstants.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  /// Petit récapitulatif affiché en dernière étape, pour rassurer avant
  /// l'envoi final (pas d'appel API, juste un résumé visuel).
  Widget _recapitulatif() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          _ligneRecap('Poste', _posteCtrl.text),
          _ligneRecap('Entreprise', _entrepriseNomCtrl.text),
          _ligneRecap(
            'Période',
            (_dateDebut != null && _dateFin != null)
                ? '${_formatDate(_dateDebut)} → ${_formatDate(_dateFin)}'
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _ligneRecap(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              valeur.isEmpty ? '—' : valeur,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Champs réutilisables
  // ============================================================

  Widget _champTexte(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    String? helper,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null,
    );
  }

  Widget _champDate(String label, DateTime? valeur, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(
          _formatDate(valeur),
          style: TextStyle(color: valeur == null ? Colors.grey.shade600 : Colors.black),
        ),
      ),
    );
  }

  Widget _champPosition() {
    final aPosition = _lieuStageLat != null && _lieuStageLng != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _localisationEnCours ? null : _localiserAutomatiquement,
            icon: _localisationEnCours
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(aPosition ? Icons.check_circle : Icons.my_location_rounded),
            label: Text(
              _localisationEnCours
                  ? 'Localisation en cours...'
                  : aPosition
                      ? 'Position détectée'
                      : 'Localiser automatiquement',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: aPosition ? ColorConstants.success : ColorConstants.primary,
              side: BorderSide(color: aPosition ? ColorConstants.success : ColorConstants.primary),
            ),
          ),
        ),
        if (aPosition) ...[
          const SizedBox(height: 6),
          Text(
            '${_lieuStageLat!.toStringAsFixed(6)}, ${_lieuStageLng!.toStringAsFixed(6)}',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _choisirPosition,
          icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
          label: const Text('Ajuster manuellement'),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
      ],
    );
  }

  Widget _dropdownDomaine() {
    return DropdownButtonFormField<String>(
      initialValue: _domaineFormationId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Domaine de formation *',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _domaineItems,
      validator: (v) => v == null ? 'Champ requis' : null,
      onChanged: (v) {
        setState(() => _domaineFormationId = v);
        if (v != null) _chargerMetiers(v);
      },
    );
  }

  Widget _dropdownMetier() {
    return DropdownButtonFormField<String>(
      initialValue: _metierId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Métier *',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: _loadingMetiers
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        helperText: _domaineFormationId == null ? "Choisissez d'abord un domaine" : null,
      ),
      items: _metierItems,
      validator: (v) => v == null ? 'Champ requis' : null,
      onChanged: (_loadingMetiers || _domaineFormationId == null)
          ? null
          : (v) => setState(() => _metierId = v),
    );
  }

  Widget _dropdownNiveau() {
    return DropdownButtonFormField<String>(
      initialValue: _niveauFormationId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Niveau de formation *',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _niveauItems,
      validator: (v) => v == null ? 'Champ requis' : null,
      onChanged: (v) => setState(() => _niveauFormationId = v),
    );
  }
}
