# Carta Gantt — Proyecto Simple (Prótesis Cognitiva)

> **Período registrado:** 27 abril 2026 – 13 mayo 2026  
> **Repositorio:** Nefta-AR/Organizate  
> **Plataforma:** Flutter + Firebase  

---

## Resumen de Fases

| # | Fase | Inicio | Fin | Estado |
|---|------|--------|-----|--------|
| 1 | Fundación y Autenticación | 27 abr | 28 abr | ✅ Completado |
| 2 | Integración IA (Súper Experto) | 28 abr | 29 abr | ✅ Completado |
| 3 | Módulo TEA — Pictogramas | 30 abr | 06 may | ✅ Completado |
| 4 | Módulo TDAH — Tareas y Foco | 05 may | 09 may | ✅ Completado |
| 5 | Integración y Correcciones | 09 may | 13 may | 🔄 En curso |

---

## Carta Gantt Detallada

```
FASE / TAREA                           ABR-27  ABR-28  ABR-29  ABR-30  MAY-01  MAY-05  MAY-06  MAY-09  MAY-13
─────────────────────────────────────────────────────────────────────────────────────────────────────────────

FASE 1 — FUNDACIÓN Y AUTH
  Base Organízate 2.0 / Rediseño UI    [██]
  Sistema Login (email + Google)       [██─────]
  Cambio nombre → Simple + Logo                [██]
  Login Web funcional                          [█──]

FASE 2 — IA / SÚPER EXPERTO
  Integración Cloud Functions IA               [██]
  Súper Experto funcional                      [██]
  Función desglosarTarea (Gemini)              [█──]

FASE 3 — MÓDULO TEA
  Pantalla Pictogramas Beta                            [██]
  Banco pictogramas predefinidos (SVG)                 [█──────────]
  Pictogramas con color                                        [████]
  Merge rama Pictogramas                                       [█]
  Gestor de pictogramas personalizados                         [████]

FASE 4 — MÓDULO TDAH
  Gestión de tareas (CRUD + categorías)                       [█───]
  Swipe para eliminar tareas completadas                       [██]
  Migración completa a "Simple"                                [██]
  Timer Pomodoro + ejercicios respiración                     [████]
  Sistema de puntos y racha                                   [████]

FASE 5 — INTEGRACIÓN Y CORRECCIONES
  Corrección SHA + conexiones Firebase                                [████]
  Eliminación Modo Foco → Pictogramas TEA                            [████]
  Fix superposición botones (TEA)                                    [██]
  Tutor conectado a paciente (vinculación)                                  [██]

─────────────────────────────────────────────────────────────────────────────────────────────────────────────
LEYENDA:  [██] Inicio/fin mismo día   [█──] Trabajo en progreso   [████] Trabajo intensivo varios días
```

---

## Hitos (Milestones)

| Fecha | Commit | Descripción |
|-------|--------|-------------|
| 27 abr 2026 | `8e73da2` | Base Organízate 2.0 + rediseño UI Login |
| 28 abr 2026 | `e48e5d0` | Cambio de nombre a **Simple**, nuevo logo, login web |
| 29 abr 2026 | `2d886cc` | **Súper Experto IA funcional** (Gemini + Cloud Functions) |
| 29 abr 2026 | `231eb96` | Login Web completamente funcional |
| 30 abr 2026 | `0633e86` | **Pantalla Pictogramas Beta** (módulo TEA) |
| 05 may 2026 | `e723ddd` | Eliminación de tareas completadas al deslizar |
| 05 may 2026 | `12bd20d` | Migración completa de Organízate → Simple |
| 06 may 2026 | `335f814` | **Pantalla Pictogramas completa** |
| 06 may 2026 | `d361ef0` | Pictogramas con color |
| 09 may 2026 | `97fd1b1` | Eliminación Modo Foco → reemplazado por Pictogramas TEA |
| 09 may 2026 | `f953774` | Fix superposición de botones en Pictogramas |
| 09 may 2026 | `542ceae` | Estabilización general |
| 13 may 2026 | `ce5c88a` | **Tutor conectado a paciente** (vinculación completada) |

---

## Distribución de trabajo por módulo

```
Autenticación y base     ████████░░░░░░░░░░░░   ~15%
Módulo TEA (Pictogramas) ██████████████░░░░░░   ~35%
Módulo TDAH (Tareas)     ████████████░░░░░░░░   ~25%
IA / Súper Experto       ████░░░░░░░░░░░░░░░░   ~10%
Vinculación Tutor        ████░░░░░░░░░░░░░░░░   ~10%
Infraestructura Firebase ██░░░░░░░░░░░░░░░░░░   ~5%
```

---

## Pendientes identificados (próximo sprint)

- [ ] Completar supervisión tutor → detalle de paciente
- [ ] Sincronización bidireccional tareas tutor ↔ paciente
- [ ] Kiosk Mode para paciente TEA (control parental)
- [ ] Pulir dashboard de progreso (gráficos fl_chart)
- [ ] Notificaciones push FCM completas
- [ ] Testing y correcciones de bugs menores
- [ ] Preparación para distribución (Play Store / App Store)
