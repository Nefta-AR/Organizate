import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  final uri = Uri.parse('tel:$cleanedPhone');
  try {
    final success = await launchUrl(uri);
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
