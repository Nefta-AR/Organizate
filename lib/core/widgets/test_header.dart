// ============================================================
// lib/core/widgets/test_header.dart
// ============================================================
// Widget de cabecera de la app (prototipo de gamificación).
//
// Muestra:
//   - Nombre "Simple" a la izquierda.
//   - Contadores de tokens (⭐) y recompensas (🔥) centrados.
//   - Avatar de usuario a la derecha.
//
// Se usa como `title` del AppBar en pantallas de onboarding
// (TestInitialScreen). En el resto de la app, el AppBar
// muestra el título de la pantalla directamente.
// ============================================================

import 'package:flutter/material.dart';

/// Cabecera de app con nombre, tokens y recompensas gamificadas.
///
/// Se usa como widget hijo del parámetro `title` de [AppBar].
class AppHeader extends StatelessWidget {
  /// Cantidad de tokens acumulados (muestra con ⭐).
  final int tokens;

  /// Cantidad de recompensas o racha (muestra con 🔥).
  final int rewards;

  const AppHeader({super.key, required this.tokens, required this.rewards});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Nombre de la app
        const Text(
          'Simple',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const Spacer(),
        Row(
          children: [
            // Contador de tokens (estrellas)
            const Icon(Icons.star, size: 20, color: Colors.amber),
            const SizedBox(width: 4),
            Text('$tokens',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            // Contador de recompensas/racha (llama)
            const Icon(Icons.local_fire_department,
                size: 20, color: Colors.orange),
            const SizedBox(width: 4),
            Text('$rewards',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            // Avatar circular del usuario
            CircleAvatar(
              radius: 14,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.sentiment_satisfied_alt,
                  size: 18, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }
}
