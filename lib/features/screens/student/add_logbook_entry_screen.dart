import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class AddLogbookEntryScreen extends StatefulWidget {
  final String carnetId;
  const AddLogbookEntryScreen({super.key, required this.carnetId});

  @override
  State<AddLogbookEntryScreen> createState() => _AddLogbookEntryScreenState();
}

class _AddLogbookEntryScreenState extends State<AddLogbookEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  String _type = 'MISSION';
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _dateDebut = DateTime.now();
  DateTime? _dateFin;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _dateDebut : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.createEntreeJournal(widget.carnetId, {
        'type': _type,
        'titre': _titreCtrl.text.trim(),
        'commentaire_stagiaire': _descCtrl.text.trim(),
        'date_debut': _dateDebut.toIso8601String(),
        'date_fin': _dateFin?.toIso8601String(),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      appBar: AppBar(
        title: const Text('Nouvelle entrée'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type d\'entrée', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: 'Mission',
                      icon: Icons.assignment_outlined,
                      selected: _type == 'MISSION',
                      onTap: () => setState(() => _type = 'MISSION'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeChip(
                      label: 'Difficulté',
                      icon: Icons.warning_amber_rounded,
                      selected: _type == 'DIFFICULTE',
                      onTap: () => setState(() => _type = 'DIFFICULTE'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildField('Titre de la mission / difficulté', _titreCtrl, Icons.title),
              const SizedBox(height: 16),
              _buildField('Description / Commentaire', _descCtrl, Icons.notes, maxLines: 4),
              const SizedBox(height: 24),
              const Text('Dates', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: 'Début',
                      date: _dateDebut,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTile(
                      label: 'Fin (optionnel)',
                      date: _dateFin,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Enregistrer',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: ColorConstants.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Ce champ est requis' : null,
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? ColorConstants.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? ColorConstants.primary : ColorConstants.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : ColorConstants.textSecondary, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : ColorConstants.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateTile({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: ColorConstants.textSecondary)),
            const SizedBox(height: 4),
            Text(date != null ? DateFormat('dd/MM/yyyy').format(date!) : 'Choisir', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
