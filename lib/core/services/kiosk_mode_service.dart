// lib/core/services/kiosk_mode_service.dart
//
// Servicio para controlar el modo Kiosk (bloqueo de pantalla) en Android.
//
// Usa MethodChannel para comunicarse con el código nativo Kotlin que ejecuta
// `startLockTask()` / `stopLockTask()` de Android.
//
// ## Comportamiento
//
// - **Activar**: Bloquea la navegación fuera de la app (no funciona botón home,
//   recientes, ni cambio de app). La primera vez Android pide confirmación al usuario.
// - **Desactivar**: Requiere PIN de tutor/cuidador para evitar que el usuario
//   salga accidentalmente del modo kiosk.
// - **Persistencia**: El estado se guarda en Firestore (`kioskModeEnabled`) para
//   que el tutor pueda activarlo remotamente desde su panel.
//
// ## Limitaciones
//
// - Solo funciona en Android 5.0+ (API 21+).
// - En dispositivos sin device owner, el usuario debe confirmar la primera vez.
// - No bloquea el botón de encendido/apagado.

import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KioskModeService {
  KioskModeService._();

  static const _channel = MethodChannel('com.example.organizate/kiosk_mode');
  static const _usersCollection = 'users';

  /// Activa el modo kiosk y persiste el estado en Firestore.
  static Future<void> enable({String? userId}) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _channel.invokeMethod('startKioskMode');
      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(uid)
          .set({'kioskModeEnabled': true}, SetOptions(merge: true));
    } on PlatformException catch (e) {
      // Si no hay actividad (ej: en web), se ignora silenciosamente
      if (e.code != 'NO_ACTIVITY') rethrow;
    }
  }

  /// Desactiva el modo kiosk y persiste el estado en Firestore.
  static Future<void> disable({String? userId}) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _channel.invokeMethod('stopKioskMode');
      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(uid)
          .set({'kioskModeEnabled': false}, SetOptions(merge: true));
    } on PlatformException catch (e) {
      if (e.code != 'NO_ACTIVITY') rethrow;
    }
  }

  /// Verifica si el modo kiosk está activo actualmente.
  static Future<bool> isActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isKioskModeActive');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Lee el estado persistente de Firestore.
  static Future<bool> isEnabledInFirestore({String? userId}) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection(_usersCollection)
        .doc(uid)
        .get();

    return doc.data()?['kioskModeEnabled'] as bool? ?? false;
  }

  /// Stream del estado de kiosk mode desde Firestore.
  static Stream<bool> streamEnabled({String? userId}) {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['kioskModeEnabled'] as bool? ?? false);
  }
}
