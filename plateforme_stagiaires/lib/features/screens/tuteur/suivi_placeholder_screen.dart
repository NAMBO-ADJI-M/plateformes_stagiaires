import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';

/// Onglet Suivi (carnets des stagiaires côté tuteur) : aucun mockup fourni,
/// ce placeholder tient la place dans la navigation en attendant le design.
class SuiviPlaceholderScreen extends StatelessWidget {
  const SuiviPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined, size: 42, color: ColorConstants.textSecondary),
            SizedBox(height: 12),
            Text('Suivi des carnets',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorConstants.textPrimary)),
            SizedBox(height: 6),
            Text(
              'Écran à concevoir (aucune maquette fournie pour la vue de suivi détaillée).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: ColorConstants.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
