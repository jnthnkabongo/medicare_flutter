import 'package:flutter/material.dart';
import 'services/initialization_service.dart';
import 'services/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/pages/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicare - Gestion Hospitalière',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final InitializationService _initService = InitializationService();
  final AuthService _authService = AuthService();

  bool _isInitializing = true;
  String _statusMessage = 'Initialisation de l\'application...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _statusMessage = 'Vérification de la base de données...';
      });

      final result = await _initService.initializeApp();

      if (result.success) {
        setState(() {
          _statusMessage = result.message;
        });

        // Attendre un peu pour que l'utilisateur voie le message
        await Future.delayed(const Duration(seconds: 2));

        // Vérifier si un utilisateur est déjà connecté
        await _authService.loadUser();

        if (mounted) {
          if (_authService.isLoggedIn) {
            // L'utilisateur est déjà connecté, aller au dashboard
            Navigator.of(context).pushReplacementNamed('/dashboard');
          } else if (result.needsAdminSetup) {
            // Aucun admin, aller à la page d'inscription
            Navigator.of(context).pushReplacementNamed('/signup');
          } else {
            // Admin existe mais personne connecté, aller au login
            Navigator.of(context).pushReplacementNamed('/login');
          }
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur lors de l\'initialisation: $e';
      });
    }
  }

  void _retryInitialization() {
    setState(() {
      _isInitializing = true;
      _hasError = false;
      _errorMessage = '';
      _statusMessage = 'Nouvelle tentative d\'initialisation...';
    });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade800],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo et titre
                Icon(Icons.local_hospital, size: 100, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  'Medicare',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Système de Gestion Hospitalière',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 48),

                // État d'initialisation
                if (_isInitializing) ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Erreur
                if (_hasError) ...[
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Erreur d\'initialisation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _retryInitialization,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
