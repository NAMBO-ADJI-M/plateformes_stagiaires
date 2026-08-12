import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/features/auth/choose_user_type_page.dart';
import 'package:plateforme_stagiaires/features/auth/code_register_page.dart';
import 'package:plateforme_stagiaires/features/auth/code_verify_page.dart';
import 'package:plateforme_stagiaires/features/onboarding/onboarding_page.dart';
import 'package:plateforme_stagiaires/features/screens/home_router.dart';
import 'package:plateforme_stagiaires/features/splash/splash_screen.dart';
import 'package:plateforme_stagiaires/modeles/user_type.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';  // ✅ AJOUTER CET IMPORT

Future<void> main() async {  // ✅ AJOUTER async
  WidgetsFlutterBinding.ensureInitialized();  // ✅ AJOUTER

  // ✅ Charger le token avant de lancer l'application
  final apiService = ApiService();
  await apiService.loadToken();

  runApp(const MonApplication());
}

class MonApplication extends StatelessWidget {
  const MonApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plateforme Stagiaire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: ColorConstants.primary,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingPage());

          case '/auth':
            return MaterialPageRoute(
              builder: (_) => const ChooseUserTypePage(),
              settings: settings,
            );

          case '/register-code':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => CodeRegisterPage(
                email: args?['email'] ?? '',
                userType: args?['userType'] ?? UserType.stagiaire,
              ),
              settings: settings,
            );

          case '/verify-code':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => CodeVerifyPage(
                email: args?['email'] ?? '',
                userType: args?['userType'] ?? UserType.stagiaire,
              ),
              settings: settings,
            );

          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeRouter());

          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}