// lib/core/widgets/app_header.dart

import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final int tokens;
  final int rewards;

  const AppHeader({super.key, required this.tokens, required this.rewards});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Simple',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.star, size: 20, color: Colors.amber),
            const SizedBox(width: 4),
            Text('$tokens',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            const Icon(Icons.local_fire_department,
                size: 20, color: Colors.orange),
            const SizedBox(width: 4),
            Text('$rewards',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
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
