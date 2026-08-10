import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        _NotificationTile(
          title: 'Nouveau message de votre tuteur',
          subtitle: 'Vérifiez votre messagerie pour plus de détails.',
        ),
        SizedBox(height: 16),
        _NotificationTile(
          title: 'Document ajouté',
          subtitle: 'Votre convention de stage est maintenant disponible.',
        ),
        SizedBox(height: 16),
        _NotificationTile(
          title: 'Rappel de réunion',
          subtitle: 'Réunion de suivi demain à 14h.',
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NotificationTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
