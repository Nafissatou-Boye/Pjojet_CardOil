import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'langue/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'models/models.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/client/client_dashboard.dart';
import 'screens/corporate/corporate_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
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


class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final loggedIn = await authService.isLoggedIn();

    if (!loggedIn) {
      if (mounted) setState(() { _loading = false; _destination = const WelcomeScreen(); });
      return;
    }

   
    final result = await authService.loadUserProfile();
    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'] as UserModel;
      _destination = _screenForRole(user);
    } else {
      
      await authService.signOut();
      _destination = const WelcomeScreen();
    }

    if (mounted) setState(() => _loading = false);
  }


  Widget _screenForRole(UserModel user) {
    final role = (user.role ?? '').toUpperCase().trim();
    print('🔀 AuthWrapper role: "$role" uid: ${user.uid}');

    switch (role) {
      case 'EMPLOYE':              // LOGIN 5 chiffres
        return CorporateDashboardScreen(userId: user.uid);
      case 'CLIENT':
      default:
        return const ClientDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))));
    }
    return _destination ?? const WelcomeScreen();
  }
}