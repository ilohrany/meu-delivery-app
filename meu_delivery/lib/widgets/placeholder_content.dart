import 'package:flutter/material.dart';

class PlaceholderContent extends StatelessWidget {
  final String titulo;
  final IconData icone;

  const PlaceholderContent({
    super.key,
    required this.titulo,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Tela de $titulo',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          const Text(
            '(conteúdo será implementado em outra tarefa)',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
