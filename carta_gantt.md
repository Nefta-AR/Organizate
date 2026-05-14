# Carta Gantt - Proyecto: App de Comunicación para Pacientes TEA

## Información General del Proyecto

| Campo | Detalle |
|-------|---------|
| **Nombre del Proyecto** | App de Comunicación para Pacientes TEA |
| **Stack Tecnológico** | Flutter (Frontend), Firebase (Backend + BD), APIs de Terceros |
| **Fecha de Inicio** | 15 de Marzo 2026 |
| **Fecha Límite** | Julio 2026 |
| **Duración Total** | Aproximadamente 16 semanas |

## Alcance del MVP

### Funcionalidades Principales:
- **Paciente TEA:**
  - Interfaz de pictogramas interactivos
  - Pictogramas que "hablan" al ser seleccionados (TTS)
  - Rutina personalizada según horario
  
- **Tutor:**
  - Panel de supervisión
  - Agregar/modificar tareas del paciente
  - Personalizar pictogramas (agregar, editar, eliminar)
  - Configurar rutinas personalizadas

---

## Paso 1: Identificación de Tareas

### 1. Análisis y Planificación
| ID | Tarea | Descripción | Duración | Dependencias |
|----|-------|-------------|----------|--------------|
| A1 | Análisis de requisitos | Definir funcionalidades MVP, casos de uso, perfiles de usuario | 1 semana | - |
| A2 | Investigación de APIs TTS | Evaluar servicios de texto-a-voz (Google TTS, Azure Speech, etc.) | 1 semana | A1 |
| A3 | Arquitectura técnica | Definir estructura de Firebase (Firestore, Auth, Storage) | 1 semana | A1, A2 |
| A4 | Diseño de modelo de datos | Crear esquema de base de datos Firebase | 1 semana | A3 |

**Subtotal Análisis:** 2 semanas (paralelizable en parte)

### 2. Diseño UX/UI
| ID | Tarea | Descripción | Duración | Dependencias |
|----|-------|-------------|----------|--------------|
| D1 | Wireframes y flujos de usuario | Diseñar navegación paciente y tutor | 1 semana | A1 |
| D2 | Diseño UI/UX Paciente | Interfaz accesible, colores contrastantes, pictogramas grandes | 1 semana | D1 |
| D3 | Diseño UI/UX Tutor | Panel de administración, formularios de gestión | 1 semana | D1 |
| D4 | Diseño de pictogramas base | Crear/buscar biblioteca inicial de pictogramas | 1 semana | D2 |
| D5 | Prototipo interactivo | Prototipo en Figma/Adobe XD para validación | 1 semana | D2, D3 |

**Subtotal Diseño:** 3 semanas

### 3. Configuración de Infraestructura
| ID | Tarea | Descripción | Duración | Dependencias |
|----|-------|-------------|----------|--------------|
| I1 | Setup proyecto Flutter | Configurar proyecto base, arquitectura clean | 1 semana | A3 |
| I2 | Configuración Firebase | Crear proyecto, habilitar Auth, Firestore, Storage | 1 semana | A4 |
| I3 | Implementación Autenticación | Login/registro paciente y tutor | 1 semana | I2 |
| I4 | Configuración APIs TTS | Integrar servicio de voz seleccionado | 1 semana | A2, I1 |

**Subtotal Infraestructura:** 2 semanas

### 4. Desarrollo - Módulo Paciente
| ID | Tarea | Descripción | Duración | Dependencias |
|----|-------|-------------|----------|--------------|
| P1 | Vista de pictogramas principales | Grid de pictogramas con imágenes y sonidos | 2 semanas | I1, I4, D2 |
| P2 | Sistema de rutinas | Mostrar pictogramas según horario del día | 2 semanas | P1 |
| P3 | Reproducción de voz | Implementar TTS al tocar pictogramas | 1 semana | I4, P1 |
| P4 | Personalización visual del paciente | Cambiar temas, tamaños de fuente | 1 semana | P1 |

**Subtotal Módulo Paciente:** 4 semanas (algunas en paralelo)

### 5. Desarrollo - Módulo Tutor
| ID | Tarea | Descripción | Duración | Dependencias |
|----|-------|-------------|----------|--------------|
| T1 | Panel de supervisión | Dashboard con resumen de actividad del paciente | 1 semana | I3 |
| T2 | CRUD de tareas | Crear, editar, eliminar tareas del paciente | 2 semanas | I3, A4 |
| T3 | Gestión de pictogramas | Agregar, modificar, eliminar pictogramas | 2 semanas | I3, D4 |
| T4 | Configuración de rutinas | Asignar pictogramas a horarios específicos | 2 semanas | T3 |
| T5 | Vinculación paciente-tutor | Sistema de códigos o invitaciones | 1 semana | I3 |

**Subtotal Módulo Tutor:** 4 semanas

### 6. Integración y Sincronización
| ID | Tarea | Descripción | Duración | Dependencias |
|----|-------|-------------|----------|--------------|
| S1 | Sincronización en tiempo real | Actualizar datos paciente en Firebase | 1 semana | P2, T4 |
| S2 | Manejo de imágenes | Subir/descargar pictogramas a Firebase Storage | 1 semana | T3 |
| S3 | Notificaciones push | Alertas de tareas y rutinas | 1 semana | S1 |
| S4 | Modo offline básico | Cache de pictogramas recientes | 1 semana | S1 |

**Subtotal Integración:** 2 semanas

### 7. Pruebas y Calidad
| ID | Tarea | Descripción | Duración | Dependencias |
|----|-------|-------------|----------|--------------|
| Q1 | Pruebas unitarias | Tests de widgets y lógica de negocio | 1 semana | P4, T5 |
| Q2 | Pruebas de integración | Flujos completos paciente-tutor | 1 semana | S4 |
| Q3 | Pruebas con usuarios reales | Test con pacientes TEA y tutores | 2 semanas | Q2 |
| Q4 | Corrección de bugs | Solución de errores encontrados | 1 semana | Q3 |
| Q5 | Optimización de rendimiento | Mejorar velocidad y consumo de recursos | 1 semana | Q4 |

**Subtotal Pruebas:** 3 semanas

### 8. Documentación y Entrega
| ID | Tarea | Descripción | Duración | Dependencias |
|----|-------|-------------|----------|--------------|
| X1 | Documentación técnica | Arquitectura, APIs, instalación | 1 semana | Q5 |
| X2 | Manual de usuario | Guía para pacientes y tutores | 1 semana | Q3 |
| X3 | Preparación de tiendas | Descripción, screenshots, assets | 1 semana | Q5 |
| X4 | Despliegue | Publicación en Play Store y App Store | 1 semana | X3 |
| X5 | Presentación final | Demo y documentación del proyecto | 1 semana | X4 |

**Subtotal Entrega:** 2 semanas

---

## Paso 2: Organización Temporal y Dependencias

### Resumen de Fases

| Fase | Duración | Semanas |
|------|----------|---------|
| Análisis y Planificación | 2 semanas | Semana 1-2 |
| Diseño UX/UI | 3 semanas | Semana 2-4 |
| Configuración Infraestructura | 2 semanas | Semana 3-4 |
| Desarrollo Módulo Paciente | 4 semanas | Semana 4-7 |
| Desarrollo Módulo Tutor | 4 semanas | Semana 5-8 |
| Integración y Sincronización | 2 semanas | Semana 8-9 |
| Pruebas y Calidad | 3 semanas | Semana 10-12 |
| Documentación y Entrega | 2 semanas | Semana 13-14 |

**TOTAL ESTIMADO:** 14-15 semanas

### Dependencias Clave

```
A1 (Análisis) → A2, A3, A4 → D1 (Diseño)
                              ↓
                    I1, I2 (Configuración Firebase)
                              ↓
              ┌───────────────┴───────────────┐
              ↓                               ↓
    P1 (Módulo Paciente)            T1 (Módulo Tutor)
              ↓                               ↓
    P2, P3, P4 (Paciente)           T2, T3, T4, T5 (Tutor)
              └───────────────┬───────────────┘
                              ↓
                    S1-S4 (Integración)
                              ↓
                    Q1-Q5 (Pruebas)
                              ↓
                    X1-X5 (Entrega)
```

---

## Paso 3: Construcción de la Carta Gantt

### Cronograma Detallado por Semana

| ID | Tarea | Sem 1 | Sem 2 | Sem 3 | Sem 4 | Sem 5 | Sem 6 | Sem 7 | Sem 8 | Sem 9 | Sem 10 | Sem 11 | Sem 12 | Sem 13 | Sem 14 | Sem 15 | Sem 16 |
|----|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|--------|--------|--------|--------|--------|--------|--------|
| **ANÁLISIS** |
| A1 | Análisis de requisitos | ████ | | | | | | | | | | | | | | | |
| A2 | Investigación APIs TTS | | ████ | | | | | | | | | | | | | | |
| A3 | Arquitectura técnica | | ████ | | | | | | | | | | | | | | |
| A4 | Modelo de datos | | | ████ | | | | | | | | | | | | | |
| **DISEÑO** |
| D1 | Wireframes y flujos | | ████ | | | | | | | | | | | | | | |
| D2 | UI/UX Paciente | | | ████ | ████ | | | | | | | | | | | | |
| D3 | UI/UX Tutor | | | ████ | ████ | | | | | | | | | | | | |
| D4 | Biblioteca pictogramas | | | | ████ | | | | | | | | | | | | |
| D5 | Prototipo interactivo | | | | | ████ | | | | | | | | | | | |
| **INFRAESTRUCTURA** |
| I1 | Setup Flutter | | | ████ | | | | | | | | | | | | | |
| I2 | Config Firebase | | | ████ | | | | | | | | | | | | | |
| I3 | Autenticación | | | | ████ | | | | | | | | | | | | |
| I4 | Config APIs TTS | | | | ████ | | | | | | | | | | | | |
| **MÓDULO PACIENTE** |
| P1 | Vista pictogramas | | | | ████ | ████ | | | | | | | | | | | |
| P2 | Sistema rutinas | | | | | | ████ | ████ | | | | | | | | | |
| P3 | Reproducción voz | | | | | ████ | | | | | | | | | | | |
| P4 | Personalización | | | | | | | ████ | | | | | | | | | |
| **MÓDULO TUTOR** |
| T1 | Panel supervisión | | | | | ████ | | | | | | | | | | | |
| T2 | CRUD tareas | | | | | | ████ | ████ | | | | | | | | | |
| T3 | Gestión pictogramas | | | | | | | ████ | ████ | | | | | | | | |
| T4 | Config rutinas | | | | | | | | ████ | ████ | | | | | | | |
| T5 | Vinculación | | | | | ████ | | | | | | | | | | | |
| **INTEGRACIÓN** |
| S1 | Sincronización RT | | | | | | | | | ████ | | | | | | | |
| S2 | Manejo imágenes | | | | | | | | ████ | | | | | | | | |
| S3 | Notificaciones | | | | | | | | | | ████ | | | | | | |
| S4 | Modo offline | | | | | | | | | | ████ | | | | | | |
| **PRUEBAS** |
| Q1 | Tests unitarios | | | | | | | | | | ████ | | | | | | |
| Q2 | Tests integración | | | | | | | | | | | ████ | | | | | |
| Q3 | Pruebas usuarios | | | | | | | | | | | | ████ | ████ | | | |
| Q4 | Corrección bugs | | | | | | | | | | | | | | ████ | | | |
| Q5 | Optimización | | | | | | | | | | | | | | ████ | | | |
| **ENTREGA** |
| X1 | Documentación técnica | | | | | | | | | | | | | | | ████ | | |
| X2 | Manual usuario | | | | | | | | | | | | | ████ | | | | |
| X3 | Preparación tiendas | | | | | | | | | | | | | | | ████ | | |
| X4 | Despliegue | | | | | | | | | | | | | | | | ████ | |
| X5 | Presentación final | | | | | | | | | | | | | | | | | ████ |

**Leyenda:** ████ = Tarea activa durante esa semana

---

## Paso 4: Definición de Hitos

### Hito 1: Avance 1 - Diseño y Estructura Base

| Campo | Detalle |
|-------|---------|
| **Nombre** | Avance 1: Diseño y Arquitectura Base |
| **Fecha Estimada** | Semana 4 (12 de Abril aprox.) |
| **Entregables** | |
| | ✅ Documento de requisitos aprobado |
| | ✅ Prototipos de UI/UX en Figma |
| | ✅ Proyecto Flutter configurado |
| | ✅ Firebase configurado con Auth básico |
| | ✅ Biblioteca inicial de pictogramas |
| **Criterios de Aceptación** | Prototipo navegable aprobado por stakeholders |

### Hito 2: Sistema Funcional Básico - Core Operativo

| Campo | Detalle |
|-------|---------|
| **Nombre** | Prototipo Funcional: Core Operativo |
| **Fecha Estimada** | Semana 9 (17 de Mayo aprox.) |
| **Entregables** | |
| | ✅ Módulo paciente: pictogramas con voz funcionando |
| | ✅ Módulo tutor: gestión de tareas y pictogramas |
| | ✅ Sistema de rutinas básico operativo |
| | ✅ Sincronización paciente-tutor en tiempo real |
| | ✅ Flujo completo de autenticación |
| **Criterios de Aceptación** | Tutor puede crear rutina → Paciente la visualiza y usa |

### Hito 3: Entrega Final - MVP Completado

| Campo | Detalle |
|-------|---------|
| **Nombre** | Entrega Final: MVP en Producción |
| **Fecha Estimada** | Semana 14 (21 de Junio aprox.) o Semana 15 |
| **Entregables** | |
| | ✅ Aplicación publicada en Play Store y App Store |
| | ✅ Documentación técnica completa |
| | ✅ Manual de usuario (paciente y tutor) |
| | ✅ Pruebas con usuarios reales completadas |
| | ✅ Bugs críticos corregidos |
| | ✅ Presentación final del proyecto |
| **Criterios de Aceptación** | App funcional, estable y disponible para descargar |

---

## Diagrama de Línea de Tiempo Visual

```
MARZO        ABRIL         MAYO          JUNIO         JULIO
|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
   15  
        [====ANÁLISIS====]
         [======DISEÑO======]
             [==INFRA==]
                  [====MÓDULO PACIENTE====]
                   [====MÓDULO TUTOR====]
                              [==INTEG==]
                                  [====PRUEBAS====]
                                          [==ENTREGA==]
                                           
        ▲                 ▲                      ▲
   HITO 1            HITO 2                 HITO 3
 Diseño y          Core                  MVP Final
 Arquitectura      Operativo
```

---

## Consideraciones Importantes

### Riesgos Identificados
1. **Aprobación de tiendas:** El proceso de revisión de Play Store/App Store puede tomar 1-2 semanas adicionales
2. **Pruebas con usuarios reales:** Dificultad para conseguir participantes con TEA
3. **Rendimiento de TTS:** APIs de terceros pueden tener latencia o costos
4. **Permisos y regulaciones:** Aplicación de salud puede requerir consideraciones adicionales

### Mitigación
- Iniciar proceso de tiendas en semana 13 (antes de terminar)
- Contactar organizaciones de TEA desde semana 1
- Implementar cacheo de audio generado
- Consultar lineamientos de apps médicas

### Recomendaciones de Seguimiento

**Reuniones Semanales:**
- Revisión de avance vs. cronograma
- Identificación de bloqueos
- Ajuste de prioridades

**Métricas de Seguimiento:**
- % de tareas completadas por semana
- Número de bugs encontrados vs. corregidos
- Tiempo de respuesta de Firebase

---

## Instrucciones para Importar a Excel

Para crear tu Carta Gantt en Excel:

1. **Crear columnas:**
   - A: ID Tarea
   - B: Nombre Tarea
   - C: Fecha Inicio
   - D: Duración (días)
   - E en adelante: Semanas (1-16)

2. **Usar formato condicional:**
   - Seleccionar celdas de semanas
   - Formato condicional > Nueva regla > Usar fórmula
   - Fórmula: `=AND(E$1>=$C2,E$1<=$C2+$D2-1)`
   - Formato: Relleno de color

3. **Agregar hitos:**
   - Insertar filas especiales para hitos
   - Usar formato diferente (negrita, borde)

---

## Notas Finales

- **Buffer recomendado:** 1-2 semanas antes de julio para imprevistos
- **Equipo sugerido:** Mínimo 2 desarrolladores (1 frontend Flutter, 1 backend Firebase)
- **Recursos necesarios:**
  - Cuenta de desarrollador Google Play ($25 una vez)
  - Cuenta de desarrollador Apple ($99/año)
  - Presupuesto para APIs TTS si es necesario
  - Dispositivos de prueba (Android e iOS)

---

*Documento generado el 13 de Mayo de 2026*
*Proyecto: App de Comunicación para Pacientes TEA*
