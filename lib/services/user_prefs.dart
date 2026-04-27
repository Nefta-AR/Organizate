// Importa el paquete para almacenar datos simples en el dispositivo.
import 'package:shared_preferences/shared_preferences.dart';

/// Clase estática (sin constructor público) para gestionar la
/// persistencia de datos (preferencias de usuario) de forma sencilla.
class UserPrefs {
  // Constante estática y privada: la llave bajo la que se guarda el nombre.
  static const _kName = 'display_name';

  /// Guarda el nombre del usuario en el almacenamiento local.
  static Future<void> setName(String name) async {
    // Obtiene una instancia del almacenamiento.
    final sp = await SharedPreferences.getInstance();
    // Guarda el nombre asociado a la llave, eliminando espacios extras.
    await sp.setString(_kName, name.trim());
  }

  /// Recupera el nombre del usuario del almacenamiento local.
  static Future<String?> getName() async {
    // Obtiene una instancia del almacenamiento.
    final sp = await SharedPreferences.getInstance();
    // Lee el valor guardado. Puede ser null si no existe.
    final v = sp.getString(_kName);

    // Valida: si es null o solo contiene espacios, devuelve null.
    if (v == null || v.trim().isEmpty) return null;

    // Devuelve el nombre limpio.
    return v.trim();
  }

  /// Elimina el nombre del almacenamiento local (ej. para cerrar sesión).
  static Future<void> clearName() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kName);
  }
}


