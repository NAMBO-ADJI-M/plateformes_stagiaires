import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';

/// Reproduit attestation-screen.png : formulaire de création d'attestation,
/// switch "Inclure une recommandation LinkedIn", bloc "Partager à une future
/// entreprise" (carte d'appui), aperçu et bouton "Générer et envoyer".
class AttestationsScreen extends StatefulWidget {
  const AttestationsScreen({super.key});

  @override
  State<AttestationsScreen> createState() => _AttestationsScreenState();
}

class _AttestationsScreenState extends State<AttestationsScreen> {
  bool _recommandationLinkedIn = true;
  final _nomStagiaireCtrl = TextEditingController(text: 'Marie Dupont');
  final _periodeCtrl = TextEditingController(text: '01/02/2026 au 31/07/2026');
  final _posteCtrl = TextEditingController(text: 'Stagiaire R&D UI/UX Designer');
  final _appreciationCtrl = TextEditingController(
      text:
          "Marie a fait preuve d'une grande rigueur et d'une créativité remarquable dans ses propositions de maquettes V2.");
  final _entrepriseCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text('Attestations',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.textPrimary)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Créer une attestation',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                        color: ColorConstants.textPrimary)),
                const SizedBox(height: 14),
                _LabeledField(label: 'Nom du stagiaire', controller: _nomStagiaireCtrl),
                const SizedBox(height: 12),
                _LabeledField(label: 'Période de stage', controller: _periodeCtrl),
                const SizedBox(height: 12),
                _LabeledField(label: 'Poste occupé', controller: _posteCtrl),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Appréciation générale',
                  controller: _appreciationCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Inclure une recommandation LinkedIn',
                          style: TextStyle(
                              fontSize: 13, color: ColorConstants.textPrimary)),
                    ),
                    Switch(
                      value: _recommandationLinkedIn,
                      activeThumbColor: ColorConstants.primary,
                      onChanged: (v) => setState(() => _recommandationLinkedIn = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Partager à une future entreprise',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: ColorConstants.textPrimary)),
                const SizedBox(height: 12),
                _LabeledField(
                  label: "Nom de l'entreprise",
                  controller: _entrepriseCtrl,
                  hint: 'Ex: Orange, Decathlon...',
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Email du destinataire',
                  controller: _emailCtrl,
                  hint: 'Ex: rh@entreprise.com',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.visibility_outlined, size: 17, color: ColorConstants.primary),
                    SizedBox(width: 8),
                    Text('Aperçu du document final',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: ColorConstants.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"ATTESTATION DE STAGE — Certifie que ${_nomStagiaireCtrl.text} a effectué un stage d\'UI/UX Design chez Ubisoft France..."',
                  style: const TextStyle(fontSize: 12.5, color: ColorConstants.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Générer et envoyer',
            icon: Icons.check_circle_outline,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attestation générée et envoyée.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12.5, color: ColorConstants.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13.5, color: ColorConstants.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: ColorConstants.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
