# Script para generar Carta Gantt en Excel
# Guarda este archivo como generar_gantt.ps1 y ejecútalo con PowerShell

# Crear datos de las tareas
$tareas = @(
    # ANÁLISIS - Color Azul Oscuro
    @{ID="A1"; Tarea="Análisis de requisitos"; Fase="ANÁLISIS"; Inicio=1; Duracion=1; Color="4472C4"},
    @{ID="A2"; Tarea="Investigación APIs TTS"; Fase="ANÁLISIS"; Inicio=2; Duracion=1; Color="4472C4"},
    @{ID="A3"; Tarea="Arquitectura técnica"; Fase="ANÁLISIS"; Inicio=2; Duracion=1; Color="4472C4"},
    @{ID="A4"; Tarea="Modelo de datos"; Fase="ANÁLISIS"; Inicio=3; Duracion=1; Color="4472C4"},
    
    # DISEÑO - Color Verde
    @{ID="D1"; Tarea="Wireframes y flujos de usuario"; Fase="DISEÑO"; Inicio=2; Duracion=1; Color="70AD47"},
    @{ID="D2"; Tarea="UI/UX Paciente"; Fase="DISEÑO"; Inicio=3; Duracion=2; Color="70AD47"},
    @{ID="D3"; Tarea="UI/UX Tutor"; Fase="DISEÑO"; Inicio=3; Duracion=2; Color="70AD47"},
    @{ID="D4"; Tarea="Biblioteca de pictogramas"; Fase="DISEÑO"; Inicio=4; Duracion=1; Color="70AD47"},
    @{ID="D5"; Tarea="Prototipo interactivo"; Fase="DISEÑO"; Inicio=5; Duracion=1; Color="70AD47"},
    
    # INFRAESTRUCTURA - Color Naranja
    @{ID="I1"; Tarea="Setup proyecto Flutter"; Fase="INFRAESTRUCTURA"; Inicio=3; Duracion=1; Color="ED7D31"},
    @{ID="I2"; Tarea="Configuración Firebase"; Fase="INFRAESTRUCTURA"; Inicio=3; Duracion=1; Color="ED7D31"},
    @{ID="I3"; Tarea="Autenticación"; Fase="INFRAESTRUCTURA"; Inicio=4; Duracion=1; Color="ED7D31"},
    @{ID="I4"; Tarea="Config APIs TTS"; Fase="INFRAESTRUCTURA"; Inicio=4; Duracion=1; Color="ED7D31"},
    
    # MÓDULO PACIENTE - Color Morado
    @{ID="P1"; Tarea="Vista de pictogramas"; Fase="MÓDULO PACIENTE"; Inicio=4; Duracion=2; Color="7030A0"},
    @{ID="P2"; Tarea="Sistema de rutinas"; Fase="MÓDULO PACIENTE"; Inicio=6; Duracion=2; Color="7030A0"},
    @{ID="P3"; Tarea="Reproducción de voz (TTS)"; Fase="MÓDULO PACIENTE"; Inicio=5; Duracion=1; Color="7030A0"},
    @{ID="P4"; Tarea="Personalización visual"; Fase="MÓDULO PACIENTE"; Inicio=7; Duracion=1; Color="7030A0"},
    
    # MÓDULO TUTOR - Color Rojo
    @{ID="T1"; Tarea="Panel de supervisión"; Fase="MÓDULO TUTOR"; Inicio=5; Duracion=1; Color="C00000"},
    @{ID="T2"; Tarea="CRUD de tareas"; Fase="MÓDULO TUTOR"; Inicio=6; Duracion=2; Color="C00000"},
    @{ID="T3"; Tarea="Gestión de pictogramas"; Fase="MÓDULO TUTOR"; Inicio=7; Duracion=2; Color="C00000"},
    @{ID="T4"; Tarea="Configuración de rutinas"; Fase="MÓDULO TUTOR"; Inicio=8; Duracion=2; Color="C00000"},
    @{ID="T5"; Tarea="Vinculación paciente-tutor"; Fase="MÓDULO TUTOR"; Inicio=5; Duracion=1; Color="C00000"},
    
    # INTEGRACIÓN - Color Amarillo
    @{ID="S1"; Tarea="Sincronización tiempo real"; Fase="INTEGRACIÓN"; Inicio=9; Duracion=1; Color="FFC000"},
    @{ID="S2"; Tarea="Manejo de imágenes"; Fase="INTEGRACIÓN"; Inicio=8; Duracion=1; Color="FFC000"},
    @{ID="S3"; Tarea="Notificaciones push"; Fase="INTEGRACIÓN"; Inicio=10; Duracion=1; Color="FFC000"},
    @{ID="S4"; Tarea="Modo offline"; Fase="INTEGRACIÓN"; Inicio=10; Duracion=1; Color="FFC000"},
    
    # PRUEBAS - Color Turquesa
    @{ID="Q1"; Tarea="Tests unitarios"; Fase="PRUEBAS"; Inicio=10; Duracion=1; Color="00B0F0"},
    @{ID="Q2"; Tarea="Tests de integración"; Fase="PRUEBAS"; Inicio=11; Duracion=1; Color="00B0F0"},
    @{ID="Q3"; Tarea="Pruebas con usuarios"; Fase="PRUEBAS"; Inicio=12; Duracion=2; Color="00B0F0"},
    @{ID="Q4"; Tarea="Corrección de bugs"; Fase="PRUEBAS"; Inicio=14; Duracion=1; Color="00B0F0"},
    @{ID="Q5"; Tarea="Optimización"; Fase="PRUEBAS"; Inicio=14; Duracion=1; Color="00B0F0"},
    
    # ENTREGA - Color Gris Oscuro
    @{ID="X1"; Tarea="Documentación técnica"; Fase="ENTREGA"; Inicio=15; Duracion=1; Color="404040"},
    @{ID="X2"; Tarea="Manual de usuario"; Fase="ENTREGA"; Inicio=13; Duracion=1; Color="404040"},
    @{ID="X3"; Tarea="Preparación tiendas"; Fase="ENTREGA"; Inicio=15; Duracion=1; Color="404040"},
    @{ID="X4"; Tarea="Despliegue"; Fase="ENTREGA"; Inicio=16; Duracion=1; Color="404040"},
    @{ID="X5"; Tarea="Presentación final"; Fase="ENTREGA"; Inicio=16; Duracion=1; Color="404040"}
)

# Hitos
$hitos = @(
    @{Nombre="HITO 1: Avance 1 (Diseño y Arquitectura)"; Semana=4; Color="FF0000"},
    @{Nombre="HITO 2: Core Operativo (Sistema Funcional)"; Semana=9; Color="FF0000"},
    @{Nombre="HITO 3: MVP Final (Entrega)"; Semana=14; Color="FF0000"}
)

# Crear aplicación Excel
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $true
$workbook = $excel.Workbooks.Add()
$sheet = $workbook.Worksheets.Item(1)
$sheet.Name = "Carta Gantt TEA App"

# Configurar título principal
$sheet.Cells.Item(1,1) = "CARTA GANTT - PROYECTO: APP DE COMUNICACIÓN PARA PACIENTES TEA"
$sheet.Cells.Item(1,1).Font.Bold = $true
$sheet.Cells.Item(1,1).Font.Size = 16
$sheet.Cells.Item(1,1).Font.Color = -16776961  # Azul
$sheet.Range("A1:R1").Merge()
$sheet.Cells.Item(1,1).HorizontalAlignment = -4108  # Centrado

# Información del proyecto
$sheet.Cells.Item(2,1) = "Stack: Flutter + Firebase | Inicio: 15 Marzo | Fin: Julio | Duración: 16 semanas"
$sheet.Cells.Item(2,1).Font.Size = 10
$sheet.Range("A2:R2").Merge()
$sheet.Cells.Item(2,1).HorizontalAlignment = -4108

# Encabezados
$sheet.Cells.Item(4,1) = "ID"
$sheet.Cells.Item(4,2) = "FASE"
$sheet.Cells.Item(4,3) = "TAREA"
$sheet.Cells.Item(4,4) = "INICIO"
$sheet.Cells.Item(4,5) = "DURACIÓN"

# Encabezados de semanas
for ($s = 1; $s -le 16; $s++) {
    $col = 5 + $s
    $sheet.Cells.Item(4,$col) = "S$s"
    $sheet.Cells.Item(4,$col).Font.Bold = $true
    $sheet.Cells.Item(4,$col).HorizontalAlignment = -4108
    $sheet.Cells.Item(4,$col).Interior.Color = 12632256  # Gris claro
}

# Formato encabezados
$headerRange = $sheet.Range("A4:R4")
$headerRange.Font.Bold = $true
$headerRange.Font.Size = 11
$headerRange.Interior.Color = 4210752  # Gris oscuro
$headerRange.Font.Color = -16777216  # Negro
$headerRange.HorizontalAlignment = -4108

# Escribir tareas
$row = 5
foreach ($t in $tareas) {
    $sheet.Cells.Item($row,1) = $t.ID
    $sheet.Cells.Item($row,2) = $t.Fase
    $sheet.Cells.Item($row,3) = $t.Tarea
    $sheet.Cells.Item($row,4) = $t.Inicio
    $sheet.Cells.Item($row,5) = $t.Duracion
    
    # Aplicar color a la columna de fase
    $sheet.Cells.Item($row,2).Interior.Color = [Convert]::ToInt32($t.Color, 16)
    $sheet.Cells.Item($row,2).Font.Bold = $true
    $sheet.Cells.Item($row,2).Font.Color = -1  # Blanco
    
    # Colorear las semanas correspondientes
    $inicioSemana = $t.Inicio
    $finSemana = $t.Inicio + $t.Duracion - 1
    
    for ($s = $inicioSemana; $s -le $finSemana; $s++) {
        if ($s -le 16) {
            $col = 5 + $s
            $cell = $sheet.Cells.Item($row,$col)
            $cell.Interior.Color = [Convert]::ToInt32($t.Color, 16)
            $cell.Value = "█"
            $cell.Font.Color = [Convert]::ToInt32($t.Color, 16)
            $cell.HorizontalAlignment = -4108
        }
    }
    
    $row++
}

# Agregar filas de hitos
foreach ($h in $hitos) {
    $sheet.Cells.Item($row,1) = "★"
    $sheet.Cells.Item($row,2) = "HITO"
    $sheet.Cells.Item($row,3) = $h.Nombre
    $sheet.Cells.Item($row,3).Font.Bold = $true
    $sheet.Cells.Item($row,3).Font.Color = -16776961  # Azul
    
    $col = 5 + $h.Semana
    $sheet.Cells.Item($row,$col) = "▼ HITO"
    $sheet.Cells.Item($row,$col).Interior.Color = 255  # Rojo
    $sheet.Cells.Item($row,$col).Font.Bold = $true
    $sheet.Cells.Item($row,$col).Font.Color = -16777216
    $sheet.Cells.Item($row,$col).HorizontalAlignment = -4108
    
    $sheet.Range("A$row:R$row").Interior.Color = 10092441  # Fondo celeste claro
    $row++
}

# Agregar leyenda
$leyendaRow = $row + 2
$sheet.Cells.Item($leyendaRow,1) = "LEYENDA DE FASES:"
$sheet.Cells.Item($leyendaRow,1).Font.Bold = $true
$sheet.Cells.Item($leyendaRow,1).Font.Size = 12

$coloresLeyenda = @(
    @{Nombre="ANÁLISIS"; Color="4472C4"},
    @{Nombre="DISEÑO"; Color="70AD47"},
    @{Nombre="INFRAESTRUCTURA"; Color="ED7D31"},
    @{Nombre="MÓDULO PACIENTE"; Color="7030A0"},
    @{Nombre="MÓDULO TUTOR"; Color="C00000"},
    @{Nombre="INTEGRACIÓN"; Color="FFC000"},
    @{Nombre="PRUEBAS"; Color="00B0F0"},
    @{Nombre="ENTREGA"; Color="404040"}
)

$leyendaRow++
$colLeyenda = 1
foreach ($l in $coloresLeyenda) {
    $sheet.Cells.Item($leyendaRow,$colLeyenda) = $l.Nombre
    $sheet.Cells.Item($leyendaRow,$colLeyenda).Interior.Color = [Convert]::ToInt32($l.Color, 16)
    $sheet.Cells.Item($leyendaRow,$colLeyenda).Font.Color = -1
    $sheet.Cells.Item($leyendaRow,$colLeyenda).Font.Bold = $true
    $sheet.Cells.Item($leyendaRow,$colLeyenda).HorizontalAlignment = -4108
    $colLeyenda++
}

# Ajustar anchos de columna
$sheet.Columns.Item(1).ColumnWidth = 6   # ID
$sheet.Columns.Item(2).ColumnWidth = 20  # FASE
$sheet.Columns.Item(3).ColumnWidth = 35  # TAREA
$sheet.Columns.Item(4).ColumnWidth = 8   # INICIO
$sheet.Columns.Item(5).ColumnWidth = 10  # DURACIÓN

for ($c = 6; $c -le 21; $c++) {
    $sheet.Columns.Item($c).ColumnWidth = 6  # Semanas
}

# Congelar paneles
$sheet.Application.ActiveWindow.SplitColumn = 5
$sheet.Application.ActiveWindow.SplitRow = 4
$sheet.Application.ActiveWindow.FreezePanes = $true

# Guardar archivo
$rutaArchivo = "$PSScriptRoot\Carta_Gantt_TEA_App.xlsx"
$workbook.SaveAs($rutaArchivo)

Write-Host "✅ Archivo Excel generado exitosamente en: $rutaArchivo" -ForegroundColor Green
Write-Host "📊 El archivo se ha abierto automáticamente en Excel" -ForegroundColor Cyan
