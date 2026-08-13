import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/api_exception.dart';

/// Écran de création du carnet de stage.
///
/// Fusionne en une seule saisie :
/// - la complétion du profil stagiaire (établissement, filière, téléphone)
///   -> ApiService.completeStagiaireProfile()
/// - la création du carnet à proprement parler (domaine/métier/niveau de
///   formation, poste, dates, entreprise en texte libre)
///   -> ApiService.createCarnet()
///
/// Le rattachement à une entreprise (via code d'invitation) se fait
/// séparément, plus tard, depuis l'écran de rattachement.
class CarnetCreationPage extends StatefulWidget {
  const CarnetCreationPage({super.key});

  @override
  State<CarnetCreationPage> createState() => _CarnetCreationPageState();
}

class _CarnetCreationPageState extends State<CarnetCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

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
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _apiService.loadToken();
    _chargerListes();
  }

  Future<void> _chargerListes() async {
    print('🔄 Chargement des listes initiales...');
    
    try {
      final domaines = await _apiService.getDomaines();
      final niveaux = await _apiService.getNiveauxFormation();
      
      print('📊 Domaines reçus: ${domaines.length}');
      print('📊 Niveaux reçus: ${niveaux.length}');
      
      setState(() {
        _domaineItems = domaines.map<DropdownMenuItem<String>>((d) {
          final label = d['nom']?.toString() ?? d['libelle']?.toString() ?? 'Sans nom';
          return DropdownMenuItem<String>(
            value: d['id'] as String,
            child: Text(label),
          );
        }).toList();
        
        _niveauItems = niveaux.map<DropdownMenuItem<String>>((n) {
          final label = n['nom']?.toString() ?? n['libelle']?.toString() ?? 'Sans nom';
          return DropdownMenuItem<String>(
            value: n['id'] as String,
            child: Text(label),
          );
        }).toList();
        
        _loadingListes = false;
      });
    } catch (e) {
      print('❌ Erreur chargement listes: $e');
      setState(() {
        _erreur = "Impossible de charger les listes (domaines/niveaux).\n${_formaterErreur(e)}";
        _loadingListes = false;
      });
    }
  }

  Future<void> _chargerMetiers(String domaineId) async {
    print('🔵 Chargement des métiers pour le domaine: $domaineId');
    
    setState(() {
      _loadingMetiers = true;
      _metierItems = [];
      _metierId = null;
    });
    
    try {
      final metiers = await _apiService.getMetiers(domaineId: domaineId);
      print('✅ Métiers reçus: ${metiers.length}');
      
      setState(() {
        _metierItems = metiers.map<DropdownMenuItem<String>>((m) {
          final label = m['nom']?.toString() ?? 
                       m['libelle']?.toString() ?? 
                       m['name']?.toString() ?? 
                       'Sans nom';
          final id = m['id']?.toString() ?? '';
          
          print('📌 Métier: id=$id, label=$label');
          
          return DropdownMenuItem<String>(
            value: id,
            child: Text(label),
          );
        }).toList();
        _loadingMetiers = false;
      });
      
      if (_metierItems.isEmpty) {
        print('⚠️ Aucun métier trouvé pour le domaine $domaineId');
      }
    } catch (e) {
      print('❌ Erreur chargement métiers: $e');
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

  Future<void> _choisirPosition() async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (BuildContext context) {
        final latController = TextEditingController();
        final lngController = TextEditingController();

        return AlertDialog(
          title: const Text('Positionner le lieu de stage'),
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'Ex: 2.3522',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              const Text(
                '💡 Vous pouvez obtenir les coordonnées sur Google Maps ou OpenStreetMap',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
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

  Future<void> _soumettre() async {
    setState(() => _erreur = null);

    if (!_formKey.currentState!.validate()) return;

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
    if (_lieuStageLat == null || _lieuStageLng == null) {
      setState(() => _erreur = "Merci de positionner le lieu de stage sur la carte.");
      return;
    }

    setState(() => _submitting = true);

    try {
      print('📤 Envoi des données...');
      print('  - Domaine: $_domaineFormationId');
      print('  - Métier: $_metierId');
      print('  - Niveau: $_niveauFormationId');

      // 1) Complétion du profil stagiaire
      await _apiService.completeStagiaireProfile({
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'etablissement': _etablissementCtrl.text.trim(),
        'filiere': _filiereCtrl.text.trim(),
        'telephone': _telephoneCtrl.text.trim(),
      });

      print('✅ Profil complété');

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

      print('✅ Carnet créé avec succès');

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      print('❌ Erreur soumission: $e');
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

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    print('🏗️ Build CarnetCreationPage');
    print('  - Domaine sélectionné: $_domaineFormationId');
    print('  - Métier sélectionné: $_metierId');
    print('  - Nombre de métiers: ${_metierItems.length}');
    print('  - Loading métiers: $_loadingMetiers');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Créer mon carnet de stage'),
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
      ),
      body: _loadingListes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Mon profil'),
                    const SizedBox(height: 8),
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
                    _champTexte(
                      _telephoneCtrl,
                      'Téléphone *',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('Mon stage'),
                    const SizedBox(height: 8),
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
                          child: _champDate(
                            'Date de début *',
                            _dateDebut,
                            () => _choisirDate(debut: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _champDate(
                            'Date de fin *',
                            _dateFin,
                            () => _choisirDate(debut: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('Lieu de stage'),
                    const SizedBox(height: 8),
                    _champTexte(_adresseCtrl, 'Adresse du lieu de stage *'),
                    const SizedBox(height: 12),
                    _champPosition(),
                    const SizedBox(height: 16),
                    if (_erreur != null) ...[
                      Container(
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
                              child: Text(
                                _erreur!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _soumettre,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Créer mon carnet',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String texte) => Text(
        texte,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );

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
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null,
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
          style: TextStyle(
            color: valeur == null ? Colors.grey.shade600 : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _champPosition() {
    return InkWell(
      onTap: _choisirPosition,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Position GPS *',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.map_outlined),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(
          (_lieuStageLat != null && _lieuStageLng != null)
              ? '${_lieuStageLat!.toStringAsFixed(6)}, ${_lieuStageLng!.toStringAsFixed(6)}'
              : 'Toucher pour positionner sur la carte',
          style: TextStyle(
            color: (_lieuStageLat != null) ? Colors.black : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _dropdownDomaine() {
    return DropdownButtonFormField<String>(
      value: _domaineFormationId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Domaine de formation *',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        filled: true,
        fillColor: Colors.white,
      ),
      hint: const Text('Sélectionnez un domaine'),
      items: _domaineItems,
      onChanged: (v) {
        print('🔄 Domaine sélectionné: $v');
        setState(() {
          _domaineFormationId = v;
          _metierId = null;
          _metierItems = [];
        });
        if (v != null) {
          _chargerMetiers(v);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner un domaine';
        }
        return null;
      },
    );
  }

  Widget _dropdownMetier() {
    final disabled = _domaineFormationId == null;
    final hasItems = _metierItems.isNotEmpty;
    final showNoItems = !disabled && !_loadingMetiers && !hasItems;
    
    print('🏷️ Dropdown Métier - disabled: $disabled, hasItems: $hasItems, loading: $_loadingMetiers');
    
    return DropdownButtonFormField<String>(
      value: _metierId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Métier *',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        filled: true,
        fillColor: Colors.white,
        helperText: disabled 
            ? "Sélectionnez d'abord un domaine" 
            : (showNoItems 
                ? "Aucun métier disponible pour ce domaine" 
                : null),
        helperStyle: TextStyle(
          color: showNoItems ? Colors.orange.shade700 : Colors.grey.shade600,
        ),
        suffixIcon: _loadingMetiers
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      hint: disabled 
          ? const Text('Domaine requis d\'abord') 
          : (showNoItems
              ? const Text('Aucun métier')
              : const Text('Sélectionnez un métier')),
      items: _metierItems,
      onChanged: (disabled || _loadingMetiers) 
          ? null 
          : (v) {
              print('🔄 Métier sélectionné: $v');
              setState(() => _metierId = v);
            },
      validator: (value) {
        if (disabled) {
          return 'Veuillez d\'abord sélectionner un domaine';
        }
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner un métier';
        }
        if (_metierItems.isEmpty) {
          return 'Aucun métier disponible pour ce domaine';
        }
        return null;
      },
    );
  }

  Widget _dropdownNiveau() {
    return DropdownButtonFormField<String>(
      value: _niveauFormationId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Niveau de formation *',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        filled: true,
        fillColor: Colors.white,
      ),
      hint: const Text('Sélectionnez un niveau'),
      items: _niveauItems,
      onChanged: (v) => setState(() => _niveauFormationId = v),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner un niveau';
        }
        return null;
      },
    );
  }
}