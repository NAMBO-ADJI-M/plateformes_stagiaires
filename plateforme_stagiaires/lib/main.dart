<<<<<<< HEAD
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/features/auth/choose_user_type_page.dart';
import 'package:plateforme_stagiaires/features/auth/code_login_page.dart';
import 'package:plateforme_stagiaires/features/auth/code_register_page.dart';  // ✅ Vérifier cet import
import 'package:plateforme_stagiaires/features/auth/code_verify_page.dart';
import 'package:plateforme_stagiaires/features/home/main_navigation_page.dart';
import 'package:plateforme_stagiaires/features/onboarding/onboarding_page.dart';
import 'package:plateforme_stagiaires/features/splash/splash_screen.dart';
import 'package:plateforme_stagiaires/modeles/user_type.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

=======
import 'package:flutter/material.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/features/auth/choose_user_type_page.dart';
import 'package:plateforme_stagiaires/features/auth/code_login_page.dart';
import 'package:plateforme_stagiaires/features/home/home_page.dart';
import 'package:plateforme_stagiaires/features/onboarding/onboarding_page.dart';
import 'package:plateforme_stagiaires/features/splash/splash_screen.dart';

void main() {
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
  runApp(const MonApplication());
}

class MonApplication extends StatelessWidget {
  const MonApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plateforme Stagiaire',
      debugShowCheckedModeBanner: false,
<<<<<<< HEAD
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

          case '/login-code':
            final args = settings.arguments as UserType?;
            return MaterialPageRoute(
              builder: (_) => CodeLoginPage(userType: args ?? UserType.stagiaire),
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
            return MaterialPageRoute(builder: (_) => const MainNavigationPage());

          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
=======
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
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
