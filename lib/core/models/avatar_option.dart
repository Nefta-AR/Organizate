// ============================================================
// lib/core/models/avatar_option.dart
// ============================================================
// Modelo inmutable que representa una opción de avatar en el
// selector de perfil de usuario.
//
// Cada avatar tiene:
//   - [name]: identificador textual (ej. "emoticon", "zorro").
//   - [imagePath]: ruta relativa al asset PNG del avatar.
//   - [color]: color temático asociado para el fondo del avatar.
// ============================================================

import 'package:flutter/material.dart';

/// Modelo inmutable de una opción de avatar de usuario.
class AvatarOption {
  /// Nombre identificador del avatar (ej. 'zorro', 'panda').
  final String name;

  /// Ruta del asset de imagen (ej. 'assets/avatars/zorro.png').
  final String imagePath;

  /// Color temático del avatar para fondos o bordes.
  final Color color;

  const AvatarOption({
    required this.name,
    required this.imagePath,
    required this.color,
  });
}
