import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../widgets/common_widgets.dart';

/// Reproduit progression-screen.png : anneau global, 3 barres de détail par
/// catégorie, et jalons hebdomadaires (checklist).
class ProgressionScreen extends StatelessWidget {
  const ProgressionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text('Votre Progression',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ColorConstants.textPrimary)),
        const SizedBox(height: 4),
        const Text('Aperçu de vos réalisations de stage',
            style: TextStyle(fontSize: 13.5, color: ColorConstants.textSecondary)),
        const SizedBox(height: 18),
        AppCard(
          child: Row(
            children: [
              const ProgressRing(percent: 0.62, size: 78),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Objectifs validés',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            color: ColorConstants.textPrimary)),
                    SizedBox(height: 6),
                    Text(
                      'Vous avez complété la majorité de vos objectifs obligatoires.',
                      style: TextStyle(
                          fontSize: 12.5, color: ColorConstants.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text('Détails par catégorie',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: ColorConstants.textPrimary)),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: [
              _DetailRow(
                  label: 'Missions complétées',
                  value: '8 sur 12',
                  percent: 8 / 12,
                  color: ColorConstants.primary),
              const SizedBox(height: 16),
              _DetailRow(
                  label: 'Compétences acquises',
                  value: '6 sur 10',
                  percent: 6 / 10,
                  color: ColorConstants.info),
              const SizedBox(height: 16),
              _DetailRow(
                  label: 'Heures de stage réalisées',
                  value: '180h sur 300h',
                  percent: 180 / 300,
                  color: ColorConstants.success),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text('Jalons hebdomadaires',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: ColorConstants.textPrimary)),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: const [
              _MilestoneRow(
                  week: 'Semaine 6', title: 'Validation Maquette V2', done: true),
              Divider(height: 24),
              _MilestoneRow(
                  week: 'Semaine 5', title: 'Préparation des Tests', done: true),
              Divider(height: 24),
              _MilestoneRow(
                  week: 'Semaine 4',
                  title: 'Analyse Benchmark concurrentiel',
                  done: true),
              Divider(height: 24),
              _MilestoneRow(
                  week: 'Semaine 3',
                  title: 'Exploration des personas de stage',
                  done: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color color;

  const _DetailRow(
      {required this.label,
      required this.value,
      required this.percent,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13.5, color: ColorConstants.textPrimary)),
            Text(value,
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressRow(percent: percent, color: color),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final String week;
  final String title;
  final bool done;

  const _MilestoneRow(
      {required this.week, required this.title, required this.done});

  @override
  Widget build(BuildContext context) {
    final color = done ? ColorConstants.success : ColorConstants.textSecondary;
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: color,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(week,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: done ? ColorConstants.success : ColorConstants.textSecondary)),
              const SizedBox(height: 2),
              Text(title,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: done ? ColorConstants.textPrimary : ColorConstants.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
