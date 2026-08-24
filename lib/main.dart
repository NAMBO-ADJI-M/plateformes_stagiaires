import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/features/auth/choose_user_type_page.dart';
import 'package:plateforme_stagiaires/features/auth/code_register_page.dart';
import 'package:plateforme_stagiaires/features/auth/code_verify_page.dart';
import 'package:plateforme_stagiaires/features/screens/student/entreprise_search_screen.dart';
import 'package:plateforme_stagiaires/features/onboarding/onboarding_page.dart';
import 'package:plateforme_stagiaires/features/screens/home_router.dart';
import 'package:plateforme_stagiaires/features/splash/splash_screen.dart';
import 'package:plateforme_stagiaires/modeles/user_type.dart';
import 'package:plateforme_stagiaires/services/api_service.dart';
import 'package:plateforme_stagiaires/services/offline_sync_manager.dart';
import 'package:plateforme_stagiaires/services/notification_service.dart';

/// Permet d'accepter les certificats SSL auto-signés ou Let's Encrypt mal gérés
/// par certaines versions d'Android (nécessaire pour Render/Aiven).
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Appliquer les overrides SSL globalement (pour l'API et les IMAGES)
  HttpOverrides.global = MyHttpOverrides();

  // Charger le token avant de lancer l'application
  final apiService = ApiService();
  await apiService.loadToken();

  // Initialiser le monitoring de la connexion réseau et la synchro offline
  final syncManager = OfflineSyncManager();
  await syncManager.initialize();

  // Initialiser le service de notifications locales
  await NotificationService().initialize();

  runApp(const MonApplication());
}

class MonApplication extends StatefulWidget {
  const MonApplication({super.key});

  @override
  State<MonApplication> createState() => _MonApplicationState();
}

class _MonApplicationState extends State<MonApplication>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Observer les changements du cycle de vie de l'app
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Arrêter le monitoring de la connexion à la fermeture de l'app
    OfflineSyncManager().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'app revient au premier plan : tenter une synchro si des opérations
      // sont en attente (ex: après une mise en veille puis réveil du téléphone)
      ApiService().syncOfflineQueue();
    }
  }

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
                isNewAccount: args?['isNewAccount'] ?? false,
              ),
              settings: settings,
            );

          case '/recherche-entreprise':
            return MaterialPageRoute(builder: (_) => const EntrepriseSearchScreen());

          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeRouter());

          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
