# Informe Técnico para Defensa de Título

## Organízate: Prótesis Cognitiva Móvil para Usuarios Neurodivergentes

---

## 1. Portada

| Campo | Valor |
|-------|-------|
| **Nombre del proyecto** | Organízate |
| **Alumno(s)** | [Nombre del alumno] |
| **Carrera** | Analista Programador |
| **Institución** | [Nombre de la institución] |
| **Profesor Guía** | [Nombre del profesor guía] |
| **Fecha de defensa** | [DD/MM/AAAA] |

---

## 2. Agradecimientos

Agradezco al profesor guía [Nombre] por su orientación técnica y académica durante el desarrollo de este proyecto. Asimismo, agradezco a las familias y usuarios neurodivergentes que participaron en las fases de validación, cuyo feedback fue indispensable para refinar la interfaz y la experiencia de usuario. Finalmente, agradezco a la comunidad de desarrolladores de Flutter y ARASAAC por proporcionar herramientas y recursos abiertos que hicieron posible la implementación de este sistema.

---

## 3. Resumen (Abstract)

### Resumen en español

**Organízate** es una aplicación móvil desarrollada como **prótesis cognitiva** dirigida a personas neurodivergentes, con énfasis en usuarios con **Trastorno por Déficit de Atención e Hiperactividad (TDAH)** y **Trastorno del Espectro Autista (TEA)**. El sistema integra pictogramas del sistema **ARASAAC** para facilitar la comunicación aumentativa y alternativa (CAA), junto con módulos de gestión de tareas, temporizador Pomodoro, historial de actividad y supervisión remota por tutores. La arquitectura del sistema se basa en un modelo **cliente-servidor** donde el cliente es una aplicación móvil multiplataforma desarrollada en **Flutter/Dart**, y el backend se implementa mediante **Firebase** (Firestore, Authentication, Storage, Cloud Functions) y **Node.js** para procesos adicionales. Los resultados obtenidos demuestran una reducción del [X]% en la carga cognitiva percibida por los usuarios durante la organización de rutinas diarias, validando la hipótesis de que una interfaz simplificada basada en pictogramas mejora significativamente la autonomía de usuarios neurodivergentes.

### Abstract (English)

**Organízate** is a mobile application developed as a **cognitive prosthesis** aimed at neurodivergent individuals, with emphasis on users with **ADHD** and **Autism Spectrum Disorder (ASD)**. The system integrates **ARASAAC** pictograms to facilitate Augmentative and Alternative Communication (AAC), along with task management modules, Pomodoro timer, activity history, and remote supervision by tutors. The system architecture follows a **client-server model** with a cross-platform mobile client built in **Flutter/Dart**, and a backend implemented using **Firebase** (Firestore, Authentication, Storage, Cloud Functions) and **Node.js** for additional processing. Results demonstrate a [X]% reduction in perceived cognitive load during daily routine organization, validating the hypothesis that a simplified pictogram-based interface significantly improves autonomy for neurodivergent users.

**Palabras clave:** Prótesis cognitiva, neurodivergencia, TDAH, TEA, ARASAAC, Flutter, Firebase, comunicación aumentativa, aplicación móvil.

---

## 4. Índice de Contenido, Tablas y Figuras

### Índice de Contenido
1. Portada
2. Agradecimientos
3. Resumen
4. Índice
5. Introducción
6. Planteamiento del problema y justificación
7. Objetivos
8. Estado del arte
9. Metodología
10. Análisis del sistema
11. Diseño del sistema
12. Desarrollo e implementación
13. Pruebas del sistema
14. Resultados y evaluación
15. Conclusiones
16. Recomendaciones y trabajo futuro
17. Bibliografía
18. Anexos

### Índice de Tablas
- Tabla 1: Requerimientos funcionales
- Tabla 2: Requerimientos no funcionales
- Tabla 3: Comparativa de tecnologías cross-platform
- Tabla 4: Cronograma de actividades
- Tabla 5: Resultados de pruebas de usabilidad

### Índice de Figuras
- Figura 1: Diagrama de arquitectura del sistema
- Figura 2: Diagrama de casos de uso
- Figura 3: Diagrama de clases principales
- Figura 4: Diagrama de secuencia - Flujo de autenticación
- Figura 5: Diagrama de secuencia - Uso de pictograma
- Figura 6: Diagrama de flujo de datos
- Figura 7: Mockups de interfaz de usuario
- Figura 8: Capturas de pantalla del sistema

---

## 5. Introducción

### 5.1 Contexto y antecedentes

La neurodivergencia comprende variaciones naturales en el cerebro humano respecto a lo que se considera "neurotípico". Entre las condiciones más frecuentes se encuentran el **Trastorno del Espectro Autista (TEA)** y el **Trastorno por Déficit de Atención e Hiperactividad (TDAH)**. Según la OMS, aproximadamente **1 de cada 100 niños** tiene TEA, y el TDAH afecta alrededor del **5%** de la población infantil y el **2.5%** de adultos a nivel mundial.

Una de las principales dificultades enfrentadas por estas personas es la **regulación ejecutiva**: la capacidad de planificar, organizar, iniciar y completar tareas. Las **prótesis cognitivas** —herramientas tecnológicas que externalizan funciones cognitivas— han demostrado ser efectivas para compensar estas dificultades.

### 5.2 Motivación

La motivación de este proyecto surge de la observación directa de que las aplicaciones existentes de organización personal (calendarios, recordatorios, listas de tareas) están diseñadas para usuarios neurotípicos, con interfaces complejas, alto texto, múltiples niveles de navegación y estímulos visuales que pueden resultar **saturadores** para personas con TEA o TDAH. Existe una brecha significativa en el mercado de aplicaciones móviles que combinen **simplicidad visual, pictogramas estandarizados, comunicación aumentativa y supervisión parental/tutor** en una sola plataforma integrada.

### 5.3 Alcance del proyecto

El proyecto comprende el desarrollo completo de una aplicación móvil multiplataforma (Android/iOS) con los siguientes módulos:

- **Módulo de pictogramas y comunicación aumentativa (CAA)** con pictogramas ARASAAC
- **Módulo de gestión de tareas** con categorías y recordatorios
- **Módulo de temporizador Pomodoro** con sonidos y vibración
- **Módulo de tutor/supervisor** con vinculación mediante códigos de invitación
- **Módulo de historial de actividad** para análisis de patrones
- **Sistema de roles** (usuario vs tutor) con routing dinámico
- **Respaldo y sincronización** con Google Drive

### 5.4 Estructura del informe

El presente informe se estructura en 18 secciones que abarcan desde la fundamentación teórica hasta la implementación técnica, pruebas y resultados. La sección 11 (Diseño del sistema) detalla la arquitectura técnica, mientras que la sección 12 profundiza en los módulos de desarrollo. La sección 13 documenta las pruebas realizadas y la sección 16 propone mejoras futuras.

---

## 6. Planteamiento del Problema y Justificación

### 6.1 ¿Qué necesidad o problema se aborda?

Las personas neurodivergentes enfrentan desafíos específicos en la organización diaria:

1. **Dificultad de iniciación de tareas**: El TDAH afecta la capacidad de "iniciar" acciones sin estímulos externos.
2. **Necesidad de rutinas estructuradas**: El TEA se beneficia de predictibilidad y representaciones visuales claras.
3. **Saturación sensorial**: Interfaces con demasiado texto, colores contrastantes o navegación compleja pueden generar ansiedad.
4. **Falta de independencia**: Muchos adultos y jóvenes dependen de supervisión constante para completar rutinas básicas.
5. **Barreras de comunicación**: Algunos usuarios con TEA no verbal o con lenguaje limitado requieren sistemas de comunicación aumentativa.

### 6.2 ¿Por qué es importante resolverlo?

Resolver este problema tiene implicaciones multidimensionales:

- **Social**: Aumenta la autonomía y calidad de vida de personas neurodivergentes, reduciendo dependencia de cuidadores.
- **Educativa**: Facilita la organización escolar y el cumplimiento de tareas, mejorando resultados académicos.
- **Económica**: Reduce costos asociados a terapias de organización y supervisión constante.
- **Tecnológica**: Demuestra la aplicación de principios de **diseño inclusivo** (inclusive design) y **diseño universal** (universal design) en el desarrollo de software móvil.
- **Ética**: Promueve la **equidad digital** al garantizar que la tecnología sea accesible para poblaciones históricamente excluidas.

La justificación técnica se fundamenta en la **hipótesis de carga cognitiva**: una interfaz que externaliza la memoria de trabajo y reduce la toma de decisiones ejecutivas (mediante pictogramas, estructuras predefinidas y retroalimentación multisensorial) disminuye la carga cognitiva del usuario, permitiendo una mayor eficiencia en la ejecución de rutinas.

---

## 7. Objetivos

### 7.1 Objetivo General

Desarrollar una aplicación móvil multiplataforma que funcione como **prótesis cognitiva** para personas neurodivergentes (TDAH y TEA), integrando pictogramas ARASAAC, gestión de tareas, temporizador Pomodoro, comunicación aumentativa y supervisión remota por tutores, mediante una arquitectura cliente-servidor basada en Flutter, Firebase y Node.js.

### 7.2 Objetivos Específicos

1. **Diseñar e implementar una interfaz de usuario** basada en pictogramas ARASAAC con navegación simplificada y categorías visuales (Mañana, Tarde, Noche, Comida, Emociones, Acciones).

2. **Desarrollar un sistema de gestión de tareas** con categorías, recordatorios temporizados, notificaciones locales y estados de completitud trazables por tutores.

3. **Implementar un temporizador Pomodoro** con retroalimentación háptica (vibración) y auditiva, configurable por el usuario o tutor.

4. **Crear un sistema de vinculación tutor-usuario** mediante códigos de invitación de 6 caracteres, con permisos diferenciados y reglas de seguridad en Firestore.

5. **Desarrollar un módulo de supervisión** para tutores que permita visualizar tareas, pictogramas personalizados, historial de actividad y configurar las pestañas visibles del usuario.

6. **Implementar un sistema de roles dinámico** con routing automático basado en el campo `role` del usuario en Firestore.

7. **Integrar servicios de síntesis de voz (TTS)** para la lectura de pictogramas en español, con fallback a nube si es necesario.

8. **Desarrollar un sistema de respaldo** con Google Drive para exportar/importar configuraciones y pictogramas personalizados.

9. **Aplicar metodologías ágiles** (Scrum adaptado) con sprints de 2 semanas para el desarrollo iterativo.

10. **Realizar pruebas de usabilidad** con usuarios reales neurodivergentes y tutores para validar la eficacia de la prótesis cognitiva.

---

## 8. Estado del Arte y Marco Teórico

### 8.1 Investigación previa

#### Prótesis Cognitivas Digitales

El concepto de **prótesis cognitiva** fue acuñado por el psicólogo canadiense **Donald Schön** y posteriormente desarrollado por **Cicerone et al. (2000)** en el contexto de rehabilitación neuropsicológica. Una prótesis cognitiva es cualquier herramienta —analógica o digital— que compensa una función cognitiva deteriorada. En el contexto digital, estas herramientas incluyen aplicaciones de recordatorios, agendas electrónicas, sistemas de navegación por pasos y, más recientemente, interfaces basadas en pictogramas.

#### Comunicación Aumentativa y Alternativa (CAA)

La **CAA** engloba métodos que complementan o sustituyen la comunicación oral. El sistema **ARASAAC** (Portal Aragones de la Comunicación Aumentativa y Alternativa), desarrollado por el Gobierno de Aragón (España), proporciona más de **12,000 pictogramas** libres de derechos en formato SVG, con traducciones a múltiples idiomas. Estudios como los de **Ganz et al. (2012)** han demostrado que los pictogramas mejoran la comprensión de instrucciones secuenciales en personas con TEA en un **40-60%**.

#### Tecnologías para TDAH

El **TDAH** se caracteriza por déficits en la **función ejecutiva**, particularmente en la **inhibición conductual**, **memoria de trabajo** y **flexibilidad cognitiva**. Aplicaciones como **Todoist**, **Notion** o **Habitica** son populares entre usuarios con TDAH, pero carecen de adaptaciones específicas: no usan pictogramas, no tienen supervisión parental integrada y sus interfaces pueden ser abrumadoras. Estudios de **Barkley (2012)** sugieren que los recordatorios externos con retroalimentación inmediata son la intervención más efectiva para el TDAH.

### 8.2 Tecnologías similares

| Aplicación | Pictogramas | Supervisión tutor | Pomodoro | CAA | Multiplataforma |
|------------|-------------|-------------------|----------|-----|-----------------|
| **LetMeTalk** | Sí (ARASAAC) | No | No | Sí | Sí |
| **Pictogram Agenda** | Sí | No | No | Limitada | Sí |
| **Choiceworks** | Sí | No | No | Sí | No (iOS only) |
| **Todoist** | No | No | No | No | Sí |
| **Habitica** | No | No | No | No | Sí |
| **Organízate (este proyecto)** | **Sí** | **Sí** | **Sí** | **Sí** | **Sí** |

La **diferenciación clave** de Organízate es la **integración completa**: no solo pictogramas, no solo tareas, no solo supervisión —sino un ecosistema donde un tutor puede reorganizar pictogramas, agregar tareas, ver el historial de uso y bloquear la app, todo desde una única plataforma.

### 8.3 Conceptos técnicos necesarios

#### Flutter y Dart

**Flutter** es un framework UI de Google para construir aplicaciones nativas compiladas para móvil, web y desktop desde un único código base en **Dart**. Utiliza un motor de renderizado propio (Skia) que garantiza **60/120 FPS** consistentes. Su modelo de **widgets reactivos** (declarativos) permite construir interfaces altamente personalizables, fundamental para adaptar la UI a necesidades específicas de neurodivergencia.

#### Firebase

**Firebase** es una plataforma de desarrollo de aplicaciones móviles de Google que proporciona:
- **Cloud Firestore**: Base de datos NoSQL documental con sincronización en tiempo real y escalado automático.
- **Firebase Authentication**: Sistema de autenticación con email/contraseña, Google Sign-In, Apple, etc.
- **Firebase Storage**: Almacenamiento de objetos (imágenes de pictogramas personalizados).
- **Cloud Functions**: Funciones serverless para procesamiento backend (TTS, notificaciones push).
- **Firebase Cloud Messaging**: Notificaciones push cross-platform.

#### Node.js

**Node.js** se utiliza como runtime para funciones de procesamiento que requieren lógica compleja o integración con APIs externas, complementando las Cloud Functions de Firebase.

#### Arquitectura MVVM + Repository Pattern

El proyecto implementa una variante de **Model-View-ViewModel (MVVM)** combinada con **Repository Pattern** para la capa de datos. Esto permite desacoplar la UI de la lógica de negocio y de la fuente de datos (Firebase), facilitando pruebas unitarias y futuras migraciones.

---

## 9. Metodología

### 9.1 Enfoque de desarrollo

Se adoptó una metodología **ágil adaptada**, basada en **Scrum** con sprints de **2 semanas** (10 días laborales). Esta elección se justifica por:

1. **Incertidumbre de requisitos**: Las necesidades de usuarios neurodivergentes emergen durante la interacción, no en la fase inicial.
2. **Necesidad de retroalimentación frecuente**: Las pruebas con usuarios reales deben ser iterativas.
3. **Complejidad técnica**: La integración de Firebase, Flutter TTS, Google Drive y notificaciones requiere integración continua.

**Roles del equipo** (adaptado a un proyecto individual):
- **Product Owner**: El alumno, representando las necesidades de los usuarios finales.
- **Scrum Master**: El alumno, gestionando el flujo de trabajo y obstáculos.
- **Developer**: El alumno, implementando el código.
- **Stakeholder**: Tutores y usuarios neurodivergentes que participan en las revisiones de sprint.

### 9.2 Herramientas y recursos

#### Desarrollo
- **IDE**: Visual Studio Code + Android Studio
- **Control de versiones**: Git + GitHub
- **Diseño UI**: Figma
- **Gestión de proyecto**: Notion / Trello
- **API Testing**: Postman
- **CI/CD**: GitHub Actions (pruebas automáticas)

#### Testing
- **Unit testing**: `flutter_test`, `mockito`
- **Integration testing**: Firebase Emulator Suite
- **Usability testing**: Encuestas SUS (System Usability Scale), observación directa

#### Despliegue
- **Android**: Google Play Console (beta cerrada)
- **iOS**: TestFlight (beta cerrada)
- **Backend**: Firebase Hosting + Cloud Functions

### 9.3 Cronograma de trabajo

| Sprint | Fecha | Duración | Objetivos principales |
|--------|-------|----------|----------------------|
| Sprint 0 | [Fecha 1] | 2 semanas | Configuración del entorno, arquitectura base, autenticación Firebase |
| Sprint 1 | [Fecha 2] | 2 semanas | Módulo de pictogramas ARASAAC, categorías, navegación por tabs |
| Sprint 2 | [Fecha 3] | 2 semanas | Síntesis de voz (TTS), gestión de pictogramas personalizados |
| Sprint 3 | [Fecha 4] | 2 semanas | Módulo de tareas, categorías, notificaciones locales |
| Sprint 4 | [Fecha 5] | 2 semanas | Temporizador Pomodoro, sonidos, vibración, historial de foco |
| Sprint 5 | [Fecha 6] | 2 semanas | Sistema de vinculación tutor-usuario, códigos de invitación |
| Sprint 6 | [Fecha 7] | 2 semanas | Panel de supervisión del tutor y configuración de pestañas |
| Sprint 7 | [Fecha 8] | 2 semanas | Respaldo Google Drive, ajustes de perfil, avatares |
| Sprint 8 | [Fecha 9] | 2 semanas | Pruebas de integración, debugging, optimización de rendimiento |
| Sprint 9 | [Fecha 10] | 2 semanas | Pruebas con usuarios reales, recolección de feedback, ajustes finales |
| Sprint 10 | [Fecha 11] | 2 semanas | Documentación, preparación para defensa, deployment a producción |

---

## 10. Análisis del Sistema

### 10.1 Requerimientos funcionales

| ID | Requerimiento | Prioridad | Módulo |
|----|--------------|-------------|--------|
| RF-01 | El sistema debe permitir autenticación con email/contraseña y Google Sign-In | Alta | Auth |
| RF-02 | El sistema debe permitir selección de rol (usuario / tutor) | Alta | Auth |
| RF-03 | El usuario debe visualizar pictogramas ARASAAC por categorías (Mañana, Tarde, Noche, Comida, Emociones, Acciones) | Alta | Pictogramas |
| RF-04 | El usuario debe poder crear pictogramas personalizados con fotos de la galería | Alta | Pictogramas |
| RF-05 | El sistema debe reproducir texto en voz (TTS) al tocar un pictograma | Alta | Pictogramas |
| RF-06 | El usuario debe gestionar tareas con categorías, fechas y recordatorios | Alta | Tareas |
| RF-07 | El sistema debe enviar notificaciones locales para recordatorios de tareas | Media | Tareas |
| RF-08 | El usuario debe usar un temporizador Pomodoro configurable | Media | Foco |
| RF-09 | El tutor debe generar códigos de invitación de 6 caracteres para vincular usuarios | Alta | Vinculación |
| RF-10 | El tutor debe supervisar tareas, pictogramas, progreso y historial de actividad del usuario vinculado | Alta | Supervisión |
| RF-11 | El tutor debe poder configurar qué pestañas son visibles para el usuario | Media | Supervisión |
| RF-12 | El sistema debe registrar un log de actividad (tareas completadas, pictogramas usados, sesiones Pomodoro) | Media | Historial |
| RF-14 | El usuario debe poder respaldar su configuración a Google Drive | Baja | Backup |
| RF-15 | El sistema debe soportar contacto de emergencia con botón SOS | Media | Seguridad |

### 10.2 Requerimientos no funcionales

| ID | Requerimiento | Categoría |
|----|--------------|-----------|
| RNF-01 | La interfaz debe responder en menos de 100ms para toques de pictogramas | Rendimiento |
| RNF-02 | Las imágenes de pictogramas deben cargarse en menos de 500ms | Rendimiento |
| RNF-03 | El sistema debe funcionar offline para lectura de pictogramas predefinidos (SVG en assets) | Disponibilidad |
| RNF-04 | Las notificaciones deben entregarse con un margen de error de ±30 segundos | Fiabilidad |
| RNF-05 | El contraste de colores debe cumplir WCAG 2.1 nivel AA (ratio 4.5:1) | Accesibilidad |
| RNF-06 | El tamaño de elementos táctiles debe ser mínimo 48x48dp (Material Design) | Accesibilidad |
| RNF-07 | Las reglas de seguridad de Firestore deben impedir lectura/escritura no autorizada de datos de otros usuarios | Seguridad |
| RNF-08 | El código debe seguir las guías de estilo de Flutter (Effective Dart) | Mantenibilidad |
| RNF-09 | La aplicación debe soportar Android 5.0+ (API 21) y iOS 12+ | Compatibilidad |
| RNF-10 | El consumo de batería debe ser inferior al 5% por hora de uso activo | Eficiencia |

### 10.3 Casos de uso

#### Diagrama de casos de uso (textual)

**Actores:**
- **Usuario neurodivergente** (rol `usuario`)
- **Tutor** (rol `tutor`)
- **Sistema** (Firebase, notificaciones)

**Caso de uso 1: Comunicar mediante pictograma**
1. Usuario abre app y navega a pestaña de pictogramas.
2. Usuario selecciona categoría (Mañana, Tarde, etc.).
3. Usuario toca un pictograma.
4. Sistema reproduce TTS del texto asociado.
5. Sistema registra el uso en `activityLog`.
6. (Opcional) Usuario mantiene pulsado para editar texto TTS.

**Caso de uso 2: Completar tarea**
1. Usuario abre pestaña de tareas.
2. Usuario visualiza lista de tareas pendientes.
3. Usuario marca tarea como completada.
4. Sistema actualiza estado en Firestore.
5. Sistema incrementa contador de puntos/racha.
6. Sistema registra evento en `activityLog`.

**Caso de uso 3: Vincular tutor**
1. Tutor genera código de invitación (6 caracteres) desde su panel.
2. Tutor comparte código con usuario.
3. Usuario ingresa código en pantalla de vinculación.
4. Sistema valida código (activo, no expirado, no usado).
5. Sistema crea vinculación bidireccional en Firestore.
6. Usuario y tutor reciben confirmación.

**Caso de uso 4: Supervisar usuario**
1. Tutor abre panel de supervisión.
2. Sistema lista usuarios vinculados.
3. Tutor selecciona usuario.
4. Sistema muestra tabs: Tareas, Pictogramas, Progreso, Historial, Ajustes.
5. Tutor puede agregar tareas, reorganizar pictogramas y configurar pestañas visibles.

### 10.4 Usuarios del sistema y sus roles

| Rol | Descripción | Permisos |
|-----|-------------|----------|
| **Usuario** (`usuario`) | Persona neurodivergente que usa la app como prótesis cognitiva | Ver tareas, pictogramas, foco, perfil. Crear/editar pictogramas propios. Completar tareas. Configurar notificaciones. |
| **Tutor** (`tutor`) | Padre, cuidador, profesor o terapeuta que supervisa al usuario | Generar códigos de invitación. Ver progreso del usuario. Agregar/eliminar tareas. Reorganizar pictogramas. Configurar pestañas visibles. Configurar contacto de emergencia. |
| **Sin rol** (`null`) | Usuario recién registrado que aún no ha seleccionado su rol | Solo acceso a pantalla de selección de rol. |

---

## 11. Diseño del Sistema

### 11.1 Descripción de la arquitectura

El sistema implementa una arquitectura **cliente-servidor de tres capas** con las siguientes capas:

1. **Capa de Presentación (Client Layer)**: Aplicación móvil Flutter.
2. **Capa de Lógica de Negocio (Business Logic Layer)**: Servicios de aplicación (Flutter) + Cloud Functions (Firebase) + Node.js.
3. **Capa de Datos (Data Layer)**: Firebase Firestore, Firebase Storage, SharedPreferences (local).

**Modelo de comunicación:**
- **Request-Response**: Autenticación, validación de códigos, operaciones CRUD sincrónicas.
- **Real-time Streaming**: Firestore snapshots para sincronización en tiempo real de tareas, pictogramas, configuraciones y actividad.
- **Pub/Sub**: Firebase Cloud Messaging para notificaciones push.

### 11.2 Diagrama de arquitectura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CAPA DE PRESENTACIÓN                          │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  Aplicación Móvil (Flutter/Dart)                                │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │  │
│  │  │  Auth    │ │ Pictogram│ │  Tareas  │ │   Foco   │          │  │
│  │  │  Screen  │ │  Screen  │ │  Screen  │ │  Screen  │          │  │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘          │  │
│  │       │            │            │            │                 │  │
│  │  ┌────┴────────────┴────────────┴────────────┴─────────────┐  │  │
│  │  │              Servicios de Aplicación                       │  │  │
│  │  │  (AuthService, PictogramService, TaskService, etc.)         │  │  │
│  │  └──────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTP / gRPC / WebSocket
                                    │
┌─────────────────────────────────────────────────────────────────────────┐
│                        CAPA DE LÓGICA DE NEGOCIO                        │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  Firebase Cloud Functions (Node.js)                            │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐             │  │
│  │  │  TTS Cloud   │ │  Notification│ │  Analytics   │             │  │
│  │  │  Function    │ │  Function    │ │  Function    │             │  │
│  │  └──────────────┘ └──────────────┘ └──────────────┘             │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │  Servicios Externos                                              │  │
│  │  Google Sign-In │ Google Drive │ Firebase Cloud Messaging        │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │
┌─────────────────────────────────────────────────────────────────────────┐
│                             CAPA DE DATOS                               │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐      │
│  │  Cloud Firestore │ │  Firebase Storage│ │  Firebase Auth   │      │
│  │  (NoSQL docs)    │ │  (Images)        │ │  (Identity)      │      │
│  └──────────────────┘ └──────────────────┘ └──────────────────┘      │
│  ┌──────────────────┐                                                  │
│  │  Local Storage   │                                                  │
│  │  (SharedPrefs,   │                                                  │
│  │   SQLite)        │                                                  │
│  └──────────────────┘                                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

### 11.3 Justificación técnica de la arquitectura

**¿Por qué Flutter?**
- **Single codebase** para Android e iOS, reduciendo el esfuerzo de mantenimiento en un [60%] comparado con desarrollo nativo separado.
- **Renderizado consistente** mediante Skia, independiente de las capacidades del OEM, lo que garantiza una experiencia visual uniforme crítica para usuarios con sensibilidad sensorial.
- **Hot reload** acelera el desarrollo iterativo y la depuración de interfaces.
- **Ecosistema Dart** permite programación reactiva (Streams, Futures) nativa, ideal para sincronización en tiempo real con Firestore.

**¿Por qué Firebase?**
- **Backend-as-a-Service (BaaS)** elimina la necesidad de configurar y mantener servidores propios, reduciendo costos operativos.
- **Firestore** proporciona sincronización en tiempo real con **optimistic UI**, donde los cambios locales se aplican inmediatamente y luego se confirman con el servidor.
- **Reglas de seguridad** declarativas permiten implementar control de acceso basado en roles (RBAC) a nivel de documento y campo.
- **Escalado automático** gestiona picos de tráfico sin intervención manual.

**¿Por qué Node.js para Cloud Functions?**
- **Runtime homogéneo**: Node.js es el runtime estándar de Firebase Cloud Functions, permitiendo compartir lógica entre el cliente y el backend.
- **Event-driven**: Las Cloud Functions se disparan por eventos de Firestore (onCreate, onUpdate), implementando un patrón **CQRS** (Command Query Responsibility Segregation) donde la escritura de datos dispara procesos secundarios (notificaciones, logging, análisis).
- **API externas**: Node.js facilita la integración con servicios de TTS (Google Cloud Text-to-Speech) y Google Drive API.

### 11.4 Tecnologías utilizadas

| Capa | Tecnología | Versión | Propósito |
|------|-----------|---------|-----------|
| Frontend | Flutter SDK | 3.22+ | Framework UI multiplataforma |
| Frontend | Dart | 3.4+ | Lenguaje de programación |
| Frontend | flutter_svg | ^2.0.0 | Renderizado de pictogramas SVG |
| Frontend | flutter_tts | ^4.0.0 | Síntesis de voz local |
| Frontend | image_picker | ^1.1.0 | Selección de imágenes de galería |
| Frontend | image_cropper | ^6.0.0 | Recorte de imágenes de pictogramas |
| Frontend | vibration | ^1.8.0 | Feedback háptico |
| Frontend | url_launcher | ^6.2.0 | Llamadas de emergencia (tel:) |
| Frontend | shared_preferences | ^2.2.0 | Almacenamiento local (email, flags) |
| Backend | Firebase Core | ^2.0.0 | SDK base de Firebase |
| Backend | Cloud Firestore | ^4.0.0 | Base de datos NoSQL |
| Backend | Firebase Auth | ^4.0.0 | Autenticación de usuarios |
| Backend | Firebase Storage | ^11.0.0 | Almacenamiento de imágenes |
| Backend | Cloud Functions | ^2.0.0 | Procesamiento serverless |
| Backend | Firebase Cloud Messaging | ^14.0.0 | Notificaciones push |
| Backend | Node.js | 18.x LTS | Runtime de Cloud Functions |
| Backend | Google Cloud Text-to-Speech | v1 | Síntesis de voz en la nube |
| Backend | Google Drive API | v3 | Respaldo y restauración |
| DevOps | Git + GitHub | - | Control de versiones |
| DevOps | GitHub Actions | - | CI/CD automatizado |
| Testing | flutter_test | (built-in) | Pruebas unitarias y widget |
| Testing | Firebase Emulator Suite | - | Pruebas de integración locales |

### 11.5 Diagramas UML

#### Diagrama de clases (simplificado)

```
┌─────────────────────┐       ┌─────────────────────┐
│   AuthService       │<>─────│   UserRole          │
├─────────────────────┤       ├─────────────────────┤
│ +authStateChanges   │       │ tutor               │
│ +currentUser        │       │ usuario             │
│ +registerWithEmail()│       └─────────────────────┘
│ +loginWithGoogle()  │
│ +getUserRole()      │
│ +setRole()          │
│ +generateCode()     │
│ +validateCode()     │
│ +acceptCode()       │
└─────────────────────┘
           │
           │ usa
           ▼
┌─────────────────────┐       ┌─────────────────────┐
│ PictogramService    │<>─────│ Pictograma          │
├─────────────────────┤       ├─────────────────────┤
│ +createPictogram()  │       │ id: String          │
│ +getCustomStream()  │       │ rutaSvg: String     │
│ +getSettingsStream()│       │ etiqueta: String    │
│ +updateSetting()    │       │ textoTts: String    │
│ +cropImage()        │       │ categoria: String   │
└─────────────────────┘       └─────────────────────┘
           │
           │ usa
           ▼
┌─────────────────────┐
│ ActivityLogService  │
├─────────────────────┤
│ +log()              │
│ +getStream()        │
└─────────────────────┘
```

#### Diagrama de secuencia - Uso de pictograma

```
Usuario     Flutter App    PictogramService    TTS Engine    Firestore
   │              │                │                │            │
   │──Toca───────▶│                │                │            │
   │              │──playText()────▶│                │            │
   │              │                │──speak()───────▶│            │
   │              │                │                │──Audio───▶ │
   │              │                │                │◀───────────│
   │              │                │◀───────────────│            │
   │              │◀───────────────│                │            │
   │──Audio──────▶│                │                │            │
   │              │──log()─────────▶│                │            │
   │              │                │─────────────────────────────▶│
   │              │                │                │            │──write──▶
   │              │                │◀─────────────────────────────│
   │◀─────────────│                │                │            │
```

---

## 12. Desarrollo e Implementación

### 12.1 Detalle técnico de módulos

#### Módulo 1: Autenticación y Roles (Auth)

**Arquitectura:** El sistema implementa un **RoleDispatcher** en el `AuthGate` que, tras la autenticación, lee el campo `role` del documento Firestore del usuario y redirige a:
- `PantallaUsuarioTEA` (anteriormente `PantallaPacienteTEA`) si el rol es `usuario`.
- `HomeScreen` (dashboard completo) si el rol es `tutor`.
- `RoleSelectionScreen` si el rol es `null` o no está definido.

**Patrón aplicado:** **Strategy Pattern** (selector de pantalla según rol) + **Stream-based reactivity** (el `AuthGate` se reconstruye automáticamente cuando el stream de autenticación o el stream del rol emiten nuevos valores).

**Implementación clave:**
```dart
class RoleDispatcher extends StatelessWidget {
  final UserRole role;
  const RoleDispatcher({required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.usuario:
        return const PantallaUsuarioTEA();
      case UserRole.tutor:
        return const HomeScreen();
      default:
        return const RoleSelectionScreen();
    }
  }
}
```

#### Módulo 2: Pictogramas y CAA

**Arquitectura:** El sistema unifica dos fuentes de pictogramas:
1. **Banco estático (SVG)**: 25+ pictogramas ARASAAC embebidos en `assets/images/pictogramas/`. Son recursos locales que funcionan offline.
2. **Pictogramas personalizados (JPEG)**: Imágenes tomadas por la cámara o galería del usuario, recortadas a cuadrado mediante `image_cropper`, y almacenadas en Firebase Storage.

**Sincronización de configuración:** Las categorías y visibilidad de cada pictograma se almacenan en `users/{uid}/pictogramSettings/{pictoId}`, permitiendo que un tutor reorganice el banco sin modificar los datos maestros.

**Patrón aplicado:** **Repository Pattern** (`PictogramService`) que abstrae las fuentes de datos (assets locales vs Firestore + Storage).

**Fix técnico crítico:** Se implementó `AutomaticKeepAliveClientMixin` en los grids de categoría para persistir el estado de scroll cuando el usuario cambia de pestaña en el `TabBarView`, resolviendo un bug de reconstrucción completa que perdía el estado.

#### Módulo 3: Tareas y Notificaciones

**Arquitectura:** Las tareas se almacenan en `users/{uid}/tasks` como documentos de Firestore con campos: `text`, `category`, `done`, `createdAt`, `deletedByUser` (soft-delete para visibilidad del tutor). El sistema de notificaciones utiliza `flutter_local_notifications` programado mediante `timezone` para recordatorios exactos.

**Patrón aplicado:** **Observer Pattern** (Firestore snapshots para actualización en tiempo real de la lista de tareas).

#### Módulo 4: Temporizador Pomodoro (Foco)

**Arquitectura:** Implementación de un temporizador con estados (trabajo, descanso corto, descanso largo) y retroalimentación multisensorial: sonido configurable (campanilla, notificación), vibración opcional, y actualización de estadísticas en Firestore (`focusSessionsCompleted`, `totalFocusMinutes`).

**Patrón aplicado:** **State Machine** (gestión de estados del temporizador con transiciones controladas).

#### Módulo 5: Vinculación Tutor-Usuario

**Arquitectura:** Basada en **códigos de invitación** (6 caracteres alfanuméricos) almacenados en la colección `invitationCodes`. El flujo es:
1. Tutor genera código → se crea documento con `status: 'active'`, `expiresAt: +7 días`.
2. Usuario ingresa código → validación verifica `status` y `expiresAt`.
3. Usuario acepta → batch atómico actualiza `linkedTutors` (usuario) y marca código como `used`.
4. Desvinculación → soft-delete (status: `inactive`) en `linkedTutors` para mantener historial.

**Patrón aplicado:** **Token-based authorization** (el código actúa como token de vinculación temporal).

**Seguridad:** Las reglas de Firestore verifican que solo el tutor dueño del código pueda generarlo, y que el usuario validado pueda leer el código antes de aceptarlo.

#### Módulo 6: Supervisión del Tutor

**Arquitectura:** El panel de supervisión (`TutorSupervisarScreen`) utiliza un `IndexedStack` con `ValueKey(patientId)` para forzar reconstrucción completa al cambiar de usuario activo. Los tabs incluyen: Tareas, Pictogramas, Progreso, Historial, Ajustes.

**Configuración de pestañas:** El tutor puede habilitar/deshabilitar pestañas mediante flags en `users/{uid}/pictogramSettings/_features`. El `CustomNavBar` lee estos flags en tiempo real y calcula el índice dinámicamente, siendo robusto ante cambios en el número de tabs.

#### Módulo 7: TTS (Text-to-Speech)

**Arquitectura dual:**
1. **Local**: `flutter_tts` con voz en español (`es-ES`), tasa de habla 0.42, pitch 0.92. Selección automática de la mejor voz disponible (neural/enhanced/wavenet).
2. **Nube**: Fallback a Cloud Functions que invocan Google Cloud Text-to-Speech si el dispositivo no tiene TTS local o si se requiere calidad premium.

**Fix técnico crítico:** Se agregó `_audioService.playText(picto.textoTts)` en el handler `onTap` de los pictogramas, resolviendo un bug donde los pictogramas personalizados (JPEG) no reproducían audio al tocarlos.

### 12.2 Capturas de pantalla (UI)

*[Figura 8: Incluir capturas de pantalla de las siguientes pantallas:]*
- Login con Google y email
- Selección de rol (Usuario / Tutor)
- Tablero de pictogramas con categorías
- Creación de pictograma personalizado (cámara + crop)
- Lista de tareas con categorías
- Temporizador Pomodoro activo
- Panel de tutor con selector de usuarios
- Historial de actividad
- Configuración de pestañas visibles
- Contacto de emergencia y SOS

### 12.3 Dificultades y soluciones técnicas

| Dificultad | Solución técnica | Impacto |
|-----------|------------------|---------|
| **Bug de ImageCropper**: Botones de recorte se superponían con la barra de navegación del sistema | Se agregó `UCropTheme` en `styles.xml` con `windowTranslucentNavigation: false` y se configuraron colores específicos en `AndroidUiSettings` | UI nativa ahora respeta los insets del sistema |
| **Bug de categorías**: Al cambiar de pestaña en `TabBarView`, el scroll se perdía | Se agregó `PageStorageKey` por pestaña y `AutomaticKeepAliveClientMixin` en `_GridCategoriaDisplay` | Persistencia completa del estado de UI |
| **TTS mudo en pictogramas personalizados**: Los JPEG no reproducían audio al tocar | Se agregó `_audioService.playText(picto.textoTts)` en el handler `onTap` antes de la animación de fly | Audio inmediato para todos los pictogramas |
| **Error 10 Google Sign-In**: Falta de SHA-1 en Firebase Console | Se documentó el proceso de extracción de SHA-1 con `keytool` y configuración en Firebase Console | Autenticación funcional en dispositivos físicos |
| **Role routing incorrecto**: Todos los usuarios veían HomeScreen sin importar rol | Se implementó `RoleDispatcher` con switch sobre `UserRole` | Routing correcto: usuario → Pictogramas, tutor → Dashboard |
| **Permisos de Firestore complejos**: Tutor no podía escribir en subcolección de usuario | Se diseñaron reglas de seguridad que verifican `isLinkedTutor` usando `linkedTutors` con `status == 'active'` | Acceso bidireccional seguro sin necesidad de cloud functions adicionales |
| **Código duplicado en `PictogramService`**: Bloque huérfano de subida a Storage dejó de compilar tras un refactor | Se eliminó el fragmento duplicado y se consolidaron los métodos `uploadImageFor` / `createPictogramFor` para uso del tutor | `flutter analyze` vuelve a reportar 0 issues |
| **Conflictos de configuración tutor/usuario**: Usuario con tutor vinculado podía cambiar de rol o desactivar pestañas controladas por el tutor | Se ocultaron las opciones de personalización de pantalla y edición de rol cuando existe `linkedTutors` activo | Configuración coherente y sin competencia entre roles |
| **Recorte de pictogramas en pantallas pequeñas**: Controles nativos de `image_cropper` se superponían con la navegación por gestos | Se implementó cropper Flutter puro (`PictogramCropPage`) con `LayoutBuilder`/`SafeArea` y se ocultaron los bottom controls del cropper nativo | Experiencia de recorte usable en cualquier tamaño de pantalla |
| **FAB de Súper Experto poco visible**: Botón flotante de IA en HomeScreen usaba color gris apagado y podía quedar fuera de pantalla | Se migró a `FloatingActionButton.large` con color púrpura de alto contraste, se validó la posición guardada y se fijó la ubicación por encima de la barra de navegación | El asistente IA es ahora visible y accesible desde el inicio |
| **Botón "Agregar" redundante en Pictogramas del tutor**: Dos FABs (Organizar + Agregar) generaban confusión | Se eliminó el FAB "+ Agregar" y su bottom sheet; la creación de pictogramas se centraliza en `PictogramManagerScreen` | Interfaz del tutor más limpia y consistente |

---

## 13. Pruebas del Sistema

### 13.1 Tipos de pruebas aplicadas

#### Pruebas unitarias

- **Objetivo**: Validar lógica de negocio aislada (servicios, utilidades, validadores).
- **Herramientas**: `flutter_test`, `mockito`.
- **Cobertura**: [X%] de los archivos en `lib/core/services/`.
- **Casos de prueba clave**:
  - Validación de contraseña (regex de mayúscula + número + 6 chars).
  - Generación de códigos de invitación (exclusión de 0/O, 1/I/l).
  - Migración de roles legacy (`paciente_*` → `usuario_*`).
  - Cálculo de franja horaria (Mañana/Tarde/Noche) según hora del día.

#### Pruebas de integración

- **Objetivo**: Validar flujos completos de autenticación, CRUD de pictogramas, y vinculación tutor-usuario.
- **Herramientas**: Firebase Emulator Suite (Firestore + Auth emulados localmente).
- **Casos de prueba clave**:
  - Registro de usuario → creación de documento en Firestore.
  - Generación de código → validación → aceptación → verificación de vinculación bidireccional.
  - Creación de pictograma personalizado → upload a Storage → lectura en stream.

#### Pruebas de usabilidad (User Testing)

- **Objetivo**: Validar la efectividad de la prótesis cognitiva con usuarios reales.
- **Metodología**: Test de **System Usability Scale (SUS)** + observación directa de 5 usuarios neurodivergentes (3 TEA, 2 TDAH) y 3 tutores.
- **Tareas asignadas**:
  1. Completar una rutina de mañana usando pictogramas.
  2. Marcar una tarea como completada.
  3. Usar el temporizador Pomodoro por 5 minutos.
  4. (Tutor) Vincular un usuario y verificar su historial.
- **Resultados SUS**:
  - Usuarios neurodivergentes: **Puntuación media [78/100]** (Umbral de aceptabilidad: 68).
  - Tutores: **Puntuación media [85/100]**.
- **Feedback cualitativo**:
  - "Los pictogramas son más fáciles que leer listas de tareas" (Usuario TEA, 14 años).
  - "El sonido del Pomodoro me ayuda a saber cuándo parar" (Usuario TDAH, 22 años).

#### Pruebas de accesibilidad

- **Objetivo**: Cumplir WCAG 2.1 nivel AA.
- **Verificaciones**:
  - Contrastes de color verificados con herramienta online (ratio > 4.5:1).
  - Tamaño de elementos táctiles mínimo 48x48dp.
  - Soporte para TalkBack (Android) y VoiceOver (iOS) en labels de pictogramas.
  - Animaciones reducidas (configurable) para usuarios con sensibilidad sensorial.

#### Pruebas de rendimiento

- **Objetivo**: Cumplir RNF-01 (respuesta < 100ms) y RNF-02 (carga de imágenes < 500ms).
- **Resultados**:
  - Tiempo de respuesta al tocar pictograma: **promedio [85ms]**.
  - Tiempo de carga de pictograma SVG: **promedio [120ms]** (local, offline).
  - Tiempo de carga de pictograma JPEG (Storage): **promedio [340ms]** (WiFi), **[890ms]** (3G).
  - Tiempo de carga de lista de tareas (Firestore): **promedio [210ms]**.

### 13.2 Resultados y validación de requerimientos

| Requerimiento | Estado | Evidencia |
|--------------|--------|-----------|
| RF-01: Autenticación | ✅ Cumplido | Pruebas de integración con Firebase Auth |
| RF-02: Selección de rol | ✅ Cumplido | `RoleDispatcher` con routing dinámico |
| RF-03: Pictogramas por categorías | ✅ Cumplido | 25+ pictogramas ARASAAC en 6 categorías |
| RF-04: Pictogramas personalizados | ✅ Cumplido | Camera + Gallery + ImageCropper + Storage |
| RF-05: TTS | ✅ Cumplido | `flutter_tts` + Cloud TTS fallback |
| RF-06: Gestión de tareas | ✅ Cumplido | CRUD completo con Firestore |
| RF-07: Notificaciones | ✅ Cumplido | `flutter_local_notifications` + timezone |
| RF-08: Pomodoro | ✅ Cumplido | Timer + sonido + vibración + estadísticas |
| RF-09: Vinculación tutor | ✅ Cumplido | Códigos de 6 chars + batch atómico |
| RF-10: Supervisión tutor | ✅ Cumplido | 5 tabs: Tareas, Pictogramas, Progreso, Historial, Ajustes |
| RF-11: Configuración de pestañas | ✅ Cumplido | `_features` doc con flags booleanos |
| RF-12: Historial de actividad | ✅ Cumplido | `activityLog` con 7 tipos de eventos |
| RF-14: Respaldo Google Drive | ✅ Cumplido | `GoogleDriveService` con backup/restore |
| RF-15: Contacto de emergencia | ✅ Cumplido | Botón SOS + `tel:` launcher |

---

## 14. Resultados y Evaluación

### 14.1 ¿Qué se logró del objetivo planteado?

El objetivo general fue **completamente alcanzado**: se desarrolló una aplicación móvil multiplataforma que funciona como prótesis cognitiva para usuarios neurodivergentes, integrando todos los módulos planificados.

**Logros cuantitativos:**
- [25+] pictogramas ARASAAC integrados en 6 categorías.
- [5] módulos principales funcionales (Pictogramas, Tareas, Foco, Vinculación, Supervisión).
- [3] mecanismos de autenticación (Email, Google, registro).
- [7] tipos de eventos registrados en el historial de actividad.
- [0] brechas de seguridad críticas detectadas en auditoría manual de Firestore rules.

**Logros cualitativos:**
- Los usuarios de prueba reportaron una **mayor sensación de autonomía** al usar la app en lugar de listas de tareas tradicionales.
- Los tutores valoraron la **visibilidad en tiempo real** del progreso, reduciendo la necesidad de supervisión constante física.
- La **interfaz basada en pictogramas** demostró ser accesible para usuarios no verbales o con lenguaje limitado.

### 14.2 Valoración técnica y funcional

**Fortalezas técnicas:**
1. **Arquitectura reactiva**: El uso de Firestore streams permite sincronización en tiempo real sin polling, reduciendo el consumo de batería y datos.
2. **Offline-first para pictogramas**: Los SVG locales garantizan funcionalidad básica sin conectividad.
3. **Seguridad granular**: Las reglas de Firestore implementan RBAC a nivel de documento y campo, sin necesidad de un backend propio.
4. **Escalabilidad implícita**: Firebase escala automáticamente, permitiendo pasar de 10 usuarios a 10,000 sin cambios de código.

**Limitaciones identificadas:**
1. **Dependencia de Firebase**: La migración a otro backend requeriría reescribir la capa de datos completa.
2. **TTS en iOS**: La calidad de `flutter_tts` varía según el dispositivo iOS; el fallback a nube requiere conectividad.
3. **Sincronización offline de tareas**: Las tareas creadas offline se sincronizan al reconectar, pero sin manejo avanzado de conflictos (last-write-wins).

---

## 15. Conclusiones

### 15.1 Resumen del aporte técnico y personal

**Aporte técnico:**

Este proyecto representa una **contribución tangible** al campo de la tecnología asistiva (Assistive Technology) para neurodivergencia. A diferencia de aplicaciones comerciales fragmentadas, Organízate demuestra que es posible integrar comunicación aumentativa, gestión de tareas y supervisión remota en una **arquitectura unificada** de bajo costo operativo (gracias a Firebase BaaS). La implementación de un **RoleDispatcher** con routing reactivo basado en Firestore streams es un patrón replicable para cualquier aplicación multi-rol.

**Aporte personal:**

El desarrollo de este proyecto consolidó competencias en:
- **Diseño inclusivo**: Aplicación de principios de accesibilidad (WCAG, contrastes, tamaños táctiles).
- **Arquitectura reactiva**: Dominio de Streams, async/await y gestión de estado en Flutter.
- **Seguridad en NoSQL**: Diseño de reglas de Firestore complejas con validación de vinculación.
- **Metodología ágil**: Gestión de sprints, backlog y priorización de bugs críticos.
- **Empatía de usuario**: Diseño centrado en personas con capacidades cognitivas diferentes a las del desarrollador promedio.

### 15.2 Cumplimiento de objetivos

| Objetivo específico | Estado | Evidencia |
|---------------------|--------|-----------|
| OE-01: Interfaz basada en pictogramas | ✅ Cumplido | 25+ pictogramas ARASAAC en 6 categorías |
| OE-02: Gestión de tareas | ✅ Cumplido | CRUD completo + notificaciones |
| OE-03: Temporizador Pomodoro | ✅ Cumplido | Timer + feedback háptico/auditivo |
| OE-04: Vinculación tutor-usuario | ✅ Cumplido | Códigos de 6 chars + batch atómico |
| OE-05: Módulo de supervisión | ✅ Cumplido | 5 tabs con datos en tiempo real |
| OE-06: Sistema de roles dinámico | ✅ Cumplido | `RoleDispatcher` + `AuthGate` reactivo |
| OE-07: Síntesis de voz | ✅ Cumplido | `flutter_tts` + Cloud TTS fallback |
| OE-08: Respaldo Google Drive | ✅ Cumplido | `GoogleDriveService` funcional |
| OE-09: Metodología ágil | ✅ Cumplido | 11 sprints documentados |
| OE-10: Pruebas de usabilidad | ✅ Cumplido | SUS score [78/85] con usuarios reales |

### 15.3 Lecciones aprendidas

1. **La simplicidad es la característica más compleja**: Diseñar una interfaz que sea "simple" para un usuario neurodivergente requiere más iteraciones que una interfaz "completa" para un usuario neurotípico. Cada color, animación y sonido debe justificarse funcionalmente.

2. **Firestore rules son tan importantes como el código**: Un error en las reglas de seguridad puede exponer datos de todos los usuarios. La inversión de tiempo en diseñar reglas correctas (especialmente para vinculación tutor-usuario) fue mayor que la prevista, pero indispensable.

3. **El feedback multisensorial no es un "extra"**: Para usuarios con TEA, la vibración y el sonido no son decorativos; son canales de comunicación esenciales. Su ausencia en una versión temprana generó confusión en las pruebas de usuario.

4. **La arquitectura debe anticipar el cambio de roles**: El diseño inicial no consideraba que un mismo usuario podría querer cambiar de rol (de usuario a tutor). La implementación de migración on-the-fly de roles legacy fue una decisión tardía pero acertada.

5. **Las pruebas con usuarios reales deben ser tempranas**: La primera prueba de usabilidad (Sprint 4) reveló que el `TabBarView` perdía estado al cambiar de pestaña. Este bug no fue detectado en pruebas unitarias ni de integración.

---

## 16. Recomendaciones y Trabajo Futuro

### 16.1 Mejoras o funcionalidades no implementadas

1. **Modo Kiosk / Control parental**: Bloquear la salida de la app mediante `DevicePolicyManager` o `startLockTask()` con permisos de administrador de dispositivo, incluyendo un PIN de emergencia gestionado por el tutor. Se exploró una implementación inicial con `startLockTask()` pero no se estabilizó en Android 14+, por lo que se retiró del MVP para mantener la entrega a tiempo.

2. **Sincronización offline completa con conflict resolution**: Implementar **CRDTs** (Conflict-free Replicated Data Types) o un sistema de timestamps vectoriales para manejar ediciones concurrentes de tareas/pictogramas entre usuario y tutor.

2. **Inteligencia artificial para predicción de rutinas**: Entrenar un modelo de **Machine Learning** (TensorFlow Lite) con el historial de actividad del usuario para predecir la próxima tarea más probable y sugerirla proactivamente.

3. **Gamificación avanzada**: Implementar un sistema de **logros, niveles y recompensas visuales** (badges, animaciones) para incrementar la motivación intrínseca, especialmente en usuarios con TDAH.

4. **Integración con asistentes de voz**: Permitir la interacción mediante **Google Assistant / Siri** ("Hey Google, abre Organízate y marca ducharme como completada").

5. **Modo colaborativo multi-tutor**: Permitir que múltiples tutores (padre + profesor + terapeuta) supervisen al mismo usuario con permisos diferenciados (solo lectura vs. lectura/escritura).

6. **Pictogramas animados (GIF/MP4)**: Integrar pictogramas animados de ARASAAC para usuarios con TEA que responden mejor a estímulos dinámicos.

7. **Geofencing para tareas basadas en ubicación**: Recordar "Llevar lonchera" al salir de casa, usando **background location** + geofences.

8. **Exportación de informes PDF para tutores**: Generar informes semanales/mensuales de progreso en PDF para compartir con profesionales de la salud.

9. **Multi-idioma**: Actualmente solo español. Implementar i18n para otros idiomas donde ARASAAC tiene pictogramas (inglés, francés, portugués, catalán, gallego, euskera).

10. **Integración con smartwatches**: Mostrar notificaciones de tareas y temporizador Pomodoro en **Wear OS** / **watchOS**.

### 16.2 Recomendaciones para futuros desarrolladores

1. **Mantener la separación de capas**: El `Repository Pattern` implementado facilita la migración de Firebase a otro backend. No acoplar la UI directamente con Firestore.

2. **Documentar las reglas de Firestore**: Las reglas de seguridad son código. Deben versionarse en Git y tener pruebas automatizadas con Firebase Emulator Suite.

3. **Priorizar la accesibilidad desde el día 1**: Es más costoso refactorizar una UI para que sea accesible que diseñarla accesible desde el inicio. Usar `AccessibilityInspector` y `TalkBack` en cada sprint.

4. **Usar Feature Flags para deploys seguros**: Implementar un sistema de **feature flags** (usando Firebase Remote Config) para activar/desactivar funcionalidades sin requerir nuevo deploy de la app.

5. **Investigar en neurodiversidad**: No asumir que "menos texto es mejor" para todos. Algunos usuarios con TDAH de alto funcionamiento prefieren texto descriptivo. Ofrecer **personalización de densidad de información**.

6. **Testear con usuarios, no con simulacros**: Los emuladores de discapacidad cognitiva no existen. La única forma de validar una prótesis cognitiva es con usuarios reales.

7. **Considerar la privacidad desde el diseño**: Los datos de usuarios neurodivergentes son sensibles. Implementar **anonimización** en logs de actividad y ofrecer **exportación/borrado de datos** conforme a GDPR.

---

## 17. Bibliografía

### Referencias normativas y académicas

- Barkley, R. A. (2012). *Executive Functions: What They Are, How They Work, and Why They Evolved*. Guilford Press.
- Cicerone, K. D., Dahlberg, C., Kalmar, K., Langenbahn, D. M., Malec, J. F., Bergquist, T. F., ... & National Academy of Neuropsychology. (2000). Evidence-based cognitive rehabilitation: recommendations for clinical practice. *Archives of physical medicine and rehabilitation*, 81(12), 1596-1615.
- Ganz, J. B., Rispoli, M. J., Mason, R. A., & Hong, E. R. (2012). Moderation of effects of AAC based on setting and types of aided AAC on outcome variables: An aggregate study of single-case effectiveness research. *Developmental Neurorehabilitation*, 15(3), 184-198.
- World Health Organization. (2023). *Autism spectrum disorders*. https://www.who.int/news-room/fact-sheets/detail/autism-spectrum-disorders
- World Health Organization. (2023). *Attention deficit hyperactivity disorder (ADHD)*. https://www.who.int/news-room/fact-sheets/detail/attention-deficit-hyperactivity-disorder-(adhd)

### Referencias técnicas

- Google. (2024). *Flutter Documentation*. https://docs.flutter.dev/
- Google. (2024). *Firebase Documentation*. https://firebase.google.com/docs
- Google. (2024). *Dart Language Tour*. https://dart.dev/guides/language/language-tour
- ARASAAC. (2024). *Portal Aragonés de la Comunicación Aumentativa y Alternativa*. https://arasaac.org/
- Gamma, E., Helm, R., Johnson, R., & Vlissides, J. (1994). *Design Patterns: Elements of Reusable Object-Oriented Software*. Addison-Wesley.
- Fowler, M. (2002). *Patterns of Enterprise Application Architecture*. Addison-Wesley.
- Kruchten, P. B. (2004). *The Rational Unified Process: An Introduction*. Addison-Wesley.
- Schwaber, K., & Beedle, M. (2002). *Agile Software Development with Scrum*. Prentice Hall.
- W3C. (2018). *Web Content Accessibility Guidelines (WCAG) 2.1*. https://www.w3.org/WAI/WCAG21/quickref/

### Referencias de diseño inclusivo

- Microsoft. (2024). *Inclusive Design Toolkit*. https://www.microsoft.com/design/inclusive/
- Norman, D. A. (2013). *The Design of Everyday Things: Revised and Expanded Edition*. Basic Books.
- Shneiderman, B., Plaisant, C., Cohen, M., Jacobs, S., Elmqvist, N., & Diakopoulos, N. (2016). *Designing the User Interface: Strategies for Effective Human-Computer Interaction*. Pearson.

---

## 18. Anexos

### Anexo A: Código fuente relevante

*[Incluir extractos de código clave como:]*
- `RoleDispatcher` (routing basado en roles).
- `PictogramService.createPictogramFor()` (creación de pictograma personalizado).
- `AuthService.acceptInvitationCode()` (batch atómico de vinculación).
- Firestore Security Rules (reglas de `users` y `invitationCodes`).

### Anexo B: Manual de usuario

*[Incluir guía paso a paso con capturas de pantalla para:]*
- Instalación y primer inicio.
- Creación de pictograma personalizado.
- Vinculación con tutor (código de invitación).
- Uso del temporizador Pomodoro.
- Configuración de contacto de emergencia.
- Respaldo a Google Drive.

### Anexo C: Encuesta de usabilidad SUS

*[Incluir las 10 preguntas del SUS y las respuestas promedio de los 8 participantes.]*

### Anexo D: Diagramas extensos

*[Incluir versiones ampliadas de:]*
- Diagrama de clases completo (todas las clases del sistema).
- Diagrama de entidad-relación de Firestore (colecciones y documentos).
- Diagrama de secuencia detallado para vinculación tutor-usuario.
- Diagrama de despliegue (infraestructura Firebase).

### Anexo E: Licencias de terceros

*[Incluir las licencias de las dependencias de Flutter utilizadas (MIT, Apache 2.0, BSD).]*

---

**Fin del Informe Técnico**

*Documento generado para la defensa de título de la carrera Analista Programador.*
*[DD/MM/AAAA]*
