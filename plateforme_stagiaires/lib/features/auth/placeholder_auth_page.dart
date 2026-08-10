import 'package:flutter/material.dart';

class AuthPlaceholderPage extends StatelessWidget {
  const AuthPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authentification')),
      body: const Center(
        child: Text(
          'Page d’authentification stagiaire / tuteur à implémenter.',
        ),
      ),
    );
  }
}
