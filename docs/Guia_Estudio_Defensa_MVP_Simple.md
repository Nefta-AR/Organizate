# Guia de estudio para la defensa del MVP - Simple

Fecha de estudio: 8 de julio de 2026  
Presentacion: 9 de julio de 2026  
Objetivo: que puedas explicar el proyecto con seguridad, moverte por el codigo y responder preguntas tecnicas sin quedarte en blanco.

---

## 0. Como estudiar esta guia si tienes TDAH

No intentes memorizar cada linea. La defensa no se gana recitando codigo; se gana entendiendo el mapa.

Usa esta regla:

1. Primero aprende el flujo completo: "login -> rol -> pantalla -> Firestore -> Cloud Functions".
2. Luego aprende donde vive cada cosa.
3. Despues memoriza 10 respuestas clave.
4. Finalmente practica abriendo los archivos mientras explicas.

Frase ancla:

> "Simple es una app Flutter con Firebase. Flutter muestra la interfaz, Firebase Auth identifica al usuario, Firestore guarda los datos, Storage guarda imagenes, Cloud Functions protege la IA y FCM/notificaciones recuerdan tareas."

Si se te olvida algo, vuelve a esa frase.

---

## 1. Explicacion en 60 segundos

Simple es una aplicacion movil desarrollada en Flutter para apoyar a personas neurodivergentes, principalmente TEA y TDAH. Tiene dos roles:

- Usuario: usa tareas, foco, pictogramas, Super Experto y configuracion personal.
- Tutor: supervisa usuarios vinculados, agrega tareas, revisa pictogramas, progreso, historial y ajustes.

La app usa Firebase como backend:

- Firebase Auth para iniciar sesion.
- Firestore para guardar usuarios, tareas, pictogramas, progreso y vinculaciones.
- Firebase Storage para imagenes personalizadas.
- Cloud Functions para ejecutar codigo servidor, incluyendo Gemini y notificaciones.
- FCM y notificaciones locales para recordatorios.

La API de Gemini no esta dentro de la app movil. La app llama a una Cloud Function llamada `desglosarTarea`, y esa funcion llama a Gemini usando un secret de Firebase. Asi, aunque alguien descompile el APK, no encuentra directamente la API key.

---

## 2. Mapa simple del proyecto

Piensa el proyecto como una casa:

| Parte | Que es | Donde esta |
|---|---|---|
| Puerta principal | Inicializa Firebase y abre la app | `lib/main.dart` |
| Guardia de entrada | Decide si va a Login, Usuario o Tutor | `lib/core/navigation/auth_gate.dart` |
| Pasillos | Barra inferior y navegacion | `lib/core/widgets/custom_nav_bar.dart` |
| Habitacion usuario | Inicio, tareas, foco, pictogramas, perfil | `lib/features/tutor_dashboard/screens/home_screen.dart`, `lib/features/tda_focus/`, `lib/features/tea_board/`, `settings_screen.dart` |
| Habitacion tutor | Panel de supervision | `lib/features/tutor_dashboard/screens/tutor_supervise_screen.dart` |
| Bodega de datos | Firestore, Storage, Auth | `lib/core/services/` |
| Cocina servidor | Cloud Functions, Gemini, TTS, push | `functions/src/index.ts` |
| Candados | Reglas de seguridad | `firestore.rules` |

---

## 3. Flujo completo desde que abre la app

Archivo principal: `lib/main.dart`

Orden real:

1. `WidgetsFlutterBinding.ensureInitialized()`
   - Prepara Flutter antes de usar plugins nativos.

2. `Firebase.initializeApp(...)`
   - Conecta la app con el proyecto Firebase.

3. `FirebaseMessaging.onBackgroundMessage(...)`
   - Registra el handler de mensajes push en segundo plano.

4. `initializeDateFormatting('es', null)`
   - Permite fechas en espanol.

5. `NotificationService.init()`
   - Prepara notificaciones locales.

6. `PushNotificationService.initialize()`
   - Guarda el token FCM del dispositivo.

7. `runApp(MultiProvider(... MyApp()))`
   - Levanta la interfaz y deja disponible `PomodoroService`.

8. `MaterialApp(home: AuthGate())`
   - La primera pantalla real es `AuthGate`.

Respuesta corta si te preguntan:

> "La app parte en `main.dart`, inicializa Firebase, notificaciones y servicios globales. Luego monta `AuthGate`, que decide que pantalla corresponde segun sesion, onboarding y rol."

---

## 4. AuthGate: la maquina de decisiones

Archivo: `lib/core/navigation/auth_gate.dart`

AuthGate tiene 3 niveles:

### Nivel 1: sesion

Clase: `AuthGate`

Usa:

```dart
FirebaseAuth.instance.authStateChanges()
```

Decide:

- Si no hay usuario -> `LoginScreen`.
- Si hay usuario -> `_UserOnboardingGate`.

### Nivel 2: documento del usuario

Clase: `_UserOnboardingGate`

Lee:

```text
users/{uid}
```

Decide:

- Sin `role` -> `RoleSelectionScreen`.
- Sin onboarding -> `RoleSelectionScreen`.
- Sin perfil -> `ProfileSetupScreen`.
- Todo listo -> `RoleDispatcher`.

### Nivel 3: rol

Clase: `RoleDispatcher`

Decide:

- `role == 'tutor'` -> `TutorSupervisarScreen`.
- cualquier otro -> `HomeScreen`.

Respuesta corta:

> "No navego manualmente con muchos push. Uso streams reactivos: si cambia Firebase Auth o Firestore, la app cambia sola de pantalla."

---

## 5. Pantallas principales del usuario

### 5.1 Inicio

Archivo: `lib/features/tutor_dashboard/screens/home_screen.dart`

Responsabilidad:

- Saludo del usuario.
- Frase motivacional.
- Tarea prioritaria.
- Promo de Super Experto.
- Accesos rapidos a Estudios, Hogar y Meds.
- Boton magico arrastrable.
- Tour de bienvenida del usuario.

Metodos importantes:

| Metodo | Que hace |
---|---|
| `_loadFabPosition()` | Carga la posicion del boton magico desde `SharedPreferences`. |
| `_saveFabPosition()` | Guarda donde el usuario dejo el boton. |
| `_buildBody()` | Construye el contenido principal de Inicio. |
| `_buildGreeting()` | Muestra nombre y frase motivacional. |
| `_buildPriorityTaskCard()` | Escucha tareas pendientes y elige la prioritaria. |
| `_buildEmptyPriorityCard()` | Muestra "Todo al dia" si no hay tareas. |
| `_buildTaskCard()` | Dibuja la tarjeta de tarea prioritaria. |
| `_buildSuperExpertoPromo()` | Tarjeta que abre el asistente IA. |
| `_buildQuickAccess()` | Botones Estudios, Hogar, Meds. |
| `_toggleTaskCompletion()` | Marca tarea como hecha y suma/resta puntos. |
| `_startHomeTour()` | Muestra el tour de bienvenida. |
| `_buildDraggableFab()` | Boton magico movible con long press. |

Explicacion simple:

> "Inicio es el tablero rapido. No muestra todo; muestra lo mas urgente y accesos directos. Para evitar ansiedad, prioriza una tarea y deja el resto disponible en Tareas."

### 5.2 Tareas

Archivo: `lib/features/tda_focus/screens/tareas_screen.dart`

Responsabilidad:

- Listar tareas.
- Crear, editar, eliminar.
- Filtrar por categoria.
- Programar recordatorios.
- Manejar tareas recurrentes.

Datos:

```text
users/{uid}/tasks/{taskId}
```

Campos tipicos:

| Campo | Para que sirve |
---|---|
| `text` | Descripcion de la tarea. |
| `category` | Estudios, Hogar, Meds, Foco, General. |
| `done` | Si esta completada. |
| `dueDate` | Fecha/hora de entrega. |
| `reminderMinutes` | Cuantos minutos antes avisar. |
| `recurrence` | daily, weekly, monthly. |
| `deletedByUser` | Soft delete para mantener historial. |
| `addedByTutor` | Marca si la creo el tutor. |

Respuesta corta:

> "Las tareas viven en Firestore bajo cada usuario. La app las escucha con streams, por eso si un tutor agrega una tarea, al usuario le aparece en tiempo real."

### 5.3 Foco

Archivo: `lib/features/tda_focus/screens/foco_screen.dart`

Servicio principal:

```text
lib/features/tda_focus/services/pomodoro_service.dart
```

Responsabilidad:

- Temporizador Pomodoro.
- Pausar, reanudar, cancelar.
- Persistir estado aunque el usuario cambie de pantalla.
- Notificar cuando termina.

Por que usa `Provider`:

> "PomodoroService se registra en `main.dart` con `ChangeNotifierProvider`, porque el temporizador debe vivir mas que una pantalla. Si navego, no quiero que el timer muera."

### 5.4 Progreso

Archivo: `lib/features/tda_focus/screens/progreso_screen.dart`

Responsabilidad:

- Graficos de avance.
- Estadisticas de tareas.
- Uso de pictogramas.
- Sesiones de foco.

Libreria:

```text
fl_chart
```

Respuesta corta:

> "Progreso transforma datos de Firestore en graficos simples para que usuario y tutor entiendan avances sin leer tablas."

### 5.5 Pictogramas TEA

Archivo principal:

```text
lib/features/tea_board/screens/pantalla_paciente_tea.dart
```

Pantallas relacionadas:

| Archivo | Que hace |
---|---|
| `pantalla_paciente_tea.dart` | Tablero visible para el usuario. |
| `pictogram_manager_screen.dart` | Gestiona visibilidad/categorias. |
| `crear_pictograma_sheet.dart` | Crea pictograma personalizado. |
| `pictogram_crop_page.dart` | Recorte de imagen. |

Metodos importantes en `pantalla_paciente_tea.dart`:

| Metodo | Que hace |
---|---|
| `_initTts()` | Configura texto a voz. |
| `_buildPictogramasStream()` | Mezcla banco base + pictogramas custom + settings. |
| `_crearPictograma()` | Abre flujo de creacion. |
| `_abrirManager()` | Abre gestion de pictogramas. |
| `_toggleSilentMode()` | Activa/desactiva voz. |
| `_hablar()` | Reproduce texto con TTS. |
| `_hablarPictograma()` | Habla el pictograma tocado y registra actividad. |
| `_editarTexto()` | Permite editar texto de pictograma custom. |
| `_startUserTour()` | Tour especifico del tablero TEA. |

Explicacion simple:

> "El tablero TEA es comunicacion aumentativa. Cada pictograma es un boton visual. Al tocarlo, la app dice el texto en voz alta y registra el uso para que el tutor pueda ver patrones."

### 5.6 Perfil / Configuracion

Archivo:

```text
lib/features/tutor_dashboard/screens/settings_screen.dart
```

Responsabilidad:

- Perfil y foto/avatar.
- Rol.
- Vinculacion tutor/usuario.
- Contacto de emergencia.
- Notificaciones.
- Sonido Pomodoro.
- Backup Google Drive.
- Repetir tour.
- Cerrar sesion.

Metodos importantes:

| Metodo | Que hace |
---|---|
| `_handleLogout()` | Cierra sesion. |
| `_saveEmergencyContact()` | Guarda contacto de emergencia. |
| `_uploadProfilePhoto()` | Sube foto de perfil. |
| `_showAvatarPicker()` | Cambia avatar local. |
| `_buildVinculacionCard()` | Vista de vinculacion segun rol. |
| `_vincularConTutor()` | Usuario acepta codigo de tutor. |
| `_buildPantallasNavTile()` | Acceso a configuracion de pantallas. |
| `_buildTourCard()` | Reinicia tours de bienvenida. |
| `_handleBackup()` | Respaldar en Drive. |
| `_handleRestore()` | Restaurar desde Drive. |

Respuesta corta:

> "Settings es un centro de control. No es solo perfil; tambien concentra vinculacion, respaldo, notificaciones, emergencia y tours."

---

## 6. Pantalla principal del tutor

Archivo:

```text
lib/features/tutor_dashboard/screens/tutor_supervise_screen.dart
```

Responsabilidad:

- Elegir usuario supervisado.
- Ver y crear tareas.
- Gestionar pictogramas.
- Ver progreso.
- Ver historial.
- Ajustar pantallas disponibles del usuario.
- Mostrar tour de bienvenida del tutor.

Tabs del tutor:

| Tab | Clase/metodo | Que explica |
---|---|---|
| Tareas | `_TutorTasksTab` | Pendientes, completadas, eliminadas, agregar tarea. |
| Pictogramas | `_TutorPictogramsTab` | Gestionar pictogramas del usuario vinculado. |
| Progreso | `ProgresoScreen(userId: pk)` | Reutiliza la pantalla de progreso pero con UID del paciente. |
| Historial | `_TutorHistorialTab` | Lee `activityLog` del usuario. |
| Ajustes | `_TutorConfigTab` | Activa/desactiva pantallas para el usuario. |

Concepto clave:

> "El tutor no entra a la cuenta del usuario. El tutor usa su propia cuenta y las reglas de Firestore le permiten leer/escribir solo si existe una vinculacion activa."

Metodos importantes:

| Metodo | Que hace |
---|---|
| `_scheduleTutorTourIfNeeded()` | Decide si mostrar tour tutor o tour sin pacientes. |
| `_startTutorTour()` | Tour cuando ya hay usuario vinculado. |
| `_startEmptyTutorTour()` | Tour cuando aun no hay usuarios. |
| `_showPatientPicker()` | Cambia usuario supervisado. |
| `_buildAppBar()` | Nombre/avatar del usuario y configuracion. |
| `_buildNoPatients()` | Estado cuando no hay usuarios vinculados. |
| `_TutorTasksTab._addTask()` | Tutor crea tarea para usuario. |
| `_TutorTasksTab._toggleDone()` | Tutor marca/desmarca tarea. |
| `_TutorTasksTab._deleteTask()` | Elimina tarea desde supervision. |
| `_TutorConfigTab._toggle()` | Activa/desactiva pantallas. |
| `_TutorHistorialTab` | Escucha el log de actividad. |

Respuesta corta:

> "TutorSupervisarScreen es el dashboard del tutor. Usa `AuthService.getLinkedPatientsStream()` para saber que usuarios estan vinculados y renderiza un `IndexedStack` con las cinco secciones principales."

---

## 7. Navegacion inferior dinamica

Archivo:

```text
lib/core/widgets/custom_nav_bar.dart
```

Idea:

La barra inferior no es fija. Lee flags desde:

```text
users/{uid}/pictogramSettings/_features
```

Flags:

| Flag | Controla |
---|---|
| `featureInicio` | Mostrar Inicio. |
| `featureTareas` | Mostrar Tareas. |
| `featurePictogramas` | Mostrar Pictogramas. |
| `featureFoco` | Mostrar Foco. |
| `featurePerfil` | Mostrar Perfil. |

Por que importa:

> "Un tutor puede adaptar la app al usuario. Si una pantalla abruma, se puede ocultar sin borrar datos."

Metodos:

| Metodo | Que hace |
---|---|
| `_listenSettings()` | Escucha flags en Firestore. |
| `_entries` | Construye lista de tabs visibles. |
| `_indexOf()` | Evita indices invalidos si cambia la lista. |
| `_onItemTapped()` | Navega con `pushReplacement` sin animacion. |

Respuesta corta:

> "La navegacion es configurable en tiempo real. Si el tutor desactiva una pantalla, la app actualiza la barra y redirige al usuario a una pantalla disponible."

---

## 8. Super Experto IA y Gemini

Front:

```text
lib/features/onboarding/screens/super_experto_sheet.dart
lib/features/tda_focus/services/ia_service.dart
```

Backend:

```text
functions/src/index.ts
```

Flujo:

1. Usuario abre Super Experto.
2. Selecciona o escribe una tarea.
3. Escoge tiempo disponible.
4. `SuperExpertoSheet._generarPlan()` llama a:

```dart
IAService.desglosarEnPasos(...)
```

5. `IAService` llama a Firebase Cloud Function:

```dart
httpsCallable('desglosarTarea')
```

6. Cloud Function valida que el usuario este autenticado:

```ts
if (!request.auth) throw unauthenticated
```

7. Cloud Function arma prompt y llama a Gemini.
8. Si Gemini falla por cuota/servicio, usa `generarPlanLocal(...)`.
9. Devuelve pasos JSON.
10. La app muestra los pasos y puede guardarlos como subtareas.

Respuesta corta:

> "La app nunca llama directo a Gemini. Llama a Cloud Functions. Eso protege la API key, centraliza el prompt y permite fallback local si Gemini falla."

### Seguridad de la API de Gemini

Donde se protege:

```ts
const GEMINI_API_KEY = params.defineSecret('GEMINI_API_KEY');
```

Eso significa:

- La key no esta hardcodeada en Flutter.
- La key no va dentro del APK.
- La key no deberia estar en Git.
- Solo Cloud Functions la lee en servidor.

La funcion usa:

```ts
secrets: [GEMINI_API_KEY]
```

Y luego:

```ts
const apiKey = GEMINI_API_KEY.value();
```

Respuesta si preguntan "como evitas que roben la API key":

> "No incluyo la key en el cliente. El APK solo conoce el nombre de la Cloud Function. La API key vive como Firebase Secret y solo se resuelve en el entorno servidor. Ademas, la funcion exige `request.auth`, valida parametros, limita timeout e incluye fallback local."

Honestidad tecnica:

> "Esto no hace imposible todo abuso, pero reduce mucho la exposicion. Para una version productiva mas robusta agregaria Firebase App Check, cuotas por usuario, rate limiting y monitoreo de uso."

---

## 9. Backend Firebase: que guarda cada cosa

Coleccion central:

```text
users/{userId}
```

Subcolecciones:

| Ruta | Que guarda |
---|---|
| `users/{uid}/tasks` | Tareas del usuario. |
| `users/{uid}/pictograms` | Pictogramas personalizados. |
| `users/{uid}/pictogramSettings` | Visibilidad/categoria y flags de pantallas. |
| `users/{uid}/activityLog` | Historial de acciones. |
| `users/{uid}/linkedTutors` | Tutores vinculados al usuario. |
| `users/{uid}/invitationCodes` | Codigos del tutor si aplica. |

Colecciones globales:

| Ruta | Que guarda |
---|---|
| `invitationCodes/{code}` | Codigos de vinculacion tutor-usuario. |
| `sensitiveData/{patientId}` | Datos clinicos tutor-only. |
| `pictogramTemplates/{templateId}` | Banco publico de pictogramas. |

Storage:

```text
users/{uid}/pictograms/{filename}
user_photos/{uid}/profile.jpg
```

---

## 10. Reglas de seguridad Firestore

Archivo:

```text
firestore.rules
```

Idea simple:

> "La seguridad no depende de esconder botones. Aunque alguien modifique la app, Firestore valida permisos en servidor."

Funciones clave:

| Funcion | Que valida |
---|---|
| `isAuthenticated()` | Hay usuario logueado. |
| `getUserRole()` | Lee rol desde Firestore. |
| `isTutor()` | Usuario autenticado con rol tutor. |
| `isUsuario()` | Usuario autenticado con rol usuario. |
| `isOwner(userId)` | El usuario esta tocando su propio documento. |
| `isLinkedPatient(tutorId, patientId)` | Tutor esta vinculado al usuario. |
| `isLinkedTutor(patientId, tutorId)` | Usuario esta vinculado a ese tutor. |
| `canReadUser(userId)` | Puede leer si es owner, tutor vinculado o usuario vinculado al tutor. |

Reglas importantes:

- El usuario puede leer/escribir sus propios datos.
- El tutor puede leer datos de usuarios vinculados.
- El tutor puede crear tareas y pictogramas para usuarios vinculados.
- El usuario escribe su `activityLog`; el tutor lo lee.
- `sensitiveData` es solo para tutor vinculado.
- `invitationCodes` permite validar codigos y marcarlos como usados.

Respuesta corta:

> "La relacion tutor-usuario no se basa solo en el campo rol. Se valida con documentos `linkedTutors/{tutorId}` activos. Eso evita que cualquier tutor vea cualquier usuario."

---

## 11. Vinculacion tutor-usuario

Servicio:

```text
lib/core/services/auth_service.dart
```

Flujo:

1. Tutor genera codigo.
   - Metodo: `AuthService.generateInvitationCode()`.
   - Guarda en `invitationCodes/{code}`.

2. Usuario ingresa codigo.
   - Metodo: `AuthService.validateInvitationCode(code)`.
   - Verifica existencia, estado y expiracion.

3. Usuario acepta.
   - Metodo: `AuthService.acceptInvitationCode(code)`.
   - Marca codigo como `used`.
   - Crea `users/{patientId}/linkedTutors/{tutorId}`.
   - Guarda `acceptedInvitationCode`.

4. Tutor ve usuario.
   - Metodo: `AuthService.getLinkedPatientsStream()`.
   - Busca codigos usados por ese tutor y lee usuarios.

Respuesta corta:

> "La vinculacion se hace con codigo de invitacion. Cuando se acepta, queda una relacion persistente en Firestore. Las reglas usan esa relacion para permitir o negar acceso."

---

## 12. Pictogramas: banco base + personalizados

Servicio:

```text
lib/core/services/pictogram_service.dart
```

Modelo:

```dart
PictogramaPersonalizado
```

Campos:

| Campo | Explicacion |
---|---|
| `id` | ID Firestore. |
| `imageUrl` | URL de Storage o asset. |
| `etiqueta` | Texto visible. |
| `textoTts` | Texto que dira la voz. |
| `categoria` | Categoria del tablero. |
| `createdAt` | Orden cronologico. |

Flujo de creacion:

1. `pickImageFromCamera()` o `pickImageFromGallery()`.
2. `cropImage()` recorta cuadrado 1:1.
3. `uploadImage()` sube a Storage.
4. `createPictogram()` crea documento en Firestore.

Metodos con `For(userId)`:

> "Permiten que el tutor trabaje sobre los pictogramas del usuario vinculado, sin cambiar de cuenta."

Respuesta corta:

> "El banco base son assets locales. Los personalizados viven en Storage y Firestore. Las preferencias de visibilidad/categoria se guardan por usuario en `pictogramSettings`."

---

## 13. Tareas, puntos y racha

Pantallas:

```text
home_screen.dart
tareas_screen.dart
tutor_supervise_screen.dart
```

Servicios:

```text
lib/features/tda_focus/services/streak_service.dart
lib/core/services/reminder_dispatcher.dart
```

Cuando el usuario completa una tarea:

1. Se actualiza `done`.
2. Se suman puntos.
3. Se cancela recordatorio.
4. Se actualiza racha.
5. Se registra actividad.
6. Cloud Function puede notificar al tutor.

Cloud Function relacionada:

```text
notifyTutorOnTaskComplete
```

Respuesta corta:

> "Completar una tarea no solo cambia un checkbox. Tambien actualiza gamificacion, cancela recordatorios, registra actividad y puede avisar al tutor."

---

## 14. Recordatorios y notificaciones

Servicios:

| Archivo | Rol |
---|---|
| `notification_service.dart` | Notificaciones locales. |
| `push_notification_service.dart` | Tokens FCM y cola remota. |
| `reminder_dispatcher.dart` | Coordina local + remoto. |

Cloud Function:

```text
processDueNotifications
```

Flujo:

1. Usuario crea tarea con fecha y recordatorio.
2. `ReminderDispatcher.scheduleTaskReminder()` programa dos canales:
   - local con `NotificationService`.
   - remoto con `PushNotificationService.queueRemoteReminder()`.
3. Se crea un documento en `notificationQueue`.
4. Cloud Function programada corre cada minuto.
5. Busca recordatorios vencidos.
6. Envia FCM.
7. Marca estado `sent`, `failed` o `no_tokens`.

Respuesta corta:

> "Uso una estrategia dual: notificacion local para respuesta inmediata y cola remota para mayor confiabilidad con FCM."

---

## 15. Actividad e historial

Servicio:

```text
lib/core/services/activity_log_service.dart
```

Ruta:

```text
users/{uid}/activityLog
```

Eventos:

| Tipo | Cuando ocurre |
---|---|
| `task_completed` | Completa tarea. |
| `task_created` | Crea tarea. |
| `task_deleted` | Elimina tarea. |
| `pictogram_created` | Crea pictograma. |
| `pictogram_deleted` | Elimina pictograma. |
| `pictogram_used` | Usa pictograma/TTS. |
| `pomodoro_completed` | Termina Pomodoro. |

Por que falla silenciosamente:

> "El log es observacional. Si falla, no debe romper la experiencia del usuario."

Respuesta corta:

> "ActivityLog es una bitacora. El usuario la genera y el tutor la consulta para supervision."

---

## 16. Backup Google Drive

Servicio:

```text
lib/core/services/google_drive_service.dart
```

Pantalla:

```text
settings_screen.dart
```

Que respalda:

- Configuracion.
- Pictogramas locales.
- Preferencias relevantes.

Respuesta corta:

> "Google Drive se usa para que el usuario tenga soberania sobre sus datos. No depende solo de nuestra plataforma para conservar configuracion y recursos."

---

## 17. Tours de bienvenida

Servicio:

```text
lib/core/services/tour_service.dart
```

Widget:

```text
lib/core/widgets/tour_step_card.dart
```

Donde se usan:

| Tour | Archivo |
---|---|
| Usuario Inicio | `home_screen.dart` |
| Usuario TEA/Pictogramas | `pantalla_paciente_tea.dart` |
| Tutor con pacientes | `tutor_supervise_screen.dart` |
| Tutor sin pacientes | `tutor_supervise_screen.dart` |

Como recuerda si ya se mostro:

```text
SharedPreferences
```

Respuesta corta:

> "Los tours no son pantallas separadas. Son overlays que resaltan elementos reales de la interfaz para ensenar sin sacar al usuario del flujo."

---

## 18. Viabilidad del proyecto

Si preguntan "es viable?", responde:

> "Si, es viable porque usa tecnologias maduras: Flutter para multiplataforma y Firebase para autenticacion, base de datos, storage, funciones y notificaciones. El MVP ya demuestra los flujos criticos: login, roles, tareas, pictogramas, IA, tutor, vinculacion y sincronizacion en tiempo real."

Puntos fuertes:

- Arquitectura por modulos.
- Seguridad en Firestore rules.
- Rol tutor/usuario claro.
- IA protegida por Cloud Functions.
- Sincronizacion en tiempo real.
- App entregable por APK.

Limitaciones honestas:

- No hay suite completa de tests automatizados.
- App Check y rate limiting por usuario serian mejoras de produccion.
- FCM puede depender de configuracion del dispositivo.
- Google Drive requiere permisos y cuenta Google.

Respuesta equilibrada:

> "Para un MVP academico y funcional, esta listo. Para produccion masiva, reforzaria pruebas automatizadas, App Check, monitoreo de funciones, rate limiting y documentacion de soporte."

---

## 19. Preguntas probables y respuestas

### Que tecnologia usaste?

> "Flutter para el frontend movil/web, Firebase para backend: Auth, Firestore, Storage, Cloud Functions y FCM."

### Por que Flutter?

> "Porque permite construir una experiencia consistente multiplataforma con una sola base de codigo, y tiene buen soporte para accesibilidad, Material Design y Firebase."

### Como separas usuario y tutor?

> "El rol vive en `users/{uid}.role`. `AuthGate` lee ese rol y `RoleDispatcher` manda a `HomeScreen` o `TutorSupervisarScreen`."

### Como evitas que un tutor vea usuarios que no corresponden?

> "Firestore rules validan que exista `users/{patientId}/linkedTutors/{tutorId}` con `status == active`. Sin esa relacion, el acceso se niega en servidor."

### Donde esta la API de Gemini?

> "No esta en Flutter ni en el APK. Esta en Cloud Functions como Firebase Secret: `GEMINI_API_KEY`."

### Que pasa si Gemini falla?

> "La Cloud Function intenta modelos alternativos y si hay cuota o servicio caido, usa `generarPlanLocal()`, que crea un plan basico sin IA."

### Por que usar Cloud Functions?

> "Para ejecutar logica sensible en servidor: proteger API keys, enviar notificaciones, usar TTS, procesar recordatorios y mantener reglas de negocio fuera del cliente."

### Que es Firestore?

> "Una base NoSQL en tiempo real. La app escucha documentos y subcolecciones con streams, por eso los cambios aparecen instantaneamente."

### Que diferencia hay entre Auth y Firestore rules?

> "Auth identifica quien eres. Firestore rules decide que puedes leer o escribir."

### Por que `StreamBuilder`?

> "Porque la app necesita reaccionar a cambios en tiempo real: tareas, usuario vinculado, flags de pantallas, pictogramas."

### Que es soft delete?

> "En vez de borrar completamente una tarea, se marca `deletedByUser: true`. Asi el tutor conserva historial."

### Como funciona el boton magico?

> "Es un `FloatingActionButton` dentro de un `GestureDetector`. Tap abre Super Experto; long press permite arrastrarlo; su posicion se guarda en `SharedPreferences`."

### Por que guardas la posicion local y no en Firestore?

> "Porque es una preferencia visual del dispositivo, no un dato compartido. SharedPreferences es suficiente y mas rapido."

### Como funciona la barra inferior?

> "Lee flags desde `pictogramSettings/_features`. Si el tutor desactiva una pantalla, la barra se actualiza en tiempo real."

### Como se crean pictogramas personalizados?

> "Se toma o selecciona imagen, se recorta cuadrada, se sube a Firebase Storage y se guarda el documento en Firestore."

### Como funciona el historial del tutor?

> "El usuario genera eventos en `activityLog`; el tutor vinculado puede leerlos por reglas de Firestore."

### Como funcionan las notificaciones?

> "Hay dos canales: local para el dispositivo y remoto por FCM usando una cola en Firestore procesada por Cloud Functions."

### Que pasa si no hay internet?

> "Firestore puede cachear algunos datos, pero funciones como IA, backup y sincronizacion completa requieren conexion. Modo offline robusto queda como mejora post-MVP."

### Que haria falta para produccion?

> "Tests automatizados, App Check, rate limiting, monitoreo de errores, hardening de reglas, QA en dispositivos reales y firma formal del APK."

---

## 20. Como moverte en el codigo durante la presentacion

Ruta de demostracion recomendada:

1. Abrir `lib/main.dart`.
   - Explica inicializacion.

2. Abrir `lib/core/navigation/auth_gate.dart`.
   - Explica login, onboarding y roles.

3. Abrir `lib/core/widgets/custom_nav_bar.dart`.
   - Explica pantallas dinamicas.

4. Abrir `lib/features/tutor_dashboard/screens/home_screen.dart`.
   - Explica Inicio, tarea prioritaria y boton magico.

5. Abrir `lib/features/onboarding/screens/super_experto_sheet.dart`.
   - Explica UI del asistente.

6. Abrir `lib/features/tda_focus/services/ia_service.dart`.
   - Explica llamada a Cloud Function.

7. Abrir `functions/src/index.ts`.
   - Explica Gemini y secret.

8. Abrir `firestore.rules`.
   - Explica seguridad tutor/usuario.

9. Abrir `lib/features/tutor_dashboard/screens/tutor_supervise_screen.dart`.
   - Explica dashboard tutor.

10. Abrir `lib/core/services/pictogram_service.dart`.
    - Explica pictogramas y Storage.

Frase para cambiar de archivo:

> "Ahora les muestro donde se implementa esa parte."

---

## 21. Mapa rapido "donde esta cada cosa"

| Necesito explicar | Archivo |
---|---|
| Arranque app | `lib/main.dart` |
| Login/rol/onboarding | `lib/core/navigation/auth_gate.dart` |
| Login UI | `lib/features/auth/screens/login_screen.dart` |
| Seleccion rol | `lib/features/auth/screens/role_selection_screen.dart` |
| Perfil inicial | `lib/features/auth/screens/profile_setup_screen.dart` |
| Vincular tutor desde usuario | `lib/features/auth/screens/vinculacion_tutor_screen.dart` |
| Servicio Auth/vinculacion | `lib/core/services/auth_service.dart` |
| Inicio usuario | `lib/features/tutor_dashboard/screens/home_screen.dart` |
| Barra inferior | `lib/core/widgets/custom_nav_bar.dart` |
| Tareas | `lib/features/tda_focus/screens/tareas_screen.dart` |
| Pomodoro/Foco | `lib/features/tda_focus/screens/foco_screen.dart` |
| Servicio Pomodoro | `lib/features/tda_focus/services/pomodoro_service.dart` |
| Progreso | `lib/features/tda_focus/screens/progreso_screen.dart` |
| Super Experto UI | `lib/features/onboarding/screens/super_experto_sheet.dart` |
| Servicio IA Flutter | `lib/features/tda_focus/services/ia_service.dart` |
| Cloud Functions | `functions/src/index.ts` |
| Pictogramas usuario | `lib/features/tea_board/screens/pantalla_paciente_tea.dart` |
| Gestion pictogramas | `lib/features/tea_board/screens/pictogram_manager_screen.dart` |
| Crear pictograma | `lib/features/tea_board/screens/crear_pictograma_sheet.dart` |
| Servicio pictogramas | `lib/core/services/pictogram_service.dart` |
| Tutor dashboard | `lib/features/tutor_dashboard/screens/tutor_supervise_screen.dart` |
| Configuracion/perfil | `lib/features/tutor_dashboard/screens/settings_screen.dart` |
| Config pantallas usuario | `lib/features/tutor_dashboard/screens/pantallas_config_screen.dart` |
| Tour state | `lib/core/services/tour_service.dart` |
| Tour cards | `lib/core/widgets/tour_step_card.dart` |
| Notificaciones locales | `lib/core/services/notification_service.dart` |
| Push FCM | `lib/core/services/push_notification_service.dart` |
| Dispatcher recordatorios | `lib/core/services/reminder_dispatcher.dart` |
| Historial actividad | `lib/core/services/activity_log_service.dart` |
| Reglas seguridad | `firestore.rules` |
| Config Android icono/nombre | `android/app/src/main/AndroidManifest.xml` |

---

## 22. Mini glosario para explicar sin trabarse

| Termino | Explicacion con peras y manzanas |
---|---|
| Widget | Pieza visual de Flutter: boton, texto, pantalla, tarjeta. |
| StatefulWidget | Widget que cambia con el tiempo. |
| Stream | Tuberia de datos en vivo. Si Firestore cambia, la UI se actualiza. |
| StreamBuilder | Widget que escucha un stream y reconstruye UI. |
| Future | Resultado que llega despues, como pedir datos una vez. |
| Firestore | Base de datos NoSQL en tiempo real. |
| Document | Un registro, como `users/{uid}`. |
| Collection | Grupo de documentos, como `tasks`. |
| Subcollection | Coleccion dentro de un documento, como `users/{uid}/tasks`. |
| Firebase Auth | Servicio que dice quien es el usuario. |
| Firestore Rules | Reglas servidor que dicen que puede leer/escribir. |
| Storage | Lugar para archivos, como fotos de pictogramas. |
| Cloud Function | Codigo backend que corre en servidor. |
| FCM | Firebase Cloud Messaging, push remoto. |
| SharedPreferences | Memoria local simple del dispositivo. |
| Provider | Forma de compartir estado en Flutter. |
| APK | Archivo instalable Android. |

---

## 23. Explicacion por capas

### Capa 1: UI

Son pantallas y widgets.

Ejemplos:

- `HomeScreen`
- `TareasScreen`
- `PantallaUsuarioTEA`
- `TutorSupervisarScreen`
- `SettingsScreen`

### Capa 2: Servicios

Son clases que hacen trabajo pesado o reutilizable.

Ejemplos:

- `AuthService`
- `PictogramService`
- `NotificationService`
- `IAService`
- `ReminderDispatcher`

### Capa 3: Backend

Firebase:

- Auth
- Firestore
- Storage
- Functions
- FCM

### Capa 4: Seguridad

Reglas:

- `firestore.rules`
- Cloud Function `request.auth`
- Firebase Secrets

Respuesta corta:

> "La UI no decide la seguridad. La UI pide. Firebase y las reglas autorizan."

---

## 24. Resumen de arquitectura en una frase

> "Simple usa Flutter como cliente reactivo, Firebase como backend seguro en tiempo real, Cloud Functions como capa protegida para IA/notificaciones, y Firestore rules para separar correctamente usuario y tutor."

Memoriza esta frase.

---

## 25. Checklist antes de presentar

### Codigo

- Abrir VS Code en el repo.
- Tener pestañas preparadas:
  - `main.dart`
  - `auth_gate.dart`
  - `home_screen.dart`
  - `tutor_supervise_screen.dart`
  - `ia_service.dart`
  - `functions/src/index.ts`
  - `firestore.rules`

### Demo

- Usuario con tareas.
- Tutor con usuario vinculado.
- Super Experto listo.
- Pictogramas cargados.
- APK instalado con logo Simple.

### Respuestas listas

- Seguridad Gemini.
- Separacion tutor/usuario.
- Por que Flutter/Firebase.
- Como se sincroniza en tiempo real.
- Que falta para produccion.

---

## 26. Si te bloqueas durante la defensa

Usa este patron:

1. "Esa parte esta en..."
2. "La responsabilidad de ese archivo es..."
3. "El flujo es..."
4. "La seguridad se controla con..."

Ejemplo:

> "Esa parte esta en `AuthGate`. Su responsabilidad es decidir que pantalla mostrar. El flujo es Auth -> documento usuario -> rol. La seguridad no depende solo de eso; Firestore rules tambien validan permisos."

---

## 27. Lo mas importante que debes recordar

1. `main.dart` arranca todo.
2. `AuthGate` decide login/rol.
3. `HomeScreen` es Inicio del usuario.
4. `TutorSupervisarScreen` es panel del tutor.
5. `CustomNavBar` controla navegacion dinamica.
6. `AuthService` maneja login y vinculacion.
7. `PictogramService` maneja pictogramas y Storage.
8. `IAService` llama a Cloud Functions.
9. `functions/src/index.ts` protege Gemini y procesa backend.
10. `firestore.rules` son los candados reales.

Si sabes explicar esos 10 puntos, puedes defender el MVP con seguridad.

