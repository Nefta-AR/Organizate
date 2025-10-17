// lib/widgets/test_header.dart

import 'package:flutter/material.dart';


/// Encabezado compacto (Row con el título y contadores) para usar dentro de un AppBar.
class TestHeader extends StatelessWidget {
  final int tokens;
  final int rewards;


  const TestHeader({super.key, required this.tokens, required this.rewards});


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Título de la aplicación.
        const Text(
          'Organízate',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const Spacer(), // Ocupa el espacio restante en el medio.

        // Contenedor de los indicadores (tokens y recompensas).
        Row(
          children: [
            // Contador de Tokens (Estrellas/Monedas).
            const Icon(Icons.star, size: 20, color: Colors.amber),
            const SizedBox(width: 4),
            Text('$tokens', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),

            // Contador de Racha/Recompensas (Fuego).
            const Icon(Icons.local_fire_department, size: 20, color: Colors.orange),
            const SizedBox(width: 4),
            Text('$rewards', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),

            // Icono de Avatar.
            CircleAvatar(
              radius: 14,
              // CORRECCIÓN: Usamos .withOpacity(0.15) para la opacidad.
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              child: const Icon(Icons.sentiment_satisfied_alt, size: 18, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }
}