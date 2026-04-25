import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'langue/app_localizations.dart';
import 'services/auth_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/client/client_dashboard.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CardOilApp());
}

class CardOilApp extends StatelessWidget {
  const CardOilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppLocaleProvider()),
      ],
      child: Consumer<AppLocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'Card Oil',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
            ),
            locale: localeProvider.locale,
            supportedLocales: AppLocaleProvider.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthWrapper(),
            routes: {
              '/welcome': (_) => const WelcomeScreen(),
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/dashboard': (_) => const ClientDashboard(),
            },
          );
        },
      ),
    );
  }
}



class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // On ne fait aucune vérification de token → toujours WelcomeScreen
    return const WelcomeScreen();
  }
}