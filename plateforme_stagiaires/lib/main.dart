import 'package:flutter/material.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/features/auth/choose_user_type_page.dart';
import 'package:plateforme_stagiaires/features/auth/code_login_page.dart';
import 'package:plateforme_stagiaires/features/home/home_page.dart';
import 'package:plateforme_stagiaires/features/onboarding/onboarding_page.dart';
import 'package:plateforme_stagiaires/features/splash/splash_screen.dart';

void main() {
  runApp(const MonApplication());
}

class MonApplication extends StatelessWidget {
  const MonApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plateforme Stagiaire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: ColorConstants.primary),
      home: const SplashScreen(),
      routes: {
        '/onboarding': (_) => const OnboardingPage(),
        '/auth': (_) => const ChooseUserTypePage(),
        '/login-code': (_) => const CodeLoginPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}
