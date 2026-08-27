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

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  // 2. Cadre administratif
  final _posteCtrl = TextEditingController();
  final _etablissementCtrl = TextEditingController();
  
  // Tuteur / Maître de stage
  final _tuteurDesigneCtrl = TextEditingController();
  final _tuteurNomCtrl = TextEditingController();
  final _tuteurPrenomCtrl = TextEditingController();
  final _tuteurFonctionCtrl = TextEditingController();
  final _tuteurEmailCtrl = TextEditingController();
  final _tuteurTelCtrl = TextEditingController();
  
  // Entreprise (infos spécifiques document)
  final _raisonSocialeCtrl = TextEditingController();
  final _adresseCustomCtrl = TextEditingController();
  final _situationGeoCtrl = TextEditingController();
  final _secteurActiviteCtrl = TextEditingController();
  final _entrepriseEmailDocCtrl = TextEditingController();
  final _entrepriseTelDocCtrl = TextEditingController();
  
  // Représentant Légal
  final _repLegalNomCtrl = TextEditingController();
  final _repLegalFonctionCtrl = TextEditingController();
  final _repLegalContactCtrl = TextEditingController();
  
  final _objetStageCtrl = TextEditingController();
  final _cursusCtrl = TextEditingController();
  final _anneeAcademiqueCtrl = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;

  // 3. Conditions matérielles
  final _lieuExecutionCtrl = TextEditingController();
  final _latExecutionCtrl = TextEditingController();
  final _lngExecutionCtrl = TextEditingController();
  final _dureeHebdoCtrl = TextEditingController();
  final _joursPresenceCtrl = TextEditingController();
  final _teletravailCtrl = TextEditingController();

  // 4. Encadrement & Gratification
  final _referentNomCtrl = TextEditingController();
  final _referentContactCtrl = TextEditingController();
  final _modalitesSuiviCtrl = TextEditingController();
  final _congesAbsencesCtrl = TextEditingController();
  final _conditionsLibresCtrl = TextEditingController();
  
  bool _gratificationPrevue = false;
  final _gratificationMontantCtrl = TextEditingController();
  final _gratificationPeriodiciteCtrl = TextEditingController();

  final InternshipService _apiService = InternshipService();
  bool _isLoading = false;
  String? _generatedCode;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dateDebut == null || _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir toutes les informations obligatoires.'))
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> data = {
        'email': _emailCtrl.text.trim(),
        'poste': _posteCtrl.text.trim(),
        'date_debut': DateFormat('yyyy-MM-dd').format(_dateDebut!),
        'date_fin': DateFormat('yyyy-MM-dd').format(_dateFin!),
        'etablissement_nom': _etablissementCtrl.text.trim(),
        
        'tuteur_designe': _tuteurDesigneCtrl.text.trim(),
        'tuteur_nom': _tuteurNomCtrl.text.trim(),
        'tuteur_prenom': _tuteurPrenomCtrl.text.trim(),
        'tuteur_fonction': _tuteurFonctionCtrl.text.trim(),
        'tuteur_email': _tuteurEmailCtrl.text.trim(),
        'tuteur_telephone': _tuteurTelCtrl.text.trim(),

        'raison_sociale_custom': _raisonSocialeCtrl.text.trim(),
        'adresse_custom': _adresseCustomCtrl.text.trim(),
        'situation_geographique': _situationGeoCtrl.text.trim(),
        'secteur_activite_custom': _secteurActiviteCtrl.text.trim(),
        'entreprise_email_document': _entrepriseEmailDocCtrl.text.trim(),
        'entreprise_telephone_document': _entrepriseTelDocCtrl.text.trim(),

        'representant_legal_nom': _repLegalNomCtrl.text.trim(),
        'representant_legal_fonction': _repLegalFonctionCtrl.text.trim(),
        'representant_legal_contact': _repLegalContactCtrl.text.trim(),

        'objet_stage': _objetStageCtrl.text.trim(),
        'cursus_rattachement': _cursusCtrl.text.trim(),
        'stagiaire_annee_academique': _anneeAcademiqueCtrl.text.trim(),
        
        'lieu_execution': _lieuExecutionCtrl.text.trim(),
        'lieu_execution_lat': double.tryParse(_latExecutionCtrl.text),
        'lieu_execution_lng': double.tryParse(_lngExecutionCtrl.text),
        'duree_hebdomadaire': _dureeHebdoCtrl.text.trim(),
        'jours_presence': _joursPresenceCtrl.text.trim(),
        'teletravail_modalites': _teletravailCtrl.text.trim(),
        
        'referent_pedagogique_nom': _referentNomCtrl.text.trim(),
        'referent_pedagogique_contact': _referentContactCtrl.text.trim(),
        'modalites_suivi_detail': _modalitesSuiviCtrl.text.trim(),
        
        'gratification_prevue': _gratificationPrevue,
        'gratification_montant': double.tryParse(_gratificationMontantCtrl.text),
        'gratification_periodicite': _gratificationPeriodiciteCtrl.text.trim(),
        'conges_absences': _congesAbsencesCtrl.text.trim(),
        'conditions_stage': _conditionsLibresCtrl.text.trim(),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('1. Identité du Stagiaire'),
                        _buildField('Email du stagiaire', _emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                        
                        const SizedBox(height: 24),
                        _sectionTitle('2. Identité de l\'Entreprise'),
                        _buildField('Raison sociale (pour document)', _raisonSocialeCtrl, Icons.business_outlined),
                        const SizedBox(height: 12),
                        _buildField('Adresse du siège', _adresseCustomCtrl, Icons.home_work_outlined),
                        const SizedBox(height: 12),
                        _buildField('Situation géographique', _situationGeoCtrl, Icons.explore_outlined),
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

                        const SizedBox(height: 24),
                        _sectionTitle('3. Représentant Légal'),
                        _buildField('Nom complet du représentant', _repLegalNomCtrl, Icons.person_outline),
                        const SizedBox(height: 12),
                        _buildField('Fonction', _repLegalFonctionCtrl, Icons.assignment_ind_outlined),
                        const SizedBox(height: 12),
                        _buildField('Contact (Email/Tel)', _repLegalContactCtrl, Icons.contact_phone_outlined),

                        const SizedBox(height: 24),
                        _sectionTitle('4. Cadre Administratif du Stage'),
                        _buildField('Poste occupé par le stagiaire', _posteCtrl, Icons.work_outline),
                        const SizedBox(height: 12),
                        _buildField('Établissement d\'enseignement', _etablissementCtrl, Icons.school_outlined),
                        const SizedBox(height: 12),
                        _buildField('Maître de stage (Nom Complet)', _tuteurDesigneCtrl, Icons.person_search_outlined),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildField('Nom tuteur', _tuteurNomCtrl, Icons.person_outline)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildField('Prénom tuteur', _tuteurPrenomCtrl, Icons.person_outline)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildField('Fonction du tuteur', _tuteurFonctionCtrl, Icons.assignment_ind_outlined),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildField('Email tuteur', _tuteurEmailCtrl, Icons.alternate_email_outlined, keyboardType: TextInputType.emailAddress)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildField('Tel tuteur', _tuteurTelCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _dateTile('Début', _dateDebut, () => _pickDate(true))),
                            const SizedBox(width: 10),
                            Expanded(child: _dateTile('Fin', _dateFin, () => _pickDate(false))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildField('Objet du stage (missions)', _objetStageCtrl, Icons.flag_outlined),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildField('Cursus / Filière', _cursusCtrl, Icons.account_tree_outlined)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildField('Année académique', _anneeAcademiqueCtrl, Icons.calendar_today_outlined)),
                          ],
                        ),

                        const SizedBox(height: 24),
                        _sectionTitle('5. Conditions Matérielles'),
                        _buildField('Lieu exact d\'exécution', _lieuExecutionCtrl, Icons.location_on_outlined),
                        const SizedBox(height: 12),
                        _buildLocationPicker(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildField('Durée hebdo', _dureeHebdoCtrl, Icons.timer_outlined, required: false)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildField('Jours présence', _joursPresenceCtrl, Icons.calendar_month_outlined, required: false)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildField('Modalités télétravail', _teletravailCtrl, Icons.laptop_mac_outlined, required: false),

                        const SizedBox(height: 24),
                        _sectionTitle('6. Encadrement & Suivi'),
                        _buildField('Référent pédagogique (École)', _referentNomCtrl, Icons.school_outlined, required: false),
                        const SizedBox(height: 12),
                        _buildField('Contact référent', _referentContactCtrl, Icons.alternate_email_outlined, required: false),
                        const SizedBox(height: 12),
                        _buildField('Modalités de suivi', _modalitesSuiviCtrl, Icons.fact_check_outlined, maxLines: 3, required: false),
                        const SizedBox(height: 12),
                        _buildField('Congés & Absences', _congesAbsencesCtrl, Icons.event_busy_outlined, maxLines: 2, required: false),

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
                        const SizedBox(height: 12),
                        _buildField('Autres avantages / conditions', _conditionsLibresCtrl, Icons.more_horiz_rounded, maxLines: 2, required: false),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: BoxDecoration(
        color: ColorConstants.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(bottom: BorderSide(color: ColorConstants.line)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: ColorConstants.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Nouvelle Convention', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        border: Border(top: BorderSide(color: ColorConstants.line)),
      ),
      child: PrimaryButton(
        label: 'Générer le projet de convention',
        isLoading: _isLoading,
        onPressed: _submit,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ColorConstants.primary, letterSpacing: 1.1)),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1, TextInputType? keyboardType, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: ColorConstants.textSecondary),
        filled: true,
        fillColor: ColorConstants.paper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: required ? (v) => v == null || v.isEmpty ? 'Requis' : null : null,
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: ColorConstants.paper, borderRadius: BorderRadius.circular(16)),
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

  Widget _buildLocationPicker() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final pos = await Geolocator.getCurrentPosition();
                setState(() {
                  _latExecutionCtrl.text = pos.latitude.toString();
                  _lngExecutionCtrl.text = pos.longitude.toString();
                });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📍 Position GPS capturée !')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur GPS.')));
              }
            },
            icon: const Icon(Icons.my_location, size: 16),
            label: const Text('Ma position GPS', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _buildField('Lat.', _latExecutionCtrl, Icons.map_outlined, keyboardType: TextInputType.number)),
        const SizedBox(width: 8),
        Expanded(child: _buildField('Long.', _lngExecutionCtrl, Icons.map_outlined, keyboardType: TextInputType.number)),
      ],
    );
  }
}
