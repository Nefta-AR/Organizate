# Cronología del Proyecto: Simple

Este documento consolida la **Carta Gantt** y la planificación de **Sprints** para el desarrollo de la aplicación Simple.

**Período:** 27 Abril 2026 - 07 Julio 2026 (10 semanas)  
**Estado Actual:** 85% Completado | Fase 5: Integración y Correcciones (75%)  
**Próximo Hito:** Sincronización Completa (26 Mayo 2026)

---

## Resumen Ejecutivo

### Progreso por Fase

| Fase | Periodo | Estado | Progreso |
|:---|:---|:---:|:---:|
| **Fase 1** | 27-28 Abr | Fundación y Auth | ✅ Completado | 100% |
| **Fase 2** | 28-29 Abr | IA / Súper Experto | ✅ Completado | 100% |
| **Fase 3** | 30 Abr-06 May | Módulo TEA (Pictogramas) | ✅ Completado | 100% |
| **Fase 4** | 05-09 May | Módulo TDAH (Tareas) | ✅ Completado | 100% |
| **Fase 5** | 09-26 May | Integración y Correcciones | 🔄 En Curso | 75% |
| **Fase 6** | 27 May-16 Jun | Pulido y Testing | ⏳ Pendiente | 0% |
| **Fase 7** | 17 Jun-07 Jul | Documentación y Entrega | ⏳ Pendiente | 0% |

### Hitos del Proyecto

| Hito | Fecha | Descripción | Estado |
|:---|:---|:---|:---:|
| **HITO 1** | 13 May 2026 | Vinculación Tutor-Paciente | ✅ Alcanzado |
| **HITO 2** | 26 May 2026 | Sincronización Completa | 🔄 En Progreso |
| **HITO 3** | 30 Jun 2026 | MVP Listo | ⏳ Pendiente |
| **HITO 4** | 07 Jul 2026 | Entrega Final (APK + Doc) | ⏳ Pendiente |

---

## Carta Gantt Detallada

### Cronograma Semanal Completo (27 Abril - 07 Julio 2026)

| Fase | Tarea | S1<br>27-30Abr | S2<br>01-04May | S3<br>05-09May | S4<br>10-13May | S5<br>14-18May | S6<br>19-23May | S7<br>24-30May | S8<br>31May-06Jun | S9<br>07-13Jun | S10<br>14-20Jun | S11<br>21-27Jun | S12<br>28Jun-07Jul |
|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **FASE 1** | Base Organizate 2.0 + UI | ██████ | | | | | | | | | | | |
| | Sistema Login (email + Google) | ██████ | | | | | | | | | | | |
| | Cambio nombre -> Simple + Logo | ██████ | | | | | | | | | | | |
| | Login Web funcional | ██████ | | | | | | | | | | | |
| **FASE 2** | Integración Cloud Functions IA | | ██████ | | | | | | | | | | |
| | Súper Experto funcional (Gemini) | | ██████ | | | | | | | | | | |
| | Función desglosarTarea | | ██████ | | | | | | | | | | |
| **FASE 3** | Pantalla Pictogramas Beta | | | ██████ | | | | | | | | | |
| | Banco pictogramas (SVG) | | | ██████ | | | | | | | | | |
| | Pictogramas con color | | | | ██████ | | | | | | | | |
| | Gestor pictogramas personalizados | | | | ██████ | | | | | | | | |
| **FASE 4** | Gestión tareas (CRUD) | | | ██████ | | | | | | | | | |
| | Swipe eliminar tareas | | | ██████ | | | | | | | | | |
| | Migración completa a Simple | | | ██████ | | | | | | | | | |
| | Timer Pomodoro + respiración | | | | ██████ | | | | | | | | |
| | Sistema puntos y racha | | | | ██████ | | | | | | | | |
| **FASE 5** | Corrección SHA + Firebase | | | | ██████ | | | | | | | | |
| | Eliminación Modo Foco | | | | ██████ | | | | | | | | |
| | Fix superposición botones TEA | | | | ██████ | | | | | | | | |
| | Tutor conectado a paciente | | | | | ██████ | | | | | | | |
| | Supervisión tutor -> detalle | | | | | ██████ | | | | | | | |
| | Sincronización bidireccional | | | | | | ██████ | | | | | | |
| | Corrección bugs integración | | | | | | ██████ | | | | | | |
| **FASE 6** | Kiosk Mode paciente TEA | | | | | | | ██████ | | | | | |
| | Dashboard progreso (fl_chart) | | | | | | | ██████ | | | | | |
| | Notificaciones push FCM | | | | | | | | ██████ | | | | |
| | Testing y bugs menores | | | | | | | | ██████ | | | | |
| **FASE 7** | Optimización rendimiento | | | | | | | | | ██████ | | | |
| | Documentación técnica | | | | | | | | | ██████ | | | |
| | Pruebas finales | | | | | | | | | | ██████ | | |
| | Manual de usuario | | | | | | | | | | ██████ | | |
| | Presentación final | | | | | | | | | | | | ██████ |

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
- ✅ Refactor del código base heredado de *Organízate*
- ✅ Configuración de arquitectura Flutter con features por módulos
- ✅ Setup de Firebase (Auth, Firestore, Storage)
- ✅ Implementación de login con Email/Password
- ✅ Implementación de Google Sign-In
- ✅ Configuración de reglas de seguridad iniciales
- ✅ Diseño base con paleta Soft UI (colores calmos, bordes redondeados)
- ✅ `RoleDispatcher` para enrutamiento automático según rol del usuario

**Hitos Alcanzados:**
- Proyecto Flutter limpio con arquitectura escalable
- Firebase conectado y funcional
- Flujo de autenticación completo

---

### ✅ Fase 2: IA / Súper Experto (28-29 Abril 2026)

**Objetivo:** Integrar inteligencia artificial para asistencia en tareas.

**Commits Principales:**
- `2d886cc` (29 Abr): Súper Experto IA funcional (Gemini + Cloud Functions)
- `c417861` (29 Abr): Función desglosarTarea (Gemini)

**Tareas Completadas:**
- ✅ Configuración de Google Cloud Functions
- ✅ Integración con Gemini API
- ✅ Desarrollo del "Súper Experto" - asistente IA
- ✅ Función `desglosarTarea()` para dividir tareas complejas en pasos simples
- ✅ Implementación de interfaz de chat con IA

**Hitos Alcanzados:**
- IA funcionando en tiempo real
- Desglose automático de tareas para TDAH

---

### ✅ Fase 3: Módulo TEA - Pictogramas (30 Abril - 06 Mayo 2026)

**Objetivo:** Desarrollar el sistema de comunicación aumentativa para pacientes TEA.

**Commits Principales:**
- `0633e86` (30 Abr): Pantalla Pictogramas Beta (módulo TEA)
- `335f814` (06 May): Pantalla Pictogramas completa
- `d361ef0` (06 May): Pictogramas con color

**Tareas Completadas:**
- ✅ Tablero de pictogramas dinámico
- ✅ Organización por franjas horarias: Mañana, Tarde, Noche
- ✅ Categorías: Comida, Emociones, Acciones
- ✅ Banco de pictogramas predefinidos (SVG)
- ✅ Síntesis de voz inmediata (TTS) al pulsar pictogramas
- ✅ Creación de pictogramas personalizados con cámara/galería
- ✅ Recorte cuadrado integrado (1:1)
- ✅ Subida directa a Firebase Storage
- ✅ Gestión de visibilidad por pictograma
- ✅ Reasignación de categoría y horario
- ✅ `pictogramSettings` como subcolección separada en Firestore

**Hitos Alcanzados:**
- Comunicación aumentativa funcional completa
- Personalización total de pictogramas

---

### ✅ Fase 4: Módulo TDAH - Tareas y Foco (05-09 Mayo 2026)

**Objetivo:** Desarrollar herramientas de organización y enfoque para TDAH.

**Commits Principales:**
- `12bd20d` (05 May): Migración completa de Organizate -> Simple
- `e723ddd` (05 May): Eliminación de tareas completadas al deslizar
- `89ec05e` (09 May): Timer Pomodoro + respiración

**Tareas Completadas:**
- ✅ Sistema CRUD de tareas
- ✅ Categorización de tareas
- ✅ Swipe para eliminar tareas completadas
- ✅ Temporizador Pomodoro configurable
- ✅ Ciclos de trabajo/descanso personalizables
- ✅ Rutinas de respiración guiada
- ✅ Sistema de puntos y racha (gamificación)
- ✅ Animaciones de refuerzo positivo
- ✅ Migración completa de datos de Organizate a Simple

**Hitos Alcanzados:**
- Herramientas de productividad completas
- Sistema de gamificación implementado

---

## Fase en Curso

### 🔄 Fase 5: Integración y Correcciones (09-26 Mayo 2026)

**Estado:** 75% Completado | **Proyección:** 26 Mayo 2026

**Objetivo:** Conectar todos los módulos y corregir bugs de integración.

**Commits Realizados:**
- `97fd1b1` (09 May): Eliminación Modo Foco -> reemplazado por Pictogramas TEA
- `f953774` (09 May): Solución de superposición de botones en Pictogramas
- `89ec05e` (09 May): Conexiones arregladas, nuevo SHA, nuevo JSON
- `ce5c88a` (13 May): Tutor conectado a paciente (vinculación completada) ⭐ **HITO 1**

#### Tareas Completadas (75%):
- ✅ Corrección SHA-1 para inicio de sesión estable con Google
- ✅ Reestructuración de conexiones Firebase
- ✅ Eliminación del Modo Foco (reemplazado por Pictogramas en perfil TEA)
- ✅ Fix de superposición de botones en el apartado pictogramas
- ✅ Vinculación tutor-paciente mediante código de invitación
- ✅ Sistema de vinculación funcional en tiempo real

#### Tareas Pendientes (25%):
- 🔄 Completar supervisión tutor -> detalle de paciente
  - Ver tareas completadas por el paciente en tiempo real
  - Ver uso de pictogramas con timestamps
  - Ver sesiones Pomodoro completadas
  
- 🔄 Sincronización bidireccional tareas tutor <-> paciente
  - Tareas creadas por tutor aparecen en dispositivo del paciente
  - Estado de completitud se sincroniza en ambos sentidos
  - Actualización en tiempo real sin necesidad de reiniciar app

- 🔄 Corrección de bugs menores de integración

**Dependencias:**
- Requiere completar Fases 1-4
- Bloquea el inicio de Fase 6 (Testing)

---

## Fases Pendientes

### ⏳ Fase 6: Pulido y Testing (27 Mayo - 16 Junio 2026)

**Estado:** 0% | **Proyección:** 16 Junio 2026

**Objetivo:** Optimizar UX y realizar testing exhaustivo.

#### Tareas Planificadas:

**Semana 3 (27 May - 02 Jun):**
- Kiosk Mode para paciente TEA (control parental)
  - Bloqueo de botones físicos (volumen, home)
  - PIN para salir de la app
  - Prevención de cambio de app accidental
  
- Pulir dashboard de progreso (gráficos fl_chart)
  - Gráfico de tareas completadas por día
  - Gráfico de uso de pictogramas
  - Estadísticas de sesiones Pomodoro

**Semana 4 (03-09 Jun):**
- Notificaciones push FCM completas
  - Recordatorios de tareas
  - Alertas de rutinas
  - Notificaciones tutor de actividad del paciente
  
- Testing y correcciones de bugs menores
  - Testing en dispositivos Android de gama baja
  - Testing de accesibilidad
  - Corrección de bugs reportados

**Dependencias:**
- Requiere Fase 5 completada
- Bloquea Fase 7

---

### ⏳ Fase 7: Documentación y Entrega (17 Junio - 07 Julio 2026)

**Estado:** 0% | **Proyección:** 07 Julio 2026 | ⭐ **HITO 3 y 4**

**Objetivo:** Finalizar el proyecto con documentación completa y entrega del MVP.

#### Tareas Planificadas:

**Semana 5-6 (17-27 Jun):**
- Optimización de rendimiento
  - Lazy loading de imágenes
  - Cache de pictogramas frecuentes
  - Optimización de consultas Firestore
  - Reducción de tamaño del APK
  
- Documentación técnica completa
  - Arquitectura del sistema
  - Guía de instalación
  - Documentación de API
  - Comentarios en código crítico

- Pruebas finales
  - Testing con usuarios reales (familias con niños TEA/TDAH)
  - Validación de flujos completos
  - Verificación de sincronización tutor-paciente

**Semana 7 (28 Jun - 07 Jul):**
- Manual de usuario
  - Guía para pacientes TEA
  - Guía para tutores
  - Guía rápida de instalación
  
- Preparación de entrega
  - Generación de APK firmado
  - Empaquetado de documentación
  - Video demo del proyecto
  
- Presentación final
  - Demo funcional del proyecto
  - Documentación de entrega
  - Informe de métricas y aprendizajes

**Entregables Finales:**
- APK funcional de la aplicación
- Manual de usuario completo
- Documentación técnica
- Presentación del proyecto
- Repositorio documentado

**Nota:** La entrega será mediante APK/instalación directa, sin publicación en tiendas.

---

## Próximo Sprint: Prioridades

### Tareas Críticas (Semana 1-2: 13-26 Mayo)

| Prioridad | Tarea | Responsable | Estimación |
|:---|:---|:---:|:---:|
| 🔴 **Alta** | Completar supervisión tutor -> detalle de paciente | Dev | 3 días |
| 🔴 **Alta** | Sincronización bidireccional tareas tutor <-> paciente | Dev | 5 días |
| 🟡 **Media** | Testing de integración | Dev | 2 días |

**Objetivo del Sprint:** Alcanzar HITO 2 (Sincronización Completa) para el 26 de Mayo.

---

## Registro de Decisiones Arquitectónicas Clave

| Fecha | Decisión | Motivo | Fase |
|:---|:---|:---|:---:|
| 27 Abr | Migración `Organizate` → `Simple` | Nombre más claro y representativo del producto | Fase 1 |
| 28 Abr | Enrutamiento basado en roles con `RoleDispatcher` | Evitar que un paciente acceda al entorno de otro perfil | Fase 1 |
| 30 Abr | `pictogramSettings` como subcolección separada | Permite sobrescribir categoría/visibilidad sin modificar el pictograma original | Fase 3 |
| 06 May | `IndexedStack` + `ValueKey(patientId)` en panel tutor | Forzar reconstrucción de tabs al cambiar de paciente activo | Fase 3 |
| 09 May | Eliminación Modo Foco | Reemplazo por Pictogramas en perfil TEA (más funcional) | Fase 5 |
| 13 May | Sistema de vinculación por código | Más seguro y simple que vinculación por email | Fase 5 |

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|:---|:---:|:---:|:---|
| Retraso en sincronización bidireccional | Media | Alto | Priorizar esta tarea, trabajar en iteraciones pequeñas |
| Bugs en integración Firebase | Media | Alto | Testing continuo, logs detallados |
| Compatibilidad con dispositivos diversos | Media | Medio | Testing en múltiples dispositivos Android |
| Falta de testers con TEA/TDAH | Media | Medio | Contactar organizaciones desde semana 5 |

---

## Métricas de Avance

### Por Módulo

| Módulo | % del Proyecto | Estado | Líneas de Código (aprox) |
|:---|:---:|:---:|:---:|
| Autenticación y base | 15% | ✅ Completado | ~2,500 |
| Módulo TEA (Pictogramas) | 35% | ✅ Completado | ~5,500 |
| Módulo TDAH (Tareas) | 25% | ✅ Completado | ~4,000 |
| IA / Súper Experto | 10% | ✅ Completado | ~1,500 |
| Vinculación Tutor | 10% | 🔄 En Curso | ~1,200 |
| Infraestructura Firebase | 5% | ✅ Completado | ~800 |

### Total Estimado
- **Líneas de código:** ~15,500
- **Archivos Dart:** 60+
- **Commits:** 20+
- **Funcionalidades implementadas:** 40+

---

## Documentación Adicional

- [📋 README del Proyecto](README.md)
- [👁️ Visión del Proyecto](VisionDelProyecto.md)
- [📊 Carta Gantt Completa](Carta_Gantt_Organizate_COMPLETO.xlsx)

---

## Notas de Actualización

**Última actualización:** 14 Mayo 2026  
**Próxima revisión:** 20 Mayo 2026 (revisión de avance Fase 5)  
**Próximo milestone:** 26 Mayo 2026 (Sincronización Completa)
