# Simple

> Anteriormente conocido como **Organízate**

Simple es una aplicación móvil inclusiva diseñada específicamente para apoyar a personas neurodivergentes, con módulos dedicados para el **Trastorno del Espectro Autista (TEA)** y el **Trastorno por Déficit de Atención e Hiperactividad (TDAH)**.

**Estado del Proyecto:** 🟠 En Desarrollo (85% Completado) | **Fecha Estimada:** Julio 2026

---

## Características Principales

### Gestión de Roles
Entornos completamente aislados y seguros para tres perfiles distintos:
- **Paciente TEA** — acceso exclusivo al tablero de comunicación por pictogramas.
- **Paciente TDAH** — acceso exclusivo a las herramientas de foco y organización.
- **Tutor** — panel de supervisión con acceso controlado a los perfiles de sus pacientes vinculados.

El enrutamiento basado en roles (`RoleDispatcher`) garantiza que cada usuario llegue únicamente a su entorno, sin posibilidad de acceder a funcionalidades ajenas.

### Módulo TEA — Comunicación Aumentativa y Alternativa (CAA)
- Tablero de pictogramas dinámico organizado por franjas horarias: **Mañana**, **Tarde** y **Noche**.
- Pestañas de categorías: **Comida**, **Emociones** y **Acciones**.
- **Síntesis de voz inmediata** (Text-to-Speech) al pulsar cualquier pictograma.
- Creación de pictogramas personalizados mediante **cámara o galería**, con recorte cuadrado integrado y subida directa a **Firebase Storage**.
- Gestión de visibilidad y categoría por pictograma: cada usuario puede ocultar pictogramas o reasignarlos a otro horario o categoría sin eliminarlos.
- Historial de acciones del paciente registrado en tiempo real.

### Módulo TDAH — Foco y Organización
- **Temporizador Pomodoro** con ciclos de trabajo y descanso configurables.
- **Lista de tareas** con creación, completado y eliminación, registrando cada acción en el historial de actividad.
- Rutinas de **respiración guiada** para gestión de la ansiedad.
- **Asistente IA** impulsado por Gemini para el desglose automático de tareas complejas en pasos simples.

### Panel del Tutor
- Vinculación con pacientes mediante **código de invitación** generado desde la app.
- **Cambio de paciente activo** con un selector de fondo cuando el tutor tiene más de un paciente vinculado.
- Supervisión de **tareas**: consulta y creación de tareas para el paciente desde el panel del tutor.
- Gestión de **pictogramas**: agregar pictogramas personalizados al paciente y organizar su visibilidad y categoría por horario desde la misma interfaz del gestor.
- **Historial de actividad**: línea de tiempo con las acciones completadas por el paciente (tareas, pictogramas, sesiones).
- Subida de imágenes a **Firebase Storage** y gestión de respaldos seguros a través de **Google Drive** (soberanía de datos).

---

## Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | Flutter — Diseño Soft UI (colores calmos, bordes redondeados) |
| Autenticación | Firebase Authentication (Email/Password + Google Sign-In) |
| Base de datos | Cloud Firestore (reglas de seguridad por rol) |
| Almacenamiento | Firebase Storage (imágenes de perfil y pictogramas) |
| IA generativa | Gemini API (asistente de desglose de tareas TDAH) |
| Notificaciones | Firebase Cloud Messaging |
| Respaldo | Google Drive API |
| Funciones cloud | Google Cloud Functions |

---

## Arquitectura de Seguridad

Las reglas de Firestore implementan control de acceso granular:
- Un **paciente** solo puede leer y escribir su propia subcolección de datos.
- Un **tutor** puede leer y gestionar datos de sus pacientes vinculados (verificado con la subcolección `linkedTutors` y estado `active`).
- Los **pictogramas personalizados** y sus configuraciones (`pictogramSettings`) son accesibles para el propietario y su tutor vinculado.
- El **historial de actividad** (`activityLog`) es de solo creación para el paciente y de solo lectura para el tutor.

---

## Estado del Proyecto

### Progreso General: 85%

El proyecto ha alcanzado hitos significativos desde su inicio el **27 de Abril 2026**:

#### ✅ Completado (Fases 1-4)

**Fase 1: Fundación y Autenticación**
- [x] Base Organizate 2.0 + rediseño UI Login (27 Abr)
- [x] Sistema Login (email + Google) funcional
- [x] Cambio de nombre a Simple + nuevo logo
- [x] Login Web funcional

**Fase 2: IA / Súper Experto**
- [x] Integración Cloud Functions IA
- [x] Súper Experto funcional (Gemini + Cloud Functions)
- [x] Función desglosarTarea (29 Abr)

**Fase 3: Módulo TEA (Pictogramas)**
- [x] Pantalla Pictogramas Beta (30 Abr)
- [x] Banco de pictogramas predefinidos (SVG)
- [x] Pictogramas con color (06 May)
- [x] Merge rama Pictogramas
- [x] Gestor de pictogramas personalizados

**Fase 4: Módulo TDAH (Tareas)**
- [x] Gestión de tareas (CRUD + categorías) (05 May)
- [x] Swipe para eliminar tareas
- [x] Migración completa a Simple
- [x] Timer Pomodoro + respiración
- [x] Sistema de puntos y racha

#### 🔄 En Curso (Fase 5 - 75% Completado)

**Fase 5: Integración y Correcciones**
- [x] Corrección SHA + conexiones Firebase (09 May)
- [x] Eliminación Modo Foco -> reemplazado por Pictogramas TEA (09 May)
- [x] Fix superposición botones (TEA) (09 May)
- [x] Tutor conectado a paciente - vinculación completada (13 May) ⭐ **HITO 1**
- [ ] Completar supervisión tutor -> detalle de paciente
- [ ] Sincronización bidireccional tareas tutor <-> paciente

#### ⏳ Pendiente

**Fase 6: Pulido y Testing**
- [ ] Kiosk Mode para paciente TEA (control parental)
- [ ] Pulir dashboard de progreso (gráficos fl_chart)
- [ ] Notificaciones push FCM completas
- [ ] Testing y correcciones de bugs menores

**Fase 7: Documentación y Entrega**
- [ ] Optimización de rendimiento
- [ ] Documentación técnica completa
- [ ] Pruebas finales
- [ ] Manual de usuario
- [ ] Presentación final

---

## Hitos del Proyecto

| Hito | Fecha | Descripción | Estado |
|:---|:---|:---|:---:|
| **HITO 1** | 13 May 2026 | Vinculación Tutor-Paciente completada | ✅ Alcanzado |
| **HITO 2** | 26 May 2026 | Sincronización completa tutor-paciente | 🔄 En Progreso |
| **HITO 3** | 30 Jun 2026 | MVP listo para entrega | ⏳ Pendiente |
| **HITO 4** | 07 Jul 2026 | Entrega final (APK + Documentación) | ⏳ Pendiente |

---

## Distribución de Trabajo

| Módulo | Porcentaje | Estado |
|:---|:---:|:---|
| Autenticación y base | 15% | ✅ Completado |
| Módulo TEA (Pictogramas) | 35% | ✅ Completado |
| Módulo TDAH (Tareas) | 25% | ✅ Completado |
| IA / Súper Experto | 10% | ✅ Completado |
| Vinculación Tutor | 10% | 🔄 En Curso |
| Infraestructura Firebase | 5% | ✅ Completado |

---

## Documentación Adicional

- [📋 Carta Gantt del Proyecto](Carta_Gantt_Organizate_COMPLETO.xlsx)
- [👁️ Visión del Proyecto](VisionDelProyecto.md)
- [📅 Cronología y Sprints](CronologiaDelProyecto.md)

---

## Equipo

**Desarrollador Principal:** Pablo Ignacio Mardones Beltrán

**Repositorio:** [Nefta-AR/Organizate](https://github.com/Nefta-AR/Organizate)

**Tecnologías:** Flutter + Firebase | Periodo: Abril - Julio 2026
