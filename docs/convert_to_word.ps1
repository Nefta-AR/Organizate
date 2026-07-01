$htmlPath  = "d:\ProyectosFlutter\Organizate\docs\documentacion_simple.html"
$docxPath  = "d:\ProyectosFlutter\Organizate\docs\Documentacion_Tecnica_Simple.docx"

$word = New-Object -ComObject Word.Application
$word.Visible = $false

$doc = $word.Documents.Open($htmlPath)
$doc.SaveAs2($docxPath, 16)
$doc.Close()
$word.Quit()

Write-Host "Conversion complete: $docxPath"
