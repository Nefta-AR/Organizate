const XLSX = require('xlsx');
const fs = require('fs');

// Datos de las tareas organizadas por fase
const tareas = [
  // ANÁLISIS - Color Azul
  { id: 'A1', fase: 'ANÁLISIS', tarea: 'Análisis de requisitos', inicio: 1, duracion: 1, color: '4472C4' },
  { id: 'A2', fase: 'ANÁLISIS', tarea: 'Investigación APIs TTS', inicio: 2, duracion: 1, color: '4472C4' },
  { id: 'A3', fase: 'ANÁLISIS', tarea: 'Arquitectura técnica', inicio: 2, duracion: 1, color: '4472C4' },
  { id: 'A4', fase: 'ANÁLISIS', tarea: 'Modelo de datos', inicio: 3, duracion: 1, color: '4472C4' },
  
  // DISEÑO - Color Verde
  { id: 'D1', fase: 'DISEÑO', tarea: 'Wireframes y flujos', inicio: 2, duracion: 1, color: '70AD47' },
  { id: 'D2', fase: 'DISEÑO', tarea: 'UI/UX Paciente', inicio: 3, duracion: 2, color: '70AD47' },
  { id: 'D3', fase: 'DISEÑO', tarea: 'UI/UX Tutor', inicio: 3, duracion: 2, color: '70AD47' },
  { id: 'D4', fase: 'DISEÑO', tarea: 'Biblioteca pictogramas', inicio: 4, duracion: 1, color: '70AD47' },
  { id: 'D5', fase: 'DISEÑO', tarea: 'Prototipo interactivo', inicio: 5, duracion: 1, color: '70AD47' },
  
  // INFRAESTRUCTURA - Color Naranja
  { id: 'I1', fase: 'INFRAESTRUCTURA', tarea: 'Setup Flutter', inicio: 3, duracion: 1, color: 'ED7D31' },
  { id: 'I2', fase: 'INFRAESTRUCTURA', tarea: 'Configuración Firebase', inicio: 3, duracion: 1, color: 'ED7D31' },
  { id: 'I3', fase: 'INFRAESTRUCTURA', tarea: 'Autenticación', inicio: 4, duracion: 1, color: 'ED7D31' },
  { id: 'I4', fase: 'INFRAESTRUCTURA', tarea: 'Config APIs TTS', inicio: 4, duracion: 1, color: 'ED7D31' },
  
  // MÓDULO PACIENTE - Color Morado
  { id: 'P1', fase: 'MÓDULO PACIENTE', tarea: 'Vista de pictogramas', inicio: 4, duracion: 2, color: '7030A0' },
  { id: 'P2', fase: 'MÓDULO PACIENTE', tarea: 'Sistema de rutinas', inicio: 6, duracion: 2, color: '7030A0' },
  { id: 'P3', fase: 'MÓDULO PACIENTE', tarea: 'Reproducción voz TTS', inicio: 5, duracion: 1, color: '7030A0' },
  { id: 'P4', fase: 'MÓDULO PACIENTE', tarea: 'Personalización visual', inicio: 7, duracion: 1, color: '7030A0' },
  
  // MÓDULO TUTOR - Color Rojo
  { id: 'T1', fase: 'MÓDULO TUTOR', tarea: 'Panel de supervisión', inicio: 5, duracion: 1, color: 'C00000' },
  { id: 'T2', fase: 'MÓDULO TUTOR', tarea: 'CRUD de tareas', inicio: 6, duracion: 2, color: 'C00000' },
  { id: 'T3', fase: 'MÓDULO TUTOR', tarea: 'Gestión de pictogramas', inicio: 7, duracion: 2, color: 'C00000' },
  { id: 'T4', fase: 'MÓDULO TUTOR', tarea: 'Configuración rutinas', inicio: 8, duracion: 2, color: 'C00000' },
  { id: 'T5', fase: 'MÓDULO TUTOR', tarea: 'Vinculación paciente-tutor', inicio: 5, duracion: 1, color: 'C00000' },
  
  // INTEGRACIÓN - Color Amarillo
  { id: 'S1', fase: 'INTEGRACIÓN', tarea: 'Sincronización tiempo real', inicio: 9, duracion: 1, color: 'FFC000' },
  { id: 'S2', fase: 'INTEGRACIÓN', tarea: 'Manejo de imágenes', inicio: 8, duracion: 1, color: 'FFC000' },
  { id: 'S3', fase: 'INTEGRACIÓN', tarea: 'Notificaciones push', inicio: 10, duracion: 1, color: 'FFC000' },
  { id: 'S4', fase: 'INTEGRACIÓN', tarea: 'Modo offline', inicio: 10, duracion: 1, color: 'FFC000' },
  
  // PRUEBAS - Color Turquesa
  { id: 'Q1', fase: 'PRUEBAS', tarea: 'Tests unitarios', inicio: 10, duracion: 1, color: '00B0F0' },
  { id: 'Q2', fase: 'PRUEBAS', tarea: 'Tests de integración', inicio: 11, duracion: 1, color: '00B0F0' },
  { id: 'Q3', fase: 'PRUEBAS', tarea: 'Pruebas con usuarios', inicio: 12, duracion: 2, color: '00B0F0' },
  { id: 'Q4', fase: 'PRUEBAS', tarea: 'Corrección de bugs', inicio: 14, duracion: 1, color: '00B0F0' },
  { id: 'Q5', fase: 'PRUEBAS', tarea: 'Optimización', inicio: 14, duracion: 1, color: '00B0F0' },
  
  // ENTREGA - Color Gris
  { id: 'X1', fase: 'ENTREGA', tarea: 'Documentación técnica', inicio: 15, duracion: 1, color: '404040' },
  { id: 'X2', fase: 'ENTREGA', tarea: 'Manual de usuario', inicio: 13, duracion: 1, color: '404040' },
  { id: 'X3', fase: 'ENTREGA', tarea: 'Preparación tiendas', inicio: 15, duracion: 1, color: '404040' },
  { id: 'X4', fase: 'ENTREGA', tarea: 'Despliegue', inicio: 16, duracion: 1, color: '404040' },
  { id: 'X5', fase: 'ENTREGA', tarea: 'Presentación final', inicio: 16, duracion: 1, color: '404040' }
];

// Crear el libro de trabajo
const wb = XLSX.utils.book_new();
wb.Props = {
  Title: "Carta Gantt - App TEA",
  Subject: "Proyecto App Comunicación TEA",
  Author: "Project Manager",
  CreatedDate: new Date()
};

// Preparar datos para la hoja
const wsData = [];

// Título
wsData.push(['CARTA GANTT - PROYECTO: APP DE COMUNICACIÓN PARA PACIENTES TEA']);
wsData.push(['Stack: Flutter + Firebase | Inicio: 15 Marzo | Fin: Julio | Duración: 16 semanas']);
wsData.push([]);

// Encabezados
const headers = ['ID', 'FASE', 'TAREA', 'INICIO', 'DURACIÓN (sem)'];
for (let i = 1; i <= 16; i++) {
  headers.push(`S${i}`);
}
wsData.push(headers);

// Datos de tareas
tareas.forEach(t => {
  const row = [t.id, t.fase, t.tarea, t.inicio, t.duracion];
  
  // Llenar semanas con barras
  for (let s = 1; s <= 16; s++) {
    if (s >= t.inicio && s < t.inicio + t.duracion) {
      row.push('██████');
    } else {
      row.push('');
    }
  }
  
  wsData.push(row);
});

// Agregar hitos
wsData.push([]);
wsData.push(['★', 'HITO', 'HITO 1: Avance 1 - Diseño y Arquitectura', '', '', '', '', '', '▼ HITO 1', '', '', '', '', '', '', '', '', '', '', '', '']);
wsData.push(['★', 'HITO', 'HITO 2: Core Operativo - Sistema Funcional', '', '', '', '', '', '', '', '▼ HITO 2', '', '', '', '', '', '', '', '', '', '']);
wsData.push(['★', 'HITO', 'HITO 3: MVP Final - Entrega', '', '', '', '', '', '', '', '', '', '', '', '▼ HITO 3', '', '', '', '', '', '']);

// Agregar leyenda
wsData.push([]);
wsData.push(['LEYENDA DE FASES:']);
wsData.push(['', 'ANÁLISIS', 'DISEÑO', 'INFRAESTRUCTURA', 'MÓDULO PACIENTE', 'MÓDULO TUTOR', 'INTEGRACIÓN', 'PRUEBAS', 'ENTREGA']);

// Crear la hoja de trabajo
const ws = XLSX.utils.aoa_to_sheet(wsData);

// Configurar anchos de columna
ws['!cols'] = [
  { wch: 6 },   // ID
  { wch: 20 },  // FASE
  { wch: 38 },  // TAREA
  { wch: 8 },   // INICIO
  { wch: 15 },  // DURACIÓN
];

// Agregar anchos para las 16 semanas
for (let i = 0; i < 16; i++) {
  ws['!cols'].push({ wch: 9 });
}

// Aplicar formato y colores
const range = XLSX.utils.decode_range(ws['!ref']);

// Merge celdas del título
ws['!merges'] = [
  { s: { r: 0, c: 0 }, e: { r: 0, c: 20 } },
  { s: { r: 1, c: 0 }, e: { r: 1, c: 20 } }
];

// Colores de fases
const coloresFases = {
  'ANÁLISIS': '4472C4',
  'DISEÑO': '70AD47',
  'INFRAESTRUCTURA': 'ED7D31',
  'MÓDULO PACIENTE': '7030A0',
  'MÓDULO TUTOR': 'C00000',
  'INTEGRACIÓN': 'FFC000',
  'PRUEBAS': '00B0F0',
  'ENTREGA': '404040'
};

// Aplicar estilos
for (let R = range.s.r; R <= range.e.r; R++) {
  for (let C = range.s.c; C <= range.e.c; C++) {
    const cellAddress = XLSX.utils.encode_cell({ r: R, c: C });
    const cell = ws[cellAddress];
    
    if (!cell) continue;
    
    // Encabezado (fila 3)
    if (R === 3) {
      cell.s = {
        font: { bold: true, color: { rgb: "FFFFFF" } },
        fill: { fgColor: { rgb: "404040" } },
        alignment: { horizontal: "center", vertical: "center" }
      };
    }
    
    // Título principal
    if (R === 0) {
      cell.s = {
        font: { bold: true, sz: 16, color: { rgb: "0066CC" } },
        alignment: { horizontal: "center" }
      };
    }
    
    // Subtítulo
    if (R === 1) {
      cell.s = {
        font: { sz: 10 },
        alignment: { horizontal: "center" }
      };
    }
    
    // Datos de tareas (filas 4 en adelante, hasta los hitos)
    if (R >= 4 && R <= 40) {
      const rowData = wsData[R];
      const fase = rowData ? rowData[1] : '';
      const color = coloresFases[fase];
      
      // Columna FASE
      if (C === 1 && color) {
        cell.s = {
          font: { bold: true, color: { rgb: "FFFFFF" } },
          fill: { fgColor: { rgb: color } },
          alignment: { horizontal: "center" }
        };
      }
      
      // Columnas de semanas (de C=5 en adelante son las semanas)
      if (C >= 5 && cell.v && cell.v.includes('█')) {
        cell.s = {
          font: { color: { rgb: color } },
          fill: { fgColor: { rgb: color } },
          alignment: { horizontal: "center" }
        };
      }
    }
    
    // Hitos
    if (R >= 42 && R <= 44) {
      if (C === 0) {
        cell.s = {
          font: { bold: true, sz: 14, color: { rgb: "FF0000" } }
        };
      }
      if (C === 2) {
        cell.s = {
          font: { bold: true, color: { rgb: "0066CC" } }
        };
      }
      // Marcar columna del hito
      if (cell.v && cell.v.includes('▼')) {
        cell.s = {
          font: { bold: true },
          fill: { fgColor: { rgb: "FFFF00" } },
          alignment: { horizontal: "center" }
        };
      }
    }
    
    // Leyenda
    if (R === 47) {
      cell.s = {
        font: { bold: true, sz: 12 }
      };
    }
  }
}

// Agregar la hoja al libro
XLSX.utils.book_append_sheet(wb, ws, "Carta Gantt");

// Guardar archivo
const outputPath = './Carta_Gantt_TEA_App.xlsx';
XLSX.writeFile(wb, outputPath);

console.log('✅ Archivo Excel generado exitosamente: Carta_Gantt_TEA_App.xlsx');
console.log('📊 Incluye:');
console.log('   - 37 tareas organizadas por fases');
console.log('   - Colores por fase (Análisis, Diseño, Infraestructura, etc.)');
console.log('   - 3 Hitos marcados');
console.log('   - 16 semanas de cronograma');
console.log('   - Formato profesional listo para usar');
