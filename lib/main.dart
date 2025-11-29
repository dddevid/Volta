import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'core/api/api_client.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Italian locale for date formatting
  await initializeDateFormatting('it_IT', null);
  runApp(const NuvolaApp());
}

class NuvolaApp extends StatelessWidget {
  const NuvolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Crea una singola istanza di ApiClient
    final apiClient = ApiClient();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(AppConstants.primaryColorValue),
                primary: const Color(AppConstants.primaryColorValue),
                secondary: const Color(AppConstants.secondaryColorValue),
                error: const Color(AppConstants.errorColorValue),
                background: const Color(AppConstants.scaffoldBackgroundColor),
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor:
                  const Color(AppConstants.scaffoldBackgroundColor),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(AppConstants.primaryColorValue),
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
              ),
              textTheme: GoogleFonts.interTextTheme(
                const TextTheme(
                  displayLarge: TextStyle(color: Color(0xFF1A1A1A)),
                  displayMedium: TextStyle(color: Color(0xFF1A1A1A)),
                  displaySmall: TextStyle(color: Color(0xFF1A1A1A)),
                  headlineMedium: TextStyle(color: Color(0xFF1A1A1A)),
                  headlineSmall: TextStyle(color: Color(0xFF1A1A1A)),
                  titleLarge: TextStyle(color: Color(0xFF1A1A1A)),
                  titleMedium: TextStyle(color: Color(0xFF1A1A1A)),
                  titleSmall: TextStyle(color: Color(0xFF1A1A1A)),
                  bodyLarge: TextStyle(color: Color(0xFF333333)),
                  bodyMedium: TextStyle(color: Color(0xFF333333)),
                  bodySmall: TextStyle(color: Color(0xFF666666)),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(AppConstants.primaryColorValue),
                primary: const Color(AppConstants.primaryColorValue),
                secondary: const Color(AppConstants.secondaryColorValue),
                error: const Color(AppConstants.errorColorValue),
                background: const Color(0xFF121212),
                surface: const Color(0xFF1E1E1E),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
              ),
              textTheme: GoogleFonts.interTextTheme(
                const TextTheme(
                  displayLarge: TextStyle(color: Colors.white),
                  displayMedium: TextStyle(color: Colors.white),
                  displaySmall: TextStyle(color: Colors.white),
                  headlineMedium: TextStyle(color: Colors.white),
                  headlineSmall: TextStyle(color: Colors.white),
                  titleLarge: TextStyle(color: Colors.white),
                  titleMedium: TextStyle(color: Colors.white),
                  titleSmall: TextStyle(color: Colors.white),
                  bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
                  bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
                  bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
                ),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// Splash screen per verificare lo stato di autenticazione
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = await authProvider.checkAuthStatus();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              isAuthenticated ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
