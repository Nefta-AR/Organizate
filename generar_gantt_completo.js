const XLSX = require('xlsx');

// Colores
const COLORES = {
  completado: '70AD47',
  enCurso: 'ED7D31',
  pendiente: 'FFC000',
  alta: 'C00000',
  media: 'ED7D31',
  baja: '4472C4',
  fase: '203864',
  header: '404040',
  hito: 'FF0000',
  blanco: 'FFFFFF'
};

// Datos del proyecto
const proyecto = {
  nombre: 'ORGANÍZATE / SIMPLE',
  repositorio: 'Nefta-AR/Organizate',
  plataforma: 'Flutter + Firebase',
  periodo: '27 Abril 2026 – Julio 2026',
  estado: 'En Desarrollo (85% Completado)'
};

// Fases completadas
const fases = [
  { nombre: 'Fase 1: Fundación y Auth', estado: 'Completado', progreso: '100%' },
  { nombre: 'Fase 2: IA / Súper Experto', estado: 'Completado', progreso: '100%' },
  { nombre: 'Fase 3: Módulo TEA (Pictogramas)', estado: 'Completado', progreso: '100%' },
  { nombre: 'Fase 4: Módulo TDAH (Tareas)', estado: 'Completado', progreso: '100%' },
  { nombre: 'Fase 5: Integración y Correcciones', estado: 'En Curso', progreso: '75%' },
  { nombre: 'Fase 6: Pulido y Testing', estado: 'Pendiente', progreso: '0%' },
  { nombre: 'Fase 7: Documentación y Entrega', estado: 'Pendiente', progreso: '0%' }
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

// Cronograma Gantt COMPLETO (desde abril)
const cronograma = [
  // FASE 1: Fundación y Auth (27-28 Abr)
  { fase: 'FASE 1: Fundación y Auth', tarea: 'Base Organizate 2.0 + rediseño UI', estado: 'Completado', s1: '██████', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Sistema Login (email + Google)', estado: 'Completado', s1: '██████', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Cambio nombre -> Simple + Logo', estado: 'Completado', s1: '██████', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Login Web funcional', estado: 'Completado', s1: '██████', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  
  // FASE 2: IA / Súper Experto (28-29 Abr)
  { fase: 'FASE 2: IA / Súper Experto', tarea: 'Integración Cloud Functions IA', estado: 'Completado', s1: '', s2: '██████', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Súper Experto funcional (Gemini)', estado: 'Completado', s1: '', s2: '██████', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Función desglosarTarea', estado: 'Completado', s1: '', s2: '██████', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  
  // FASE 3: Módulo TEA (30 Abr - 06 May)
  { fase: 'FASE 3: Módulo TEA (Pictogramas)', tarea: 'Pantalla Pictogramas Beta', estado: 'Completado', s1: '', s2: '', s3: '██████', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Banco pictogramas predefinidos (SVG)', estado: 'Completado', s1: '', s2: '', s3: '██████', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Pictogramas con color', estado: 'Completado', s1: '', s2: '', s3: '', s4: '██████', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Gestor pictogramas personalizados', estado: 'Completado', s1: '', s2: '', s3: '', s4: '██████', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  
  // FASE 4: Módulo TDAH (05-09 May)
  { fase: 'FASE 4: Módulo TDAH (Tareas)', tarea: 'Gestión tareas (CRUD + categorías)', estado: 'Completado', s1: '', s2: '', s3: '', s4: '██████', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Swipe para eliminar tareas', estado: 'Completado', s1: '', s2: '', s3: '', s4: '██████', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Migración completa a Simple', estado: 'Completado', s1: '', s2: '', s3: '', s4: '██████', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Timer Pomodoro + respiración', estado: 'Completado', s1: '', s2: '', s3: '', s4: '', s5: '██████', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Sistema puntos y racha', estado: 'Completado', s1: '', s2: '', s3: '', s4: '', s5: '██████', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  
  // FASE 5: Integración (09 May - 26 May)
  { fase: 'FASE 5: Integración', tarea: 'Corrección SHA + Firebase', estado: 'Completado', s1: '', s2: '', s3: '', s4: '', s5: '██████', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Eliminación Modo Foco', estado: 'Completado', s1: '', s2: '', s3: '', s4: '', s5: '██████', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Fix superposición botones TEA', estado: 'Completado', s1: '', s2: '', s3: '', s4: '', s5: '██████', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Tutor conectado a paciente', estado: 'Completado', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '██████', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Supervisión tutor -> detalle paciente', estado: 'En Curso', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '██████', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Sincronización bidireccional', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '██████', s8: '', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Corrección bugs integración', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '██████', s8: '', s9: '', s10: '', s11: '', s12: '' },
  
  // FASE 6: Pulido (27 May - 16 Jun)
  { fase: 'FASE 6: Pulido', tarea: 'Kiosk Mode paciente TEA', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '██████', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Dashboard progreso (fl_chart)', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '██████', s9: '', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Notificaciones push FCM', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '██████', s10: '', s11: '', s12: '' },
  { fase: '', tarea: 'Testing y bugs menores', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '██████', s10: '', s11: '', s12: '' },
  
  // FASE 7: Documentación y Entrega (17 Jun - 07 Jul) - SIN TIENDAS
  { fase: 'FASE 7: Documentación', tarea: 'Optimización rendimiento', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '██████', s11: '', s12: '' },
  { fase: '', tarea: 'Documentación técnica', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '██████', s11: '', s12: '' },
  { fase: '', tarea: 'Pruebas finales', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '██████', s12: '' },
  { fase: '', tarea: 'Manual de usuario', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '██████', s12: '' },
  { fase: '', tarea: 'Presentación final', estado: 'Pendiente', s1: '', s2: '', s3: '', s4: '', s5: '', s6: '', s7: '', s8: '', s9: '', s10: '', s11: '', s12: '██████' }
];

// Hitos actualizados
const hitos = [
  { semana: 'S6', hito: '▼ HITO 1: Vinculación Tutor-Paciente', fecha: '13 May 2026', estado: '✓ ALCANZADO' },
  { semana: 'S7', hito: '▼ HITO 2: Sincronización Completa', fecha: '26 May 2026', estado: 'PENDIENTE' },
  { semana: 'S11', hito: '▼ HITO 3: MVP Listo', fecha: '30 Jun 2026', estado: 'PENDIENTE' },
  { semana: 'S12', hito: '▼ HITO 4: Entrega Final', fecha: '07 Jul 2026', estado: 'PENDIENTE' }
];

// Tareas pendientes - SIN TIENDAS
const tareasPendientes = [
  { prioridad: 'Alta', tarea: 'Completar supervisión tutor -> detalle de paciente', fase: 'Fase 5' },
  { prioridad: 'Alta', tarea: 'Sincronización bidireccional tareas tutor <-> paciente', fase: 'Fase 5' },
  { prioridad: 'Media', tarea: 'Kiosk Mode para paciente TEA (control parental)', fase: 'Fase 6' },
  { prioridad: 'Media', tarea: 'Pulir dashboard de progreso (gráficos fl_chart)', fase: 'Fase 6' },
  { prioridad: 'Baja', tarea: 'Notificaciones push FCM completas', fase: 'Fase 6' },
  { prioridad: 'Baja', tarea: 'Testing y correcciones de bugs menores', fase: 'Fase 6' },
  { prioridad: 'Media', tarea: 'Documentación técnica completa', fase: 'Fase 7' },
  { prioridad: 'Media', tarea: 'Manual de usuario', fase: 'Fase 7' },
  { prioridad: 'Media', tarea: 'Presentación final del proyecto', fase: 'Fase 7' }
];

// Historial de commits completo
const commits = [
  { fecha: '27 Abr 2026', commit: '8e73da2', descripcion: 'Base Organizate 2.0 + rediseño UI Login', fase: 'Fase 1' },
  { fecha: '28 Abr 2026', commit: 'e48e5d0', descripcion: 'Cambio de nombre a Simple, nuevo logo, login web', fase: 'Fase 1' },
  { fecha: '29 Abr 2026', commit: '2d886cc', descripcion: 'Súper Experto IA funcional (Gemini + Cloud Functions)', fase: 'Fase 2' },
  { fecha: '30 Abr 2026', commit: '0633e86', descripcion: 'Pantalla Pictogramas Beta (módulo TEA)', fase: 'Fase 3' },
  { fecha: '05 May 2026', commit: '12bd20d', descripcion: 'Migración completa de Organizate -> Simple', fase: 'Fase 4' },
  { fecha: '06 May 2026', commit: '335f814', descripcion: 'Pantalla Pictogramas completa', fase: 'Fase 3' },
  { fecha: '09 May 2026', commit: '97fd1b1', descripcion: 'Eliminación Modo Foco -> reemplazado por Pictogramas TEA', fase: 'Fase 5' },
  { fecha: '13 May 2026', commit: 'ce5c88a', descripcion: 'Tutor conectado a paciente (vinculación completada)', fase: 'Fase 5' }
];

// Crear libro
const wb = XLSX.utils.book_new();

// HOJA 1: Resumen
const wsResumenData = [
  ['REPORTE DE PROYECTO: ORGANÍZATE / SIMPLE'],
  [],
  ['INFORMACIÓN GENERAL'],
  ['Repositorio', proyecto.repositorio],
  ['Plataforma', proyecto.plataforma],
  ['Período', proyecto.periodo],
  ['Estado General', proyecto.estado],
  [],
  ['PROGRESO GENERAL: 85%'],
  [],
  ['FASES DEL PROYECTO'],
  ['Fase', 'Estado', 'Progreso']
];

fases.forEach(f => {
  wsResumenData.push([f.nombre, f.estado, f.progreso]);
});

wsResumenData.push([]);
wsResumenData.push(['DISTRIBUCIÓN DE TRABAJO POR MÓDULO']);
wsResumenData.push(['Módulo', 'Porcentaje (%)', 'Estado']);

distribucion.forEach(d => {
  wsResumenData.push([d.modulo, d.porcentaje, d.estado]);
});

const ws1 = XLSX.utils.aoa_to_sheet(wsResumenData);
XLSX.utils.book_append_sheet(wb, ws1, 'Resumen del Proyecto');

// HOJA 2: Carta Gantt COMPLETA
const wsGanttData = [
  ['CARTA GANTT - CRONOGRAMA COMPLETO (27 Abril - 07 Julio 2026)'],
  [],
  ['FASE', 'TAREA', 'ESTADO', 'S1\n27-30Abr', 'S2\n01-04May', 'S3\n05-09May', 'S4\n10-13May', 'S5\n14-18May', 'S6\n19-23May', 'S7\n24-30May', 'S8\n31May-06Jun', 'S9\n07-13Jun', 'S10\n14-20Jun', 'S11\n21-27Jun', 'S12\n28Jun-07Jul']
];

cronograma.forEach(c => {
  wsGanttData.push([c.fase, c.tarea, c.estado, c.s1, c.s2, c.s3, c.s4, c.s5, c.s6, c.s7, c.s8, c.s9, c.s10, c.s11, c.s12]);
});

wsGanttData.push([]);
wsGanttData.push(['HITOS DEL PROYECTO']);
wsGanttData.push(['SEMANA', 'HITO', 'FECHA', 'ESTADO']);

hitos.forEach(h => {
  wsGanttData.push([h.semana, h.hito, h.fecha, h.estado]);
});

const ws2 = XLSX.utils.aoa_to_sheet(wsGanttData);
XLSX.utils.book_append_sheet(wb, ws2, 'Carta Gantt');

// HOJA 3: Próximo Sprint
const wsSprintData = [
  ['PRÓXIMO SPRINT - TAREAS PENDIENTES'],
  ['Actualizado: 14 Mayo 2026'],
  [],
  ['Prioridad', 'Tarea', 'Fase', 'Estado']
];

tareasPendientes.forEach(t => {
  wsSprintData.push([t.prioridad, t.tarea, t.fase, 'Pendiente']);
});

wsSprintData.push([]);
wsSprintData.push(['LEYENDA DE PRIORIDADES:']);
wsSprintData.push(['Alta', 'Crítico para el funcionamiento']);
wsSprintData.push(['Media', 'Mejora la experiencia de usuario']);
wsSprintData.push(['Baja', 'Puede esperar al final']);

const ws3 = XLSX.utils.aoa_to_sheet(wsSprintData);
XLSX.utils.book_append_sheet(wb, ws3, 'Próximo Sprint');

// HOJA 4: Hitos
const wsHitosData = [
  ['HISTORIAL DE HITOS (COMMITS)'],
  [],
  ['Fecha', 'Commit', 'Descripción', 'Fase']
];

commits.forEach(c => {
  wsHitosData.push([c.fecha, c.commit, c.descripcion, c.fase]);
});

const ws4 = XLSX.utils.aoa_to_sheet(wsHitosData);
XLSX.utils.book_append_sheet(wb, ws4, 'Hitos (Milestones)');

// Ajustar anchos
wb.SheetNames.forEach(name => {
  const ws = wb.Sheets[name];
  ws['!cols'] = [{ wch: 30 }, { wch: 50 }, { wch: 20 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 12 }, { wch: 12 }];
});

// Guardar
XLSX.writeFile(wb, 'Carta_Gantt_Organizate_COMPLETO.xlsx');

console.log('✅ CARTA GANTT COMPLETA GENERADA EXITOSAMENTE!');
console.log('');
console.log('📊 Archivo: Carta_Gantt_Organizate_COMPLETO.xlsx');
console.log('');
console.log('📋 CONTENIDO:');
console.log('   ✅ Hoja 1: Resumen del Proyecto (85% completado)');
console.log('   ✅ Hoja 2: Carta Gantt COMPLETA (12 semanas - Abril a Julio)');
console.log('   ✅ Hoja 3: Próximo Sprint (9 tareas pendientes)');
console.log('   ✅ Hoja 4: Hitos / Historial de Commits');
console.log('');
console.log('🎯 ESTADO ACTUAL:');
console.log('   • Fase 1: Fundación y Auth ✓ Completado (27-28 Abr)');
console.log('   • Fase 2: IA / Súper Experto ✓ Completado (28-29 Abr)');
console.log('   • Fase 3: Módulo TEA (Pictogramas) ✓ Completado (30 Abr-06 May)');
console.log('   • Fase 4: Módulo TDAH (Tareas) ✓ Completado (05-09 May)');
console.log('   • Fase 5: Integración y Correcciones ► En Curso (75%)');
console.log('   • Fase 6: Pulido y Testing ○ Pendiente');
console.log('   • Fase 7: Documentación y Entrega ○ Pendiente (SIN TIENDAS)');
console.log('');
console.log('📌 TAREAS CRÍTICAS PENDIENTES:');
console.log('   🔴 Alta: Completar supervisión tutor -> detalle de paciente');
console.log('   🔴 Alta: Sincronización bidireccional tareas tutor <-> paciente');
console.log('   🟡 Media: Kiosk Mode paciente TEA');
console.log('   🟡 Media: Dashboard progreso (fl_chart)');
console.log('   🟡 Media: Documentación técnica');
console.log('   🟡 Media: Manual de usuario');
console.log('   🟡 Media: Presentación final');
console.log('');
console.log('📅 HITOS:');
console.log('   ✓ S6 (13 May): Vinculación Tutor-Paciente (ALCANZADO)');
console.log('   ○ S7 (26 May): Sincronización Completa (Pendiente)');
console.log('   ○ S11 (30 Jun): MVP Listo (Pendiente)');
console.log('   ○ S12 (07 Jul): Entrega Final (Pendiente)');
console.log('');
console.log('⚠️  NOTA: Se eliminó todo lo relacionado con Play Store y App Store');
console.log('   La entrega será mediante APK/Instalación directa');
