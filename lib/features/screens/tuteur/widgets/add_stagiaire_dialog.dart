import 'package:flutter/material.dart';
import '../../../../core/constants/constants_colors.dart';
import '../../../../services/api_service.dart';
import '../../../widgets/common_widgets.dart';

class AddStagiaireDialog extends StatefulWidget {
  const AddStagiaireDialog({super.key});

  @override
  State<AddStagiaireDialog> createState() => _AddStagiaireDialogState();
}

class _AddStagiaireDialogState extends State<AddStagiaireDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _generatedCode;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.createFicheInvitation({
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });

      setState(() {
        _generatedCode = response['code_invitation'];
        _isLoading = false;
      });
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
    if (_generatedCode != null) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Invitation générée', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Transmettez ce code à votre stagiaire pour qu\'il puisse lier son carnet :'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorConstants.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                _generatedCode!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: ColorConstants.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          PrimaryButton(
            label: 'Terminer',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Inviter un stagiaire', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField('Prénom', _prenomCtrl, Icons.person_outline),
              const SizedBox(height: 12),
              _buildField('Nom', _nomCtrl, Icons.person_outline),
              const SizedBox(height: 12),
              _buildField('Email', _emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        SizedBox(
          width: 150,
          child: PrimaryButton(
            label: 'Générer le code',
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
    );
  }
}
