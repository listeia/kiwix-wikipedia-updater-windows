[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$taskName = "Actualizar Wikipedia Kiwix"
$installDir = Join-Path $env:LOCALAPPDATA "KiwixUpdater"

$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Tarea programada eliminada."
}
else {
    Write-Host "No se encontró la tarea programada."
}

if (Test-Path -LiteralPath $installDir) {
    Remove-Item -LiteralPath $installDir -Recurse -Force
    Write-Host "Configuración del actualizador eliminada."
}

Write-Host "Los archivos .zim NO se han borrado."
Read-Host "Pulsa Intro"
