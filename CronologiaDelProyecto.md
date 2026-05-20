# Cronología del Proyecto: Simple

Este documento consolida la **Carta Gantt**, la planificación de **Sprints** y el registro de avance real del desarrollo de la aplicación Simple.

**Período:** 27 Abril 2026 - 07 Julio 2026 (10 semanas)  
**Estado Actual:** 94% Completado | Dashboard de progreso integrado  
**Próximo Hito:** Kiosk Mode para usuario TEA

---

## Resumen Ejecutivo

### Progreso por Fase

| Fase | Periodo | Nombre | Estado | Progreso |
|:---|:---|:---|:---:|:---:|
| **Fase 1** | 27-28 Abr | Fundación y Auth | ✅ Completado | 100% |
| **Fase 2** | 28-29 Abr | IA / Súper Experto | ✅ Completado | 100% |
| **Fase 3** | 30 Abr-06 May | Módulo TEA (Pictogramas) | ✅ Completado | 100% |
| **Fase 4** | 05-09 May | Módulo TDAH (Tareas y Foco) | ✅ Completado | 100% |
| **Fase 5** | 09-23 May | Integración y Correcciones | ✅ Completado | 100% |
| **Fase 6** | 24 May-16 Jun | Pulido y Testing | 🔄 En Curso | 25% |
| **Fase 7** | 17 Jun-07 Jul | Documentación y Entrega | ⏳ Pendiente | 0% |

### Hitos del Proyecto

| Hito | Fecha | Descripción | Estado |
|:---|:---|:---|:---:|
| **HITO 1** | 13 May 2026 | Vinculación Tutor-Usuario | ✅ Alcanzado |
| **HITO 2** | 26 May 2026 | Sincronización Completa | ✅ Alcanzado |
| **HITO 3** | 30 Jun 2026 | MVP Listo | ⏳ Pendiente |
| **HITO 4** | 07 Jul 2026 | Entrega Final (APK + Doc) | ⏳ Pendiente |

---

## Carta Gantt Detallada

### Cronograma Semanal Completo (27 Abril - 07 Julio 2026)

| Fase | Tarea | S1<br>27-30Abr | S2<br>01-04May | S3<br>05-09May | S4<br>10-13May | S5<br>14-18May | S6<br>19-23May | S7<br>24-30May | S8<br>31May-06Jun | S9<br>07-13Jun | S10<br>14-20Jun | S11<br>21-27Jun | S12<br>28Jun-07Jul |
|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **FASE 1** | Base Organizate 2.0 + UI | ██████ | | | | | | | | | | | |
| | Sistema Login (email + Google) | ██████ | | | | | | | | | | | |
| | Cambio nombre → Simple + Logo | ██████ | | | | | | | | | | | |
| **FASE 2** | Integración Cloud Functions IA | | ██████ | | | | | | | | | | |
| | Súper Experto funcional (Gemini) | | ██████ | | | | | | | | | | |
| **FASE 3** | Pantalla Pictogramas (ARASAAC) | | | ██████ | | | | | | | | | |
| | Banco pictogramas SVG + TTS | | | ██████ | | | | | | | | | |
| | Pictogramas custom (cámara/storage) | | | | ██████ | | | | | | | | |
| **FASE 4** | Gestión tareas (CRUD) | | | ██████ | | | | | | | | | |
| | Timer Pomodoro + respiración | | | | ██████ | | | | | | | | |
| | Sistema dopamina (puntos + racha) | | | | ██████ | | | | | | | | |
| **FASE 5** | Vinculación tutor-usuario | | | | | ██████ | | | | | | | |
| | Panel supervisión tutor completo | | | | | | ██████ | | | | | | |
| | Sincronización bidireccional tareas | | | | | | ██████ | | | | | | |
| | Correcciones y renombrado roles | | | | | | ██████ | | | | | | |
| **FASE 6** | Kiosk Mode usuario TEA | | | | | | | ██████ | | | | | |
| | Dashboard progreso (fl_chart) | | | | | | | ██████ | | | | | |
| | Notificaciones push FCM | | | | | | | | ██████ | | | | |
| | QA y bugs menores | | | | | | | | ██████ | | | | |
| **FASE 7** | Comentarios en código crítico | | | | | | | | | ██████ | | | |
| | Pruebas finales con usuarios | | | | | | | | | ██████ | | | |
| | Manual de usuario (tutores/TEA) | | | | | | | | | | ██████ | | |
| | APK firmado + entrega | | | | | | | | | | | | ██████ |

**Leyenda:** ██████ = Período de desarrollo activo  
**Nota:** La entrega será mediante APK/instalación directa, sin publicación en tiendas.

---

## Fases Completadas

### ✅ Fase 1: Fundación y Autenticación (27-28 Abril 2026)

**Objetivo:** Establecer la arquitectura base y el sistema de autenticación.

**Commits Principales:**
- `8e73da2` (27 Abr): Base Organizate 2.0 + rediseño UI Login
- `e48e5d0` (28 Abr): Cambio de nombre a Simple, nuevo logo, login web

**Tareas Completadas:**
- ✅ Refactor del código base heredado de *Organízate* — carpetas limpias, estructura por `features/`
- ✅ Diseño base con paleta Soft UI (colores calmos, bordes redondeados, tipografía)
- ✅ Setup de Firebase (Auth, Firestore, Storage)
- ✅ Login con Email/Password y Google Sign-In
- ✅ Reglas de seguridad Firestore iniciales
- ✅ `RoleDispatcher` — enrutamiento automático según rol del usuario

---

### ✅ Fase 2: IA / Súper Experto (28-29 Abril 2026)

**Objetivo:** Integrar inteligencia artificial para asistencia en tareas.

**Commits Principales:**
- `2d886cc` (29 Abr): Súper Experto IA funcional (Gemini + Cloud Functions)
- `c417861` (29 Abr): Función `desglosarTarea` (Gemini)

**Tareas Completadas:**
- ✅ Google Cloud Functions v2 (TypeScript) con Secret Manager para la API key
- ✅ Integración con Gemini API — desglose automático de tareas en pasos simples
- ✅ Fallback local `generarPlanLocal()` cuando Gemini no está disponible
- ✅ UI de chat con el "Súper Experto" en pantalla de foco TDAH
- ✅ Manejo correcto de errores (región explícita `us-central1`, timeout 30s)

---

### ✅ Fase 3: Módulo TEA — Pictogramas (30 Abril - 06 Mayo 2026)

**Objetivo:** Desarrollar el sistema de comunicación aumentativa para usuarios TEA.

**Commits Principales:**
- `0633e86` (30 Abr): Pantalla Pictogramas Beta (módulo TEA)
- `335f814` (06 May): Pantalla Pictogramas completa con banco ARASAAC
- `d361ef0` (06 May): Pictogramas con color

**Tareas Completadas:**
- ✅ Tablero de pictogramas con franjas horarias: Mañana, Tarde, Noche
- ✅ Categorías: Comida, Emociones, Acciones, Emergencia
- ✅ Banco de pictogramas predefinidos (SVG — banco ARASAAC local)
- ✅ Síntesis de voz (TTS) inmediata al pulsar cada pictograma
- ✅ Creación de pictogramas personalizados con cámara/galería + recorte 1:1
- ✅ Subida a Firebase Storage + metadatos en Firestore
- ✅ Gestión de visibilidad, categoría y horario por pictograma
- ✅ `pictogramSettings` como subcolección separada (sin modificar el original)
- ✅ Tutor puede agregar/eliminar pictogramas del usuario desde su panel

---

### ✅ Fase 4: Módulo TDAH — Tareas y Foco (05-09 Mayo 2026)

**Objetivo:** Desarrollar herramientas de organización y enfoque para TDAH.

**Commits Principales:**
- `12bd20d` (05 May): Migración completa de Organizate → Simple
- `e723ddd` (05 May): Swipe para eliminar tareas completadas
- `89ec05e` (09 May): Timer Pomodoro + respiración guiada

**Tareas Completadas:**
- ✅ CRUD de tareas con categorías (General, Estudios, Hogar, Meds, Foco)
- ✅ Swipe para eliminar tareas completadas
- ✅ Temporizador Pomodoro configurable (15, 25, 45 min)
- ✅ Rutinas de respiración guiada animada
- ✅ Sistema de dopamina: puntos (+10 por tarea), racha diaria, animaciones de refuerzo
- ✅ "Súper Experto" IA conectado al contexto de la pantalla de foco

---

### ✅ Fase 5: Integración y Correcciones (09-23 Mayo 2026)

**Objetivo:** Conectar todos los módulos, corregir bugs y completar el panel del tutor.

**Commits Realizados:**
- `97fd1b1` (09 May): Eliminación Modo Foco → reemplazado por Pictogramas TEA
- `f953774` (09 May): Fix superposición de botones en Pictogramas
- `89ec05e` (09 May): Conexiones Firebase, nuevo SHA-1, nuevo `google-services.json`
- `ce5c88a` (13 May): Tutor conectado a usuario — vinculación por código ⭐ **HITO 1**
- `e6d1494` (14 May): Inicio de sesión con Google corregido
- *(19 May)*: `ProfileSetupScreen` post-rol + renombrado completo `paciente` → `usuario`
- *(19 May)*: Panel historial tutor: stats en tiempo real + log Pomodoro + log pictogramas + badge Tutor en tareas

**Tareas Completadas:**
- ✅ Corrección SHA-1 — inicio de sesión con Google estable
- ✅ `.firebaserc` configurado con proyecto `organizate-26065`
- ✅ Eliminación del Modo Foco (reemplazado por Pictogramas en perfil TEA)
- ✅ Fix superposición de botones en el tablero de pictogramas
- ✅ Vinculación tutor-usuario mediante código de invitación de 6 caracteres
- ✅ `ProfileSetupScreen` — pantalla de nombre + avatar después de elegir rol
- ✅ Botón × visible en tarjetas de pictograma del tutor (eliminación directa)
- ✅ Fix Súper Experto: `throw String` → `throw Exception(...)` para captura correcta
- ✅ Fix dialog "Añadir tarea": se cierra automáticamente al guardar
- ✅ Renombrado completo `paciente_tdah` → `usuario_tdah`, `paciente_tea` → `usuario_tea` — código + Firestore rules + migración automática al abrir sesión
- ✅ Tab Historial del tutor: tarjeta de 4 stats en tiempo real (sesiones Pomodoro, minutos foco, racha, puntos)
- ✅ `ActivityType.pomodoroCompleted` — sesiones Pomodoro ahora aparecen en el historial del tutor
- ✅ `ActivityType.pictogramUsed` — cada uso de pictograma (TTS) queda registrado
- ✅ Badge azul "Tutor" en tareas creadas por el tutor visibles en pantalla del usuario ⭐ **HITO 2**
- ✅ Sincronización bidireccional de tareas tutor ↔ usuario (Firestore compartido, tiempo real)
- ✅ Sección "Eliminadas por el usuario" en tab Tareas del tutor (`_DeletedTaskTile` con tachado y color gris)
- ✅ `PictogramManagerScreen` rediseñado como cuadrícula 3 columnas (`_PictoManagerCard`)
- ✅ Tab "Ajustes" en panel tutor: switches para activar/desactivar pestañas Pictogramas y Foco del usuario TEA en tiempo real
- ✅ `CustomNavBar` reactivo: dos streams paralelos (rol + feature flags) — índice clampeado para evitar out-of-bounds al cambiar cantidad de tabs
- ✅ Comentarios de arquitectura profesionales en 8 archivos críticos (servicios, navegación, reglas Firestore, pantallas)
- ✅ `SettingsScreen` rediseñado: tarjeta unificada perfil+rol con edición de nombre, foto y rol por íconos de lápiz + diálogo de confirmación antes de cambiar rol
- ✅ Fix bug cambio de rol: `Navigator.pushAndRemoveUntil(AuthGate)` limpia el stack — el usuario ya no queda pegado en `RoleSelectionScreen`

---

## Fase en Curso

### 🔄 Fase 6: Pulido y Testing (24 Mayo - 16 Junio 2026)

**Estado:** 40% iniciado | **Proyección:** 16 Junio 2026

**Objetivo:** Pulir la UX, agregar funcionalidades de control parental, notificaciones y testing exhaustivo.

#### Tareas Planificadas

**Sprint A — Control y Visualización (24 May - 02 Jun):**

- 🔲 **Kiosk Mode para usuario TEA** *(alta prioridad)*
  - Bloqueo de botones físicos (volumen, home, recientes)
  - PIN para salir de la app (para el tutor/cuidador)
  - Prevención de cambio de app accidental

- ✅ **Dashboard de progreso visual** *(alta prioridad)*
  - ✅ Gráfico de barras: tareas completadas por categoría (`fl_chart`)
  - ✅ Gráfico de anillo: pictogramas más usados por categoría (extraído de `activityLog`)
  - ✅ Gráfico de línea: sesiones Pomodoro semanales (minutos por día)
  - ✅ Tarjeta resumen: puntos, racha, sesiones, minutos de foco
  - ✅ Integrado en `CustomNavBar` (tab "Progreso" para TDAH/general/TEA)
  - ✅ Integrado en `TutorSupervisarScreen` (tab "Progreso" con `userId` del paciente)
  - ✅ `ProgresoScreen` reescrito (420 líneas) con 3 gráficos independientes + resumen

- ✅ **Control granular de pestañas (tutor)** *(alta prioridad)*
  - ✅ Nuevos toggles en tab "Ajustes" del tutor: **Inicio** + **Tareas** (además de Pictogramas y Foco)
  - ✅ `CustomNavBar` lee `featureInicio` y `featureTareas` desde `pictogramSettings/_features`
  - ✅ Tabs Inicio y Tareas ahora son condicionales en la app del usuario TEA
  - ✅ 4 toggles totales: Inicio, Tareas, Pictogramas, Foco — todos controlables por el tutor

- ✅ **Fix: contenido tapado por nav bar** *(bug crítico)*
  - ✅ `SettingsScreen`: padding inferior dinámico (`widget.showNavBar ? 96 : 16`)
  - ✅ `ProgresoScreen`: padding inferior 96px para consistencia
  - ✅ Verificado: `FocoScreen` (100px), `HomeScreen` (110px), `TareasScreen` (Expanded), `PantallaPacienteTEA` (Expanded) ya protegidos

**Sprint B — Notificaciones y QA (03 - 16 Jun):**

- 🔲 **Notificaciones push FCM** *(media prioridad)*
  - Recordatorios de tareas con fecha/hora límite
  - Alertas de rutinas diarias
  - Notificación al tutor cuando el usuario completa una tarea

- 🔲 **QA y corrección de bugs** *(alta prioridad)*
  - Testing en dispositivos Android de gama baja/media
  - Verificar flujo completo: registro → rol → perfil → funcionalidad
  - Corrección de bugs reportados en testing

**Dependencias:**
- Requiere Fase 5 completada ✅
- Bloquea inicio de Fase 7

---

## Fases Pendientes

### ⏳ Fase 7: Documentación y Entrega (17 Junio - 07 Julio 2026)

**Estado:** 0% | **Proyección:** 07 Julio 2026 | ⭐ **HITO 3 y 4**

**Objetivo:** Finalizar el proyecto con documentación completa y entrega del MVP.

#### Tareas Planificadas

**Semana 1-2 (17-27 Jun):**
- 🔲 Comentarios en código crítico — explicar decisiones no obvias para estudio
- 🔲 Documentación técnica: arquitectura, guía de instalación, reglas Firestore
- 🔲 Pruebas finales con usuarios reales (familias con niños TEA/TDAH)
- 🔲 Optimización: lazy loading de imágenes, caché de pictogramas frecuentes

**Semana 3 (28 Jun - 07 Jul):**
- 🔲 Manual de usuario
  - Guía para usuarios TEA (pictogramas)
  - Guía para tutores (panel de supervisión)
  - Guía rápida de instalación del APK
- 🔲 APK firmado y empaquetado de entrega
- 🔲 Video demo del proyecto
- 🔲 Presentación final con métricas y aprendizajes

**Entregables Finales:**
- APK funcional firmado
- Manual de usuario completo
- Documentación técnica
- Presentación del proyecto
- Repositorio documentado con README actualizado

---

## Próximo Sprint: Prioridades (Semana del 20 Mayo)

### Tareas Críticas — Fase 6 en Curso

| Prioridad | Tarea | Estimación | Estado |
|:---|:---|:---:|:---:|
| 🔴 **Alta** | Dashboard de progreso con `fl_chart` | 3 días | ✅ Completado |
| 🔴 **Alta** | Kiosk Mode para usuario TEA | 3 días | 🔲 Pendiente |
| 🟡 **Media** | Notificaciones push FCM | 4 días | ✅ Infraestructura lista |
| 🟡 **Media** | QA — testing en dispositivos reales | 2 días | 🔲 Pendiente |

**Objetivo del Sprint:** Cerrar funcionalidades de pulido antes del 16 de junio para entrar a Fase 7.

---

## Registro de Decisiones Arquitectónicas Clave

| Fecha | Decisión | Motivo | Fase |
|:---|:---|:---|:---:|
| 27 Abr | Migración `Organizate` → `Simple` | Nombre más claro y representativo del producto | Fase 1 |
| 28 Abr | Enrutamiento basado en roles con `RoleDispatcher` | Evitar que un usuario acceda al entorno de otro perfil | Fase 1 |
| 29 Abr | Fallback local `generarPlanLocal()` en Cloud Function | Si Gemini falla o no hay API key, la app no rompe | Fase 2 |
| 30 Abr | `pictogramSettings` como subcolección separada | Permite sobrescribir categoría/visibilidad sin modificar el pictograma original | Fase 3 |
| 06 May | `IndexedStack` + `ValueKey(patientId)` en panel tutor | Forzar reconstrucción de tabs al cambiar de usuario activo | Fase 3 |
| 09 May | Eliminación Modo Foco | Reemplazo por Pictogramas en perfil TEA (más funcional) | Fase 5 |
| 13 May | Vinculación por código de 6 caracteres | Más seguro y simple que vinculación por email | Fase 5 |
| 19 May | `ProfileSetupScreen` post-rol | Garantizar que todo usuario tenga nombre y avatar antes de entrar | Fase 5 |
| 19 May | Renombrado `paciente_*` → `usuario_*` | Terminología más inclusiva; migración automática en `getUserRole()` | Fase 5 |
| 19 May | Log de Pomodoro y pictogramas en `activityLog` | El tutor necesita ver actividad completa, no solo tareas | Fase 5 |
| 19 May | `SliverList` + `_StatsCard` en tab Historial | Stats en tiempo real arriba del log para una vista rápida del tutor | Fase 5 |
| 19 May | `SvgPicture.asset()` para imágenes `.svg` en panel tutor | `Image.asset()` no renderiza SVG — se necesita `flutter_svg` explícitamente | Fase 5 |
| 19 May | Soft-delete en tareas (`deletedByUser: true`) | El usuario elimina tareas visualmente, pero el tutor conserva el registro en Firestore | Fase 5 |
| 19 May | `PictogramManagerScreen` en cuadrícula 3 columnas | Vista de lista era difícil de escanear — cuadrícula da mejor visión general para el tutor | Fase 6 |
| 19 May | Tab "Ajustes" en panel tutor + `featurePictogramas`/`featureFoco` | Flags almacenados en `pictogramSettings/_features` (tutor ya tiene write-access sin deploy); `CustomNavBar` reactivo con dos streams | Fase 6 |
| 19 May | Documentación profesional de código (comentarios de arquitectura) | 8 archivos comentados: servicios core, navegación, reglas Firestore, pantallas principales | Fase 7 |
| 19 May | Tarjeta unificada perfil+rol en `SettingsScreen` | Combina foto, nombre (editable), email y rol (editable) en una sola tarjeta — elimina la duplicidad visual y mejora la UX con íconos de lápiz | Fase 6 |
| 19 May | `Navigator.pushAndRemoveUntil(AuthGate)` al confirmar cambio de rol | `RoleSelectionScreen` estaba sobre `AuthGate` en el stack; el stream de rol se disparaba pero el usuario nunca salía de la pantalla — limpiar el stack fuerza la re-evaluación correcta | Fase 5 |
| 19 May | Unificación de roles: `usuario_tea`/`usuario_tdah`/`usuario_general` → `usuario` | Un solo rol simplifica onboarding y evita fragmentación; el usuario controla sus pestañas desde Ajustes; migración automática on-the-fly en `getUserRole()` y `getUserRoleStream()` | Fase 6 |
| 19 May | `NavScreen` enum reemplaza `initialIndex: int` en `CustomNavBar` | El índice numérico quedaba desincronizado al cambiar el número de tabs dinámicamente; la identidad semántica se resuelve en `build()` buscando la entrada que coincide | Fase 6 |
| 19 May | Card "Personalización de pantalla" en Ajustes para rol `usuario` | El usuario puede activar/desactivar pestañas Pictogramas y Foco desde su propio perfil; si tiene tutor vinculado, los switches se bloquean y solo el tutor puede modificarlos | Fase 6 |
| 19 May | `ProgresoScreen` unificado con 3 gráficos (`BarChart`, `PieChart`, `LineChart`) | Dashboard único reutilizable: acepta `userId` opcional para modo tutor; datos de `activityLog` evitan leer colecciones separadas; tooltips interactivos en gráficos | Fase 6 |
| 19 May | Toggles `featureInicio` + `featureTareas` en panel tutor | El tutor puede ocultar Inicio y Tareas al usuario TEA; `CustomNavBar` lee 4 flags desde `pictogramSettings/_features`; default `true` para no romper UX existente | Fase 6 |
| 19 May | Padding inferior dinámico en `SettingsScreen` y `ProgresoScreen` | `widget.showNavBar ? 96 : 16` evita que el contenido quede tapado por `BottomNavigationBar`; otras pantallas ya usaban `Expanded` o padding fijo suficiente | Fase 6 |

---

## Reconciliación con Tablero Trello (19 Mayo 2026)

El Trello original tenía 5 sprints. Estado actual vs lo planificado:

| Sprint Trello | Descripción | Estado |
|:---|:---|:---:|
| **Sprint 1**: Cimientos y Limpieza | Refactor código + diseño base UI/UX | ✅ Completo |
| **Sprint 2**: Tablero TEA (Visual) | UI por horarios, banco ARASAAC, TTS | ✅ Completo |
| **Sprint 3**: Módulo TDA (Ejecutivo) | Pantalla Foco + IA Gemini + Sistema Dopamina | ✅ Completo |
| **Sprint 4**: El Centro del Tutor | Panel tutor Firebase + pictogramas custom | ✅ Completo |
| **Sprint 5**: Pulido Final | Documentación código + QA + lanzamiento | 🔄 En Curso (Fase 6-7) |

**Pendiente del Sprint 5 del Trello:**
- 🔲 Comentar el código crítico paso a paso (para estudio y evaluación)
- 🔲 Pruebas de usuario con casos reales TEA/TDAH
- 🔲 Pulir animaciones y microinteracciones

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|:---|:---:|:---:|:---|
| Google Sign-In falla (SHA-1 no registrado) | Alta | Alto | Registrar SHA-1 del keystore en Firebase Console manualmente |
| Kiosk Mode — incompatibilidad Android 14+ | Media | Medio | Usar `DevicePolicyManager` con fallback graceful si no hay permisos |
| Bugs en integración Firebase en gama baja | Media | Alto | Testing temprano en dispositivos reales, no solo emuladores |
| Falta de testers con TEA/TDAH | Media | Medio | Contactar organizaciones desde semana 5 |
| Gemini API key no configurada en producción | Alta | Medio | Fallback local ya implementado — no bloquea el MVP |

---

## Métricas de Avance

### Por Módulo

| Módulo | % del Proyecto | Estado | Líneas de Código (aprox) |
|:---|:---:|:---:|:---:|
| Autenticación y base | 15% | ✅ Completado | ~2,500 |
| Módulo TEA (Pictogramas) | 30% | ✅ Completado | ~6,000 |
| Módulo TDAH (Tareas + Foco) | 20% | ✅ Completado | ~4,500 |
| IA / Súper Experto | 8% | ✅ Completado | ~1,500 |
| Panel Tutor (supervisión) | 12% | ✅ Completado | ~2,200 |
| Infraestructura Firebase | 5% | ✅ Completado | ~800 |
| Pulido, Dashboard, Kiosk | 10% | 🔲 Pendiente | — |

### Total Estimado
- **Líneas de código:** ~17,500+
- **Archivos Dart:** 65+
- **Commits:** 25+
- **Funcionalidades implementadas:** 48+

---

## Documentación Adicional

- [📋 README del Proyecto](README.md)
- [👁️ Visión del Proyecto](VisionDelProyecto.md)
- [📊 Carta Gantt Completa](Carta_Gantt_Organizate_COMPLETO.xlsx)

---

## Notas de Actualización

**Última actualización:** 19 Mayo 2026 — sesión 2 (panel tutor, nav bar reactiva, ajustes rediseñados, fix cambio de rol)  
**Próxima revisión:** 02 Junio 2026 (cierre Sprint A de Fase 6)  
**Próximo milestone:** 16 Junio 2026 (cierre Fase 6 — inicio documentación)
