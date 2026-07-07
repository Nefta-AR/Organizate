# Anexo D: Diagramas Extensos del Sistema Organízate (Simple)

---

## D.1 Diagrama de Clases Completo

El siguiente diagrama abarca **todas las clases, modelos, servicios, pantallas y widgets** del sistema Organízate, con sus atributos principales, métodos públicos y relaciones de herencia/composición.

### D.1.1 Convenciones del diagrama

| Símbolo | Significado |
|---------|-------------|
| `+` | Atributo o método público |
| `-` | Atributo o método privado |
| `→` | Asociación (usa/referencia) |
| `◆─` | Composición (el componente no existe sin el contenedor) |
| `◇─` | Agregación (el componente puede existir independientemente) |
| `▷─` | Herencia/Extensión |

---

### D.1.2 Modelos de Datos (Capa de Dominio)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          MODELOS DE DATOS                                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────┐
│      <<model>>              │
│   PictogramaPersonalizado   │
├─────────────────────────────┤
│ + id: String                │
│ + imageUrl: String          │
│ + etiqueta: String          │
│ + textoTts: String          │
│ + categoria: String         │
│ + createdAt: DateTime       │
├─────────────────────────────┤
│ + fromFirestore(doc):       │
│   PictogramaPersonalizado   │
│ + toMap(): Map<String,dyn>  │
└─────────────────────────────┘
            △
            │ (factory desde DocumentSnapshot)
            │
┌─────────────────────────────┐
│      <<model>>              │
│       Pictograma            │
├─────────────────────────────┤
│ + id: String                │
│ + rutaSvg: String           │
│ + etiqueta: String          │
│ + textoTts: String          │
│ + categoria: String         │
└─────────────────────────────┘

┌─────────────────────────────┐
│      <<model>>              │
│    PictogramaDisplay        │
├─────────────────────────────┤
│ + id: String                │
│ + rutaSvg: String?          │
│ + imageUrl: String?         │
│ + etiqueta: String          │
│ + textoTts: String          │
│ + categoria: String         │
│ + esPersonalizado: bool     │
├─────────────────────────────┤
│ + fromLocal(p): Display     │
│ + fromCustom(p): Display    │
└─────────────────────────────┘
            △
            │ (Adapter Pattern)
    ┌───────┴───────┐
    │               │
┌───┴───┐      ┌────┴────────┐
│Picto  │      │Pictograma   │
│Entry  │      │Personalizado│
└───────┘      └─────────────┘

┌─────────────────────────────┐
│      <<model>>              │
│       PictoEntry            │
├─────────────────────────────┤
│ + id: String                │
│ + svgPath: String?          │
│ + imageUrl: String?         │
│ + etiqueta: String          │
│ + defaultCategoria: String  │
│ + esPersonalizado: bool     │
└─────────────────────────────┘

┌─────────────────────────────┐
│      <<model>>              │
│      AvatarOption           │
├─────────────────────────────┤
│ + name: String              │
│ + imagePath: String         │
│ + color: Color              │
└─────────────────────────────┘

┌─────────────────────────────┐
│      <<enum>>               │
│        UserRole             │
├─────────────────────────────┤
│ tutor                       │
│ usuario                     │
└─────────────────────────────┘

┌─────────────────────────────┐
│      <<enum>>               │
│     PomodoroStatus          │
├─────────────────────────────┤
│ idle                        │
│ running                     │
│ paused                      │
│ finished                    │
└─────────────────────────────┘

┌─────────────────────────────┐
│      <<enum>>               │
│       NavScreen             │
├─────────────────────────────┤
│ inicio                      │
│ tareas                      │
│ pictogramas                 │
│ foco                        │
│ perfil                      │
└─────────────────────────────┘

┌─────────────────────────────┐
│    <<constants>>            │
│      ActivityType           │
├─────────────────────────────┤
│ + taskCompleted: String     │
│ + taskCreated: String       │
│ + taskDeleted: String       │
│ + pictogramCreated: String  │
│ + pictogramDeleted: String  │
│ + pictogramUsed: String     │
│ + pomodoroCompleted: String │
└─────────────────────────────┘

┌─────────────────────────────┐
│      <<DTO>>                │
│   NotificationTestResult    │
├─────────────────────────────┤
│ + notificationSent: bool    │
│ + previewSoundPlayed: bool  │
│ + failure: Failure?         │
│ + errorDescription: String? │
│ + usedFallbackSound: bool   │
└─────────────────────────────┘

┌─────────────────────────────┐
│      <<DTO>>                │
│     DriveBackupStatus       │
├─────────────────────────────┤
│ + success: bool             │
│ + message: String           │
│ + timestamp: DateTime?      │
│ + filesUploaded: int?       │
└─────────────────────────────┘

┌─────────────────────────────┐
│      <<DTO>>                │
│    DriveRestoreResult       │
├─────────────────────────────┤
│ + success: bool             │
│ + message: String           │
│ + cloudIsNewer: bool        │
│ + restoredFiles: List<String│
└─────────────────────────────┘
```

---

### D.1.3 Servicios de Aplicación (Capa de Negocio)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SERVICIOS DE APLICACIÓN                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│      AuthService            │
├─────────────────────────────┤
│ - _auth: FirebaseAuth       │
│ - _firestore: Firestore     │
│ - _googleSignIn: GoogleSignIn│
├─────────────────────────────┤
│ + authStateChanges: Stream  │
│ + currentUser: User?        │
│ + registerWithEmail(...)    │
│ + loginWithEmail(...)       │
│ + loginWithGoogle(): Future │
│ + getUserRole(): Future     │
│ + getUserRoleStream(): Strm │
│ + setRole(role): Future     │
│ + generateInvitationCode()  │
│ + validateInvitationCode()  │
│ + acceptInvitationCode()    │
│ + removePatientLink()       │
│ + getLinkedPatientsStream() │
│ + getLinkedTutorStream()    │
│ + logout(): Future          │
└─────────────────────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│   ActivityLogService        │
├─────────────────────────────┤
│ - _firestore: Firestore     │
│ - _auth: FirebaseAuth       │
├─────────────────────────────┤
│ + log({userId,type,desc,   │
│   metadata}): Future        │
│ + getStream(userId): Stream │
│   <List<Map>>               │
└─────────────────────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│     AudioService            │
│    (Singleton)              │
├─────────────────────────────┤
│ - _player: AudioPlayer      │
│ - _cache: Map<String,String>│
│ - _isPlaying: bool          │
│ - _onPlayingChanged: Func?  │
├─────────────────────────────┤
│ + instance: AudioService    │
│ + isPlaying: bool           │
│ + setOnPlayingChanged(fn)   │
│ + playText(text,vozId): Fut │
│ + stop(): Future            │
│ + clearCache(): Future      │
│ + getCacheSize(): Future<int│
│ + dispose()                 │
│ - _hashText(text): String   │
│ - _fetchFromCloud(text): Fut│
│ - _playFile(path): Future   │
└─────────────────────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│  NotificationService        │
├─────────────────────────────┤
│ - _plugin: FlutterLocal...  │
│ - _initialized: bool        │
│ - _tzInitialized: bool      │
│ - _pomodoroNotificationId   │
│ - _channel: AndroidNotif... │
├─────────────────────────────┤
│ + init(): Future            │
│ + ensureDeviceCanDeliver()  │
│ + requestPermissions(): Fut │
│ + showInstantNotification() │
│ + showTestNotification():   │
│   NotificationTestResult    │
│ + showPomodoroFinished()    │
│ + schedulePomodoroNotif(dt) │
│ + cancelPomodoroNotif()     │
│ + scheduleReminderIfNeeded()│
│ + cancelTaskNotification()  │
│ - _defaultDetails(): Notif..│
│ - _configureLocalTimezone() │
│ - _arePermissionsGranted()  │
│ - _hasExactAlarmPermission()│
└─────────────────────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│    PictogramService         │
├─────────────────────────────┤
│ - _storage: FirebaseStorage │
│ - _firestore: Firestore     │
│ - _auth: FirebaseAuth       │
│ - _picker: ImagePicker      │
├─────────────────────────────┤
│ + getCustomPictogramsStream()│
│ + getCustomPictogramsStreamFor()│
│ + getPictogramSettingsStrm()│
│ + updatePictogramSettingFor()│
│ + createPictogramFor(...)   │
│ + createPictogram(...)      │
│ + deletePictogramFor(...)   │
│ + deletePictogram(...)      │
│ + pickImageFromCamera()     │
│ + pickImageFromGallery()    │
│ + cropImage(...): Cropped?  │
│ + uploadImage(...): String  │
│ + uploadImageFor(...): Str  │
│ + captureAndCreate(): Picto?│
└─────────────────────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│   ReminderDispatcher        │
├─────────────────────────────┤
├─────────────────────────────┤
│ + scheduleTaskReminder(...) │
│ + cancelTaskReminder(...)   │
│ + normalizeReminderMinutes()│
└─────────────────────────────┘
            ◇
            │ (usa)
    ┌───────┴───────┐
    │               │
┌───┴───┐      ┌────┴────────┐
│Notif. │      │PushNotif.   │
│Service│      │Service      │
└───────┘      └─────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│ PushNotificationService     │
├─────────────────────────────┤
│ + queueRemoteReminder(...)  │
│ + cancelRemoteReminder(...) │
└─────────────────────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│      UserPrefs              │
├─────────────────────────────┤
│ - _kName: String            │
├─────────────────────────────┤
│ + setName(name): Future     │
│ + getName(): Future<String?>│
│ + clearName(): Future       │
└─────────────────────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│   GoogleDriveService        │
│    (Singleton)              │
├─────────────────────────────┤
│ - _cachedAccount: GoogleAcct│
│ - _driveApi: DriveApi?      │
│ - _backupFolderName: String │
│ - _settingsFileName: String │
│ - _pictogramsSubfolder: Str │
│ - _lastSyncKey: String      │
├─────────────────────────────┤
│ + instance: GoogleDriveSvc  │
│ + backupToDrive():          │
│   DriveBackupStatus         │
│ + restoreFromDrive():       │
│   DriveRestoreResult        │
│ + getLastSyncTime(): Future │
│ + isCloudNewerThanLocal()   │
│ + signOut()                 │
│ - _ensureSignedIn(): Future │
│ - _getOrCreateBackupFolder()│
│ - _collectSettings(): Map   │
│ - _applySettings(map): Fut  │
│ - _getLocalPictogramFiles() │
│ - _getLocalPictogramsDir()  │
│ - _collectBytes(stream): Fut│
└─────────────────────────────┘
            ◇
            │ (usa)
    ┌───────┴───────┐
    │               │
┌───┴───┐      ┌────┴────────┐
│Google │      │GoogleAuth   │
│SignIn │      │HttpClient   │
└───────┘      └─────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│       IAService             │
├─────────────────────────────┤
│ - _functions: FirebaseFunc  │
├─────────────────────────────┤
│ + desglosarEnPasos({        │
│   tarea,tiempoDisponible}): │
│   Future<List<Map>>         │
│ - _mapFirebaseError(e): Str │
│ - _mapGenericError(e): Str  │
└─────────────────────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│     StreakService           │
├─────────────────────────────┤
├─────────────────────────────┤
│ + updateStreakOnTaskComp()  │
│ - _computeNewStreak(...):int│
│ - _stripTime(date): DateTime│
└─────────────────────────────┘

┌─────────────────────────────┐
│   <<service>>               │
│    PomodoroService          │
│   (ChangeNotifier)          │
├─────────────────────────────┤
│ + totalDuration: Duration   │
│ + remaining: Duration       │
│ + status: PomodoroStatus    │
│ - _ticker: Timer?           │
│ - _endTime: DateTime?       │
├─────────────────────────────┤
│ + start(duration): Future   │
│ + pause(): Future           │
│ + resume(): Future          │
│ + cancel(): Future          │
│ - _tick(): Future           │
│ - _persistState(): Future   │
│ - _restoreState(): Future   │
│ - _scheduleSystemNotif()    │
│ - _cancelNotificationSafely()│
└─────────────────────────────┘
```

---

### D.1.4 Pantallas y Widgets (Capa de Presentación)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      PANTALLAS (SCREENS)                                     │
└─────────────────────────────────────────────────────────────────────────────┘

<<screen>> AuthGate (StatelessWidget)
  → StreamBuilder<User?> (authStateChanges)
    → StreamBuilder<UserRole?> (getUserRoleStream)
      → RoleDispatcher
        → PantallaUsuarioTEA | HomeScreen | RoleSelectionScreen

<<screen>> LoginScreen (StatefulWidget)
  - _formKey: GlobalKey<FormState>
  - _emailController: TextEditingController
  - _passwordController: TextEditingController
  - _nameController: TextEditingController
  - _isLogin, _isLoading, _isGoogleLoading, _obscurePassword: bool
  + _handleLogin(): Future
  + _handleGoogleLogin(): Future
  + _handleForgotPassword(): Future
  + _buildInput(...): Widget
  + _mapAuthError(code): String

<<screen>> RoleSelectionScreen (StatefulWidget)
  - _loadingRole: String?
  + _selectRole(role): Future
  → _RoleCard (private widget)

<<screen>> ProfileSetupScreen (StatefulWidget)
  - _avatars: List<String>
  - _nameCtrl: TextEditingController
  - _selectedAvatar: String?
  - _saving: bool
  + _save(): Future

<<screen>> HomeScreen (StatefulWidget)
  - _motivationalPhrases: List<String>
  - _dateTimeFormatter: DateFormat
  + _buildAppBar(): AppBar
  + _buildBody(): Widget
  + _buildGreeting(name): Widget
  + _buildPriorityTaskCard(): Widget
  + _buildEmptyPriorityCard(): Widget
  + _buildTaskCard(...): Widget
  + _buildQuickAccess(): Widget
  + _toggleTaskCompletion(...): Future
  + _showTaskOptionsDialog(...): void
  + _showEditTaskDialog(...): void

<<screen>> PantallaUsuarioTEA (StatefulWidget)
  - _tts: FlutterTts
  - _localOverrides: Map<String,String>
  - _pictoSettings: Map<String,Map>
  - _settingsSub: StreamSubscription?
  - _userSub: StreamSubscription?
  - _emergencyName, _emergencyPhone: String?
  - _transicionNotificada: bool
  - _pictogramasStream: Stream?
  + _initTts(): Future
  + _buildPictogramasStream(): Stream
  + _crearPictograma(): Future
  + _abrirManager(): void
  + _hablar(texto): Future
  + _hablarPictograma(picto): void
  + _editarTexto(picto): Future
  + _showSosDialog(): Future
  + _catHoraria: String
  + _nombreRutina: String
  + _iconoRutina: IconData
  + _siguienteActividad: String
  + _filtrarPorCategoria(todos,cat): List
  + _onTransicionCercana(): void
  + _resetTransicionFlag(): void
  + _buildAyudaRow(colors): Widget
  → ContadorTransicion (StatefulWidget)
  → _GridCategoriaDisplay (StatefulWidget)
  → _TarjetaPictogramaDisplay (StatefulWidget)

<<screen>> TareasScreen (StatefulWidget)
  → StreamBuilder<QuerySnapshot>
    → Lista de tareas con categorías, fechas, checkboxes
    → FAB para agregar tarea

<<screen>> FocoScreen (StatefulWidget)
  → Provider<PomodoroService>
    → Timer visual circular
    → Botones Start/Pause/Resume/Cancel
    → Configuración de sonido/vibración

<<screen>> SettingsScreen (StatefulWidget)
  - _userDoc: DocumentReference
  - _emergencyNameController: TextEditingController
  - _emergencyPhoneController: TextEditingController
  - _isEmergencyDirty: bool
  - _isSavingEmergency: bool
  - _isUploadingPhoto: bool
  - _isBackingUp: bool
  - _backupProgress: double?
  - _lastSync: DateTime?
  + _handleLogout(): Future
  + _saveEmergencyContact(): Future
  + _uploadProfilePhoto(): Future
  + _showPhotoOptions(current): Future
  + _showAvatarPicker(current): Future
  + _resolveAvatar(photoUrl,avatar): ImageProvider?
  + _editDisplayName(current): Future
  + _showRoleChangeConfirmation(): Future
  + _buildProfileRoleCard(...): Widget
  + _buildVinculacionCard(): Widget
  + _buildVinculacionUsuarioCard(): Widget
  + _buildPantallasNavTile(): Widget
  + _buildEmergencyCard(): Widget
  + _buildNotificacionesCard(...): Widget
  + _buildFocoCard(...): Widget
  + _buildBackupCard(): Widget
  + _buildLogoutCard(): Widget
  + _handleBackup(): Future
  + _handleRestore(): Future
  + _formatSyncDate(date): String

<<screen>> TutorSupervisarScreen (StatefulWidget)
  - _currentIndex: int
  - _patients: List<Map>
  - _selectedPatient: Map?
  - _loading: bool
  - _patientsSub: StreamSubscription
  + _patientId: String
  + _patientName: String
  + _patientAvatar: String?
  + _switchPatient(patient): void
  + _showPatientPicker(): void
  + _buildAppBar(): AppBar
  + _buildNoPatients(): Widget
  → _TutorTasksTab (StatefulWidget)
  → _TutorPictogramsTab (StatelessWidget)
  → ProgresoScreen (StatefulWidget)
  → _TutorHistorialTab (StatelessWidget)
  → _TutorConfigTab (StatefulWidget)

<<screen>> TutorVinculacionScreen (StatefulWidget)
  - _isGenerating: bool
  - _currentCode: String?
  + _generateCode(): Future
  + _copyCode(code): void
  + _removePatient(patientId,name): Future
  + _buildGenerateCodeCard(): Widget
  + _buildCodeDisplayCard(code): Widget
  + _buildLinkedPatientsList(): Widget
  + _buildPatientTile(...): Widget
  + _formatDate(date): String

<<screen>> VinculacionTutorScreen (StatefulWidget)
  - _codeController: TextEditingController
  - _isValidating: bool
  - _isAccepting: bool
  - _validationResult: Map?
  - _isLinked: bool
  + _checkIfAlreadyLinked(): Future
  + _validateCode(): Future
  + _acceptCode(): Future
  + _buildAlreadyLinkedView(): Widget
  + _buildInfoCard(): Widget
  + _buildCodeInputCard(): Widget
  + _buildValidationSuccessCard(): Widget
  + _buildHowItWorksCard(): Widget
  + _buildStep(...): Widget

<<screen>> PictogramManagerScreen (StatefulWidget)
  - _settings: Map<String,Map>
  - _loadingSettings: bool
  - _customs: List<PictogramaPersonalizado>
  - _loadingCustoms: bool
  - _filterCat: String?
  + _efectiva(id,defaultCat): String
  + _visible(id): bool
  + _setCategoria(id,newCat): Future
  + _toggleVisible(id): Future
  + _allEntries: List<PictoEntry>
  + _filtered: List<PictoEntry>
  + _buildFilterBar(): Widget
  + _buildLegend(): Widget
  + _buildGrid(): Widget
  + _showCategoryPicker(entry): void
  + _resetAll(): Future
  → _PictoManagerCard (StatelessWidget)

<<screen>> SuperExpertoSheet (StatefulWidget)
  - _tareaId: String?
  - _tareaTexto: String?
  - _tiempo: String
  - _cargando: bool
  - _error: String?
  - _pasos: List<Map<String,String>>?
  - _guardando: bool
  - _guardadoExito: bool
  + _generarPlan(): Future
  + _guardarSubtareas(): Future
  + _buildHeader(): Widget
  + _buildSelectorTarea(): Widget
  + _buildSelectorTiempo(): Widget
  + _buildBotonGenerar(): Widget
  + _buildCargando(): Widget
  + _buildError(): Widget
  + _buildResultado(): Widget
  + _buildPasoItem(num,paso): Widget

<<screen>> OnboardingScreen (StatefulWidget)
  → Páginas de onboarding: Estudios, Hogar, Meds, FeatureTour

<<screen>> ProgresoScreen (StatefulWidget)
  → Gráficos de uso: tareas completadas, sesiones Pomodoro, racha
```

---

### D.1.5 Widgets Reutilizables y de Soporte

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WIDGETS REUTILIZABLES                                     │
└─────────────────────────────────────────────────────────────────────────────┘

<<widget>> CustomNavBar (StatefulWidget)
  - _currentScreen: NavScreen
  - _featureInicio: bool
  - _featureTareas: bool
  - _featurePictogramas: bool
  - _featureFoco: bool
  - _featurePerfil: bool
  - _featuresSub: StreamSubscription?
  + _entries: List<_NavEntry>
  + _indexOf(screen,entries): int
  + _onItemTapped(index): void
  + _listenSettings(): void
  → BottomNavigationBar

<<widget>> _GridCategoriaDisplay (StatefulWidget)
  + pictogramas: List<PictogramaDisplay>
  + onTap: Function(PictogramaDisplay)
  + onLongPress: Function(PictogramaDisplay)
  + nombreRutina: String?
  + iconoRutina: IconData?
  + wantKeepAlive = true

<<widget>> _TarjetaPictogramaDisplay (StatefulWidget)
  + pictograma: PictogramaDisplay
  + onTap: VoidCallback?
  + onLongPress: VoidCallback?
  - _pressController: AnimationController
  - _scaleAnimation: Animation<double>
  - _progressTimer: Timer?
  - _isLongPressing: bool
  - _longPressProgress: double
  + _buildImagen(colors): Widget

<<widget>> _PictoManagerCard (StatelessWidget)
  + entry: PictoEntry
  + settings: Map<String,dynamic>
  + categoriaEfectiva: String
  + isVisible: bool
  + onCategoryTap: VoidCallback
  + onToggleVisible: VoidCallback

<<widget>> _RoleCard (StatelessWidget)
  + role: String
  + label: String
  + description: String
  + icon: IconData
  + cardColor: Color
  + accentColor: Color
  + isLoading: bool
  + isDisabled: bool
  + onTap: VoidCallback

<<widget>> ContadorTransicion (StatefulWidget)
  + onTransicionCercana: VoidCallback
  + onReset: VoidCallback
  + siguienteActividad: String
  - _pulseController: AnimationController
  - _pulseAnimation: Animation<double>
  - _tickTimer: Timer?
  - _estadoActual: _EstadoUrgencia
  + _minutosRestantes(): double
  + _progreso(): double
  + _colorArco(colors): Color
  + _buildArc(...): Widget

<<widget>> _FeatureToggleTile (StatelessWidget)
  + icon: IconData
  + color: Color
  + title: String
  + subtitle: String
  + value: bool
  + onChanged: ValueChanged<bool>?

<<widget>> _StatChip (StatelessWidget)
  + icon: IconData
  + color: Color
  + label: String
  + sub: String

<<widget>> _SupervisionTaskTile (StatelessWidget)
  + doc: QueryDocumentSnapshot
  + onToggle: VoidCallback
  + onDelete: VoidCallback

<<widget>> _SupervisionPictoCard (StatelessWidget)
  + picto: PictogramaPersonalizado
  + onDelete: VoidCallback

<<widget>> _TutorTasksTab (StatefulWidget)
  + patientId: String
  + patientName: String
  - _tasksRef: CollectionReference
  + _toggleDone(taskId,current): Future
  + _deleteTask(taskId): Future
  + _addTask(): Future
  + _sectionHeader(label,color): Widget

<<widget>> _TutorPictogramsTab (StatelessWidget)
  + patientId: String
  + patientName: String
  - _builtins: List<_BuiltinPicto>
  + _showAddSheet(context): Future
  + _openManager(context): void

<<widget>> _TutorHistorialTab (StatelessWidget)
  + patientId: String
  - _icon(type): IconData
  - _color(type): Color
  - _label(type): String
  → _StatsCard

<<widget>> _TutorConfigTab (StatefulWidget)
  + patientId: String
  + patientName: String
  - _featureInicio..Perfil: bool?
  - _emergencyNameCtrl: TextEditingController
  - _emergencyPhoneCtrl: TextEditingController
  - _emergencyDirty: bool
  - _emergencySaving: bool
  + _toggle(field,current): Future
  + _saveEmergency(): Future

<<widget>> _StatsCard (StatelessWidget)
  + patientId: String
  → StreamBuilder<DocumentSnapshot>
    → _StatChip x4 (sesiones, minutos, racha, puntos)
```

---

## D.2 Diagrama de Estructura Firestore

### D.2.1 Esquema completo de colecciones, documentos y tipos de datos

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

### D.2.2 Índices compuestos requeridos

| Colección | Campos indexados | Orden | Propósito |
|-----------|-----------------|-------|-----------|
| `users/{uid}/tasks` | `done` + `deletedByUser` | ascendente | Filtrar tareas pendientes en supervisión del tutor |
| `users/{uid}/tasks` | `createdAt` | descendente | Ordenar tareas por fecha de creación |
| `users/{uid}/activityLog` | `timestamp` | descendente | Log en orden cronológico inverso |
| `users/{uid}/pictograms` | `createdAt` | descendente | Pictogramas personalizados recientes primero |
| `invitationCodes` | `tutorId` + `status` | ascendente | Buscar códigos activos de un tutor |
| `invitationCodes` | `tutorId` + `usedBy` | ascendente | Verificar vinculación tutor-usuario |
| `users/{uid}/pictogramSettings` | — | — | Sin ordenación específica (lookup por ID) |

### D.2.3 Reglas de seguridad (resumen)

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

## D.3 Diagrama de Secuencia: Vinculación Tutor-Usuario

### D.3.1 Secuencia detallada del flujo completo

```
┌──────────┐   ┌──────────┐   ┌────────────┐   ┌────────────┐   ┌────────────┐
│  Tutor   │   │  Flutter │   │   Firebase │   │  Firebase  │   │   Google   │
│ (Persona)│   │   App    │   │   Auth     │   │  Firestore │   │   Cloud    │
│          │   │          │   │            │   │            │   │ Functions  │
└────┬─────┘   └────┬─────┘   └─────┬──────┘   └─────┬──────┘   └─────┬──────┘
     │              │               │                │                │

[PHASE 1: GENERACIÓN DEL CÓDIGO DE INVITACIÓN]

     │              │               │                │                │
     │──"Generar───▶│               │                │                │
     │  código"     │               │                │                │
     │              │──onPressed───▶│                │                │
     │              │ _generateCode()│                │                │
     │              │               │                │                │
     │              │──POST /generate│                │                │
     │              │  (HTTPS Callable)               │                │
     │              │               │────────────────▶│                │
     │              │               │  Invoca         │                │
     │              │               │  desglosarTarea │                │
     │              │               │  (no, es AuthService)
     │              │               │                │                │
     │              │               │──Verifica rol──▶│                │
     │              │               │  tutor?         │                │
     │              │               │◀───rol=tutor────│                │
     │              │               │                │                │
     │              │               │──Genera código──▶│               │
     │              │               │  (6 chars)      │                │
     │              │               │                │                │
     │              │               │──Crea doc───────▶│                │
     │              │               │  invitationCodes│                │
     │              │               │  /{code}        │                │
     │              │               │                │                │
     │              │◀──────────────│  Retorna código │                │
     │              │               │                │                │
     │◀─────────────│  Muestra código│               │                │
     │              │  + Snackbar OK │                │                │
     │              │               │                │                │

[PHASE 2: COMPARTIR CÓDIGO (OUT-OF-BAND)]

     │──"Comparte──▶│               │                │                │
     │  código"     │               │                │                │
     │  (WhatsApp,   │               │                │                │
     │   email, voz) │               │                │                │
     │              │               │                │                │

[PHASE 3: VALIDACIÓN DEL CÓDIGO POR EL USUARIO]

     │              │               │                │                │
     │              │   ┌───────────┘                │                │
     │              │   │  Usuario ingresa código    │                │
     │              │   │  en VinculacionTutorScreen │                │
     │              │   │                            │                │
     │              │   │──_validateCode()──────────▶│                │
     │              │   │  AuthService.validateCode()│                │
     │              │   │                            │                │
     │              │   │──GET invitationCodes/{code}│                │
     │              │   │                            │                │
     │              │   │◀──Doc existe───────────────│                │
     │              │   │  status='active'           │                │
     │              │   │  expiresAt > now           │                │
     │              │   │                            │                │
     │              │   │◀──Retorna tutorId,         │                │
     │              │   │  tutorName                 │                │
     │              │   │                            │                │
     │              │   │──Muestra card de éxito────▶│                │
     │              │   │  "Código válido.           │                │
     │              │   │   Tutor: [Nombre]"         │                │
     │              │   │                            │                │

[PHASE 4: ACEPTACIÓN Y VINCULACIÓN BIDIRECCIONAL]

     │              │   │                            │                │
     │              │   │──"Aceptar y vincularme"───▶│                │
     │              │   │  _acceptCode()             │                │
     │              │   │                            │                │
     │              │   │──Batch atómico────────────▶│                │
     │              │   │  (transacción Firestore)   │                │
     │              │   │                            │                │
     │              │   │  [Dentro del batch]:       │                │
     │              │   │  1. Update invitationCodes │                │
     │              │   │     /{code}                │                │
     │              │   │     status → 'used'        │                │
     │              │   │     usedBy → user.uid      │                │
     │              │   │     usedAt → serverTimestamp│               │
     │              │   │                            │                │
     │              │   │  2. Set users/{user.uid}   │                │
     │              │   │     /linkedTutors/{tutorId}│                │
     │              │   │     tutorId, linkedAt,     │                │
     │              │   │     status='active'        │                │
     │              │   │                            │                │
     │              │   │  3. Set users/{user.uid}   │                │
     │              │   │     acceptedInvitationCode │                │
     │              │   │     → {code}               │                │
     │              │   │                            │                │
     │              │   │◀──Batch commit OK──────────│                │
     │              │   │                            │                │
     │              │   │──Snackbar éxito───────────▶│                │
     │              │   │  "¡Vinculado con éxito!"   │                │
     │              │   │                            │                │

[PHASE 5: SINCRONIZACIÓN EN TIEMPO REAL]

     │              │   │                            │                │
     │              │   │  [Firestore emite snapshot]│                │
     │              │   │  a todos los listeners:    │                │
     │              │   │                            │                │
     │              │◀──│  StreamBuilder en          │                │
     │              │   │  TutorVinculacionScreen    │                │
     │              │   │  recibe nuevo paciente     │                │
     │              │   │                            │                │
     │◀─────────────│   │  Lista actualizada de      │                │
     │  "Nuevo      │   │  pacientes vinculados"     │                │
│  usuario"      │   │                            │                │
     │              │   │                            │                │
     │              │   │◀──StreamBuilder en         │                │
     │              │   │  SettingsScreen            │                │
     │              │   │  recibe tutor vinculado    │                │
     │              │   │                            │                │
     │              │   │──UI actualizada───────────▶│                │
     │              │   │  "Tutor vinculado: [Name]" │                │
     │              │   │                            │                │

[PHASE 6: SUPERVISIÓN (POST-VINCULACIÓN)]

     │──"Abre panel──│               │                │                │
     │  de tutor"   │               │                │                │
     │              │──Navega a─────▶│                │                │
     │              │ TutorSupervisar│                │                │
     │              │               │                │                │
     │              │──GET linkedTutors/{tutorId}────▶│               │
     │              │  (reglas: tutor puede leer)     │               │
     │              │               │                │                │
     │              │◀───Datos del usuario────────────│                │
     │              │   (tareas, pictogramas, log)    │                │
     │              │   (solo si status='active')     │                │
     │              │               │                │                │
     │◀─────────────│  Muestra tabs: Tareas,         │                │
     │              │  Pictogramas, Progreso,         │                │
     │              │  Historial, Ajustes             │                │
     │              │               │                │                │
```

---

## D.4 Diagrama de Despliegue (Infraestructura Firebase)

### D.4.1 Arquitectura de despliegue completa

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DISPOSITIVO MÓVIL (Cliente)                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Aplicación Flutter (Android / iOS)                                  │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │   │
│  │  │   Auth      │  │   Firestore │  │   Storage   │  │  Functions │ │   │
│  │  │   SDK       │  │   SDK       │  │   SDK       │  │  (HTTPS)   │ │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─────┬──────┘ │   │
│  │         │                │                │               │        │   │
│  │  ┌──────┴────────────────┴────────────────┴───────────────┘        │   │
│  │  │                    Servicios de Aplicación                       │   │
│  │  │  (AuthService, PictogramService, NotificationService, etc.)      │   │
│  │  └─────────────────────────────────────────────────────────────────┘   │   │
│  │         │                                                             │   │
│  │  ┌──────┴──────────────────────────────────────────────────────────┐  │   │
│  │  │                    Capa de Presentación (UI)                     │  │   │
│  │  │  (Screens, Widgets, Animations, State Management)                │  │   │
│  │  └──────────────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                    │                    │                         │
│         │ HTTPS / gRPC       │ HTTPS / WebSocket  │ HTTPS                   │
│         │                    │                    │                         │
└─────────┼────────────────────┼────────────────────┼─────────────────────────┘
          │                    │                    │
          ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BACKEND (Firebase/Google Cloud)                      │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  FIREBASE AUTHENTICATION                                             │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │  • Email/Password (Firebase Auth)                              │    │    │
│  │  │  • Google Sign-In (OAuth 2.0)                                  │    │    │
│  │  │  • Anonymous Auth (para onboarding sin registro)               │    │    │
│  │  │  • Custom Claims (roles: tutor | usuario)                      │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  CLOUD FIRESTORE (NoSQL Documental)                                  │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │  Region: us-central1 (o la más cercana al usuario)           │    │    │
│  │  │  Modo: Native (no Datastore mode)                            │    │    │
│  │  │  Colecciones: users, invitationCodes, notificationQueue      │    │    │
│  │  │  Subcolecciones: tasks, pictograms, pictogramSettings,       │    │    │
│  │  │                  activityLog, linkedTutors, linkedPatients   │    │    │
│  │  │  Índices: Compuestos para queries de tutor y ordenación      │    │    │
│  │  │  Reglas: RBAC basado en roles y vinculación                  │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  FIREBASE STORAGE (Objetos)                                          │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │  Bucket: [project-id].appspot.com                             │    │    │
│  │  │  Path: users/{uid}/pictograms/{filename}.jpg                  │    │    │
│  │  │  Rules: Lectura por usuario autenticado                       │    │    │
│  │  │         Escritura por owner o linkedTutor                     │    │    │
│  │  │  Metadata: uploadedBy, createdAt (auditoría)                  │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  FIREBASE CLOUD FUNCTIONS (Node.js 18)                               │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │  Function: desglosarTarea                                     │    │    │
│  │  │  Trigger: HTTPS Callable                                      │    │    │
│  │  │  Runtime: Node.js 18                                          │    │    │
│  │  │  Memoria: 256MB                                               │    │    │
│  │  │  Timeout: 10s                                                 │    │    │
│  │  │  Dependencias: Google Generative AI (Gemini)                  │    │    │
│  │  │  Input: {tarea, tiempoDisponible}                             │    │    │
│  │  │  Output: [{titulo, tiempo_estimado}]                          │    │    │
│  │  │                                                               │    │    │
│  │  │  Function: sintetizarVoz                                      │    │    │
│  │  │  Trigger: HTTPS Callable                                      │    │    │
│  │  │  Dependencias: Google Cloud Text-to-Speech API                │    │    │
│  │  │  Input: {texto, vozId}                                        │    │    │
│  │  │  Output: {audioContent: base64}                               │    │    │
│  │  │                                                               │    │    │
│  │  │  Function: processDueNotifications                            │    │    │
│  │  │  Trigger: Cloud Scheduler (cron cada 1 minuto)                │    │    │
│  │  │  Dependencias: Firebase Admin SDK, FCM                        │    │    │
│  │  │  Acción: Procesa notificationQueue y envía FCM                │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  FIREBASE CLOUD MESSAGING (FCM)                                      │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │  Canal: notificationQueue → Cloud Function → FCM → Device     │    │    │
│  │  │  Payload: {taskTitle, dueDate, reminderMinutes}               │    │    │
│  │  │  Topics: No se usan topics (mensajes directos por token)      │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  SERVICIOS EXTERNOS (Google Cloud APIs)                              │    │
│  │  ┌─────────────────────────┐  ┌─────────────────────────────────┐  │    │
│  │  │ Google Cloud Text-to-   │  │ Google Drive API (v3)           │  │    │
│  │  │ Speech API              │  │ Scope: drive.file               │  │    │
│  │  │ Modelo: Neural2 (es-ES) │  │ Operaciones: backup/restore     │  │    │
│  │  │ Voz: neural2-f          │  │ Formato: JSON + imágenes ZIP    │  │    │
│  │  └─────────────────────────┘  └─────────────────────────────────┘  │    │
│  │  ┌─────────────────────────┐                                        │    │
│  │  │ Google Generative AI    │                                        │    │
│  │  │ Modelo: Gemini 2.0/2.5  │                                        │    │
│  │  │ Flash                   │                                        │    │
│  │  └─────────────────────────┘                                        │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         CI/CD Y DESARROLLO                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐   │
│  │   GitHub        │  │  GitHub Actions │  │   Firebase Emulator Suite   │   │
│  │   (Repositorio) │  │  (CI/CD)        │  │   (Pruebas locales)         │   │
│  │                 │  │  • flutter test │  │   • Firestore emulator      │   │
│  │  Organizate/    │  │  • flutter build│  │   • Auth emulator           │   │
│  │  simple         │  │  • firebase deploy│  │   • Functions emulator      │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### D.4.2 Flujo de datos en la infraestructura

```
[Usuario abre app]
    ↓
[Firebase Auth] → Verifica JWT del token de sesión
    ↓
[Firestore] → Sincronización en tiempo real de:
    • Documento del usuario (role, nombre, avatar, puntos)
    • Subcolección tasks (pendientes, completadas)
    • Subcolección pictogramSettings (feature flags)
    • Subcolección pictograms (personalizados)
    ↓
[Firebase Storage] → Descarga bajo demanda:
    • Imágenes de pictogramas personalizados (lazy loading)
    • Fotos de perfil
    ↓
[Cloud Functions] → Invocación bajo demanda:
    • desglosarTarea() → Gemini AI → retorna micro-pasos
    • sintetizarVoz() → Google TTS → retorna audio base64
    ↓
[FCM] → Notificaciones push programadas:
    • Recordatorios de tareas (Cloud Scheduler → FCM → dispositivo)
    • Fin de Pomodoro (local notification + FCM fallback)
    ↓
[Google Drive API] → Operaciones manuales del usuario:
    • Backup: JSON de configuración + imágenes → carpeta Simple_App_Backup
    • Restore: Descarga desde Drive → aplica a Firestore + almacenamiento local
```

---

## D.5 Mockups de Interfaz de Usuario

### D.5.1 Pantalla de Pictogramas (Tablero TEA - PantallaUsuarioTEA)

```
┌─────────────────────────────────────────┐
│  ┌─────┐         MI DÍA          [⚙️] [➕] [⏱️] │
│  │ SOS │                              │
│  └─────┘                              │
├─────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│ │ MI      │ │ COMIDA  │ │EMOCIONES│ │ACCIONES │ │
│ │ RUTINA  │ │         │ │         │ │         │ │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘ │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │  ☀️ RUTINA DE MAÑANA            │    │
│  │                                 │    │
│  │  ┌────┐  ┌────┐  ┌────┐        │    │
│  │  │ 🚿 │  │ 🎒 │  │ 🪥 │        │    │
│  │  │    │  │    │  │    │        │    │
│  │  │DES-│  │COLE│  │DIEN│        │    │
│  │  │PERT│  │GIO │  │TES │        │    │
│  │  └────┘  └────┘  └────┘        │    │
│  │                                 │    │
│  │  ┌────┐  ┌────┐  ┌────┐        │    │
│  │  │ 🚽 │  │ 👕 │  │ 🍽️ │        │    │
│  │  │    │  │    │  │    │        │    │
│  │  │BAÑO│  │VEST│  │DESA│        │    │
│  │  │    │  │IR  │  │YUNO│        │    │
│  │  └────┘  └────┘  └────┘        │    │
│  └─────────────────────────────────┘    │
├─────────────────────────────────────────┤
│  [🔔 AYUDA]                            │
└─────────────────────────────────────────┘
│  🏠    📋    🖼️    ⏱️    👤          │
└─────────────────────────────────────────┘

Especificaciones técnicas del mockup:
───────────────────────────────────────
AppBar:
  - Leading: Container 48x48, BorderRadius 12, Color: Colors.red,
    Text: 'SOS', FontWeight.w900, FontSize 13, LetterSpacing 1.5
  - Title: 'MI DÍA', FontSize 20 (titleLarge), FontWeight.w800,
    Color: Theme.primary, LetterSpacing 2.0
  - Actions: IconButton tune (organizar), IconButton add_photo_alternate
    (crear pictograma), ContadorTransicion widget (semaforo circular 44x44)

TabBar:
  - 4 tabs: MI RUTINA | COMIDA | EMOCIONES | ACCIONES
  - IndicatorColor: Theme.primary, IndicatorWeight: 3
  - IndicatorSize: TabBarIndicatorSize.label
  - LabelColor: Theme.primary, UnselectedLabelColor: Theme.onSurfaceVariant
  - LabelStyle: FontWeight.w800, FontSize 11, LetterSpacing 0.8

Grid de Pictogramas:
  - CrossAxisCount: 3 (tres columnas)
  - CrossAxisSpacing: 12, MainAxisSpacing: 12
  - ChildAspectRatio: 0.82
  - Padding: EdgeInsets.fromLTRB(16, 8, 16, 16)

Tarjeta de Pictograma:
  - Container: BorderRadius 24, Color: Theme.surface
  - Border: 1.0-1.5px, Color: Theme.outlineVariant (o secondary para personalizados)
  - BoxShadow: Color.withAlpha(0.06), BlurRadius 10, Offset(0, 4)
  - Imagen: Padding 10,10,10,6 → Expanded con SVG o Image.network
  - Label: Container con Color primaryContainer/secondaryContainer at 15-20%,
    FontSize 8-9, FontWeight.w800, Color primary/secondary
  - Para personalizados: Icon(Icons.photo_camera, size 8) + espacio 3px

Header de Rutina (dentro de _GridCategoriaDisplay):
  - Container: Padding 14x8, BorderRadius 10,
    Color: primaryContainer.withAlpha(0.35)
  - Icon: iconoRutina, Color primary, Size 16
  - Text: 'RUTINA DE ${nombreRutina}', FontSize labelMedium,
    FontWeight.w800, Color primary, LetterSpacing 0.8

Botón de Ayuda (bottom):
  - ElevatedButton.icon: Color errorContainer, Foreground onErrorContainer
  - Padding vertical 10, BorderRadius 14
  - Icon: Icons.warning_rounded, Size 20
  - Label: 'AYUDA', FontWeight.w800, FontSize 13, LetterSpacing 1.5

BottomNavigationBar (CustomNavBar):
  - Type: BottomNavigationBarType.fixed
  - SelectedItemColor: Colors.blue.shade700
  - UnselectedItemColor: Colors.grey.shade500
  - FontSize: 12 (selected y unselected)
  - BackgroundColor: Colors.white, Elevation 8
```

### D.5.2 Panel del Tutor (TutorSupervisarScreen)

```
┌─────────────────────────────────────────┐
│  [👤]  María González ▼          [⚙️]  │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐│
│  │  📋 TAREAS           [+] Agregar    ││
│  │                                     ││
│  │  ┌─────────────────────────────┐   ││
│  │  │ [⚪] Estudiar matemáticas    │   ││
│  │  │     📚 Estudios · Hoy 15:00 │   ││
│  │  └─────────────────────────────┘   ││
│  │  ┌─────────────────────────────┐   ││
│  │  │ [✅] Lavar los platos       │   ││
│  │  │     🏠 Hogar · Completada   │   ││
│  │  └─────────────────────────────┘   ││
│  │  ┌─────────────────────────────┐   ││
│  │  │ [🗑️] Hacer la cama          │   ││
│  │  │     🏠 Hogar · Eliminada    │   ││
│  │  └─────────────────────────────┘   ││
│  └─────────────────────────────────────┘│
├─────────────────────────────────────────┤
│  Tareas  🖼️  Progreso  📜  Ajustes     │
└─────────────────────────────────────────┘

Especificaciones técnicas del mockup:
───────────────────────────────────────
AppBar:
  - BackgroundColor: Colors.transparent, Elevation: 0
  - Leading: CircleAvatar (radius 18, backgroundColor grey.shade200,
    backgroundImage: AssetImage('assets/avatars/$avatar.png') o Icon(Icons.person))
  - Title: GestureDetector → Row con Text(_patientName, FontWeight.w600) + Icon(Icons.arrow_drop_down)
    (solo si _patients.length > 1)
  - Actions: IconButton(Icons.settings_outlined) → SettingsScreen

Selector de Usuario (BottomSheet):
  - Shape: RoundedRectangleBorder, BorderRadius.vertical(top: Radius.circular(20))
  - Children: ListTile por cada paciente vinculado
    - Leading: CircleAvatar (radius 20, backgroundImage o Icon)
    - Title: Text(name, FontWeight.w500)
    - Subtitle: Text(email, FontSize 12)
    - Trailing: isSelected ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.radio_button_unchecked, color: Colors.grey)

IndexedStack (5 tabs):
  - Index: _currentIndex
  - Children con ValueKey('tasks_$patientId'), ValueKey('pictos_$patientId'), etc.
  - Cada tab se reconstruye completamente al cambiar de paciente (ValueKey)

Tab _TutorTasksTab:
  - FloatingActionButton.extended: onPressed _addTask,
    Icon(Icons.add), Label: 'Agregar tarea'
  - StreamBuilder<QuerySnapshot> de _tasksRef
  - Secciones: 'Pendientes (N)' [Colors.blueAccent],
    'Completadas (N)' [Colors.green],
    'Eliminadas por el usuario (N)' [Colors.grey]
  - _SupervisionTaskTile: Card con Checkbox, título, categoría con chip de color,
    fecha, IconButton delete

Tab _TutorPictogramsTab:
  - FloatingActionButtons: 'Organizar pictogramas' (heroTag, naranja) +
    'Agregar' (heroTag, primario)
  - StreamBuilder<List<PictogramaPersonalizado>>
  - GridView 3 columnas, aspect ratio 0.85
  - _SupervisionPictoCard: Imagen + etiqueta + IconButton delete

Tab ProgresoScreen:
  - userId: patientId (para mostrar datos del usuario seleccionado)
  - Gráficos: tareas por categoría, uso de pictogramas, sesiones Pomodoro semanales

Tab _TutorHistorialTab:
  - SliverList con _StatsCard (4 chips: sesiones, minutos, racha, puntos)
  - StreamBuilder de ActivityLogService.getStream(patientId)
  - Cada item: Container con fondo color.withAlpha(0.06), borde del mismo color,
    Icon en círculo, título, descripción, fecha formateada

Tab _TutorConfigTab:
  - StreamBuilder de pictogramSettings/_features
  - _FeatureToggleTile x5: Inicio, Tareas, Pictogramas, Foco, Perfil
  - SwitchListTile con icono circular, título, subtítulo descriptivo
  - Modo Kiosk: StreamBuilder<bool> + _FeatureToggleTile
  - Contacto de emergencia: 2 TextFields + ElevatedButton.icon Guardar

BottomNavigationBar (NavigationBar):
  - SelectedIndex: _currentIndex
  - Destinations:
    1. NavigationDestination(Icons.task_alt_outlined / Icons.task_alt, 'Tareas')
    2. NavigationDestination(Icons.image_outlined / Icons.image_rounded, 'Pictogramas')
    3. NavigationDestination(Icons.bar_chart_outlined / Icons.bar_chart_rounded, 'Progreso')
    4. NavigationDestination(Icons.history, 'Historial')
    5. NavigationDestination(Icons.tune_outlined / Icons.tune_rounded, 'Ajustes')
```

### D.5.3 Temporizador Pomodoro (FocoScreen)

```
┌─────────────────────────────────────────┐
│  ⬅️  Modo Foco                         │
├─────────────────────────────────────────┤
│                                         │
│           ┌─────────────┐               │
│           │             │               │
│           │    25:00    │               │
│           │             │               │
│           │  ┌───────┐  │               │
│           │  │       │  │               │
│           │  │  🍅   │  │               │
│           │  │       │  │               │
│           │  └───────┘  │               │
│           │             │               │
│           └─────────────┘               │
│                                         │
│     [══════════════════════]            │
│          100% completado                │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │        [ ▶️ INICIAR ]           │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌──────┐  ┌──────┐  ┌──────┐         │
│   │ ⏸️   │  │ ⏹️   │  │ ⏭️   │         │
│   │Pausa │  │Detener│  │Saltar│         │
│   └──────┘  └──────┘  └──────┘         │
│                                         │
│   🔊 Sonido:  Campanilla clásica        │
│   📳 Vibración:  Desactivada            │
│                                         │
│   Sesiones completadas: 12              │
│   Minutos de foco: 300                  │
│                                         │
└─────────────────────────────────────────┘
│  🏠    📋    🖼️    ⏱️    👤          │
└─────────────────────────────────────────┘

Especificaciones técnicas del mockup:
───────────────────────────────────────
AppBar:
  - Leading: BackButton o IconButton(Icons.arrow_back)
  - Title: 'Modo Foco', FontWeight.bold
  - BackgroundColor: Colors.transparent, Elevation 0

Timer Principal:
  - CustomPaint circular o Stack con CircularProgressIndicator
  - Diámetro: ~220px
  - Color del track: Theme.outlineVariant.withAlpha(0.2)
  - Color del progreso: Theme.primary (o Colors.deepOrange para Pomodoro)
  - StrokeWidth: 8-12
  - Centro: Column con Text('25:00', FontSize 48, FontWeight.bold) +
    Icon(Icons.local_fire_department, size 48, Color: Colors.deepOrange)

Barra de progreso lineal:
  - LinearProgressIndicator o CustomPainter
  - Valor: (totalDuration - remaining) / totalDuration
  - Altura: 8px, BorderRadius 4

Botón Principal:
  - ElevatedButton: Padding vertical 16, BorderRadius 14
  - BackgroundColor: Theme.primary
  - ForegroundColor: Colors.white
  - Text: 'INICIAR' | 'REANUDAR' | 'PAUSAR' (según PomodoroStatus)
  - FontWeight.w600, FontSize 16

Botones Secundarios:
  - 3 IconButton o ElevatedButton.icon
  - Iconos: Icons.pause (Pausa), Icons.stop (Detener), Icons.skip_next (Saltar)
  - Labels: FontSize 12, Color: Theme.onSurfaceVariant

Configuración:
  - ListTile con leading Icon(Icons.volume_up, color: Colors.grey)
  - Title: 'Sonido al terminar Pomodoro'
  - Trailing: DropdownButton con opciones ('Campanilla clásica', 'Notificación')
  - SwitchListTile: 'Vibración al terminar Pomodoro'

Estadísticas:
  - Text('Sesiones completadas: $focusSessionsCompleted')
  - Text('Minutos de foco: $totalFocusMinutes')
  - FontSize 14, Color: Theme.onSurfaceVariant

Estados del Timer:
  - idle: Timer muestra duración configurada (default 25:00), botón INICIAR
  - running: Timer decrementa cada segundo, botón PAUSAR, progreso avanza
  - paused: Timer congela en remaining, botón REANUDAR, progreso pausado
  - finished: Timer en 00:00, SnackBar '¡Pomodoro completado!', sonido/vibración,
    ActivityLogService.log(pomodoroCompleted)
```

---

**Fin del Anexo D**

*Documento generado como parte del Informe Técnico para Defensa de Título del proyecto Organízate (Simple).*
