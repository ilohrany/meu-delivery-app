import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'client/client_home_screen.dart';
import 'error_screen.dart';
import 'profile_select_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    
    await Future.delayed(const Duration(milliseconds: 900));
    await _verificarServidor();
  }

  Future<void> _verificarServidor() async {
    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}${AppConfig.healthCheckPath}',
      );
      await http.get(uri).timeout(AppConfig.apiTimeout);

      if (!mounted) return;
      await _verificarSessao();
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ErrorScreen()),
      );
    }
  }


  Future<void> _verificarSessao() async {
    final logado = await AuthService.tokenValido();
    if (!mounted) return;

    if (logado) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSelectScreen()),
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
            const Icon(
              Icons.delivery_dining,
              size: 96,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Quero Delivery',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
