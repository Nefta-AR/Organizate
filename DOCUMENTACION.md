# Documentación Técnica Completa — Simple

> **Tipo:** Aplicación móvil Flutter  
> **Propósito:** Prótesis cognitiva para usuarios con TDAH y TEA  
> **Versión:** 1.0.0+1  
> **Autor:** Nefta-AR  
> **Fecha de documentación:** 13 mayo 2026  

---

## Tabla de contenidos

1. [Descripción del proyecto](#1-descripción-del-proyecto)
2. [Arquitectura del sistema](#2-arquitectura-del-sistema)
3. [Estructura de carpetas](#3-estructura-de-carpetas)
4. [Dependencias](#4-dependencias)
5. [Sistema de diseño](#5-sistema-de-diseño)
6. [Autenticación y roles](#6-autenticación-y-roles)
7. [Módulo TDAH — TDA Focus](#7-módulo-tdah--tda-focus)
8. [Módulo TEA — Tea Board](#8-módulo-tea--tea-board)
9. [Dashboard del tutor](#9-dashboard-del-tutor)
10. [Servicios core](#10-servicios-core)
11. [Modelo de datos Firestore](#11-modelo-de-datos-firestore)
12. [Infraestructura Firebase](#12-infraestructura-firebase)
13. [Componentes compartidos](#13-componentes-compartidos)
14. [Flujos de usuario](#14-flujos-de-usuario)
15. [Assets y recursos](#15-assets-y-recursos)
16. [Estado actual y pendientes](#16-estado-actual-y-pendientes)

---

## 1. Descripción del proyecto

**Simple** es una prótesis cognitiva minimalista diseñada para apoyar a personas con TDAH y TEA en su vida diaria. La aplicación ofrece herramientas específicas para cada perfil de usuario y permite a tutores supervisar el progreso de sus pacientes.

### Perfiles de usuario

| Rol | Descripción | Módulo principal |
|-----|-------------|-----------------|
| `tutor` | Padre, educador o cuidador | Dashboard de supervisión |
| `paciente_tdah` | Persona con TDAH | Pomodoro, tareas, foco |
| `paciente_tea` | Persona con TEA | Pictogramas + TTS |
| `usuario_general` | Usuario sin diagnóstico específico | Tareas y organización |

### Principios de diseño

- **Minimalismo:** Interfaz limpia, sin sobrecarga visual
- **Accesibilidad:** Tipografía redondeada (Nunito), colores cálidos y espaciado generoso
- **Predictibilidad:** Navegación simple y consistente
- **Feedback multisensorial:** Audio (TTS), vibración táctil y visual

---

## 2. Arquitectura del sistema

```
┌─────────────────────────────────────────────────────────┐
│                     CLIENTE FLUTTER                      │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │  Auth    │  │  TDAH    │  │   TEA    │  │ Tutor  │  │
│  │  Module  │  │  Module  │  │  Module  │  │ Dash.  │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘  │
│       │              │              │             │       │
│  ┌────▼──────────────▼──────────────▼─────────────▼───┐  │
│  │              Core Services Layer                    │  │
│  │  AuthService  │  NotifService  │  PomodoroService   │  │
│  │  AudioService │  PictoService  │  ActivityLog       │  │
│  │  DriveService │  IAService     │  UserPrefs         │  │
│  └────────────────────────┬────────────────────────────┘  │
└───────────────────────────┼─────────────────────────────┘
                            │
                ┌───────────▼────────────┐
                │       FIREBASE         │
                │  Auth │ Firestore      │
                │  Storage │ Functions   │
                │  Messaging (FCM)       │
                └────────────────────────┘
                            │
                ┌───────────▼────────────┐
                │    GOOGLE CLOUD        │
                │  Cloud Functions       │
                │  Gemini AI API         │
                │  TTS API               │
                └────────────────────────┘
```

### Patrones utilizados

| Patrón | Uso |
|--------|-----|
| Provider | PomodoroService como ChangeNotifier |
| Stream-based UI | Firestore streams para reactividad |
| Repository | Services encapsulan acceso a datos |
| Feature-first | Código organizado por funcionalidad |
| Material Design 3 | Sistema de diseño unificado |

---

## 3. Estructura de carpetas

```
d:\ProyectosFlutter\Organizate\
├── lib/
│   ├── main.dart                        # Punto de entrada, inicialización Firebase
│   ├── firebase_options.dart            # Configuración Firebase (generado automáticamente)
│   │
│   ├── core/
│   │   ├── navigation/
│   │   │   └── auth_gate.dart           # Control de flujo por estado de auth y rol
│   │   ├── router/
│   │   │   └── app_router.dart          # Rutas con transiciones fade
│   │   ├── theme/
│   │   │   └── app_theme.dart           # Material 3: colores, tipografía, radios
│   │   ├── models/
│   │   │   └── avatar_option.dart       # Modelo: nombre + imagePath + color
│   │   ├── services/
│   │   │   ├── auth_service.dart        # Auth, roles, vinculación tutor-paciente
│   │   │   ├── notification_service.dart      # Notificaciones locales (AlarmManager)
│   │   │   ├── push_notification_service.dart # FCM tokens + cola de notificaciones
│   │   │   ├── user_prefs.dart          # SharedPreferences (email, config local)
│   │   │   ├── audio_service.dart       # TTS vía Cloud Functions + caché SHA256
│   │   │   ├── activity_log_service.dart      # Log de acciones del usuario
│   │   │   ├── pictogram_service.dart   # Pictogramas personalizados + Storage
│   │   │   ├── google_drive_service.dart      # Backup OAuth en Google Drive
│   │   │   └── reminder_dispatcher.dart       # Coordinación de recordatorios
│   │   ├── utils/
│   │   │   ├── reminder_options.dart    # Constantes: 10min, 30min, 1h, 1d
│   │   │   ├── reminder_helper.dart     # Formateo y scheduling de recordatorios
│   │   │   ├── date_time_helper.dart    # Parsing y formateo de fechas en español
│   │   │   └── emergency_contact_helper.dart  # Llamada directa a contacto
│   │   └── widgets/
│   │       ├── custom_nav_bar.dart      # Barra inferior contextual por rol
│   │       └── test_header.dart         # Header de prueba/debug
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   └── screens/
│   │   │       ├── login_screen.dart              # Email + Google Sign-In
│   │   │       ├── role_selection_screen.dart     # Selección inicial de rol
│   │   │       └── paciente_vinculacion_screen.dart # Ingresar código de tutor
│   │   │
│   │   ├── onboarding/
│   │   │   └── screens/
│   │   │       ├── onboarding_screen.dart         # Bienvenida
│   │   │       ├── test_initial_screen.dart       # Test de perfil inicial
│   │   │       ├── hogar_screen.dart              # Setup tareas Hogar
│   │   │       ├── estudios_screen.dart           # Setup tareas Estudios
│   │   │       ├── meds_screen.dart               # Setup Medicamentos
│   │   │       └── super_experto_sheet.dart       # Sheet de ayuda IA
│   │   │
│   │   ├── tda_focus/
│   │   │   ├── services/
│   │   │   │   ├── pomodoro_service.dart          # ChangeNotifier, timer, persistencia
│   │   │   │   ├── streak_service.dart            # Racha de días activos
│   │   │   │   └── ia_service.dart                # Cloud Function: desglosarTarea
│   │   │   └── screens/
│   │   │       ├── foco_screen.dart               # Pomodoro + respiración animada
│   │   │       ├── tareas_screen.dart             # CRUD tareas + recordatorios
│   │   │       ├── progreso_screen.dart           # Gráficos de progreso
│   │   │       └── welcome_reward_screen.dart     # Recompensas y gamificación
│   │   │
│   │   ├── tea_board/
│   │   │   └── screens/
│   │   │       ├── pantalla_paciente_tea.dart     # Interfaz principal de pictogramas
│   │   │       ├── pictogram_manager_screen.dart  # Gestión de pictogramas
│   │   │       └── crear_pictograma_sheet.dart    # Crear pictograma personalizado
│   │   │
│   │   └── tutor_dashboard/
│   │       └── screens/
│   │           ├── home_screen.dart               # Vista de pacientes y tareas
│   │           ├── settings_screen.dart           # Configuración de perfil
│   │           ├── perfil_screen.dart             # Perfil del tutor
│   │           ├── tutor_supervise_screen.dart    # Supervisión general
│   │           ├── tutor_patient_detail_screen.dart # Detalle de paciente
│   │           └── tutor_vinculacion_screen.dart  # Generar y gestionar códigos
│   │
│   └── screens/
│       └── pantalla_paciente_tea.dart             # (legacy / duplicado)
│
├── assets/
│   ├── avatars/                  # PNGs de avatares de usuario
│   ├── icons/                    # Íconos adicionales
│   ├── images/
│   │   ├── Simple.png            # Logo de la app
│   │   └── pictogramas/          # SVGs del banco de pictogramas
│   └── sounds/                   # Audios (notificacion1.mp3, etc.)
│
├── packages/
│   └── flutter_native_timezone/  # Paquete local de zona horaria
│
├── pubspec.yaml
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── DOCUMENTACION.md              # Este archivo
└── CARTA_GANTT.md                # Carta Gantt del proyecto
```

---

## 4. Dependencias

### UI y diseño

| Paquete | Versión | Uso |
|---------|---------|-----|
| `cupertino_icons` | ^1.0.8 | Íconos iOS |
| `material_design_icons_flutter` | ^7.0.7296 | Íconos Material extendidos |
| `flutter_svg` | ^2.2.4 | Renderizado SVG (pictogramas) |
| `google_fonts` | ^6.2.1 | Fuente Nunito |
| `fl_chart` | ^1.1.1 | Gráficos de progreso |

### Firebase

| Paquete | Versión | Uso |
|---------|---------|-----|
| `firebase_core` | ^2.32.0 | Inicialización |
| `firebase_auth` | ^4.17.4 | Autenticación |
| `cloud_firestore` | ^4.17.3 | Base de datos en tiempo real |
| `firebase_storage` | ^11.7.2 | Almacenamiento de imágenes |
| `firebase_messaging` | ^14.9.1 | Notificaciones push (FCM) |
| `cloud_functions` | ^4.7.4 | IA y TTS vía Cloud |

### Notificaciones y localización

| Paquete | Versión | Uso |
|---------|---------|-----|
| `flutter_local_notifications` | ^17.1.2 | Alarmas y recordatorios |
| `flutter_native_timezone` | local | Zona horaria nativa |
| `timezone` | ^0.9.3 | Manejo de zonas horarias |
| `intl` | ^0.20.2 | Fechas en español |

### Auth Google y APIs

| Paquete | Versión | Uso |
|---------|---------|-----|
| `google_sign_in` | ^6.2.1 | Inicio con Google |
| `googleapis` | ^13.2.0 | Google Drive API |

### Audio y multimedia

| Paquete | Versión | Uso |
|---------|---------|-----|
| `audioplayers` | ^6.0.0 | Reproducción de audio |
| `flutter_tts` | ^4.2.5 | Text-to-Speech nativo |

### Persistencia local

| Paquete | Versión | Uso |
|---------|---------|-----|
| `shared_preferences` | ^2.2.3 | Configuración local |
| `path_provider` | ^2.1.2 | Rutas de directorio |
| `crypto` | ^3.0.3 | Hashing SHA256 para caché TTS |

### Estado

| Paquete | Versión | Uso |
|---------|---------|-----|
| `provider` | ^6.1.2 | ChangeNotifier (Pomodoro) |

### Utilidades

| Paquete | Versión | Uso |
|---------|---------|-----|
| `url_launcher` | ^6.3.0 | Abrir URLs |
| `permission_handler` | ^11.3.1 | Permisos en runtime |
| `image_picker` | ^1.1.2 | Seleccionar imágenes |
| `image_cropper` | ^8.1.0 | Recortar imágenes |
| `vibration` | ^3.1.4 | Feedback táctil |
| `flutter_phone_direct_caller` | ^2.1.1 | Llamadas directas |
| `http` | ^1.5.0 | Peticiones HTTP |

---

## 5. Sistema de diseño

**Archivo:** [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart)

### Paleta de colores

| Token | Color | Hex | Uso |
|-------|-------|-----|-----|
| `background` | Crema cálida | `#F7F4F0` | Fondo principal |
| `surface` | Blanco | `#FFFFFF` | Cards y sheets |
| `primary` | Azul pastel | `#7BB3D0` | Acciones principales |
| `secondary` | Verde salvia | `#8FAF8C` | Acciones secundarias |
| `tertiary` | Lavanda suave | `#B8A9C9` | Acentos |
| `error` | Rosa suave | `#D97070` | Errores |
| `onBackground` | Marrón oscuro | `#3D3835` | Texto principal |
| `onSurfaceVariant` | Gris apagado | `#8C8580` | Texto muted |

### Radios de borde

| Constante | Valor | Aplicación |
|-----------|-------|------------|
| `radiusSmall` | 12.0 | Chips, badges |
| `radiusMedium` | 16.0 | Botones, campos |
| `radiusLarge` | 24.0 | Cards |
| `radiusXLarge` | 32.0 | Dialogs, bottom sheets |

### Tipografía

- **Fuente:** Nunito (redondeada, amigable para neuroatípicos)
- Estilos definidos: displayLarge, headlineMedium, titleMedium, bodyMedium, labelMedium

---

## 6. Autenticación y roles

### AuthGate — Flujo de navegación

**Archivo:** [lib/core/navigation/auth_gate.dart](lib/core/navigation/auth_gate.dart)

```
FirebaseAuth.authStateChanges()
        │
        ▼ null?
   LoginScreen
        │
        ▼ usuario existe
  Lee Firestore users/{uid}
        │
        ▼ role vacío?
  RoleSelectionScreen
        │
        ▼ rol asignado
  RoleDispatcher:
    "tutor"       → TutorSupervisarScreen
    "paciente_tea" → PantallaPacienteTEA
    default        → HomeScreen
```

### AuthService

**Archivo:** [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart)

**Responsabilidades:**
- Registro con email/password
- Login con email y Google Sign-In (web + mobile)
- Enum `UserRole`: `tutor`, `paciente_tdah`, `paciente_tea`, `usuario_general`
- Generación de códigos de invitación (6 caracteres alfanuméricos, TTL 7 días)
- Validación y aceptación de códigos (vinculación paciente ↔ tutor)
- Desvinculación de pacientes
- Stream del estado de autenticación

**Colecciones Firestore gestionadas:**
- `users/{uid}` — Datos del usuario
- `invitationCodes/{code}` — Códigos de invitación activos
- `users/{uid}/linkedTutors/{tutorId}` — Relación paciente-tutor

### RoleSelectionScreen

**Archivo:** [lib/features/auth/screens/role_selection_screen.dart](lib/features/auth/screens/role_selection_screen.dart)

Pantalla de selección inicial con cuatro opciones:
1. Usuario General
2. Tutor
3. Paciente TDAH
4. Paciente TEA

Tras seleccionar, escribe el rol en `users/{uid}.role` y redirige.

---

## 7. Módulo TDAH — TDA Focus

### PomodoroService

**Archivo:** [lib/features/tda_focus/services/pomodoro_service.dart](lib/features/tda_focus/services/pomodoro_service.dart)

**Tipo:** `ChangeNotifier` (Provider)

**Estados:** `idle → running → paused → finished`

**Funcionalidades:**
- Duración configurable (5, 15, 25, 50 minutos)
- Persistencia del estado en SharedPreferences (sobrevive hot reload)
- Notificación local al finalizar la sesión
- `WidgetsBindingObserver` para reanudar sesiones al volver a foreground
- Registro de sesiones en `users/{uid}.focusSessionsCompleted`

### FocoScreen

**Archivo:** [lib/features/tda_focus/screens/foco_screen.dart](lib/features/tda_focus/screens/foco_screen.dart)

**Componentes:**
- Selector rápido de duración (5 / 15 / 25 / 50 min)
- Visualización circular del timer con progreso animado
- Ejercicio de respiración guiada (animación 4-4-6 segundos)
- Lista de tareas de categoría "Foco"
- Música ambiental opcional

### TareasScreen

**Archivo:** [lib/features/tda_focus/screens/tareas_screen.dart](lib/features/tda_focus/screens/tareas_screen.dart)

**Funcionalidades:**
- Filtrado por categoría: Todas / Estudios / Hogar / Meds / Foco / General
- CRUD completo de tareas
- Recordatorios configurables (10 min hasta 1 día antes)
- Swipe lateral para marcar o eliminar tareas
- Integración con ActivityLogService
- Visualización de puntos acumulados y racha actual

### IAService — Súper Experto

**Archivo:** [lib/features/tda_focus/services/ia_service.dart](lib/features/tda_focus/services/ia_service.dart)

**Integración:** Cloud Function `desglosarTarea` (Gemini API)

**Parámetros de entrada:**
```json
{
  "tarea": "string — descripción de la tarea",
  "tiempoDisponible": "string — ej: '30 minutos'"
}
```

**Respuesta:**
```json
[
  { "titulo": "string", "tiempo_estimado": "string" },
  ...
]
```

**Configuración:**
- Timeout: 25 segundos
- Manejo de errores: `unauthenticated`, `invalid-argument`, `deadline-exceeded`, `unavailable`, `internal`, `cancelled`

### StreakService

**Archivo:** [lib/features/tda_focus/services/streak_service.dart](lib/features/tda_focus/services/streak_service.dart)

Mantiene la racha de días consecutivos de actividad del usuario, almacenada en `users/{uid}.streak`.

---

## 8. Módulo TEA — Tea Board

### PantallaPacienteTEA

**Archivo:** [lib/features/tea_board/screens/pantalla_paciente_tea.dart](lib/features/tea_board/screens/pantalla_paciente_tea.dart)

**Interfaz principal de comunicación:**
- Grid de pictogramas organizados por categorías (Mañana, Tarde, Noche, Personalizado)
- Al pulsar un pictograma: reproducción TTS + vibración táctil
- Banco predefinido de 20+ SVGs con colores suaves

**Banco de pictogramas predefinidos:**

| Categoría | Pictogramas |
|-----------|------------|
| Mañana | Despertar, Lavar cara, Cepillar dientes, Colegio |
| Tarde | Almorzar, Tareas / Tech, Merienda, Jugar |
| Noche | Cena, Baño, Leer, Dormir |

### PictogramManagerScreen

**Archivo:** [lib/features/tea_board/screens/pictogram_manager_screen.dart](lib/features/tea_board/screens/pictogram_manager_screen.dart)

**Gestión de pictogramas personalizados:**
- Crear nuevos pictogramas (imagen + etiqueta + texto TTS)
- Editar categoría y visibilidad
- Eliminar pictogramas
- Subida de imágenes a Firebase Storage

### PictogramService

**Archivo:** [lib/core/services/pictogram_service.dart](lib/core/services/pictogram_service.dart)

- Banco de pictogramas predefinidos embebido
- CRUD de pictogramas personalizados en Firestore
- Subida de imágenes a `storage: users/{uid}/pictograms/`
- Configuración de visibilidad en `pictogramSettings`
- Selección, recorte y carga de imágenes (image_picker + image_cropper)

### AudioService — TTS

**Archivo:** [lib/core/services/audio_service.dart](lib/core/services/audio_service.dart)

**Flujo de síntesis de voz:**
1. Calcular hash SHA256 del texto
2. Verificar caché local en `voices_cache/`
3. Si no está en caché → Cloud Function `sintetizarVoz`
4. Guardar audio en caché
5. Reproducir con `audioplayers`

**Parámetros:**
- `texto: string`
- `vozId: string` (identificador de voz)

---

## 9. Dashboard del tutor

### TutorSupervisarScreen

**Archivo:** [lib/features/tutor_dashboard/screens/tutor_supervise_screen.dart](lib/features/tutor_dashboard/screens/tutor_supervise_screen.dart)

Vista principal del tutor con listado de pacientes vinculados.

### TutorVinculacionScreen

**Archivo:** [lib/features/tutor_dashboard/screens/tutor_vinculacion_screen.dart](lib/features/tutor_dashboard/screens/tutor_vinculacion_screen.dart)

**Funcionalidades:**
- Generar código de invitación (6 caracteres, válido 7 días)
- Copiar código al portapapeles
- Ver pacientes vinculados activos
- Desvincular pacientes

### TutorPatientDetailScreen

**Archivo:** [lib/features/tutor_dashboard/screens/tutor_patient_detail_screen.dart](lib/features/tutor_dashboard/screens/tutor_patient_detail_screen.dart)

Supervisión detallada: tareas, progreso, actividad reciente del paciente.

### HomeScreen (Tutor)

**Archivo:** [lib/features/tutor_dashboard/screens/home_screen.dart](lib/features/tutor_dashboard/screens/home_screen.dart)

- Listado de pacientes con sus tareas del día
- Visualización de puntos y racha
- FAB para acceder al Súper Experto IA
- Acceso rápido al contacto de emergencia

### SettingsScreen

**Archivo:** [lib/features/tutor_dashboard/screens/settings_screen.dart](lib/features/tutor_dashboard/screens/settings_screen.dart)

- Editar nombre y avatar
- Configurar contacto de emergencia
- Preferencias de notificaciones
- Backup en Google Drive

---

## 10. Servicios core

### NotificationService

**Archivo:** [lib/core/services/notification_service.dart](lib/core/services/notification_service.dart)

**Permisos solicitados:**
- `SCHEDULE_EXACT_ALARM` (Android 12+)
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- Notificaciones (Android 13+)

**Funcionalidades:**
- Recordatorios de tareas con fecha/hora exacta
- Notificación de fin de sesión Pomodoro
- Prueba de notificación en settings

### PushNotificationService

**Archivo:** [lib/core/services/push_notification_service.dart](lib/core/services/push_notification_service.dart)

**Firebase Cloud Messaging:**
- Sincronización de tokens FCM en `users/{uid}.fcmTokens[]`
- Cola de recordatorios en `users/{uid}/notificationQueue/{taskId}`
- Handling de mensajes en foreground y background

### ActivityLogService

**Archivo:** [lib/core/services/activity_log_service.dart](lib/core/services/activity_log_service.dart)

**Tipos de evento registrados:**
- `task_completed` — tarea completada
- `task_created` — tarea creada
- `task_deleted` — tarea eliminada
- `pictogram_created` — pictograma personalizado creado
- `pictogram_deleted` — pictograma eliminado

**Almacenamiento:** `users/{uid}/activityLog` (últimas 100 entradas)

### GoogleDriveService

**Archivo:** [lib/core/services/google_drive_service.dart](lib/core/services/google_drive_service.dart)

**Backup en la nube:**
- Autenticación OAuth2 con scope `drive.file`
- Carpeta de destino: `Simple_App_Backup`
- Respalda: configuración del usuario + pictogramas personalizados
- Restauración con resolución de conflictos por timestamp

### UserPrefs

**Archivo:** [lib/core/services/user_prefs.dart](lib/core/services/user_prefs.dart)

Wrapper de SharedPreferences para persistencia local:
- Email del último usuario
- Configuración de tema
- Estado del timer Pomodoro (entre sesiones)

---

## 11. Modelo de datos Firestore

### Colección `users/{uid}`

```
{
  name:                     string
  email:                    string
  role:                     "tutor" | "paciente_tdah" | "paciente_tea" | "usuario_general"
  avatar:                   string            // nombre del asset de avatar
  points:                   number            // puntos acumulados
  streak:                   number            // días consecutivos activos
  hasCompletedOnboarding:   boolean
  createdAt:                timestamp
  fcmTokens:                array<string>     // tokens de dispositivos registrados

  // Solo tutores:
  linkedPatients:           map<uid, boolean>
  invitationCodes:          map<code, boolean>
  kioskModeEnabled:         boolean           // modo quiosco para paciente TEA

  // Solo pacientes:
  linkedTutors:             map<uid, boolean>
  acceptedInvitationCode:   string | null

  // Perfil opcional:
  emergencyName:            string
  emergencyPhone:           string
  notiTaskDefaultOffsetMinutes: number        // offset de recordatorio por defecto
  focusSessionsCompleted:   number
  totalFocusMinutes:        number
}
```

### Subcolección `users/{uid}/tasks/{taskId}`

```
{
  title:           string
  category:        "Estudios" | "Hogar" | "Meds" | "Foco" | "General"
  done:            boolean
  dueDate:         timestamp | null
  reminderMinutes: number | null    // minutos antes para recordatorio
  description:     string | null
  createdAt:       timestamp
}
```

### Colección `invitationCodes/{code}`

```
{
  code:      string           // 6 caracteres alfanuméricos
  tutorId:   string           // uid del tutor que generó el código
  tutorName: string
  createdAt: timestamp
  status:    "active" | "used" | "deactivated"
  usedBy:    string | null    // uid del paciente que lo usó
  usedAt:    timestamp | null
  expiresAt: timestamp        // createdAt + 7 días
}
```

### Subcolección `users/{uid}/pictograms/{pictoId}`

```
{
  imageUrl:  string    // URL de Firebase Storage
  etiqueta:  string    // nombre mostrado en el pictograma
  textoTts:  string    // texto para síntesis de voz
  categoria: string    // "Mañana" | "Tarde" | "Noche" | "Personalizado"
  createdAt: timestamp
}
```

### Subcolección `users/{uid}/pictogramSettings/{pictoId}`

```
{
  categoria: string
  visible:   boolean
}
```

### Subcolección `users/{uid}/activityLog/{logId}`

```
{
  type:        string       // task_completed, pictogram_created, etc.
  description: string
  timestamp:   timestamp
  metadata:    map          // datos adicionales opcionales
}
```

### Subcolección `users/{uid}/notificationQueue/{taskId}`

```
{
  taskId:          string
  taskTitle:       string
  runAt:           timestamp
  status:          "pending"
  type:            "task"
  dueDate:         timestamp
  reminderMinutes: number
  createdAt:       timestamp
  updatedAt:       timestamp
}
```

### Subcolección `users/{uid}/linkedTutors/{tutorId}`

```
{
  tutorId:  string
  linkedAt: timestamp
  status:   "active" | "inactive"
}
```

---

## 12. Infraestructura Firebase

### Proyecto Firebase

| Campo | Valor |
|-------|-------|
| Project ID | `organizate-26065` |
| Storage Bucket | `organizate-26065.firebasestorage.app` |
| Auth Domain | `organizate-26065.firebaseapp.com` |

### Plataformas configuradas

| Plataforma | App ID |
|------------|--------|
| Android | `1:755867602564:android:df257a7a567975b33bbcd1` |
| iOS | Configurado |
| Web | Configurado |
| Windows | Configurado |

### Cloud Functions

| Función | Trigger | Descripción |
|---------|---------|-------------|
| `desglosarTarea` | HTTPS Callable | Desglosa tarea en pasos usando Gemini AI |
| `sintetizarVoz` | HTTPS Callable | Sintetiza texto a audio (TTS) |

### AppRouter — Rutas

**Archivo:** [lib/core/router/app_router.dart](lib/core/router/app_router.dart)

| Ruta | Pantalla |
|------|----------|
| `/onboarding` | OnboardingScreen |
| `/home` | HomeScreen |
| `/paciente-tea` | PantallaPacienteTEA |
| `/vincular-paciente` | PacienteVinculacionScreen |

Todas las transiciones usan `FadeTransition` de 200ms.

---

## 13. Componentes compartidos

### CustomNavBar

**Archivo:** [lib/core/widgets/custom_nav_bar.dart](lib/core/widgets/custom_nav_bar.dart)

Barra de navegación inferior adaptativa según el rol del usuario:

| Índice | Ícono | Destino TDAH | Destino TEA |
|--------|-------|--------------|-------------|
| 0 | Home | HomeScreen | HomeScreen |
| 1 | Tasks | TareasScreen | TareasScreen |
| 2 | Focus/Picto | FocoScreen | PantallaPacienteTEA |
| 3 | Profile | PerfilScreen | PerfilScreen |

---

## 14. Flujos de usuario

### Flujo: Usuario General / Paciente TDAH

```
Abrir app
    │
    ▼
LoginScreen (email o Google)
    │
    ▼ primera vez
RoleSelectionScreen → selecciona rol
    │
    ▼
HomeScreen
    ├── Crear tarea → TareasScreen → configurar recordatorio
    ├── Iniciar Pomodoro → FocoScreen → respiración / música
    ├── Ver progreso → ProgresoScreen
    └── Perfil → SettingsScreen → avatar, emergencia, backup
```

### Flujo: Paciente TEA

```
Abrir app → LoginScreen
    │
    ▼
PantallaPacienteTEA
    ├── Pulsar pictograma → TTS + vibración
    ├── Cambiar categoría (Mañana / Tarde / Noche / Custom)
    └── Gestor → PictogramManagerScreen
            ├── Crear pictograma → imagen + etiqueta + TTS
            └── Eliminar pictograma
```

### Flujo: Tutor

```
Abrir app → LoginScreen
    │
    ▼
TutorSupervisarScreen
    ├── Generar código → TutorVinculacionScreen → compartir 6 dígitos
    ├── Ver paciente → TutorPatientDetailScreen → tareas + progreso
    └── Configuración → SettingsScreen → backup Drive
```

### Flujo: Vinculación Tutor-Paciente

```
TUTOR:                          PACIENTE:
Generar código (6 chars)
    │                               │
    ▼                               ▼
Compartir código           PacienteVinculacionScreen
                                    │
                           Ingresar código
                                    │
                           Validar en Firestore
                                    │
                           Crear linkedTutors/{tutorId}
                           Crear users/{tutorId}.linkedPatients/{uid}
```

---

## 15. Assets y recursos

### Estructura de assets

```
assets/
├── avatars/           # Avatares de usuario (PNG)
│   ├── avatar_1.png
│   ├── avatar_2.png
│   └── ...
├── icons/             # Íconos adicionales de la app
├── images/
│   ├── Simple.png     # Logo de la app (launcher icon)
│   └── pictogramas/   # Banco de pictogramas en SVG
│       ├── despertar.svg
│       ├── lavar_cara.svg
│       ├── cepillar_dientes.svg
│       ├── colegio.svg
│       └── ...
└── sounds/
    └── notificacion1.mp3    # Sonido de notificación
```

### Launcher Icons

| Plataforma | Configuración |
|------------|--------------|
| Android | Adaptativo con fondo `#F5F5DC` |
| iOS | Sin canal alpha (`remove_alpha_ios: true`) |
| Fuente | `assets/images/Simple.png` |
| SDK mínimo Android | 21 (Android 5.0) |

---

## 16. Estado actual y pendientes

### Funcionalidades completadas

| Funcionalidad | Estado |
|---------------|--------|
| Autenticación email + Google | ✅ |
| Sistema de roles (4 tipos) | ✅ |
| Vinculación tutor ↔ paciente con códigos | ✅ |
| Gestión de tareas (CRUD + categorías) | ✅ |
| Recordatorios locales de tareas | ✅ |
| Timer Pomodoro con persistencia | ✅ |
| Ejercicio de respiración animado | ✅ |
| Banco de pictogramas predefinidos (SVG) | ✅ |
| Pictogramas con color por categoría | ✅ |
| TTS vía Cloud Functions (AudioService) | ✅ |
| Pictogramas personalizados (foto + TTS) | ✅ |
| Súper Experto IA (Gemini Cloud Function) | ✅ |
| Sistema de puntos y racha | ✅ |
| Activity Log | ✅ |
| Notificaciones push FCM | ✅ |
| Backup en Google Drive | ✅ |
| Perfil con avatar | ✅ |
| Contacto de emergencia | ✅ |

### Pendientes y trabajo en curso

| Tarea | Prioridad | Notas |
|-------|-----------|-------|
| Detalle completo de paciente en tutor | Alta | `tutor_patient_detail_screen.dart` en desarrollo |
| Sincronización de tareas tutor ↔ paciente | Alta | Requiere lógica en Firestore |
| Kiosk Mode para TEA | Media | `kioskModeEnabled` ya en schema |
| Dashboard de progreso con gráficos | Media | `fl_chart` ya instalado |
| Pulir ProgresoScreen | Media | Datos de `focusSessionsCompleted` disponibles |
| Arreglar pendientes en vinculación tutor | Alta | Commit `ce5c88a` marca trabajo en curso |
| Testing y QA general | Alta | Antes de distribución |
| Preparación Play Store / App Store | Baja | Requiere testing completo previo |

---

*Documentación generada el 13 de mayo de 2026.*  
*Proyecto: Simple — Prótesis Cognitiva para TDAH y TEA*
