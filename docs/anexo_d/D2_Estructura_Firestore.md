# D.2 Diagrama de Estructura Firestore

> **Versión ASCII (texto plano)** para copiar en draw.io / Lucidchart  
> **Versión Mermaid** al final para renderizar en GitHub, GitLab, Notion o [Mermaid Live Editor](https://mermaid.live)

---

## D.2.1 Esquema completo de colecciones, documentos y tipos de datos

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FIRESTORE: ESQUEMA DE BASE DE DATOS                       │
└─────────────────────────────────────────────────────────────────────────────┘

[Colección raíz]
users/{userId}                              // Documento principal del usuario
│
├── userId: String                          // UID de Firebase Auth (clave del doc)
├── name: String                            // Nombre de display
├── email: String                           // Correo electrónico
├── role: String                            // Enum: 'tutor' | 'usuario'
├── avatar: String                          // ID del avatar (ej: 'emoticon')
├── photoURL: String?                       // URL de foto de perfil (Storage)
├── points: int                             // Puntos acumulados (gamificación)
├── streak: int                             // Racha de días consecutivos
├── lastStreakDate: Timestamp               // Último día que completó una tarea
├── hasCompletedProfile: bool               // ¿Completó el onboarding de perfil?
├── hasCompletedOnboarding: bool            // ¿Completó el onboarding general?
├── createdAt: Timestamp                    // Fecha de creación de la cuenta
│
├── emergencyName: String?                  // Contacto de emergencia (nombre)
├── emergencyPhone: String?                 // Contacto de emergencia (teléfono)
│
├── notiTaskEnabled: bool                   // Notificaciones de tareas activas
├── notiTaskDefaultOffsetMinutes: int?      // Minutos de anticipación por defecto
│
├── pomodoroSoundEnabled: bool              // Sonido al terminar Pomodoro
├── pomodoroVibrationEnabled: bool          // Vibración al terminar Pomodoro
├── pomodoroSound: String                   // ID del sonido ('bell', 'notificacion1')
│
├── focusSessionsCompleted: int             // Total de sesiones Pomodoro terminadas
├── totalFocusMinutes: int                  // Total de minutos en modo foco
│
├── kioskModeEnabled: bool                  // Modo Kiosk activo (bloqueo de app)
│
│ // ─── Subcolección: Tareas ────────────────────────────────────────────────
│ tasks/{taskId}
│   ├── text: String                        // Descripción de la tarea
│   ├── category: String                    // 'General'|'Estudios'|'Hogar'|'Meds'|'Foco'
│   ├── iconName: String                    // Nombre del icono Material
│   ├── colorName: String                   // Nombre del color temático
│   ├── done: bool                          // ¿Completada?
│   ├── deletedByUser: bool                 // Soft-delete (el usuario la "eliminó")
│   ├── createdAt: Timestamp                // Fecha de creación
│   ├── dueDate: Timestamp?                 // Fecha/hora de vencimiento
│   ├── reminderMinutes: int?               // Minutos de anticipación del recordatorio
│   ├── parentTaskId: String?               // ID de la tarea padre (si es subtarea de IA)
│   ├── generadoPorIA: bool                 // true si fue creada por Súper Experto
│   └── addedByTutor: bool?                 // true si el tutor la agregó
│
│ // ─── Subcolección: Configuración de Pictogramas ──────────────────────────
│ pictogramSettings/{pictoId}
│   ├── categoria: String                   // Override de categoría (ej: 'Mañana')
│   ├── visible: bool                       // ¿Visible en el tablero? (default: true)
│
│ // Doc especial para feature flags ─────────────────────────────────────────
│ pictogramSettings/_features
│   ├── featureInicio: bool                 // Pestaña Inicio visible (default: true)
│   ├── featureTareas: bool                 // Pestaña Tareas visible (default: true)
│   ├── featurePictogramas: bool            // Pestaña Pictogramas (default: false)
│   ├── featureFoco: bool                   // Pestaña Foco visible (default: true)
│   ├── featurePerfil: bool                 // Pestaña Perfil visible (default: true)
│
│ // ─── Subcolección: Pictogramas Personalizados ────────────────────────────
│ pictograms/{pictogramId}
│   ├── imageUrl: String                    // URL de descarga de Firebase Storage
│   ├── etiqueta: String                    // Texto visible en MAYÚSCULAS
│   ├── textoTts: String                    // Texto para síntesis de voz
│   ├── categoria: String                   // Categoría asignada
│   ├── createdAt: Timestamp                // Fecha de creación
│
│ // ─── Subcolección: Log de Actividad ──────────────────────────────────────
│ activityLog/{logId}
│   ├── type: String                        // ActivityType (task_completed, etc.)
│   ├── description: String                 // Descripción legible del evento
│   ├── timestamp: Timestamp                // Fecha/hora del evento
│   ├── metadata: Map<String,dynamic>?      // Datos adicionales (ej: {minutes: 25})
│
│ // ─── Subcolección: Tutores Vinculados ────────────────────────────────────
│ linkedTutors/{tutorId}
│   ├── tutorId: String                     // UID del tutor
│   ├── linkedAt: Timestamp                 // Fecha de vinculación
│   ├── status: String                      // 'active' | 'inactive' (soft-delete)
│
│ // ─── Subcolección: Pacientes Vinculados (solo tutor) ─────────────────────
│ linkedPatients/{patientId}                // Opcional, usado por tutor
│   ├── patientId: String
│   ├── linkedAt: Timestamp
│   ├── status: String
│
│ // ─── Subcolección: Códigos de Invitación del Tutor ───────────────────────
│ invitationCodes/{codeId}                  // Opcional, historial del tutor
│   ├── code: String
│   ├── createdAt: Timestamp
│   ├── status: String
│
└─────────────────────────────────────────────────────────────────────────────┘

[Colección raíz]
invitationCodes/{code}                      // Colección global de códigos
│
├── code: String                            // Código de 6 caracteres (clave del doc)
├── tutorId: String                         // UID del tutor que lo generó
├── tutorName: String                       // Nombre del tutor (para mostrar al usuario)
├── createdAt: Timestamp                    // Fecha de creación
├── status: String                          // 'active' | 'used' | 'deactivated'
├── usedBy: String?                         // UID del usuario que lo usó
├── usedAt: Timestamp?                      // Fecha de uso
├── expiresAt: Timestamp                    // Fecha de expiración (+7 días)
│
└─────────────────────────────────────────────────────────────────────────────┘

[Colección raíz]
pictogramTemplates/{templateId}             // Banco público de pictogramas (futuro)
│
├── svgPath: String
├── etiqueta: String
├── textoTts: String
├── defaultCategoria: String
└─────────────────────────────────────────────────────────────────────────────┘

[Colección raíz]
notificationQueue/{queueId}                 // Cola de notificaciones push (Cloud Fn)
│
├── userId: String
├── taskId: String
├── taskTitle: String
├── scheduledAt: Timestamp
├── status: String                          // 'pending' | 'sent' | 'cancelled'
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## D.2.2 Índices compuestos requeridos

| Colección | Campos indexados | Orden | Propósito |
|-----------|-----------------|-------|-----------|
| `users/{uid}/tasks` | `done` + `deletedByUser` | ascendente | Filtrar tareas pendientes en supervisión del tutor |
| `users/{uid}/tasks` | `createdAt` | descendente | Ordenar tareas por fecha de creación |
| `users/{uid}/activityLog` | `timestamp` | descendente | Log en orden cronológico inverso |
| `users/{uid}/pictograms` | `createdAt` | descendente | Pictogramas personalizados recientes primero |
| `invitationCodes` | `tutorId` + `status` | ascendente | Buscar códigos activos de un tutor |
| `invitationCodes` | `tutorId` + `usedBy` | ascendente | Verificar vinculación tutor-usuario |
| `users/{uid}/pictogramSettings` | — | — | Sin ordenación específica (lookup por ID) |

---

## D.2.3 Reglas de seguridad (resumen)

```
users/{userId}
  → read:  request.auth.uid == userId
           OR isLinkedTutor(userId)
  → write: request.auth.uid == userId

users/{userId}/tasks/{taskId}
  → read/write: isOwner(userId) OR isLinkedTutor(userId)

users/{userId}/activityLog/{logId}
  → read:  isOwner(userId) OR isLinkedTutor(userId)
  → write: isOwner(userId)          // Solo el usuario escribe su propio log

users/{userId}/pictogramSettings/{id}
  → read/write: isOwner(userId) OR isLinkedTutor(userId)

users/{userId}/pictograms/{id}
  → read/write: isOwner(userId) OR isLinkedTutor(userId)

users/{userId}/linkedTutors/{tutorId}
  → read:  isOwner(userId)
  → update: isLinkedTutor(userId) OR isOwner(userId)

invitationCodes/{code}
  → read:  request.auth != null
  → write: resource.data.tutorId == request.auth.uid
```

---

## D.2.4 Versión Mermaid (renderizable)

Copia el siguiente bloque en [Mermaid Live Editor](https://mermaid.live) o en cualquier plataforma que soporte Mermaid (GitHub, GitLab, Notion).

```mermaid
graph TB
    subgraph RootCollections["Colecciones Raíz"]
        A[users/{userId}]
        B[invitationCodes/{code}]
        C[pictogramTemplates/{templateId}]
        D[notificationQueue/{queueId}]
    end

    subgraph UserDoc["Documento users/{userId}"]
        A1[userId: String]
        A2[name: String]
        A3[email: String]
        A4[role: String]
        A5[avatar: String]
        A6[photoURL: String?]
        A7[points: int]
        A8[streak: int]
        A9[lastStreakDate: Timestamp]
        A10[hasCompletedProfile: bool]
        A11[hasCompletedOnboarding: bool]
        A12[createdAt: Timestamp]
        A13[emergencyName: String?]
        A14[emergencyPhone: String?]
        A15[notiTaskEnabled: bool]
        A16[notiTaskDefaultOffsetMinutes: int?]
        A17[pomodoroSoundEnabled: bool]
        A18[pomodoroVibrationEnabled: bool]
        A19[pomodoroSound: String]
        A20[focusSessionsCompleted: int]
        A21[totalFocusMinutes: int]
        A22[kioskModeEnabled: bool]
    end

    subgraph TasksSub["Subcolección: tasks/{taskId}"]
        T1[text: String]
        T2[category: String]
        T3[iconName: String]
        T4[colorName: String]
        T5[done: bool]
        T6[deletedByUser: bool]
        T7[createdAt: Timestamp]
        T8[dueDate: Timestamp?]
        T9[reminderMinutes: int?]
        T10[parentTaskId: String?]
        T11[generadoPorIA: bool]
        T12[addedByTutor: bool?]
    end

    subgraph PictoSettingsSub["Subcolección: pictogramSettings"]
        PS1["pictogramSettings/{pictoId}"]
        PS2[categoria: String]
        PS3[visible: bool]
        PS4["pictogramSettings/_features"]
        PS5[featureInicio: bool]
        PS6[featureTareas: bool]
        PS7[featurePictogramas: bool]
        PS8[featureFoco: bool]
        PS9[featurePerfil: bool]
    end

    subgraph PictogramsSub["Subcolección: pictograms/{pictogramId}"]
        P1[imageUrl: String]
        P2[etiqueta: String]
        P3[textoTts: String]
        P4[categoria: String]
        P5[createdAt: Timestamp]
    end

    subgraph ActivityLogSub["Subcolección: activityLog/{logId}"]
        AL1[type: String]
        AL2[description: String]
        AL3[timestamp: Timestamp]
        AL4[metadata: Map?]
    end

    subgraph LinkedTutorsSub["Subcolección: linkedTutors/{tutorId}"]
        LT1[tutorId: String]
        LT2[linkedAt: Timestamp]
        LT3[status: String]
    end

    subgraph InvitationCodesRoot["Colección invitationCodes/{code}"]
        IC1[code: String]
        IC2[tutorId: String]
        IC3[tutorName: String]
        IC4[createdAt: Timestamp]
        IC5[status: String]
        IC6[usedBy: String?]
        IC7[usedAt: Timestamp?]
        IC8[expiresAt: Timestamp]
    end

    A -->|subcolección| TasksSub
    A -->|subcolección| PictoSettingsSub
    A -->|subcolección| PictogramsSub
    A -->|subcolección| ActivityLogSub
    A -->|subcolección| LinkedTutorsSub

    style RootCollections fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    style UserDoc fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style TasksSub fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style PictoSettingsSub fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    style PictogramsSub fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style ActivityLogSub fill:#e0f2f1,stroke:#00695c,stroke-width:2px
    style LinkedTutorsSub fill:#fff8e1,stroke:#ff8f00,stroke-width:2px
    style InvitationCodesRoot fill:#f1f8e9,stroke:#558b2f,stroke-width:2px
```

**Nota sobre Mermaid:** Este diagrama usa `graph TB` (top-bottom) para representar la jerarquía de colecciones → documentos → subcolecciones. Los colores diferencian cada grupo de datos. Si el renderizador no soporta `style`, el diagrama seguirá siendo legible sin colores.

---

*Fin del Anexo D.2 — Estructura Firestore*
