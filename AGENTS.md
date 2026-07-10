# AGENTS.md — Simple (ex-Organízate)

> Flutter + Firebase app for neurodivergent users (TEA/TDAH). 95% complete. Delivery: July 2026 via APK (NOT Play Store/App Store).

---

## Quick Start

```bash
flutter pub get
flutter run
```

**Firebase project:** `organizate-26065`  
**SHA-1 for Google Sign-In:** Already configured in Firebase Console (verify before running)

## Architecture

### Entry Point
- `lib/main.dart` — Initializes Firebase, notifications, PomodoroService, then mounts `AuthGate`
- `lib/core/navigation/auth_gate.dart` — 3-level navigation state machine:
  1. `AuthGate` → Firebase auth check
  2. `_UserOnboardingGate` → Firestore role/onboarding check
  3. `RoleDispatcher` → Routes to `TutorSupervisarScreen` (role='tutor') or `HomeScreen` (role='usuario')

### Feature Modules (`lib/features/`)
| Module | Purpose | Key Files |
|--------|---------|-----------|
| `auth/` | Login, role selection, profile setup | `login_screen.dart`, `role_selection_screen.dart` |
| `tea_board/` | TEA pictogram board (CAA) | `pantalla_paciente_tea.dart`, `pictogram_manager_screen.dart` |
| `tda_focus/` | TDAH tasks, Pomodoro, breathing | `tareas_screen.dart`, `foco_screen.dart`, `progreso_screen.dart` |
| `tutor_dashboard/` | Tutor supervision panel | `home_screen.dart`, `tutor_supervise_screen.dart`, `tutor_patient_detail_screen.dart` |
| `onboarding/` | Super Experto IA, meds, hogar | `super_experto_sheet.dart`, `onboarding_screen.dart` |

### Core Services (`lib/core/services/`)
- `auth_service.dart` — Firebase Auth wrapper
- `pictogram_service.dart` — Pictogram CRUD + Firebase Storage upload
- `notification_service.dart` — Local notifications
- `push_notification_service.dart` — FCM token sync
- `activity_log_service.dart` — User activity tracking
- `tour_service.dart` — Welcome tour state for usuario, home and tutor flows
- `google_drive_service.dart` — Backup/restore
- `reminder_dispatcher.dart` — Task reminders

### Cloud Functions (`functions/`)
- `desglosarTarea` — Gemini AI task breakdown (fallback to local plan)
- `sintetizarVoz` — Google Cloud TTS for pictograms
- `processDueNotifications` — Scheduled notification queue processor

**Deploy:** `cd functions && npm run deploy`  
**Emulate:** `cd functions && npm run serve`

## Firebase Structure

### Firestore Rules (CRITICAL)
- `firestore.rules` — Role-based access control
- Tutor can read/write linked patient data via `linkedTutors/{tutorId}` subcollection
- Patient owns their data; tutor has supervised access
- `invitationCodes` collection for tutor-patient linking

### Collections
```
/users/{userId}
  /tasks/{taskId}
  /progress/{progressId}
  /communications/{commId}
  /pictograms/{pictogramId}
  /activityLog/{logId}
  /pictogramSettings/{settingId}
  /linkedPatients/{patientId}
  /linkedTutors/{tutorId}
  /invitationCodes/{codeId}

/sensitiveData/{patientId}  ← Tutor-only clinical data
/invitationCodes/{code}     ← Global invitation codes
/pictogramTemplates/{templateId}  ← Public pictogram bank
/notificationQueue          ← Collection group for scheduled notifications
```

## Key Conventions

### Role-Based Routing
- **Never** bypass `AuthGate` or `RoleDispatcher`
- Role is stored in Firestore `users/{uid}.role` ('tutor' or 'usuario')
- `RoleDispatcher` uses widget replacement (not Navigator.push) to avoid web history issues

### Pictogram Settings
- `pictogramSettings` subcollection stores per-user overrides (visibility, category)
- Special doc `_features` stores feature flags (`featurePictogramas`, `featureFoco`)
- Tutor can modify these for linked patients

### Activity Log
- Write-only for patient, read-only for tutor
- Never delete activity logs (audit trail)

### Soft Delete for Tasks
- Tasks use `deletedByUser: true` flag instead of hard delete
- Tutor retains history even after patient "deletes"

### Welcome Tours
- Usuario and tutor tours are separate flows; do not reuse user tour copy for tutor screens.
- Home user tour is versioned in `TourService` and explains the bottom navigation plus Perfil/Configuración.
- Tutor tour is anchored in `TutorSupervisarScreen` and persisted with `TourService`.

### Privacy Policy Consent
- `PrivacyPolicyService` centralizes the current policy version (`2026-07-10`), policy text and consent metadata.
- `AuthGate` blocks access until `privacyPolicyAccepted == true` and `privacyPolicyVersion` matches the current version.
- Legal consent evidence is stored under `users/{uid}/legalConsents/{version}` and Firestore Rules allow create/read only for the owner, with no update/delete.

### Documentation Maintenance (REQUIRED)
- **After every significant code change**, update the project records to keep them accurate:
  - `README.md` — overall status, feature checklist and progress
  - `CronologiaDelProyecto.md` — chronology entries, phase progress and current state
  - `VisionDelProyecto.md` — MVP scope, roadmap and pending tasks
  - `AGENTS.md` — project status table and next critical tasks
  - `docs/Informe_Tecnico_Defensa_Titulo.md` — requirements, design and future-work sections
- Do **not** commit documentation-only changes as standalone fixes unless explicitly requested; include them as part of the feature/refactor commit.

## Environment

### Required Files
- `.env` — Contains `GEMINI_API_KEY` (️ **currently exposed in repo — fix this**)
- `android/app/google-services.json` — Firebase config (verify SHA-1 matches)
- `lib/firebase_options.dart` — Auto-generated by FlutterFire CLI

### Firebase Config
```bash
# Regenerate if needed:
flutterfire configure --project=organizate-26065
```

## Testing

**No test suite configured.** `flutter_test` is in dev_dependencies but no tests exist.

## Common Gotchas

1. **SHA-1 mismatch** — Google Sign-In fails if SHA-1 in Firebase Console doesn't match your keystore
2. **IndexedStack + ValueKey** — Tutor dashboard uses this pattern to force rebuild when switching patients
3. **Cloud Functions secrets** — `GEMINI_API_KEY` is a Firebase secret, not env var in production
4. **Notification Queue** — Uses collection group query on `notificationQueue` with composite index (see `firestore.indexes.json`)

## Project Status

| Phase | Status | % |
|-------|--------|---|
| Fundación y Auth | ✅ Done | 100% |
| IA / Súper Experto | ✅ Done | 100% |
| Módulo TEA (Pictogramas) | ✅ Done | 100% |
| Módulo TDAH (Tareas) | ✅ Done | 100% |
| Integración y Correcciones | ✅ Done | 100% |
| Pulido y Testing | 🔄 In Progress | 96% |
| Documentación y Entrega | ⏳ Pending | 30% |

**Next critical tasks:**
- Generate signed APK for delivery
- Final user/manual testing
- Verify Firebase Storage rules and App Check before broader real-user use
- Complete technical report (Informe Técnico)
- User manual

## References

- [README.md](README.md) — Full feature documentation
- [VisionDelProyecto.md](VisionDelProyecto.md) — Project vision and roadmap
- [CronologiaDelProyecto.md](CronologiaDelProyecto.md) — Detailed timeline and sprints
- [Carta Gantt](Carta_Gantt_Organizate_COMPLETO.xlsx) — Visual project timeline
