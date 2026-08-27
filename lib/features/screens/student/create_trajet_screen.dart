import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/carpool_service.dart';
import '../../../services/api_exception.dart';

/// Écran de création d'un trajet : formulaire pour proposer un covoiturage.
class CreateTrajetScreen extends StatefulWidget {
  const CreateTrajetScreen({super.key});

  @override
  State<CreateTrajetScreen> createState() => _CreateTrajetScreenState();
}

class _CreateTrajetScreenState extends State<CreateTrajetScreen> {
  final CarpoolService _apiService = CarpoolService();
  final _formKey = GlobalKey<FormState>();

  final _lieuDepartCtrl = TextEditingController();
  final _lieuArriveeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _tarifCtrl = TextEditingController();
  final _placesCtrl = TextEditingController(text: '1');

  DateTime? _dateDepart;
  TimeOfDay? _heureDepart;
  bool _submitting = false;
  String? _erreur;

  @override
  void dispose() {
    _lieuDepartCtrl.dispose();
    _lieuArriveeCtrl.dispose();
    _descriptionCtrl.dispose();
    _tarifCtrl.dispose();
    _placesCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (date != null) {
      setState(() => _dateDepart = date);
    }
  }

  Future<void> _choisirHeure() async {
    final now = TimeOfDay.now();
    final heure = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (heure != null) {
      setState(() => _heureDepart = heure);
    }
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateDepart == null) {
      setState(() => _erreur = 'Merci de sélectionner une date');
      return;
    }

    if (_heureDepart == null) {
      setState(() => _erreur = 'Merci de sélectionner une heure');
      return;
    }

    setState(() => _erreur = null);
    setState(() => _submitting = true);

    try {
      // Géocodage des adresses pour la carte
      double? latDep, lngDep, latArr, lngArr;
      try {
        final locDep = await locationFromAddress(_lieuDepartCtrl.text);
        if (locDep.isNotEmpty) {
          latDep = locDep.first.latitude;
          lngDep = locDep.first.longitude;
        }
        final locArr = await locationFromAddress(_lieuArriveeCtrl.text);
        if (locArr.isNotEmpty) {
          latArr = locArr.first.latitude;
          lngArr = locArr.first.longitude;
        }
      } catch (_) {}

      // Combiner la date et l'heure
      final dateTimeDepart = DateTime(
        _dateDepart!.year,
        _dateDepart!.month,
        _dateDepart!.day,
        _heureDepart!.hour,
        _heureDepart!.minute,
      );

      await _apiService.createTrajet({
        'lieu_depart': _lieuDepartCtrl.text.trim(),
        'lieu_arrivee': _lieuArriveeCtrl.text.trim(),
        'depart_lat': latDep,
        'depart_lng': lngDep,
        'arrivee_lat': latArr,
        'arrivee_lng': lngArr,
        'date_depart': dateTimeDepart.toIso8601String(),
        'description': _descriptionCtrl.text.trim(),
        'tarif': double.tryParse(_tarifCtrl.text.replaceAll(',', '.')) ?? 0,
        'places_disponibles': int.tryParse(_placesCtrl.text) ?? 1,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Trajet créé avec succès !'),
          backgroundColor: ColorConstants.success,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context, true);
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _erreur = e.userFriendlyMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erreur = 'Erreur lors de la création du trajet');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Sélectionner une date';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return 'Sélectionner une heure';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        backgroundColor: ColorConstants.cardBackground,
        foregroundColor: ColorConstants.textPrimary,
        title: const Text('Proposer un trajet'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: ColorConstants.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Proposez votre trajet et économisez en le partageant',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Lieux
              Text('Trajet',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _lieuDepartCtrl,
                decoration: InputDecoration(
                  labelText: 'Lieu de départ *',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Ex: Gare de Lyon',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _lieuArriveeCtrl,
                decoration: InputDecoration(
                  labelText: 'Lieu d\'arrivée *',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Ex: Aéroport CDG',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),

              const SizedBox(height: 24),

              // Date & Heure
              Text('Date et heure',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _submitting ? null : _choisirDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date *',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        child: Text(
                          _formatDate(_dateDepart),
                          style: TextStyle(
                            color: _dateDepart == null
                                ? Colors.grey.shade600
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _submitting ? null : _choisirHeure,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Heure *',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        child: Text(
                          _formatTime(_heureDepart),
                          style: TextStyle(
                            color: _heureDepart == null
                                ? Colors.grey.shade600
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Places & Tarif
              Text('Détails',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _placesCtrl,
                      decoration: InputDecoration(
                        labelText: 'Places disponibles *',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requis';
                        if (int.tryParse(v) == null) return 'Nombre invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _tarifCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tarif par place (€)',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionCtrl,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Ex: Non-fumeur, musique...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Erreur
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
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Bouton soumettre
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _soumettre,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_submitting ? 'Création...' : 'Créer le trajet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
