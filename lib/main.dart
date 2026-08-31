import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'theme.dart';
import 'screens/router_screen.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'widgets/app_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Necesario para formatear fechas en español (DateFormat con locale 'es').
  // Sin esto, cualquier pantalla que muestre la fecha en texto revienta con
  // LocaleDataException.
  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const RefugioApp());
}

class RefugioApp extends StatelessWidget {
  const RefugioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      // Español en los widgets de Material (selector de rango de fechas).
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}

/// Splash breve con animación de entrada del logo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();

  @override
  void initState() {
    super.initState();
    _decidir();
  }

  Future<void> _decidir() async {
    final sp = await SharedPreferences.getInstance();
    await ApiService.cargarToken();
    final logueado =
        (sp.getBool('rf_logged_in') ?? false) && ApiService.token.isNotEmpty;
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, a, __) => FadeTransition(
          opacity: a,
          child: logueado ? const RouterScreen() : const LoginScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: _c, curve: Curves.easeOutCubic)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: AppLogo(size: 76, vertical: true),
            ),
          ),
        ),
      ),
    );
  }
}
