import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Maneja la interaccion de llamada al contacto de emergencia reutilizable.
Future<void> handleEmergencyContactAction(
  BuildContext context, {
  required String? emergencyName,
  required String? emergencyPhone,
  required VoidCallback onNavigateToProfile,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final trimmedPhone = emergencyPhone?.trim();
  final hasValidPhone =
      trimmedPhone != null && trimmedPhone.replaceAll(RegExp(r'\s+'), '').length >= 6;

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
    if (goToProfile == true) {
      onNavigateToProfile();
    }
    return;
  }

  final cleanedPhone = trimmedPhone.replaceAll(RegExp(r'\s+'), '');
  final prettyName =
      (emergencyName?.trim().isEmpty ?? true) ? null : emergencyName!.trim();
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

  if (confirmation != true) {
    return;
  }

  if (kIsWeb) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Las llamadas solo funcionan en la app movil.'),
      ),
    );
    return;
  }

  final directCallStatus = await _tryDirectEmergencyCall(cleanedPhone);
  switch (directCallStatus) {
    case _DirectCallStatus.success:
      return;
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
          content: Text('No se pudo iniciar la llamada directa. Abriendo el marcador...'),
        ),
      );
      break;
    case _DirectCallStatus.unavailable:
      break;
  }

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

Future<_DirectCallStatus> _tryDirectEmergencyCall(String phone) async {
  if (defaultTargetPlatform != TargetPlatform.android) {
    return _DirectCallStatus.unavailable;
  }

  PermissionStatus status;
  try {
    status = await Permission.phone.status;
  } catch (_) {
    return _DirectCallStatus.failed;
  }

  if (status.isDenied || status.isRestricted) {
    status = await Permission.phone.request();
  }

  if (status.isPermanentlyDenied) {
    return _DirectCallStatus.permanentlyDenied;
  }
  if (!status.isGranted) {
    return _DirectCallStatus.permissionDenied;
  }

  try {
    final success = await FlutterPhoneDirectCaller.callNumber(phone);
    if (success == true) {
      return _DirectCallStatus.success;
    }
    return _DirectCallStatus.failed;
  } catch (_) {
    return _DirectCallStatus.failed;
  }
}

enum _DirectCallStatus {
  success,
  permissionDenied,
  permanentlyDenied,
  unavailable,
  failed,
}
