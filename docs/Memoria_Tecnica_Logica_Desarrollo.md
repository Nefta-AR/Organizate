# Memoria Técnica: Lógica Operativa y Desarrollo

## Organízate: Arquitectura Interna, Flujo de Datos y Decisiones Técnicas

---

## 1. Introducción a la Lógica Operativa

La presente memoria técnica documenta la **lógica interna** del sistema Organízate, desglosando los flujos de datos, los patrones de diseño aplicados y las decisiones arquitectónicas que fundamentan la operación de la aplicación como prótesis cognitiva. Este documento complementa el Informe Técnico principal y está dirigido a desarrolladores, evaluadores académicos y futuros mantenedores del sistema.

**Propósito:** Explicar **cómo** funciona el sistema, no solo **qué** hace. Se profundiza en los mecanismos de sincronización, la gestión de estado, la seguridad de datos, la reactividad de la interfaz y la integración entre el cliente (Flutter) y el backend (Firebase/Node.js).

---

## 2. Visión General del Flujo de Datos

El sistema opera bajo un modelo **reactivo de flujo de datos unidireccional** inspirado en **Flux/Redux**, adaptado a las capacidades de Flutter y Firestore. A diferencia de una arquitectura MVC tradicional donde el controlador media entre vista y modelo, aquí los **Streams** actúan como canales de comunicación continua entre todas las capas.

### 2.1 Pipeline de datos end-to-end

```
[Interacción usuario] 
    → [Widget Flutter] 
    → [Servicio de aplicación] 
    → [Firebase SDK (Cliente)] 
    → [Firebase Backend (Firestore/Auth/Storage)] 
    → [Cloud Functions (Node.js)] 
    → [Servicios externos (Google Drive, TTS, FCM)]
    → [Snapshot/Callback] 
    → [Reconstrucción de Widget] 
    → [UI actualizada]
```

**Característica crítica:** Este pipeline es **bidireccional en tiempo real**. Cuando el tutor modifica una configuración en Firestore, el snapshot se propaga hacia abajo hasta el widget del usuario sin que el usuario haya iniciado ninguna acción.

### 2.2 Capas de abstracción

| Capa | Responsabilidad | Entidades clave |
|------|-----------------|-----------------|
| **UI Layer** | Renderizar estado, capturar gestos | `StatelessWidget`, `StatefulWidget`, `StreamBuilder` |
| **Presentation Layer** | Mapear estado a modelos de vista | `ValueNotifier`, `ChangeNotifier`, `AnimationController` |
| **Service Layer** | Orquestar operaciones de negocio | `AuthService`, `PictogramService`, `TaskService`, `AudioService` |
| **Repository Layer** | Abstraer fuentes de datos | `Firestore` (directo), `FirebaseStorage`, `SharedPreferences` |
| **External Layer** | Comunicarse con servicios de terceros | `Google Drive API`, `Google Cloud TTS`, `FCM` |

---

## 3. Lógica Interna por Módulo

### 3.1 Módulo de Autenticación y Roles (AuthGate)

#### 3.1.1 Diagrama de flujo de autenticación

```
[App iniciada]
    ↓
[FirebaseAuth.instance.authStateChanges] 
    ↓ (emite User?)
    ├── null → [LoginScreen]
    └── User uid 
        ↓
        [Firestore: users/{uid}]
        ↓ (snapshot)
        ├── role == null → [RoleSelectionScreen]
        ├── role == 'usuario' → [RoleDispatcher] → [PantallaUsuarioTEA]
        └── role == 'tutor' → [RoleDispatcher] → [HomeScreen]
```

#### 3.1.2 Lógica de migración de roles (On-the-fly migration)

Una de las decisiones técnicas más críticas fue la **migración automática de roles legacy**. Cuando el sistema lee el campo `role` del documento de usuario, ejecuta tres capas de resolución:

1. **Lectura directa**: Si `role` existe y es válido (`tutor` o `usuario`), se usa directamente.
2. **Inferencia estructural**: Si `role` es null, se infiere por la presencia de campos:
   - `linkedPatients` existe → `tutor`
   - `linkedTutors` existe → `usuario`
   - Ninguno → `usuario` (default)
   Se escribe el rol inferido en Firestore para cachear futuras lecturas.
3. **Migración de strings legacy**: Si `role` contiene valores antiguos (`paciente_tea`, `paciente_tdah`, `usuario_general`), se normaliza automáticamente a `usuario` y se actualiza el documento.

**Justificación técnica:** Esta estrategia de **migración on-the-fly** elimina la necesidad de scripts de migración batch (que requieren acceso administrativo a Firestore) y garantiza compatibilidad hacia atrás con cuentas creadas en versiones anteriores de la app. Es un ejemplo de **eventual consistency** aplicado a esquemas de datos.

#### 3.1.3 Routing reactivo con StreamBuilder

El `AuthGate` no es un simple `if/else`. Es un **StreamBuilder** anidado que escucha dos streams simultáneamente:

```dart
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, authSnap) {
    if (!authSnap.hasData) return const LoginScreen();
    
    return StreamBuilder<UserRole?>(
      stream: AuthService.getUserRoleStream(),
      builder: (context, roleSnap) {
        if (roleSnap.data == null) return const RoleSelectionScreen();
        return RoleDispatcher(role: roleSnap.data!);
      },
    );
  },
)
```

**Patrón aplicado:** **Reactive Stream Composition**. La UI se reconstruye automáticamente cuando cualquiera de los dos streams emite un nuevo valor. Si el usuario cierra sesión (`authSnap` emite `null`), la UI cambia a `LoginScreen` sin necesidad de código imperativo de navegación.

### 3.2 Módulo de Pictogramas

#### 3.2.1 Modelo de datos unificado: PictogramaDisplay

El sistema unifica dos fuentes de datos conceptualmente diferentes bajo una **misma interfaz** (`PictogramaDisplay`), aplicando el **Adapter Pattern**:

```dart
class PictogramaDisplay {
  final String id;
  final String? rutaSvg;      // Solo para banco local
  final String? imageUrl;     // Solo para personalizados
  final String etiqueta;
  final String textoTts;
  final String categoria;
  final bool esPersonalizado;
}
```

- **Factory `fromLocal`**: Mapea un `Pictograma` (datos estáticos en código) a `PictogramaDisplay`.
- **Factory `fromCustom`**: Mapea un `PictogramaPersonalizado` (datos dinámicos de Firestore) a `PictogramaDisplay`, prefijando el ID con `custom_` para evitar colisiones con el banco local.

**Justificación técnica:** Sin esta unificación, el widget de la cuadrícula (`_TarjetaPictogramaDisplay`) tendría que implementar dos rutas de renderizado separadas (SVG vs JPEG), duplicando lógica. Con el Adapter, el widget solo conoce `PictogramaDisplay` y delega la resolución del asset a un método `_buildImagen()` que decide si renderizar `SvgPicture`, `Image.network` o `Image.asset`.

#### 3.2.2 Sincronización de configuración: Override de categoría

La configuración de pictogramas (categoría override, visibilidad) se almacena en `users/{uid}/pictogramSettings/{pictoId}`. La lógica de fusión (merge) ocurre en el cliente:

```dart
String _categoriaEfectiva(String id, String defaultCat) =>
    _settings[id]?['categoria'] as String? ?? defaultCat;

bool _visible(String id) => _settings[id]?['visible'] != false;
```

**Flujo de datos:**
1. El tutor cambia la categoría de un pictograma en el panel de supervisión.
2. El servicio escribe en `pictogramSettings/{pictoId}`.
3. Firestore propaga el snapshot a todos los dispositivos del usuario.
4. El cliente recibe el nuevo `_settings`, recalcula `_categoriaEfectiva` y reconstruye el `TabBarView`.

**Decisión técnica:** El merge se hace en cliente (no en Firestore con una query JOIN) porque Firestore no soporta joins. Esta es una **limitación técnica compensada por arquitectura**: el cliente mantiene el mapa `_settings` en memoria y aplica overrides en tiempo O(1) por lookup de hashmap.

#### 3.2.3 Persistencia de estado de pestañas (TabBarView)

Un bug crítico identificado en pruebas fue que el `TabBarView` de Flutter destruye y reconstruye los widgets hijos cuando cambia de tab. Para los grids de pictogramas, esto significaba:
- Pérdida de posición de scroll.
- Re-carga de todos los pictogramas desde el stream.
- Pérdida de estado de animaciones.

**Solución técnica:**

1. **PageStorageKey**: Cada tab del `TabBarView` recibe una `PageStorageKey` única (`tab_rutina`, `tab_comida`, etc.). Flutter usa estas keys para persistir el estado del scroll en un `PageStorageBucket` global.

2. **AutomaticKeepAliveClientMixin**: La clase `_GridCategoriaDisplay` implementa este mixin y devuelve `wantKeepAlive = true`. Esto instruye a Flutter para que mantenga el widget en el árbol incluso cuando no está visible.

```dart
class _GridCategoriaDisplayState extends State<_GridCategoriaDisplay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por el mixin
    // ... renderizado
  }
}
```

**Justificación técnica:** El `TabBarView` usa un mecanismo de **lazy loading** que crea widgets bajo demanda. Sin `AutomaticKeepAliveClientMixin`, el widget se destruye cuando el usuario cambia de tab. La combinación de `PageStorageKey` + `AutomaticKeepAliveClientMixin` es el patrón estándar de Flutter para tabs con estado persistente.

#### 3.2.4 Creación de pictogramas personalizados: Pipeline de imagen

El flujo completo para crear un pictograma personalizado es:

```
[Usuario toma foto / selecciona de galería]
    ↓
[ImagePicker] → devuelve XFile
    ↓
[ImageCropper] → recorta a 1:1, máximo 512x512
    ↓
[Firebase Storage] → upload con contentType: 'image/jpeg'
    ↓
[Firestore] → crea documento en users/{uid}/pictograms
    ↓
[StreamBuilder] → recibe snapshot con nuevo documento
    ↓
[UI] → muestra nuevo pictograma en categoría correspondiente
```

**Decisiones técnicas:**
- **Crop ratio 1:1**: Los pictogramas deben ser cuadrados para mantener consistencia visual con el banco ARASAAC.
- **Compresión 80%**: Balance entre calidad visual y tamaño de transferencia (reducción de ~60% vs JPEG sin compresión).
- **Max 512x512**: Suficiente para pantallas móviles (densidad máxima ~400 DPI), evitando cargas innecesarias de imágenes de alta resolución.
- **Theme personalizado para UCropActivity**: Se agregó `UCropTheme` en `styles.xml` para evitar que los botones de recorte se superpongan con la barra de navegación del sistema (bug de UI nativa).

### 3.3 Módulo de Síntesis de Voz (TTS)

#### 3.3.1 Arquitectura dual: Local + Nube

El sistema implementa una **estrategia de fallback** para TTS:

```
[Usuario toca pictograma]
    ↓
[Intento 1: flutter_tts local]
    ├── Éxito → Reproduce audio localmente
    └── Fallo (excepción, idioma no soportado, motor no instalado)
        ↓
        [Intento 2: Cloud TTS via Cloud Functions]
        ├── Éxito → Descarga audio MP3, reproduce con audioplayers
        └── Fallo → Muestra SnackBar: "No se pudo reproducir audio"
```

**Configuración de `flutter_tts`:**
- `setLanguage('es-ES')`: Idioma español de España.
- `setSpeechRate(0.42)**: Velocidad reducida (default ~0.5) para mejorar comprensión en usuarios con procesamiento auditivo lento.
- `setPitch(0.92)**: Tono ligeramente más grave que el default, percibido como más calmante en estudios de TEA.
- **Selección de voz neural**: Itera sobre las voces disponibles del dispositivo y prioriza aquellas con `neural`, `enhanced` o `wavenet` en su nombre.

**Justificación técnica:** La voz local es **instantánea** (latencia < 100ms) y funciona offline. La voz en nube es de **mayor calidad** (WaveNet) pero requiere conectividad y tiene latencia de ~500ms-2s. El fallback asegura que la funcionalidad nunca quede completamente inoperativa.

#### 3.3.2 Fix del bug "TTS mudo en pictogramas personalizados"

**Síntoma:** Los pictogramas del banco ARASAAC (SVG) reproducían TTS al tocar, pero los pictogramas personalizados (JPEG) no.

**Causa raíz:** El handler `onTap` de `_TarjetaPictogramaDisplay` estaba diseñado para llamar a `widget.onTap`, que en el caso de los pictogramas del banco ejecutaba `_hablarPictograma()`. Sin embargo, para los pictogramas en la vista de gestión (o en flujos específicos), la cadena de callbacks no propagaba la llamada a TTS.

**Solución:** Se agregó `_audioService.playText(picto.textoTts)` directamente en el método `_agregarAFraseDisplay()` (o el handler principal de toque) antes de iniciar la animación de "fly". Esto garantiza que **cualquier** pictograma tocado (sea SVG o JPEG) dispare la síntesis de voz.

```dart
void _agregarAFraseDisplay(PictogramaDisplay picto, Offset origenGlobal) {
  HapticFeedback.lightImpact();
  _audioService.playText(picto.textoTts); // ← Fix: TTS inmediato
  // ... resto de la animación
}
```

### 3.4 Módulo de Vinculación Tutor-Usuario

#### 3.4.1 Generación de códigos: Algoritmo de entropía temporal

El algoritmo de generación de códigos no utiliza `Random.secure()` (que requiere semilla criptográfica). En su lugar, usa el **timestamp actual** como semilla pseudoaleatoria:

```dart
static String _generateRandomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 32 chars
  final random = DateTime.now().millisecondsSinceEpoch;
  final code = List.generate(6, (index) {
    final idx = (random + index * 7919) % chars.length; // 7919 = primo grande
    return chars[idx];
  }).join();
  return code;
}
```

**Justificación técnica:**
- El timestamp proporciona **entropía suficiente** para un código de uso único con TTL de 7 días.
- La multiplicación por **7919** (número primo) distribuye uniformemente los índices sobre el alfabeto de 32 caracteres, evitando patrones cíclicos.
- El alfabeto excluye **0, O, 1, I, l** para evitar ambigüedades en la transcripción manual (p. ej., desde una pantalla compartida durante una videollamada).
- **No se requiere criptografía**: El código no es un token de sesión ni una contraseña. Es un identificador de vinculación temporal con un único propósito de uso.

#### 3.4.2 Validación y aceptación: Flujo de transacción distribuida

La vinculación implica escrituras en **dos colecciones diferentes** (`invitationCodes` y `users/{uid}/linkedTutors`). Firestore no soporta transacciones multi-colección que incluyan lecturas de colecciones donde el usuario no tiene permisos. Por tanto, se usa un **batch atómico** con una **verificación previa**:

```
[Tutor genera código]
    ↓
[Firestore: invitationCodes/{code}] → documento con status='active', expiresAt=+7d

[Usuario ingresa código]
    ↓
[Validación] 
    ├── Código existe? → No → Error "Código inválido"
    ├── status == 'active'? → No → Error "Código usado"
    ├── expiresAt > now? → No → Error "Código expirado"
    └── Sí → Retorna tutorId, tutorName

[Usuario acepta]
    ↓
[Segunda verificación] (race condition check)
    → Lee código nuevamente para confirmar status='active'
    ↓
[Firestore Batch] (atómico)
    ├── Update: invitationCodes/{code} → status='used', usedBy=uid, usedAt=now
    ├── Set: users/{uid}/linkedTutors/{tutorId} → status='active', linkedAt=now
    └── Set: users/{uid} → acceptedInvitationCode={code}
    ↓
[Commit batch]
    ↓
[Confirmación] → SnackBar: "Vinculado con éxito"
```

**Justificación técnica:** La segunda verificación antes del batch es esencial para detectar **condiciones de carrera** (race conditions). Si dos usuarios intentan usar el mismo código simultáneamente, la primera en ejecutar el batch gana, y la segunda recibirá un error porque el batch detectará que `status` ya no es `active` (aunque esto no se maneja explícitamente en la versión actual; la segunda batch fallará silenciosamente o generará un error de permisos).

**Patrón aplicado:** **Saga Pattern** (versión simplificada). Cada paso es idempotente o reversible. El batch atómico garantiza consistencia eventual.

#### 3.4.3 Desvinculación: Soft-delete vs Hard-delete

La desvinculación no elimina el documento de `linkedTutors`. En su lugar, actualiza el campo `status` a `'inactive'`:

```dart
batch.set(
  _firestore.collection('users').doc(patientId).collection('linkedTutors').doc(user.uid),
  {'status': 'inactive'},
  SetOptions(merge: true),
);
```

**Justificación técnica:**
- **Auditoría**: Mantener el historial de vinculaciones permite trazar quién supervisó a quién y durante cuánto tiempo.
- **Seguridad**: Las reglas de Firestore permiten al tutor actualizar su propia entrada en `linkedTutors` del usuario. Si el documento se eliminara, el tutor no podría demostrar que alguna vez estuvo vinculado (aunque el código de invitación sí tiene `usedBy`).
- **Reversibilidad**: Una desvinculación soft puede revertirse (reactivar) sin necesidad de regenerar un código de invitación.

### 3.5 Módulo de Supervisión (Tutor)

#### 3.5.1 Arquitectura del panel de supervisión

El panel de supervisión (`TutorSupervisarScreen`) implementa un **patrón de tabs con estado compartido**:

```dart
IndexedStack(
  index: _currentIndex,
  children: [
    _TutorTasksTab(key: ValueKey('tasks_$patientId'), patientId: pk),
    _TutorPictogramsTab(key: ValueKey('pictos_$patientId'), patientId: pk),
    ProgresoScreen(key: ValueKey('progreso_$pk'), userId: pk),
    _TutorHistorialTab(key: ValueKey('history_$pk'), patientId: pk),
    _TutorConfigTab(key: ValueKey('config_$pk'), patientId: pk, patientName: _patientName),
  ],
)
```

**Clave técnica:** `ValueKey('tasks_$patientId')`. Cuando el tutor cambia de usuario activo, el `patientId` cambia, el `ValueKey` cambia, y Flutter **destruye y reconstruye** el widget del tab. Esto es intencional: **limpiar el estado previo** del usuario anterior para evitar que el tutor vea datos mezclados (p. ej., tareas del usuario A mientras supervisa al usuario B).

**Justificación técnica:** Sin `ValueKey`, Flutter reutilizaría el widget existente y solo actualizaría sus propiedades. El `StreamBuilder` interno del widget podría no detectar el cambio de stream si el `initState` no se re-ejecuta. Destruir y reconstruir garantiza un estado limpio.

#### 3.5.2 Configuración de pestañas: Feature Flags en tiempo real

La configuración de qué pestañas son visibles para el usuario se almacena en:

```
users/{uid}/pictogramSettings/_features
  → featureInicio: bool
  → featureTareas: bool
  → featurePictogramas: bool
  → featureFoco: bool
  → featurePerfil: bool
```

**Lógica de `CustomNavBar`:**
1. Escucha el stream de `_features` en `initState`.
2. En cada snapshot, recalcula la lista de `_entries` (tabs disponibles).
3. Si la pantalla activa ya no está disponible (fue desactivada por el tutor), redirige automáticamente al primer tab disponible mediante `Navigator.pushReplacement` con `PageRouteBuilder` sin animación.

**Justificación técnica:** Esta arquitectura permite que el tutor **modifique la UI del usuario en tiempo real** sin requerir que el usuario cierre y abra la app. Es un ejemplo de **remote configuration** sin necesidad de Firebase Remote Config (usando Firestore directamente).

### 3.6 Módulo de Notificaciones

#### 3.6.1 Programación de notificaciones locales

Las notificaciones de tareas se programan usando `flutter_local_notifications` con precisión de tiempo basada en `timezone`:

```
[Tarea creada con fecha/hora y offset de recordatorio]
    ↓
[Calcula TZDateTime] → (fecha/hora de tarea - offset)
    ↓
[Programa notificación] → zonedSchedule()
    ↓
[Sistema operativo] → Alarma programada (AlarmManager en Android, UNUserNotificationCenter en iOS)
    ↓
[Dispara a tiempo] → Notificación mostrada al usuario
```

**Decisiones técnicas:**
- `zonedSchedule` en lugar de `schedule`: Garantiza que la notificación se dispare en la zona horaria local del usuario, no en UTC.
- `androidScheduleMode`: `exactAllowWhileIdle` para notificaciones precisas incluso en Doze mode.
- `uiLocalNotificationDateInterpretation`: `absoluteTime` para interpretación consistente entre plataformas.

**Justificación técnica:** Las notificaciones son un **canal de prótesis cognitiva crítico**. Si un recordatorio no se dispara a la hora exacta, el usuario puede olvidar una tarea médica o una rutina importante. La precisión es más importante que la eficiencia energética en este contexto.

### 3.7 Módulo de Respaldo (Google Drive)

#### 3.7.1 Flujo de backup

```
[Usuario solicita backup]
    ↓
[GoogleSignIn] → Solicita scope de Google Drive
    ↓
[Exportación de datos]
    ├── Firestore: users/{uid} → JSON
    ├── Firestore: users/{uid}/tasks → JSON
    ├── Firestore: users/{uid}/pictogramSettings → JSON
    └── Firestore: users/{uid}/activityLog → JSON (últimos 100)
    ↓
[Compresión] → ZIP
    ↓
[Google Drive API] → Upload a folder 'Simple Backups'
    ↓
[Actualización de metadata] → lastSyncTimestamp en user doc
    ↓
[Confirmación] → SnackBar + UI updated
```

**Justificación técnica:** El backup se implementa en el cliente (no en Cloud Functions) porque:
1. El usuario debe **autorizar explícitamente** el acceso a Google Drive mediante OAuth.
2. El volumen de datos por usuario es pequeño (< 1 MB típicamente), manejable en el cliente.
3. Evita costos de egress de Firebase (lecturas de Firestore) en operaciones iniciadas por el usuario.

**Patrón aplicado:** **Exportación/Importación de estado completo**. El ZIP es un snapshot portable del estado del usuario, desacoplado de la estructura de Firestore. Esto permite futuras migraciones de backend (por ejemplo, de Firebase a Supabase) simplemente importando el ZIP.

---

## 4. Patrones de Diseño Aplicados

### 4.1 Repository Pattern

Los servicios (`AuthService`, `PictogramService`, `TaskService`) actúan como **repositories** que abstraen la fuente de datos. El código de la UI nunca llama a `FirebaseFirestore.instance` directamente; siempre lo hace a través del servicio.

**Beneficio:** Si en el futuro se migra de Firestore a MongoDB, PostgreSQL o Supabase, solo los repositorios cambian. La UI permanece intacta.

### 4.2 Observer Pattern (Publish-Subscribe)

Los **Firestore Streams** son la implementación nativa del Observer Pattern. Los widgets se "suscriben" a streams mediante `StreamBuilder` y se "notifican" cuando los datos cambian.

```dart
StreamBuilder<QuerySnapshot>(
  stream: _tasksRef.orderBy('createdAt', descending: true).snapshots(),
  builder: (context, snap) { /* UI reconstruida automáticamente */ },
)
```

### 4.3 Strategy Pattern

El `RoleDispatcher` selecciona la estrategia de routing según el rol del usuario. Cada rol tiene una estrategia de presentación diferente:

```dart
class RoleDispatcher extends StatelessWidget {
  final UserRole role;
  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.usuario: return const PantallaUsuarioTEA();
      case UserRole.tutor: return const HomeScreen();
      default: return const RoleSelectionScreen();
    }
  }
}
```

### 4.4 Adapter Pattern

`PictogramaDisplay.fromLocal` y `PictogramaDisplay.fromCustom` adaptan dos modelos de datos diferentes (`Pictograma` y `PictogramaPersonalizado`) a una interfaz común (`PictogramaDisplay`) que el widget de la cuadrícula puede consumir.

### 4.5 Singleton Pattern

Los servicios principales (`AuthService`, `GoogleDriveService`) se implementan como clases estáticas o singletons. `AuthService` no tiene instancia pública; todos sus métodos son `static`, garantizando un único punto de acceso a Firebase Auth.

### 4.6 State Machine (Pomodoro)

El temporizador Pomodoro implementa una máquina de estados con transiciones controladas:

```
[Idle] --start--> [Work 25min]
[Work 25min] --complete--> [Break 5min]
[Break 5min] --complete--> [Idle] (o [Work 25min] si auto-start)
```

Cada estado tiene sus propios timers, sonidos, y actualizaciones de Firestore.

### 4.7 CQRS (Command Query Responsibility Segregation)

Firestore Cloud Functions implementan una versión ligera de CQRS:
- **Commands**: Las escrituras en Firestore (tarea completada, pictograma usado) disparan Cloud Functions.
- **Queries**: Los streams de lectura son independientes de las escrituras.
- **Separación**: El `ActivityLogService` escribe en `activityLog` (command) mientras que el `_TutorHistorialTab` lee de `activityLog` (query). Nunca se lee el log para modificar una tarea.

---

## 5. Seguridad: Diseño de Reglas de Firestore

### 5.1 Modelo de amenazas

**Amenazas identificadas:**
1. **Usuario A lee datos del Usuario B**: Un usuario no debe poder leer las tareas, pictogramas o configuración de otro usuario.
2. **Tutor espía usuarios no vinculados**: Un tutor solo debe ver datos de usuarios que aceptaron su código de invitación.
3. **Usuario modifica datos del tutor**: Un usuario no debe poder modificar la configuración del panel del tutor.
4. **Código de invitación reutilizado**: Un código ya usado no debe permitir vinculación doble.

### 5.2 Reglas de seguridad implementadas

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Función auxiliar: ¿es el dueño del documento?
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }
    
    // Función auxiliar: ¿es tutor vinculado del usuario?
    function isLinkedTutor(userId) {
      return request.auth != null && 
        exists(/databases/$(database)/documents/users/$(userId)/linkedTutors/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(userId)/linkedTutors/$(request.auth.uid)).data.status == 'active';
    }
    
    // Colección users
    match /users/{userId} {
      allow read: if isOwner(userId) || isLinkedTutor(userId);
      allow write: if isOwner(userId);
      
      // Subcolección linkedTutors
      match /linkedTutors/{tutorId} {
        allow read: if isOwner(userId);
        allow update: if isLinkedTutor(userId) || isOwner(userId); // Tutor puede desvincularse
      }
      
      // Subcolección tasks
      match /tasks/{taskId} {
        allow read, write: if isOwner(userId) || isLinkedTutor(userId);
      }
      
      // Subcolección pictogramSettings
      match /pictogramSettings/{settingId} {
        allow read, write: if isOwner(userId) || isLinkedTutor(userId);
      }
      
      // Subcolección pictograms (custom)
      match /pictograms/{pictoId} {
        allow read, write: if isOwner(userId) || isLinkedTutor(userId);
      }
      
      // Subcolección activityLog
      match /activityLog/{logId} {
        allow read: if isOwner(userId) || isLinkedTutor(userId);
        allow write: if isOwner(userId); // Solo el usuario escribe su propio log
      }
    }
    
    // Colección invitationCodes
    match /invitationCodes/{code} {
      allow read: if request.auth != null; // Cualquier usuario autenticado puede validar
      allow write: if request.auth != null && 
        resource.data.tutorId == request.auth.uid; // Solo el tutor creador puede modificar
    }
  }
}
```

**Justificación técnica:**
- `isLinkedTutor` usa una **lectura de documento** (`get(...)`) dentro de la regla. Esto es más costoso que una simple comparación de campos, pero es necesario porque la vinculación se almacena en una subcolección, no en un campo del documento raíz.
- Las reglas permiten que el tutor **escriba** en `tasks`, `pictogramSettings` y `pictograms` del usuario. Esto es esencial para la funcionalidad de supervisión.
- El `activityLog` solo permite escritura por el dueño. Los tutores pueden leer el historial, pero no falsificar entradas.

---

## 6. Optimizaciones y Rendimiento

### 6.1 Lazy loading de pictogramas

Los pictogramas del banco ARASAAC son SVG locales. Se cargan mediante `SvgPicture.asset()` que parsea el SVG en tiempo de renderizado. Para optimizar:
- **Precarga en initState**: Los pictogramas de la categoría activa se precargan en memoria durante `initState` del `TabBarView`.
- **Cache de imágenes**: `Image.network` para pictogramas personalizados usa el cache interno de Flutter (`ImageCache`), con un límite de 100 imágenes y 100 MB por defecto.

### 6.2 Debouncing de escrituras en Firestore

El tutor puede cambiar la categoría de múltiples pictogramas rápidamente. Para evitar N escrituras simultáneas:
- **Batch de configuración**: El `PictogramManagerScreen` usa un mapa local `_settings` que se actualiza optimistamente.
- **Escritura individual**: Cada cambio se escribe a Firestore inmediatamente, pero la UI no espera la confirmación (optimistic UI). Si la escritura falla, el siguiente snapshot del stream revertirá el estado.

### 6.3 Minimización de lecturas de Firestore

- **Streams persistentes**: Los `StreamSubscription` de `AuthService`, `PictogramService`, etc., se crean en `initState` y se cancelan en `dispose`. Esto evita recrear streams en cada rebuild.
- **Limitación de logs**: `ActivityLogService.getStream()` limita a 100 documentos (`orderBy('timestamp', descending: true).limit(100)`), evitando lecturas ilimitadas de historial.

### 6.4 Compresión de imágenes

- **JPEG quality 80%**: Reducción de ~60% del tamaño vs calidad 100%.
- **Max 512x512**: Reducción de ~75% del tamaño vs una foto de 1920x1080.
- **Crop cuadrado**: Elimina píxeles innecesarios, manteniendo consistencia visual.

---

## 7. Decisiones Técnicas Controversas y Justificaciones

### 7.1 ¿Por qué no usar un backend propio (Node.js/Express)?

**Decisión:** Usar Firebase BaaS en lugar de un backend Node.js/Express propio.

**Justificación:**
- **Costo operativo**: Firebase BaaS tiene un **free tier** generoso que cubre el 100% de los costos para < 10,000 usuarios activos. Un backend propio requiere servidor (VPS mínimo $5/mes) + monitoreo + backups.
- **Tiempo de desarrollo**: El 80% del backend (autenticación, base de datos, almacenamiento, notificaciones) se resuelve con Firebase SDK. El 20% restante (TTS, Drive) se implementa con Cloud Functions.
- **Escalado**: Firebase escala automáticamente. Un backend propio requiere configuración de load balancers, replicación de base de datos, etc.
- **Contra**: Vendor lock-in. Si Google cierra Firebase o aumenta precios, la migración es compleja. Se mitigó con el **Repository Pattern** y el **sistema de backup a ZIP** que desacopla los datos de la plataforma.

### 7.2 ¿Por qué no usar Provider/Riverpod/Bloc para gestión de estado?

**Decisión:** Usar `StatefulWidget` + `StreamBuilder` en lugar de una librería de gestión de estado global.

**Justificación:**
- **Simplicidad**: El estado de la app es predominantemente **remoto** (Firestore). Los `StreamBuilder` ya gestionan el estado reactivo sin necesidad de un store global.
- **Acoplamiento**: El estado del pictograma A no afecta al estado del pictograma B. No hay necesidad de un estado global compartido.
- **Excepciones**: Se usa `ValueNotifier` localmente para estados que no persisten en Firestore (ej. `_obscurePassword` en login, `_isLoading`).
- **Contra**: En una app más grande, la falta de un estado global puede generar prop drilling. Se mitigó pasando callbacks (`onTap`, `onLongPress`) en lugar de estados profundos.

### 7.3 ¿Por qué no usar SQLite local para caché?

**Decisión:** Usar `SharedPreferences` para datos pequeños y Firestore offline persistence para datos grandes.

**Justificación:**
- **Firestore offline**: Firestore SDK ya implementa persistencia local (SQLite interno) con sincronización automática. No es necesario duplicar esta capa.
- **SharedPreferences**: Suficiente para flags booleanos (ej. `hasCompletedOnboarding`, `saved_email`).
- **Contra**: Sin SQLite, las consultas complejas (ej. "tareas completadas en la última semana") requieren leer todos los documentos en memoria. Se mitigó con indexación de Firestore y limitación de queries.

### 7.4 ¿Por qué no usar Clean Architecture con capas estrictas?

**Decisión:** Usar una arquitectura de 3 capas pragmática (UI, Service, Repository) en lugar de Clean Architecture con Use Cases, Entities, DTOs, mappers, etc.

**Justificación:**
- **Complejidad del proyecto**: Con [X] módulos y [Y] pantallas, Clean Architecture introduciría una sobrecarga de boilerplate que no se justifica.
- **Velocidad de desarrollo**: El proyecto se desarrolló en 11 sprints de 2 semanas. La arquitectura pragmática permitió entregar funcionalidad completa sin sacrificar mantenibilidad.
- **Contra**: Menos testeable que Clean Architecture. Se mitigó con **Repository Pattern** que desacopla la UI de Firebase, permitiendo mocking en pruebas unitarias.

---

## 8. Flujo de Datos Detallado: Casos de Uso

### 8.1 Caso de uso: Usuario completa una tarea

```
[Usuario toca checkbox de tarea]
    ↓
[_SupervisionTaskTile.onToggle] 
    → Llama a _tasksRef.doc(taskId).update({'done': true})
    ↓
[Firestore SDK (cliente)]
    → Encola la escritura localmente (offline persistence)
    → Intenta enviar al servidor
    ↓
[Firestore Backend]
    → Valida reglas de seguridad: isLinkedTutor || isOwner
    → Actualiza documento
    → Emite snapshot a todos los listeners
    ↓
[StreamBuilder en TutorSupervisarScreen]
    → Recibe snapshot con tarea actualizada
    → Reconstruye lista de tareas
    ↓
[UI del tutor] → Tarea aparece como "Completada" en tiempo real

[Cloud Function (trigger onUpdate)]
    → Detecta cambio de 'done' a true
    → Escribe en activityLog: type='taskCompleted'
    → Incrementa focusSessionsCompleted en user doc (si aplica)
    ↓
[FCM] → Notificación push al tutor: "[Usuario] completó [Tarea]"
```

### 8.2 Caso de uso: Tutor reorganiza pictogramas

```
[Tutor abre PictogramManagerScreen]
    ↓
[StreamBuilder] → Escucha pictogramSettings stream
    ↓
[Tutor toca categoría de un pictograma]
    ↓
[_showCategoryPicker] → Muestra bottom sheet con opciones
    ↓
[Tutor selecciona nueva categoría]
    ↓
[_setCategoria] 
    → Actualiza _settings localmente (optimistic UI)
    → Llama a PictogramService.updatePictogramSettingFor(...)
    ↓
[Firestore SDK]
    → Escribe en users/{patientId}/pictogramSettings/{pictoId}
    ↓
[Firestore Backend]
    → Valida: isLinkedTutor(patientId)
    → Actualiza documento
    → Emite snapshot
    ↓
[StreamBuilder en PantallaUsuarioTEA]
    → Recibe nuevo _pictoSettings
    → Recalcula _filtrarPorCategoria
    → Reconstruye TabBarView
    ↓
[UI del usuario] → Pictograma se mueve a nueva categoría en tiempo real
```

---

## 9. Conclusión de la Memoria Técnica

La arquitectura de Organízate demuestra que una **prótesis cognitiva digital** puede construirse sobre una infraestructura serverless (Firebase) con un frontend declarativo (Flutter), manteniendo bajo costo operativo y alto rendimiento. Las decisiones clave —streaming reactivo, migración on-the-fly, soft-delete, optimistic UI, arquitectura dual de TTS— responden a las necesidades específicas de usuarios neurodivergentes: **predictibilidad, inmediatez, retroalimentación multisensorial y autonomía**.

La memoria técnica documenta no solo el **cómo** (flujo de datos, patrones, código), sino el **porqué** (justificaciones de diseño, trade-offs, lecciones aprendidas). Esto permite que futuros desarrolladores comprendan la lógica subyacente sin depender únicamente del código fuente, y que evaluadores académicos valoren la profundidad técnica del proyecto más allá de la funcionalidad superficial.

---

**Fin de la Memoria Técnica**

*Documento complementario al Informe Técnico para Defensa de Título.*
*[DD/MM/AAAA]*
