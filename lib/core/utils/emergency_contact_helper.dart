// ============================================================
// lib/core/utils/emergency_contact_helper.dart
// ============================================================
// Utilidad para llamar al contacto de emergencia del usuario.
//
// ## Cadena de fallback para llamadas
//
//   1. Llamada directa (Android): [FlutterPhoneDirectCaller] — inicia la
//      llamada sin abrir el marcador. Requiere permiso CALL_PHONE.
//   2. Marcador externo: si la llamada directa falla (permisos denegados,
//      iOS, o no disponible), se abre la app de marcador via `tel://` URI.
//
// ## Enum [_DirectCallStatus]
//
//   - success: llamada iniciada correctamente.
//   - permissionDenied: usuario negó el permiso (se puede volver a pedir).
//   - permanentlyDenied: bloqueado desde Ajustes del sistema.
//   - unavailable: plataforma no Android (iOS, web, desktop).
//   - failed: error genérico al iniciar la llamada.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Muestra el diálogo de confirmación y ejecuta la llamada de emergencia.
///
/// Si no hay contacto configurado, ofrece ir al perfil para agregarlo.
/// Si el permiso de llamada directa no está disponible, abre el marcador.
Future<void> handleEmergencyContactAction(
  BuildContext context, {
  required String? emergencyName,
  required String? emergencyPhone,
  required VoidCallback onNavigateToProfile,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final trimmedPhone = emergencyPhone?.trim();
  // Valida que el teléfono tenga al menos 6 caracteres numéricos
  final hasValidPhone = trimmedPhone != null &&
      trimmedPhone.replaceAll(RegExp(r'\s+'), '').length >= 6;

  // Sin teléfono configurado: ofrecer ir al perfil
  if (!hasValidPhone) {
    final goToProfile = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sin contacto de emergencia'),
        content: const Text(
          'Aun no has configurado un contacto de emergencia. Ve a tu perfil para agregar uno.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ir a Perfil'),
          ),
        ],
      ),
    );
    if (goToProfile == true) onNavigateToProfile();
    return;
  }

  // Limpia espacios del número para la llamada
  final cleanedPhone = trimmedPhone.replaceAll(RegExp(r'\s+'), '');
  final prettyName =
      (emergencyName?.trim().isEmpty ?? true) ? null : emergencyName!.trim();

  // Pedir confirmación al usuario antes de llamar
  final confirmation = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Llamar a contacto de emergencia'),
      content: Text(
        prettyName != null
            ? 'Llamar a $prettyName al $trimmedPhone?'
            : 'Llamar al $trimmedPhone?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Llamar'),
        ),
      ],
    ),
  );

  if (confirmation != true) return;

  // Web no soporta llamadas nativas
  if (kIsWeb) {
    messenger.showSnackBar(
      const SnackBar(
          content: Text('Las llamadas solo funcionan en la app movil.')),
    );
    return;
  }

  // Paso 1: Intentar llamada directa (Android solamente)
  final directCallStatus = await _tryDirectEmergencyCall(cleanedPhone);
  switch (directCallStatus) {
    case _DirectCallStatus.success:
      return; // Llamada iniciada exitosamente, terminar aquí
    case _DirectCallStatus.permissionDenied:
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Para llamar automaticamente concede el permiso de telefono. Abriendo el marcador...',
          ),
        ),
      );
      break;
    case _DirectCallStatus.permanentlyDenied:
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Activa el permiso de llamadas en Ajustes del sistema para usar el boton SOS. Abriendo el marcador...',
          ),
        ),
      );
      break;
    case _DirectCallStatus.failed:
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'No se pudo iniciar la llamada directa. Abriendo el marcador...'),
        ),
      );
      break;
    case _DirectCallStatus.unavailable:
      break; // iOS/desktop: ir directamente al marcador sin mostrar error
  }

  // Paso 2 (fallback): Abrir el marcador via URI tel://
  final uri = Uri.parse('tel:$cleanedPhone');
  try {
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar la llamada.')),
      );
    }
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No se pudo iniciar la llamada.')),
    );
  }
}

/// Intenta iniciar una llamada directa en Android sin abrir el marcador.
/// Gestiona los permisos de llamada automáticamente.
Future<_DirectCallStatus> _tryDirectEmergencyCall(String phone) async {
  // Solo disponible en Android
  if (defaultTargetPlatform != TargetPlatform.android) {
    return _DirectCallStatus.unavailable;
  }

  PermissionStatus status;
  try {
    status = await Permission.phone.status;
  } catch (_) {
    return _DirectCallStatus.failed;
  }

  // Solicitar permiso si aún no fue otorgado o fue restringido
  if (status.isDenied || status.isRestricted) {
    status = await Permission.phone.request();
  }

  if (status.isPermanentlyDenied) return _DirectCallStatus.permanentlyDenied;
  if (!status.isGranted) return _DirectCallStatus.permissionDenied;

  try {
    final success = await FlutterPhoneDirectCaller.callNumber(phone);
    return success == true
        ? _DirectCallStatus.success
        : _DirectCallStatus.failed;
  } catch (_) {
    return _DirectCallStatus.failed;
  }
}

/// Estado del intento de llamada directa (sin abrir el marcador).
enum _DirectCallStatus {
  success,           // Llamada iniciada correctamente
  permissionDenied,  // Permiso negado (se puede volver a pedir)
  permanentlyDenied, // Permiso bloqueado (requiere abrir Ajustes del sistema)
  unavailable,       // No disponible en esta plataforma (iOS, web, desktop)
  failed,            // Error genérico al iniciar la llamada
}
