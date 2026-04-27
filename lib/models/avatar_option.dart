// lib/models/avatar_option.dart

import 'package:flutter/material.dart';

// Clase de modelo para representar una opción de avatar.
class AvatarOption {
  final String name;
  final String imagePath; // Ahora es la ruta al archivo PNG
  final Color color;      // Color principal del borde y acento

  const AvatarOption({
    required this.name,
    required this.imagePath,
    required this.color,
  });
}