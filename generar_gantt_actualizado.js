const XLSX = require('xlsx');
const fs = require('fs');

// Colores para el Excel
const COLORES = {
  completado: '70AD47',      // Verde
  enCurso: 'ED7D31',         // Naranja
  pendiente: 'FFC000',       // Amarillo
  alta: 'C00000',           // Rojo
  media: 'ED7D31',          // Naranja
  baja: '4472C4',           // Azul
  fase: '203864',           // Azul oscuro
  header: '404040',         // Gris oscuro
  hito: 'FF0000',           // Rojo brillante
  blanco: 'FFFFFF'
};

// Datos del proyecto basados en la información real
const proyecto = {
  nombre: 'ORGANÍZATE / SIMPLE',
  repositorio: 'Nefta-AR/Organizate',
  plataforma: 'Flutter + Firebase',
  periodo: '27 Abril 2026 – Julio 2026',
  estado: 'En Desarrollo (Integración y Correcciones)'
};

// Fases completadas según el Excel del usuario
const fasesCompletadas = [
  { 
    nombre: 'Fase 1: Fundación y Auth', 
    estado: 'Completado', 
    progreso: 1,
    tareas: [
      { nombre: 'Base Organizate 2.0', fecha: '2026-04-27', completado: true },
      { nombre: 'Rediseño UI Login', fecha: '2026-04-27', completado: true },
      { nombre: 'Sistema Login (email + Google)', fecha: '2026-04-28', completado: true },
      { nombre: 'Cambio nombre -> Simple + Logo', fecha: '2026-04-28', completado: true },
      { nombre: 'Login Web funcional', fecha: '2026-04-28', completado: true }
    ]
  },
  { 
    nombre: 'Fase 2: IA / Súper Experto', 
    estado: 'Completado', 
    progreso: 1,
    tareas: [
      { nombre: 'Integración Cloud Functions IA', fecha: '2026-04-29', completado: true },
      { nombre: 'Súper Experto funcional (Gemini)', fecha: '2026-04-29', completado: true },
      { nombre: 'Función desglosarTarea', fecha: '2026-04-29', completado: true }
    ]
  },
  { 
    nombre: 'Fase 3: Módulo TEA (Pictogramas)', 
    estado: 'Completado', 
    progreso: 1,
    tareas: [
      { nombre: 'Pantalla Pictogramas Beta', fecha: '2026-04-30', completado: true },
      { nombre: 'Banco pictogramas predefinidos (SVG)', fecha: '2026-04-30', completado: true },
      { nombre: 'Pictogramas con color', fecha: '2026-05-06', completado: true },
      { nombre: 'Merge rama Pictogramas', fecha: '2026-05-06', completado: true },
      { nombre: 'Gestor de pictogramas personalizados', fecha: '2026-05-06', completado: true }
    ]
  },
  { 
    nombre: 'Fase 4: Módulo TDAH (Tareas)', 
    estado: 'Completado', 
    progreso: 1,
    tareas: [
      { nombre: 'Gestión de tareas (CRUD + categorías)', fecha: '2026-05-05', completado: true },
      { nombre: 'Swipe para eliminar tareas', fecha: '2026-05-05', completado: true },
      { nombre: 'Migración completa a Simple', fecha: '2026-05-05', completado: true },
      { nombre: 'Timer Pomodoro + respiración', fecha: '2026-05-09', completado: true },
      { nombre: 'Sistema de puntos y racha', fecha: '2026-05-09', completado: true }
    ]
  },
  { 
    nombre: 'Fase 5: Integración y Correcciones', 
    estado: 'En Curso', 
    progreso: 0.75,
    tareas: [
      { nombre: 'Corrección SHA + conexiones Firebase', fecha: '2026-05-09', completado: true },
      { nombre: 'Eliminación Modo Foco -> Pictogramas', fecha: '2026-05-09', completado: true },
      { nombre: 'Fix superposición botones (TEA)', fecha: '2026-05-09', completado: true },
      { nombre: 'Tutor conectado a paciente', fecha: '2026-05-13', completado: true }
    ]
  }
];

// Tareas pendientes del Próximo Sprint
const tareasPendientes = [
  { prioridad: 'Alta', tarea: 'Completar supervisión tutor -> detalle de paciente', fase: 'Fase 5' },
  { prioridad: 'Alta', tarea: 'Sincronización bidireccional tareas tutor <-> paciente', fase: 'Fase 5' },
  { prioridad: 'Media', tarea: 'Kiosk Mode para paciente TEA (control parental)', fase: 'Fase 6' },
  { prioridad: 'Media', tarea: 'Pulir dashboard de progreso (gráficos fl_chart)', fase: 'Fase 6' },
  { prioridad: 'Baja', tarea: 'Notificaciones push FCM completas', fase: 'Fase 6' },
  { prioridad: 'Baja', tarea: 'Testing y correcciones de bugs menores', fase: 'Fase 6' },
  { prioridad: 'Media', tarea: 'Preparación para distribución (Play Store / App Store)', fase: 'Fase 7' }
];

// Cronograma actualizado (13 mayo - julio)
const cronograma = [
  // Semana actual (13-19 mayo) - Fase 5 completándose
  { semana: 'S1 (13-19 May)', fase: 'Fase 5', tarea: 'Completar vinculación tutor-paciente', estado: 'En Curso', inicio: 1, duracion: 1 },
  { semana: 'S1 (13-19 May)', fase: 'Fase 5', tarea: 'Supervisión tutor - detalle paciente', estado: 'En Curso', inicio: 1, duracion: 1 },
  
  // Semana 2 (20-26 mayo)
  { semana: 'S2 (20-26 May)', fase: 'Fase 5', tarea: 'Sincronización bidireccional tareas', estado: 'Pendiente', inicio: 2, duracion: 1 },
  { semana: 'S2 (20-26 May)', fase: 'Fase 5', tarea: 'Corrección bugs integración', estado: 'Pendiente', inicio: 2, duracion: 1 },
  
  // Semana 3-4 (27 mayo - 9 junio) - Fase 6: Pulido
  { semana: 'S3 (27 May-02 Jun)', fase: 'Fase 6', tarea: 'Kiosk Mode paciente TEA', estado: 'Pendiente', inicio: 3, duracion: 2 },
  { semana: 'S3 (27 May-02 Jun)', fase: 'Fase 6', tarea: 'Dashboard progreso (fl_chart)', estado: 'Pendiente', inicio: 3, duracion: 2 },
  { semana: 'S4 (03-09 Jun)', fase: 'Fase 6', tarea: 'Notificaciones push FCM', estado: 'Pendiente', inicio: 4, duracion: 1 },
  { semana: 'S4 (03-09 Jun)', fase: 'Fase 6', tarea: 'Testing y bugs menores', estado: 'Pendiente', inicio: 4, duracion: 1 },
  
  // Semana 5-6 (10-23 junio) - Fase 7: Preparación
  { semana: 'S5 (10-16 Jun)', fase: 'Fase 7', tarea: 'Optimización rendimiento', estado: 'Pendiente', inicio: 5, duracion: 2 },
  { semana: 'S5 (10-16 Jun)', fase: 'Fase 7', tarea: 'Documentación técnica', estado: 'Pendiente', inicio: 5, duracion: 2 },
  { semana: 'S6 (17-23 Jun)', fase: 'Fase 7', tarea: 'Preparación tiendas (Play/App Store)', estado: 'Pendiente', inicio: 6, duracion: 1 },
  
  // Semana 7-8 (24 junio - 7 julio) - Fase 8: Entrega
  { semana: 'S7 (24-30 Jun)', fase: 'Fase 8', tarea: 'Pruebas finales', estado: 'Pendiente', inicio: 7, duracion: 1 },
  { semana: 'S7 (24-30 Jun)', fase: 'Fase 8', tarea: 'Manual de usuario', estado: 'Pendiente', inicio: 7, duracion: 1 },
  { semana: 'S8 (01-07 Jul)', fase: 'Fase 8', tarea: 'Despliegue a tiendas', estado: 'Pendiente', inicio: 8, duracion: 1 },
  { semana: 'S8 (01-07 Jul)', fase: 'Fase 8', tarea: 'Presentación final', estado: 'Pendiente', inicio: 8, duracion: 1 }
];

// Hitos
const hitos = [
  { nombre: 'HITO 1: Vinculación Tutor-Paciente', semana: 1, fecha: '13 May 2026', estado: 'Alcanzado' },
  { nombre: 'HITO 2: Sincronización Completa', semana: 2, fecha: '26 May 2026', estado: 'Pendiente' },
  { nombre: 'HITO 3: MVP Listo para Testing', semana: 6, fecha: '23 Jun 2026', estado: 'Pendiente' },
  { nombre: 'HITO 4: Entrega Final', semana: 8, fecha: '07 Jul 2026', estado: 'Pendiente' }
];

// Distribución de trabajo
const distribucion = [
  { modulo: 'Autenticación y base', porcentaje: 15, estado: 'Completado' },
  { modulo: 'Módulo TEA (Pictogramas)', porcentaje: 35, estado: 'Completado' },
  { modulo: 'Módulo TDAH (Tareas)', porcentaje: 25, estado: 'Completado' },
  { modulo: 'IA / Súper Experto', porcentaje: 10, estado: 'Completado' },
  { modulo: 'Vinculación Tutor', porcentaje: 10, estado: 'En Curso' },
  { modulo: 'Infraestructura Firebase', porcentaje: 5, estado: 'Completado' }
];

// Crear libro de trabajo
const wb = XLSX.utils.book_new();

// ============================================
// HOJA 1: RESUMEN DEL PROYECTO
// ============================================
const wsResumen = [];

wsResumen.push(['REPORTE DE PROYECTO: ORGANÍZATE / SIMPLE']);
wsResumen.push([]);
wsResumen.push(['Información General']);
wsResumen.push(['Repositorio', proyecto.repositorio]);
wsResumen.push(['Plataforma', proyecto.plataforma]);
wsResumen.push(['Período', proyecto.periodo]);
wsResumen.push(['Estado General', proyecto.estado]);
wsResumen.push([]);
wsResumen.push(['Progreso General: 85%']);
wsResumen.push([]);
wsResumen.push(['Fases Completadas']);
wsResumen.push(['Fase', 'Estado', 'Progreso']);

fasesCompletadas.forEach(f => {
  wsResumen.push([f.nombre, f.estado, `${(f.progreso * 100).toFixed(0)}%`]);
});

wsResumen.push([]);
wsResumen.push(['Distribución de Trabajo por Módulo']);
wsResumen.push(['Módulo', 'Porcentaje (%)', 'Estado']);

distribucion.forEach(d => {
  wsResumen.push([d.modulo, d.porcentaje, d.estado]);
});

const ws1 = XLSX.utils.aoa_to_sheet(wsResumen);
XLSX.utils.book_append_sheet(wb, ws1, 'Resumen del Proyecto');

// ============================================
// HOJA 2: CARTA GANTT
// ============================================
const wsGantt = [];

wsGantt.push(['CARTA GANTT - CRONOGRAMA ACTUALIZADO']);
wsGantt.push(['Período: 13 Mayo - 07 Julio 2026 (8 semanas)']);
wsGantt.push([]);

const headersGantt = ['Fase', 'Tarea', 'Estado', 'S1\n13-19May', 'S2\n20-26May', 'S3\n27May-02Jun', 'S4\n03-09Jun', 'S5\n10-16Jun', 'S6\n17-23Jun', 'S7\n24-30Jun', 'S8\n01-07Jul'];
wsGantt.push(headersGantt);

// Agrupar tareas por fase
const fasesCronograma = {};
cronograma.forEach(c => {
  if (!fasesCronograma[c.fase]) fasesCronograma[c.fase] = [];
  fasesCronograma[c.fase].push(c);
});

// Agregar tareas al Gantt
Object.keys(fasesCronograma).forEach(fase => {
  const tareas = fasesCronograma[fase];
  tareas.forEach((t, idx) => {
    const row = [
      idx === 0 ? t.fase : '',
      t.tarea,
      t.estado
    ];
    
    // Llenar semanas
    for (let s = 1; s <= 8; s++) {
      if (s >= t.inicio && s < t.inicio + t.duracion) {
        row.push('██████');
      } else {
        row.push('');
      }
    }
    
    wsGantt.push(row);
  });
});

// Agregar hitos
wsGantt.push([]);
wsGantt.push(['HITOS']);
wsGantt.push(['HITO', 'Descripción', 'Fecha', 'Estado', '', '', '', '', '', '', '']);

hitos.forEach(h => {
  const row = ['★', h.nombre, h.fecha, h.estado];
  // Marcar en la semana correspondiente
  for (let s = 1; s <= 8; s++) {
    if (s === h.semana) {
      row.push('▼ HITO');
    } else {
      row.push('');
    }
  }
  wsGantt.push(row);
});

const ws2 = XLSX.utils.aoa_to_sheet(wsGantt);
XLSX.utils.book_append_sheet(wb, ws2, 'Carta Gantt');

// ============================================
// HOJA 3: PRÓXIMO SPRINT
// ============================================
const wsSprint = [];

wsSprint.push(['PRÓXIMO SPRINT - TAREAS PENDIENTES']);
wsSprint.push(['Actualizado: 13 Mayo 2026']);
wsSprint.push([]);
wsSprint.push(['Prioridad', 'Tarea', 'Fase', 'Estado']);

tareasPendientes.forEach(t => {
  wsSprint.push([t.prioridad, t.tarea, t.fase, 'Pendiente']);
});

wsSprint.push([]);
wsSprint.push(['Leyenda de Prioridades:']);
wsSprint.push(['Alta', 'Crítico para el funcionamiento']);
wsSprint.push(['Media', 'Mejora la experiencia de usuario']);
wsSprint.push(['Baja', 'Puede esperar al final']);

const ws3 = XLSX.utils.aoa_to_sheet(wsSprint);
XLSX.utils.book_append_sheet(wb, ws3, 'Próximo Sprint');

// ============================================
// HOJA 4: HISTORIAL DE COMMITS
// ============================================
const wsCommits = [];

wsCommits.push(['HISTORIAL DE HITOS (COMMITS)']);
wsCommits.push([]);
wsCommits.push(['Fecha', 'Commit', 'Descripción', 'Fase']);

const commitsHistorial = [
  ['2026-04-27', 'Base', 'Base Organizate 2.0 + rediseño UI Login', 'Fase 1'],
  ['2026-04-28', 'e48e5d0', 'Cambio de nombre a Simple, nuevo logo, login web', 'Fase 1'],
  ['2026-04-29', '2d886cc', 'Súper Experto IA funcional (Gemini + Cloud Functions)', 'Fase 2'],
  ['2026-04-30', '0633e86', 'Pantalla Pictogramas Beta (módulo TEA)', 'Fase 3'],
  ['2026-05-05', '12bd20d', 'Migración completa de Organizate -> Simple', 'Fase 4'],
  ['2026-05-06', '335f814', 'Pantalla Pictogramas completa', 'Fase 3'],
  ['2026-05-09', '97fd1b1', 'Eliminación Modo Foco -> reemplazado por Pictogramas TEA', 'Fase 5'],
  ['2026-05-13', 'ce5c88a', 'Tutor conectado a paciente (vinculación completada)', 'Fase 5']
];

commitsHistorial.forEach(c => {
  wsCommits.push(c);
});

const ws4 = XLSX.utils.aoa_to_sheet(wsCommits);
XLSX.utils.book_append_sheet(wb, ws4, 'Hitos (Milestones)');

// ============================================
// APLICAR ESTILOS
// ============================================

// Estilos comunes
const applyStyles = (ws, sheetName) => {
  const range = XLSX.utils.decode_range(ws['!ref']);
  
  for (let R = range.s.r; R <= range.e.r; R++) {
    for (let C = range.s.c; C <= range.e.c; C++) {
      const cellAddress = XLSX.utils.encode_cell({ r: R, c: C });
      const cell = ws[cellAddress];
      if (!cell) continue;
      
      // Resumen del Proyecto
      if (sheetName === 'Resumen del Proyecto') {
        if (R === 0) {
          cell.s = { font: { bold: true, sz: 16, color: { rgb: COLORES.fase } } };
        }
        if (R === 10) { // Fases
          const fase = wsResumen[R][1];
          if (fase === 'Completado') {
            cell.s = { fill: { fgColor: { rgb: COLORES.completado } }, font: { color: { rgb: COLORES.blanco } } };
          } else if (fase === 'En Curso') {
            cell.s = { fill: { fgColor: { rgb: COLORES.enCurso } }, font: { color: { rgb: COLORES.blanco } } };
          }
        }
      }
      
      // Carta Gantt
      if (sheetName === 'Carta Gantt') {
        if (R === 0) {
          cell.s = { font: { bold: true, sz: 14, color: { rgb: COLORES.fase } } };
        }
        if (R === 3) { // Headers
          cell.s = { font: { bold: true }, fill: { fgColor: { rgb: COLORES.header } } };
        }
        if (R > 3 && cell.v === '██████') {
          const estado = wsGantt[R][2];
          const color = estado === 'Completado' ? COLORES.completado : 
                       estado === 'En Curso' ? COLORES.enCurso : COLORES.pendiente;
          cell.s = { fill: { fgColor: { rgb: color } } };
        }
        if (cell.v === '▼ HITO') {
          cell.s = { fill: { fgColor: { rgb: COLORES.hito } }, font: { bold: true, color: { rgb: COLORES.blanco } } } };
        }
      }
      
      // Próximo Sprint
      if (sheetName === 'Próximo Sprint') {
        if (R === 0) {
          cell.s = { font: { bold: true, sz: 14, color: { rgb: COLORES.fase } } };
        }
        if (R === 3) {
          cell.s = { font: { bold: true }, fill: { fgColor: { rgb: COLORES.header } } };
        }
        if (R > 3 && R < 11) {
          const prioridad = wsSprint[R][0];
          let color = COLORES.baja;
          if (prioridad === 'Alta') color = COLORES.alta;
          else if (prioridad === 'Media') color = COLORES.media;
          
          if (C === 0) {
            cell.s = { fill: { fgColor: { rgb: color } }, font: { bold: true, color: { rgb: COLORES.blanco } } };
          }
        }
      }
      
      // Hitos
      if (sheetName === 'Hitos (Milestones)') {
        if (R === 0) {
          cell.s = { font: { bold: true, sz: 14, color: { rgb: COLORES.fase } } };
        }
        if (R === 2) {
          cell.s = { font: { bold: true }, fill: { fgColor: { rgb: COLORES.header } } };
        }
      }
    }
  }
};

// Aplicar estilos a todas las hojas
wb.SheetNames.forEach(name => {
  applyStyles(wb.Sheets[name], name);
});

// Ajustar anchos de columna
wb.SheetNames.forEach(name => {
  const ws = wb.Sheets[name];
  const range = XLSX.utils.decode_range(ws['!ref']);
  ws['!cols'] = [];
  for (let C = range.s.c; C <= range.e.c; C++) {
    ws['!cols'].push({ wch: 25 });
  }
});

// Guardar archivo
const outputPath = './Carta_Gantt_Organizate_Actualizado.xlsx';
XLSX.writeFile(wb, outputPath);

console.log('✅ Carta Gantt ACTUALIZADA generada exitosamente!');
console.log('');
console.log('📊 Archivo: Carta_Gantt_Organizate_Actualizado.xlsx');
console.log('');
console.log('📋 Contenido:');
console.log('   ✅ Hoja 1: Resumen del Proyecto (85% completado)');
console.log('   ✅ Hoja 2: Carta Gantt (Cronograma 13 Mayo - 7 Julio)');
console.log('   ✅ Hoja 3: Próximo Sprint (7 tareas pendientes)');
console.log('   ✅ Hoja 4: Hitos / Historial de Commits');
console.log('');
console.log('🎯 Fases Completadas:');
console.log('   • Fase 1: Fundación y Auth ✓');
console.log('   • Fase 2: IA / Súper Experto ✓');
console.log('   • Fase 3: Módulo TEA (Pictogramas) ✓');
console.log('   • Fase 4: Módulo TDAH (Tareas) ✓');
console.log('   • Fase 5: Integración y Correcciones (75% - En Curso)');
console.log('');
console.log('📌 Próximas Tareas Críticas:');
console.log('   🔴 Alta: Completar supervisión tutor -> detalle de paciente');
console.log('   🔴 Alta: Sincronización bidireccional tareas tutor <-> paciente');
console.log('');
console.log('📅 Hitos:');
console.log('   ⭐ 13 May: Vinculación Tutor-Paciente (ALCANZADO)');
console.log('   ⭐ 26 May: Sincronización Completa (Pendiente)');
console.log('   ⭐ 23 Jun: MVP Listo para Testing (Pendiente)');
console.log('   ⭐ 07 Jul: Entrega Final (Pendiente)');
