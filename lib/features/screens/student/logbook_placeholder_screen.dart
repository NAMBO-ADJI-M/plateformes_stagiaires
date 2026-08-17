import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';

/// Onglet Logbook (carnet de stage) : aucun mockup fourni pour cet écran,
/// ce placeholder tient uniquement la place dans la navigation en attendant
/// le design définitif.
class LogbookPlaceholderScreen extends StatelessWidget {
  const LogbookPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 42, color: ColorConstants.textSecondary),
            SizedBox(height: 12),
            Text('Carnet de stage',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ColorConstants.textPrimary)),
            SizedBox(height: 6),
            Text(
              'Écran à concevoir (aucune maquette fournie pour le carnet détaillé).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: ColorConstants.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
