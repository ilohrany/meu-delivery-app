import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'profile_select_screen.dart';


class ErrorScreen extends StatefulWidget {
  const ErrorScreen({super.key});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool _carregando = false;

  Future<void> _tentarNovamente() async {
    setState(() => _carregando = true);
    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}${AppConfig.healthCheckPath}',
      );
      await http.get(uri).timeout(AppConfig.apiTimeout);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSelectScreen()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ainda não foi possível conectar ao servidor.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 80, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                const Text(
                  'Não conseguimos falar com o servidor',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verifique sua conexão com a internet e tente novamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _carregando ? null : _tentarNovamente,
                  icon: _carregando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_carregando ? 'Tentando...' : 'Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
