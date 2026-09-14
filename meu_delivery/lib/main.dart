import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MeuDeliveryApp());
}

class MeuDeliveryApp extends StatelessWidget {
  const MeuDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFFF5722),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const SplashScreen(),
    );
  }
}
