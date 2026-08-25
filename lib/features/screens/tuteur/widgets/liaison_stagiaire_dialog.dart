import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/constants_colors.dart';
import '../../../../services/api_service.dart';
import '../../../widgets/common_widgets.dart';

class LiaisonStagiaireDialog extends StatefulWidget {
  final String stagiaireId;
  final String stagiaireNom;

  const LiaisonStagiaireDialog({
    super.key,
    required this.stagiaireId,
    required this.stagiaireNom,
  });

  @override
  State<LiaisonStagiaireDialog> createState() => _LiaisonStagiaireDialogState();
}

class _LiaisonStagiaireDialogState extends State<LiaisonStagiaireDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les nouveaux champs
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
  
  // Conditions matérielles
  final _lieuExecutionCtrl = TextEditingController();
  final _latExecutionCtrl = TextEditingController();
  final _lngExecutionCtrl = TextEditingController();
  final _dureeHebdoCtrl = TextEditingController();
  final _joursPresenceCtrl = TextEditingController();
  final _teletravailCtrl = TextEditingController();
  
  // Encadrement & Gratification
  final _referentNomCtrl = TextEditingController();
  final _referentContactCtrl = TextEditingController();
  final _modalitesSuiviCtrl = TextEditingController();
  final _congesAbsencesCtrl = TextEditingController();
  
  bool _gratificationPrevue = false;
  final _gratificationMontantCtrl = TextEditingController();
  final _gratificationPeriodiciteCtrl = TextEditingController();
  
  DateTime? _dateDebut;
  DateTime? _dateFin;
  
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String? _generatedCode;

  Future<void> _pickDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir toutes les informations obligatoires.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _api.demanderSuiviPointage(
        stagiaireId: widget.stagiaireId,
        poste: _posteCtrl.text.trim(),
        dateDebut: DateFormat('yyyy-MM-dd').format(_dateDebut!),
        dateFin: DateFormat('yyyy-MM-dd').format(_dateFin!),
        
        etablissementNom: _etablissementCtrl.text.trim(),
        
        tuteurDesigne: _tuteurDesigneCtrl.text.trim(),
        tuteurNom: _tuteurNomCtrl.text.trim(),
        tuteurPrenom: _tuteurPrenomCtrl.text.trim(),
        tuteurFonction: _tuteurFonctionCtrl.text.trim(),
        tuteurEmail: _tuteurEmailCtrl.text.trim(),
        tuteurTelephone: _tuteurTelCtrl.text.trim(),

        raisonSociale: _raisonSocialeCtrl.text.trim(),
        adresse: _adresseCustomCtrl.text.trim(),
        situationGeo: _situationGeoCtrl.text.trim(),
        secteurActivite: _secteurActiviteCtrl.text.trim(),
        entrepriseEmail: _entrepriseEmailDocCtrl.text.trim(),
        entrepriseTelephone: _entrepriseTelDocCtrl.text.trim(),

        repLegalNom: _repLegalNomCtrl.text.trim(),
        repLegalFonction: _repLegalFonctionCtrl.text.trim(),
        repLegalContact: _repLegalContactCtrl.text.trim(),

        objetStage: _objetStageCtrl.text.trim(),
        cursusRattachement: _cursusCtrl.text.trim(),
        anneeAcademique: _anneeAcademiqueCtrl.text.trim(),
        
        lieuExecution: _lieuExecutionCtrl.text.trim(),
        lieuExecutionLat: double.tryParse(_latExecutionCtrl.text.trim()),
        lieuExecutionLng: double.tryParse(_lngExecutionCtrl.text.trim()),
        
        dureeHebdomadaire: _dureeHebdoCtrl.text.trim(),
        joursPresence: _joursPresenceCtrl.text.trim(),
        teletravailModalites: _teletravailCtrl.text.trim(),
        
        referentPedagogiqueNom: _referentNomCtrl.text.trim(),
        referentPedagogiqueContact: _referentContactCtrl.text.trim(),
        modalitesSuiviDetail: _modalitesSuiviCtrl.text.trim(),
        
        gratificationPrevue: _gratificationPrevue,
        gratificationMontant: double.tryParse(_gratificationMontantCtrl.text),
        gratificationPeriodicite: _gratificationPeriodiciteCtrl.text.trim(),
        congesAbsences: _congesAbsencesCtrl.text.trim(),
      );

      setState(() {
        _generatedCode = response['code'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_generatedCode != null) {
      // (Rendu du code inchangé...)
      return _buildCodeView();
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cadre de Liaison', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(widget.stagiaireNom, style: const TextStyle(fontSize: 14, color: ColorConstants.textSecondary)),
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
                _sectionTitle('1. Identité de l\'Entreprise'),
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
                _sectionTitle('2. Représentant Légal'),
                _buildField('Nom complet du représentant', _repLegalNomCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _buildField('Fonction', _repLegalFonctionCtrl, Icons.assignment_ind_outlined),
                const SizedBox(height: 12),
                _buildField('Contact (Email/Tel)', _repLegalContactCtrl, Icons.contact_phone_outlined),

                const SizedBox(height: 24),
                _sectionTitle('3. Cadre Administratif du Stage'),
                _buildField('Poste occupé', _posteCtrl, Icons.work_outline),
                const SizedBox(height: 12),
                _buildField('Établissement de formation', _etablissementCtrl, Icons.school_outlined),
                const SizedBox(height: 12),
                _buildField('Maître de stage (Nom Complet)', _tuteurDesigneCtrl, Icons.person_outline),
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
                _buildField('Objet du stage', _objetStageCtrl, Icons.flag_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Cursus / Filière', _cursusCtrl, Icons.layers_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Année académique', _anneeAcademiqueCtrl, Icons.calendar_today_outlined)),
                  ],
                ),
                
                const SizedBox(height: 24),
                _sectionTitle('4. Conditions matérielles'),
                _buildField('Lieu exact d\'exécution', _lieuExecutionCtrl, Icons.location_on_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                            if (!serviceEnabled) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci d\'activer le GPS sur votre téléphone.')));
                              return;
                            }

                            LocationPermission permission = await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                              if (permission == LocationPermission.denied) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La permission GPS est requise.')));
                                return;
                              }
                            }
                            
                            if (permission == LocationPermission.deniedForever) {
                              ScaffoldMessenger.of(context).showSnackBar(const Text('Veuillez autoriser le GPS dans les réglages.'));
                              return;
                            }

                            final pos = await Geolocator.getCurrentPosition(
                              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
                            );
                            
                            setState(() {
                              _latExecutionCtrl.text = pos.latitude.toString();
                              _lngExecutionCtrl.text = pos.longitude.toString();
                            });
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📍 Lieu d\'exécution localisé !'), backgroundColor: ColorConstants.success));
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur GPS : $e')));
                            }
                          }
                        },
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('Capturer position actuelle', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Lat. exécution', _latExecutionCtrl, Icons.map_outlined, keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Long. exécution', _lngExecutionCtrl, Icons.map_outlined, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('Durée hebdo', _dureeHebdoCtrl, Icons.timer_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Jours présence', _joursPresenceCtrl, Icons.calendar_month_outlined)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField('Modalités télétravail', _teletravailCtrl, Icons.laptop_mac_outlined),

                const SizedBox(height: 24),
                _sectionTitle('5. Encadrement & Suivi'),
                _buildField('Référent pédagogique (École)', _referentNomCtrl, Icons.person_search_outlined),
                const SizedBox(height: 12),
                _buildField('Contact référent', _referentContactCtrl, Icons.contact_mail_outlined),
                const SizedBox(height: 12),
                _buildField('Modalités de suivi détaillé', _modalitesSuiviCtrl, Icons.fact_check_outlined, maxLines: 3),
                const SizedBox(height: 12),
                _buildField('Congés & Absences', _congesAbsencesCtrl, Icons.event_busy_outlined, maxLines: 2),

                const SizedBox(height: 24),
                _sectionTitle('6. Gratification'),
                SwitchListTile(
                  title: const Text('Gratification prévue ?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: _gratificationPrevue,
                  onChanged: (v) => setState(() => _gratificationPrevue = v),
                  activeColor: ColorConstants.primary,
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ColorConstants.primary, letterSpacing: 1)),
    );
  }

  Widget _buildCodeView() {
    return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: ColorConstants.success),
            SizedBox(width: 10),
            Text('Liaison initiée', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transmettez ce code à ${widget.stagiaireNom} pour finaliser la liaison sur son accueil :'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: ColorConstants.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColorConstants.success.withValues(alpha: 0.3)),
              ),
              child: SelectableText(
                _generatedCode!,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: ColorConstants.success),
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
          PrimaryButton(label: 'Fermer', onPressed: () => Navigator.pop(context, true)),
        ],
      );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
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
      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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
