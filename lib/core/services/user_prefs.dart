// ============================================================
// lib/core/services/user_prefs.dart
// ============================================================
// Wrapper liviano de SharedPreferences para el nombre de
// visualización del usuario.
//
// Se usa como caché local del nombre para evitar lecturas
// innecesarias a Firestore en widgets que solo necesitan
// mostrar el nombre (ej. AppHeader, pantallas de carga).
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  // Clave usada en SharedPreferences para el nombre de display.
  static const _kName = 'display_name';

  /// Guarda el nombre de display del usuario en preferencias locales.
  /// Recorta espacios antes y después de guardar.
  static Future<void> setName(String name) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kName, name.trim());
  }

  /// Devuelve el nombre guardado localmente, o null si no existe o está vacío.
  static Future<String?> getName() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_kName);
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  /// Elimina el nombre guardado localmente (ej. al cerrar sesión).
  static Future<void> clearName() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kName);
  }
}
