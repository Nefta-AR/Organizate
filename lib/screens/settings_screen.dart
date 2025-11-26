// Importa Cloud Firestore para leer y actualizar la informacion del usuario.
import 'package:cloud_firestore/cloud_firestore.dart';
// Importa FirebaseAuth para saber quien es el usuario autenticado.
import 'package:firebase_auth/firebase_auth.dart';
// Importa el paquete material porque toda la interfaz usa widgets de Material.
import 'package:flutter/material.dart';
import 'package:organizate/services/notification_service.dart';
import 'package:organizate/utils/reminder_options.dart';

// Declara el widget principal de ajustes como Stateful para poder reaccionar a cambios.
class SettingsScreen extends StatefulWidget {
  // Constructor constante que acepta una clave opcional del widget.
  const SettingsScreen({super.key});

  // Crea el estado concreto que renderizara la pantalla.
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// Define el estado que administra los datos y la UI interactiva.
class _SettingsScreenState extends State<SettingsScreen> {
  // Guarda la referencia al documento del usuario en Firestore.
  late final DocumentReference<Map<String, dynamic>> _userDoc;
  // Controlador que maneja el nombre del contacto de emergencia.
  final TextEditingController _emergencyNameController = TextEditingController();
  // Controlador que maneja el texto del telefono de emergencia.
  final TextEditingController _emergencyPhoneController = TextEditingController();
  // Bandera que dice si el usuario modifico los campos de contacto.
  bool _isEmergencyDirty = false;
  // Bandera que indica si estamos enviando esos datos a Firestore.
  bool _isSavingEmergency = false;
  // Opciones disponibles para el sonido del Pomodoro.
  static const List<Map<String, String>> _pomodoroSoundOptions = [
    {'key': 'bell', 'label': 'Campanilla clásica'},
    {'key': 'notificacion1', 'label': 'Sonido Notificación'},
  ];
  // Lista fija con los nombres de los avatares disponibles.
  static const List<String> _availableAvatars = [
    // Avatar con nombre emoticon.
    'emoticon',
    // Avatar con nombre koala.
    'koala',
    // Avatar con nombre panda.
    'panda',
    // Avatar con nombre pinguino.
    'pinguino',
    // Avatar con nombre rana.
    'rana',
    // Avatar con nombre tigre.
    'tigre',
    // Avatar con nombre unicornio.
    'unicornio',
    // Avatar con nombre zorro.
    'zorro',
  ];

  // Metodo de ciclo de vida que se ejecuta al crear el estado.
  @override
  void initState() {
    // Llama primero al initState de la superclase.
    super.initState();
    // Obtiene el UID del usuario actualmente logueado.
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Crea la referencia al documento users/{uid} dentro de Firestore.
    _userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
  }

  // Metodo de ciclo de vida llamado cuando se libera el estado.
  @override
  void dispose() {
    // Libera los controladores de texto para evitar fugas de memoria.
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    // Llama al dispose de la superclase para completar la limpieza.
    super.dispose();
  }

  // Funcion que guarda el contacto de emergencia en Firestore.
  Future<void> _saveEmergencyContact() async {
    // Marca que se esta guardando para deshabilitar el boton y mostrar spinner.
    setState(() => _isSavingEmergency = true);
    final messenger = ScaffoldMessenger.of(context);
    final trimmedName = _emergencyNameController.text.trim();
    final trimmedPhone = _emergencyPhoneController.text.trim();
    final Map<String, dynamic> payload = {
      // Siempre eliminamos el campo antiguo de phone para evitar inconsistencias.
      'phone': FieldValue.delete(),
    };
    if (trimmedName.isEmpty) {
      payload['emergencyName'] = FieldValue.delete();
    } else {
      payload['emergencyName'] = trimmedName;
    }
    if (trimmedPhone.isEmpty) {
      payload['emergencyPhone'] = FieldValue.delete();
    } else {
      payload['emergencyPhone'] = trimmedPhone;
    }
    try {
      await _userDoc.set(payload, SetOptions(merge: true));
      setState(() => _isEmergencyDirty = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Contacto de emergencia actualizado')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el contacto')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingEmergency = false);
      }
    }
  }

  // Muestra un catalogo de avatares y guarda la seleccion en Firestore.
  Future<void> _showAvatarPicker(String? currentAvatar) async {
    // Permite mostrar mensajes una vez se elija un avatar.
    final messenger = ScaffoldMessenger.of(context);
    // Abre una hoja inferior que devolvera el nombre del avatar pulsado.
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        // Usa SafeArea para que el contenido no quede debajo de la barra de gestos.
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: _availableAvatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                // Obtiene el nombre del avatar en la posicion actual.
                final avatarName = _availableAvatars[index];
                // Comprueba si ese avatar es el que ya esta seleccionado.
                final isSelected = avatarName == currentAvatar;
                // Devuelve un detector de gestos para poder cerrar la hoja con la eleccion.
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(avatarName),
                  child: Column(
                    children: [
                      // Muestra la imagen circular del avatar.
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            AssetImage('assets/avatars/$avatarName.png'),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                      // Agrega un pequeno espacio debajo de la imagen.
                      const SizedBox(height: 6),
                      // Etiqueta con el nombre del avatar.
                      Text(
                        avatarName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    // Cuando se selecciona un avatar se escribe en el documento del usuario.
    if (selected != null) {
      try {
        await _userDoc.set({'avatar': selected}, SetOptions(merge: true));
        // Refresca el estado si el widget sigue en pantalla.
        if (mounted) setState(() {});
        // Muestra un mensaje confirmando el cambio.
        messenger.showSnackBar(
          const SnackBar(content: Text('Avatar actualizado')),
        );
      } catch (_) {
        // Comunica cualquier problema al intentar guardar el avatar.
        messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar el avatar')),
        );
      }
    }
  }

  // Construye la interfaz completa de la pantalla de ajustes.
  @override
  Widget build(BuildContext context) {
    // Devuelve un Scaffold que contiene la AppBar y el cuerpo con scroll.
    return Scaffold(
      // Define la barra superior con el titulo descriptivo.
      appBar: AppBar(
        title: const Text('Perfil y configuracion'),
      ),
      // El cuerpo escucha los cambios del documento del usuario.
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDoc.snapshots(),
        builder: (context, snapshot) {
          // Mientras llega la primera respuesta muestra un spinner.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Si no hay datos disponibles se avisa al usuario.
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text('No se pudo cargar tu perfil.'));
          }

          // Extrae el mapa con la informacion del usuario.
          final data = snapshot.data!.data()!;
          // Obtiene el nombre y usa un valor por defecto si falta.
          final String name = (data['name'] as String?) ?? 'Usuario';
          // Obtiene el correo y cae al email de FirebaseAuth si es necesario.
          final String email =
              (data['email'] as String?) ?? FirebaseAuth.instance.currentUser?.email ?? '';
          // Lee el avatar almacenado (puede ser nulo).
          final String? avatar = data['avatar'] as String?;
          // Lee el contacto de emergencia previamente guardado.
          final String emergencyName = (data['emergencyName'] as String?) ?? '';
          final String emergencyPhone =
              (data['emergencyPhone'] as String?) ?? (data['phone'] as String?) ?? '';
          // Determina si las notificaciones de tareas estan activadas.
          final bool notiTaskEnabled = (data['notiTaskEnabled'] as bool?) ?? true;
          final bool hasDefaultReminderKey =
              data.containsKey('notiTaskDefaultOffsetMinutes');
          // Lee el tiempo por defecto para los recordatorios. Si nunca se configuró usamos el fallback.
          final int? notiOffset = hasDefaultReminderKey
              ? (data['notiTaskDefaultOffsetMinutes'] as num?)?.toInt()
              : kDefaultReminderMinutes;
          // Obtiene el estado del sonido para pomodoro.
          final bool pomodoroSoundEnabled =
              (data['pomodoroSoundEnabled'] as bool?) ?? true;
          // Obtiene el estado de la vibracion para pomodoro.
          final bool pomodoroVibrationEnabled =
              (data['pomodoroVibrationEnabled'] as bool?) ?? false;
          final String pomodoroSoundRaw =
              (data['pomodoroSound'] as String?) ?? 'bell';
          final String pomodoroSound = _pomodoroSoundOptions
                  .any((option) => option['key'] == pomodoroSoundRaw)
              ? pomodoroSoundRaw
              : _pomodoroSoundOptions.first['key']!;
          // Recupera los puntos acumulados.
          final int points = (data['points'] as num?)?.toInt() ?? 0;
          // Recupera la racha actual guardada.
          final int streak = (data['streak'] as num?)?.toInt() ?? 0;
          // Recupera la cantidad de sesiones de foco.
          final int focusSessions =
              (data['focusSessionsCompleted'] as num?)?.toInt() ?? 0;
          // Recupera la cantidad total de minutos de foco.
          final int totalFocusMinutes =
              (data['totalFocusMinutes'] as num?)?.toInt() ?? 0;

          // Si el usuario no escribio nada nuevo se sincroniza el formulario con Firestore.
          if (!_isEmergencyDirty) {
            _emergencyNameController.text = emergencyName;
            _emergencyPhoneController.text = emergencyPhone;
          }

          // Devuelve un scroll para alojar todas las tarjetas de configuracion.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta interactiva para cambiar el avatar.
                GestureDetector(
                  onTap: () => _showAvatarPicker(avatar),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Muestra la foto o un icono por defecto.
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: avatar != null
                                ? AssetImage('assets/avatars/$avatar.png')
                                : null,
                            child:
                                avatar == null ? const Icon(Icons.person, size: 32) : null,
                          ),
                          // Separa el avatar del texto.
                          const SizedBox(width: 16),
                          // Contenedor del texto con nombre y correo.
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Muestra el nombre del usuario.
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Espacio pequeño entre lineas.
                                const SizedBox(height: 4),
                                // Muestra el correo.
                                Text(
                                  email,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                // Espacio pequeño adicional.
                                const SizedBox(height: 4),
                                // Texto guia para indicar que se puede cambiar el avatar.
                                Text(
                                  'Toca para cambiar avatar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Separador vertical entre tarjetas.
                const SizedBox(height: 16),
                // Tarjeta para editar el contacto de emergencia.
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titulo de la seccion de contacto.
                        const Text(
                          'Contacto de emergencia',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Texto auxiliar para contextualizar el campo.
                        const SizedBox(height: 8),
                        Text(
                          'Numero al que llamar en caso de emergencia (opcional).',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        // Espacio antes de los campos de texto.
                        const SizedBox(height: 12),
                        // Campo para el nombre del contacto.
                        TextField(
                          controller: _emergencyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del contacto (ej: Mama, Pareja, Amigo)',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) {
                            if (!_isEmergencyDirty) {
                              setState(() => _isEmergencyDirty = true);
                            }
                          },
                        ),
                        // Espacio antes del campo de telefono.
                        const SizedBox(height: 12),
                        // Campo donde el usuario ingresa su telefono.
                        TextField(
                          controller: _emergencyPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Telefono',
                            hintText: 'Ej: +56 9 1234 5678',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            if (!_isEmergencyDirty) {
                              setState(() => _isEmergencyDirty = true);
                            }
                          },
                        ),
                        // Espacio antes del boton de guardar.
                        const SizedBox(height: 12),
                        // Alinea el boton de guardado a la derecha.
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _isEmergencyDirty && !_isSavingEmergency
                                ? _saveEmergencyContact
                                : null,
                            icon: _isSavingEmergency
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Separador entre secciones.
                const SizedBox(height: 16),
                // Tarjeta para configurar notificaciones de tareas.
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titulo de la seccion de notificaciones.
                        const Text(
                          'Notificaciones de tareas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Espacio antes del interruptor.
                        const SizedBox(height: 12),
                        // Switch que activa o apaga las notificaciones de tareas.
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: notiTaskEnabled,
                          title: const Text('Activar notificaciones de tareas'),
                          onChanged: (value) {
                            _userDoc.set(
                              {'notiTaskEnabled': value},
                              SetOptions(merge: true),
                            );
                          },
                        ),
                        // Espacio antes del Dropdown.
                        const SizedBox(height: 8),
                        // Selector del offset predeterminado para recordatorios.
                        DropdownButtonFormField<int?>(
                          key: ValueKey(notiOffset),
                          decoration: const InputDecoration(
                            labelText: 'Recordarme antes',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: notiOffset,
                          items: kReminderOptions
                              .map(
                                (option) => DropdownMenuItem<int?>(
                                  value: option['minutes'] as int?,
                                  child: Text(option['label'] as String),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            _userDoc.set(
                              {'notiTaskDefaultOffsetMinutes': value},
                              SetOptions(merge: true),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Botón para asegurar configuración de notificaciones en Android/HyperOS
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await NotificationService.ensureDeviceCanDeliverNotifications();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Revisa permisos del sistema y optimización de batería si tu dispositivo es Xiaomi/HyperOS.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings_suggest),
                            label: const Text('Optimizar entrega en mi dispositivo'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prueba de notificación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pulsa para asegurarte de que las notificaciones y el sonido Notificacion1.mp3 funcionan en tu dispositivo.',
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final messenger =
                                  ScaffoldMessenger.of(context);
                              final result = await NotificationService
                                  .showTestNotification(
                                playPreviewSound: true,
                              );
                              if (!context.mounted) return;
                              if (!result.notificationSent) {
                                String failureMessage;
                                switch (result.failure) {
                                  case NotificationTestFailure.permissionDenied:
                                    failureMessage =
                                        'Debes aceptar el permiso de notificaciones para esta app.';
                                    break;
                                  case NotificationTestFailure
                                      .permissionPermanentlyDenied:
                                    failureMessage =
                                        'Activa las notificaciones de la app desde Ajustes del sistema y vuelve a intentarlo.';
                                    break;
                                  default:
                                    failureMessage = result.errorDescription !=
                                            null
                                        ? 'No se pudo enviar la notificación de prueba: ${result.errorDescription}'
                                        : 'No se pudo enviar la notificación de prueba. Revisa los permisos del sistema.';
                                }
                                messenger.showSnackBar(
                                  SnackBar(content: Text(failureMessage)),
                                );
                                return;
                              }
                              final message = result.previewSoundPlayed
                                  ? 'Notificación enviada. Deberías escuchar Notificacion1.mp3.'
                                  : 'Notificación enviada. Activa volumen o permisos para escuchar el sonido.';
                              final fallbackHint = result.usedFallbackSound
                                  ? '\nSe usó el sonido por defecto porque Notificacion1 no está disponible en este dispositivo. Reinstala la app tras ejecutar flutter clean para volver a probar con ese sonido.'
                                  : '';
                              messenger.showSnackBar(
                                SnackBar(content: Text(message + fallbackHint)),
                              );
                            },
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Probar notificación ahora'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Separador previo a la tarjeta de pomodoro.
                const SizedBox(height: 16),
                // Tarjeta de configuraciones relacionadas con foco/pomodoro.
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titulo de la seccion de pomodoro.
                        const Text(
                          'Foco (Pomodoro)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Espacio antes de los switches.
                        const SizedBox(height: 12),
                        // Switch que habilita o deshabilita el sonido.
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Sonido al terminar pomodoro'),
                          value: pomodoroSoundEnabled,
                          onChanged: (value) {
                            _userDoc.set(
                              {'pomodoroSoundEnabled': value},
                              SetOptions(merge: true),
                            );
                          },
                        ),
                        // Switch que habilita o deshabilita la vibracion.
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Vibracion al terminar pomodoro'),
                          value: pomodoroVibrationEnabled,
                          onChanged: (value) {
                            _userDoc.set(
                              {'pomodoroVibrationEnabled': value},
                              SetOptions(merge: true),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey(pomodoroSound),
                          decoration: const InputDecoration(
                            labelText: 'Sonido del Pomodoro',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: pomodoroSound,
                          items: _pomodoroSoundOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option['key'],
                                  child: Text(option['label'] ?? ''),
                                ),
                              )
                              .toList(),
                          onChanged: pomodoroSoundEnabled
                              ? (value) {
                                  if (value == null) return;
                                  _userDoc.set(
                                    {'pomodoroSound': value},
                                    SetOptions(merge: true),
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                // Separador antes del resumen de progreso.
                const SizedBox(height: 16),
                // Tarjeta que muestra datos estadisticos del usuario.
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titulo del resumen.
                        const Text(
                          'Resumen de foco y progreso',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Espacio antes de los textos.
                        const SizedBox(height: 12),
                        // Numero de sesiones completadas.
                        Text('Sesiones de foco completadas: $focusSessions'),
                        // Minutos acumulados de foco.
                        Text('Minutos totales de foco: $totalFocusMinutes'),
                        // Puntos actuales del usuario.
                        Text('Puntos actuales: $points'),
                        // Racha de dias consecutivos completando tareas.
                        Text('Racha actual: $streak dias'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
