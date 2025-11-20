// Importa Cloud Firestore para leer y actualizar la informacion del usuario.
import 'package:cloud_firestore/cloud_firestore.dart';
// Importa FirebaseAuth para saber quien es el usuario autenticado.
import 'package:firebase_auth/firebase_auth.dart';
// Importa el paquete material porque toda la interfaz usa widgets de Material.
import 'package:flutter/material.dart';

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
  // Controlador que maneja el texto del campo de telefono.
  final TextEditingController _phoneController = TextEditingController();
  // Bandera que dice si el usuario modifico el telefono localmente.
  bool _isPhoneDirty = false;
  // Bandera que indica si estamos enviando el telefono a Firestore.
  bool _isSavingPhone = false;
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
    // Libera el controlador de texto para evitar fugas de memoria.
    _phoneController.dispose();
    // Llama al dispose de la superclase para completar la limpieza.
    super.dispose();
  }

  // Funcion que guarda el telefono escrito en el TextField.
  Future<void> _savePhone() async {
    // Marca que se esta guardando para deshabilitar el boton y mostrar spinner.
    setState(() => _isSavingPhone = true);
    // Obtiene el messenger para poder mostrar mensajes tipo SnackBar.
    final messenger = ScaffoldMessenger.of(context);
    // Quita espacios antes y despues del numero ingresado.
    final trimmed = _phoneController.text.trim();
    try {
      // Si el usuario borro el texto se elimina el campo phone del documento.
      if (trimmed.isEmpty) {
        await _userDoc.set(
          {'phone': FieldValue.delete()},
          SetOptions(merge: true),
        );
      } else {
        // Si hay texto se guarda el numero nuevo en el documento.
        await _userDoc.set(
          {'phone': trimmed},
          SetOptions(merge: true),
        );
      }
      // Marca que ya no hay cambios pendientes en el campo de telefono.
      setState(() => _isPhoneDirty = false);
      // Muestra un mensaje indicando exito.
      messenger.showSnackBar(
        const SnackBar(content: Text('Telefono actualizado')),
      );
    } catch (_) {
      // Si ocurre un error avisa al usuario que no se guardo.
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el telefono')),
      );
    } finally {
      // Al terminar, si el widget sigue montado, desmarca el estado de guardado.
      if (mounted) {
        setState(() => _isSavingPhone = false);
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
          // Lee el telefono previamente guardado.
          final String phone = (data['phone'] as String?) ?? '';
          // Determina si las notificaciones de tareas estan activadas.
          final bool notiTaskEnabled = (data['notiTaskEnabled'] as bool?) ?? true;
          // Lee el tiempo por defecto para los recordatorios.
          final int notiOffset =
              (data['notiTaskDefaultOffsetMinutes'] as num?)?.toInt() ?? 30;
          // Obtiene el estado del sonido para pomodoro.
          final bool pomodoroSoundEnabled =
              (data['pomodoroSoundEnabled'] as bool?) ?? true;
          // Obtiene el estado de la vibracion para pomodoro.
          final bool pomodoroVibrationEnabled =
              (data['pomodoroVibrationEnabled'] as bool?) ?? false;
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

          // Si el usuario no escribio nada nuevo se sincroniza el textbox con Firestore.
          if (!_isPhoneDirty) {
            _phoneController.text = phone;
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
                // Tarjeta para editar el telefono de contacto.
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titulo de la seccion de telefono.
                        const Text(
                          'Telefono de contacto',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Espacio antes del campo de texto.
                        const SizedBox(height: 12),
                        // Campo donde el usuario ingresa su telefono.
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Agrega un numero para recordatorios',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            if (!_isPhoneDirty) {
                              setState(() => _isPhoneDirty = true);
                            }
                          },
                        ),
                        // Espacio antes del boton de guardar.
                        const SizedBox(height: 12),
                        // Alinea el boton de guardado a la derecha.
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _isPhoneDirty && !_isSavingPhone ? _savePhone : null,
                            icon: _isSavingPhone
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
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Recordarme antes',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: notiOffset,
                          items: const [15, 30, 60, 120]
                              .map(
                                (minutes) => DropdownMenuItem<int>(
                                  value: minutes,
                                  child: Text('$minutes minutos'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _userDoc.set(
                                {'notiTaskDefaultOffsetMinutes': value},
                                SetOptions(merge: true),
                              );
                            }
                          },
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
