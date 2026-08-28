import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/constants_colors.dart';
import '../../../../services/internship_service.dart';
import '../../../widgets/common_widgets.dart';

class AddStagiaireDialog extends StatefulWidget {
  final String? initialNom;
  final String? initialPrenom;
  final String? initialEmail;

  const AddStagiaireDialog({
    super.key,
    this.initialNom,
    this.initialPrenom,
    this.initialEmail,
  });

  @override
  State<AddStagiaireDialog> createState() => _AddStagiaireDialogState();
}

class _AddStagiaireDialogState extends State<AddStagiaireDialog> {
  final _formKey = GlobalKey<FormState>();

  // 1. Identité Stagiaire
  late final TextEditingController _emailCtrl;
  late final TextEditingController _nomStagiaireCtrl;
  late final TextEditingController _prenomStagiaireCtrl;

  // 2. Identité Entreprise
  final _raisonSocialeCtrl = TextEditingController();
  final _adresseSiegeCtrl = TextEditingController();
  final _secteurActiviteCtrl = TextEditingController();
  final _entrepriseEmailDocCtrl = TextEditingController();
  final _entrepriseTelDocCtrl = TextEditingController();

  // 3. Représentant Légal
  final _repLegalNomCtrl = TextEditingController();
  final _repLegalFonctionCtrl = TextEditingController();
  final _repLegalContactCtrl = TextEditingController();

  // 4. Cadre Administratif
  final _etablissementCtrl = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String? _selectedObjet;
  final _objetAutreCtrl = TextEditingController();
  final _cursusCtrl = TextEditingController();

  // 5. Conditions Matérielles
  final _lieuExecutionCtrl = TextEditingController();
  final _latExecutionCtrl = TextEditingController();
  final _lngExecutionCtrl = TextEditingController();
  final _dureeMoisCtrl = TextEditingController();
  final _dureeHebdoCtrl = TextEditingController();
  final List<String> _joursPresence = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi'];
  final _teletravailCtrl = TextEditingController();

  // 6. Encadrement
  final _congesAbsencesCtrl = TextEditingController();

  // 7. Gratification
  bool _gratificationPrevue = false;
  final _gratificationMontantCtrl = TextEditingController();
  final _gratificationPeriodiciteCtrl = TextEditingController();

  final InternshipService _apiService = InternshipService();
  bool _isLoading = false;
  String? _generatedCode;

  final List<String> _objetsStage = [
    'Stage de fin d\'études',
    'Stage obligatoire (cursus)',
    'Stage de découverte',
    'Stage professionnel',
    'Stage de réinsertion',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _nomStagiaireCtrl = TextEditingController(text: widget.initialNom);
    _prenomStagiaireCtrl = TextEditingController(text: widget.initialPrenom);
    _dureeMoisCtrl.addListener(_autoFillDurations);
  }

  @override
  void dispose() {
    _dureeMoisCtrl.removeListener(_autoFillDurations);
    _emailCtrl.dispose();
    _nomStagiaireCtrl.dispose();
    _prenomStagiaireCtrl.dispose();
    _raisonSocialeCtrl.dispose();
    _adresseSiegeCtrl.dispose();
    _secteurActiviteCtrl.dispose();
    _entrepriseEmailDocCtrl.dispose();
    _entrepriseTelDocCtrl.dispose();
    _repLegalNomCtrl.dispose();
    _repLegalFonctionCtrl.dispose();
    _repLegalContactCtrl.dispose();
    _etablissementCtrl.dispose();
    _objetAutreCtrl.dispose();
    _cursusCtrl.dispose();
    _lieuExecutionCtrl.dispose();
    _latExecutionCtrl.dispose();
    _lngExecutionCtrl.dispose();
    _dureeMoisCtrl.dispose();
    _dureeHebdoCtrl.dispose();
    _teletravailCtrl.dispose();
    _congesAbsencesCtrl.dispose();
    _gratificationMontantCtrl.dispose();
    _gratificationPeriodiciteCtrl.dispose();
    super.dispose();
  }

  void _autoFillDurations() {
    if (_dureeMoisCtrl.text.isNotEmpty) {
      if (_dureeHebdoCtrl.text.isEmpty) {
        _dureeHebdoCtrl.text = "35h/semaine";
      }
    }
  }

  Future<void> _pickDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _captureGPS() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci d\'activer le GPS.')));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission GPS refusée.')));
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() {
        _latExecutionCtrl.text = pos.latitude.toString();
        _lngExecutionCtrl.text = pos.longitude.toString();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📍 Position capturée !'), backgroundColor: ColorConstants.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur GPS : $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dateDebut == null || _dateFin == null || _selectedObjet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir toutes les informations obligatoires.'))
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'email': _emailCtrl.text.trim(),
        'stagiaire_nom': _nomStagiaireCtrl.text.trim(),
        'stagiaire_prenom': _prenomStagiaireCtrl.text.trim(),
        
        'date_debut': DateFormat('yyyy-MM-dd').format(_dateDebut!),
        'date_fin': DateFormat('yyyy-MM-dd').format(_dateFin!),
        'etablissement_nom': _etablissementCtrl.text.trim(),
        
        'raison_sociale_custom': _raisonSocialeCtrl.text.trim(),
        'adresse_custom': _adresseSiegeCtrl.text.trim(),
        'secteur_activite_custom': _secteurActiviteCtrl.text.trim(),
        'entreprise_email_document': _entrepriseEmailDocCtrl.text.trim(),
        'entreprise_telephone_document': _entrepriseTelDocCtrl.text.trim(),

        'representant_legal_nom': _repLegalNomCtrl.text.trim(),
        'representant_legal_fonction': _repLegalFonctionCtrl.text.trim(),
        'representant_legal_contact': _repLegalContactCtrl.text.trim(),

        'objet_stage': _selectedObjet,
        'objet_stage_autre': _selectedObjet == 'Autre' ? _objetAutreCtrl.text.trim() : null,
        'cursus_rattachement': _cursusCtrl.text.trim(),
        
        'lieu_execution': _lieuExecutionCtrl.text.trim(),
        'lieu_execution_lat': double.tryParse(_latExecutionCtrl.text),
        'lieu_execution_lng': double.tryParse(_lngExecutionCtrl.text),
        'nombre_mois_stage': int.tryParse(_dureeMoisCtrl.text),
        'duree_hebdomadaire': _dureeHebdoCtrl.text.trim(),
        'jours_presence': _joursPresence,
        'teletravail_modalites': _teletravailCtrl.text.trim(),
        
        'gratification_prevue': _gratificationPrevue,
        'gratification_montant': double.tryParse(_gratificationMontantCtrl.text),
        'gratification_periodicite': _gratificationPeriodiciteCtrl.text.trim(),
        'conges_absences': _congesAbsencesCtrl.text.trim(),
        
        'poste': "Stagiaire", 
      };

      final response = await _apiService.createFicheInvitation(data);

      setState(() {
        _generatedCode = response['code_invitation'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_generatedCode != null) {
      return _buildCodeView();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.description_outlined, color: ColorConstants.primary),
          SizedBox(width: 12),
          Text('Nouvelle Convention', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Identité Stagiaire
                _sectionTitle('1. Identité du Stagiaire'),
                _buildField('Email du stagiaire (obligatoire)', _emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Nom', _nomStagiaireCtrl, Icons.person_outline, required: false)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Prénom', _prenomStagiaireCtrl, Icons.person_outline, required: false)),
                  ],
                ),

                // 2. Identité Entreprise
                const SizedBox(height: 24),
                _sectionTitle('2. Identité de l\'Entreprise'),
                _buildField('Nom de l\'entreprise (Raison sociale)', _raisonSocialeCtrl, Icons.business_outlined),
                const SizedBox(height: 12),
                _buildField('Adresse du siège', _adresseSiegeCtrl, Icons.home_work_outlined),
                const SizedBox(height: 12),
                _buildField('Secteur d\'activité', _secteurActiviteCtrl, Icons.category_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Email contact', _entrepriseEmailDocCtrl, Icons.alternate_email_outlined, keyboardType: TextInputType.emailAddress)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Tel contact', _entrepriseTelDocCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone)),
                  ],
                ),

                // 3. Représentant Légal
                const SizedBox(height: 24),
                _sectionTitle('3. Représentant Légal'),
                _buildField('Nom complet du représentant', _repLegalNomCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _buildField('Fonction', _repLegalFonctionCtrl, Icons.assignment_ind_outlined),
                const SizedBox(height: 12),
                _buildField('Contact (Email/Tel)', _repLegalContactCtrl, Icons.contact_phone_outlined),

                // 4. Cadre Administratif
                const SizedBox(height: 24),
                _sectionTitle('4. Cadre Administratif du Stage'),
                _buildField('Établissement d\'enseignement', _etablissementCtrl, Icons.school_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _dateTile('Début', _dateDebut, () => _pickDate(true))),
                    const SizedBox(width: 10),
                    Expanded(child: _dateTile('Fin', _dateFin, () => _pickDate(false))),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Objet du stage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorConstants.textSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedObjet,
                  items: _objetsStage.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _selectedObjet = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                    filled: true,
                    fillColor: ColorConstants.paper,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null ? 'Requis' : null,
                ),
                if (_selectedObjet == 'Autre') ...[
                  const SizedBox(height: 12),
                  _buildField('Précisez l\'objet', _objetAutreCtrl, Icons.edit_note_outlined),
                ],
                const SizedBox(height: 12),
                _buildField('Cursus / Filière', _cursusCtrl, Icons.layers_outlined),

                // 5. Conditions Matérielles
                const SizedBox(height: 24),
                _sectionTitle('5. Conditions Matérielles'),
                _buildField('Lieu exact d\'exécution', _lieuExecutionCtrl, Icons.location_on_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _captureGPS,
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('Capturer position actuelle', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Lat.', _latExecutionCtrl, Icons.map_outlined, keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Long.', _lngExecutionCtrl, Icons.map_outlined, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField('Nombre de mois', _dureeMoisCtrl, Icons.calendar_today_rounded, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Durée hebdo', _dureeHebdoCtrl, Icons.timer_outlined)),
                    const SizedBox(width: 10),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Jours de présence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ColorConstants.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'].map((day) {
                    final isSelected = _joursPresence.contains(day);
                    return FilterChip(
                      label: Text(day[0].toUpperCase() + day.substring(1), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _joursPresence.add(day);
                          } else {
                            _joursPresence.remove(day);
                          }
                        });
                      },
                      selectedColor: ColorConstants.primary,
                      checkmarkColor: Colors.white,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _buildField('Modalités télétravail', _teletravailCtrl, Icons.laptop_mac_outlined, required: false),

                // 6. Encadrement
                const SizedBox(height: 24),
                _sectionTitle('6. Encadrement'),
                _buildField('Congés & Absences', _congesAbsencesCtrl, Icons.event_busy_outlined, maxLines: 2, required: false),

                // 7. Gratification
                const SizedBox(height: 24),
                _sectionTitle('7. Gratification'),
                SwitchListTile(
                  title: const Text('Gratification prévue ?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: _gratificationPrevue,
                  onChanged: (v) => setState(() => _gratificationPrevue = v),
                  activeThumbColor: ColorConstants.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_gratificationPrevue) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField('Montant', _gratificationMontantCtrl, Icons.euro_symbol_rounded, keyboardType: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildField('Périodicité', _gratificationPeriodiciteCtrl, Icons.update_rounded)),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Générer le code'),
        ),
      ],
    );
  }

  Widget _buildCodeView() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: ColorConstants.success),
          SizedBox(width: 10),
          Text('Projet créé', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Le projet de convention a été généré. Transmettez ce code au stagiaire :'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ColorConstants.primary.withValues(alpha: 0.3)),
            ),
            child: SelectableText(
              _generatedCode!,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2, color: ColorConstants.primary),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _generatedCode!.trim()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Code copié !')));
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copier le code'),
          ),
        ],
      ),
      actions: [
        PrimaryButton(label: 'Terminer', onPressed: () => Navigator.pop(context, true)),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ColorConstants.primary, letterSpacing: 1)),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1, TextInputType? keyboardType, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: ColorConstants.paper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: required ? (v) => v == null || v.isEmpty ? 'Requis' : null : null,
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorConstants.paper,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: ColorConstants.textSecondary)),
            const SizedBox(height: 4),
            Text(date == null ? 'Choisir' : DateFormat('dd/MM/yy').format(date), 
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
