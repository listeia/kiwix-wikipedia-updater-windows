[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$taskName = "Actualizar Wikipedia Kiwix"
$installDir = Join-Path $env:LOCALAPPDATA "KiwixUpdater"
$updaterSource = Join-Path $PSScriptRoot "Actualizar-Wikipedia-Kiwix.ps1"
$updaterTarget = Join-Path $installDir "Actualizar-Wikipedia-Kiwix.ps1"
$configPath = Join-Path $installDir "config.json"

Write-Host ""
Write-Host "CONFIGURACIÓN DEL ACTUALIZADOR DE WIKIPEDIA PARA KIWIX" -ForegroundColor Cyan
Write-Host "-----------------------------------------------------"
Write-Host "1 - mini: solo introducción e infobox; ocupa mucho menos."
Write-Host "2 - nopic: artículos completos sin imágenes. Recomendación equilibrada."
Write-Host "3 - maxi: artículos completos con imágenes; descarga muy grande."
Write-Host ""

$choice = Read-Host "Elige edición [2]"
if ([string]::IsNullOrWhiteSpace($choice)) {
    $choice = "2"
}

$edition = switch ($choice.Trim()) {
    "1" { "mini" }
    "2" { "nopic" }
    "3" { "maxi" }
    default { throw "Opción no válida. Ejecuta de nuevo el configurador." }
}

$defaultDestination = Join-Path $env:USERPROFILE "Kiwix\Wikipedia_ES"
$destinationInput = Read-Host "Carpeta donde guardar la Wikipedia [$defaultDestination]"
$destination = if ([string]::IsNullOrWhiteSpace($destinationInput)) {
    $defaultDestination
}
else {
    [Environment]::ExpandEnvironmentVariables($destinationInput.Trim().Trim('"'))
}

New-Item -ItemType Directory -Path $installDir -Force | Out-Null
New-Item -ItemType Directory -Path $destination -Force | Out-Null

if (-not (Test-Path -LiteralPath $updaterSource)) {
    throw "No se encuentra $updaterSource. Extrae primero todos los archivos del ZIP."
}

Copy-Item -LiteralPath $updaterSource -Destination $updaterTarget -Force

$config = [ordered]@{
    edition = $edition
    destination = $destination
    keepVersions = 1
}

$config | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8

$powershellExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
$arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$updaterTarget`" -ConfigPath `"$configPath`""

$action = New-ScheduledTaskAction -Execute $powershellExe -Argument $arguments
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3:00AM
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Days 4)

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Comprueba el catálogo oficial de Kiwix y descarga la Wikipedia española más reciente." `
    -Force | Out-Null

Write-Host ""
Write-Host "Configuración guardada." -ForegroundColor Green
Write-Host "Edición: $edition"
Write-Host "Carpeta: $destination"
Write-Host "La comprobación se hará cada domingo a las 03:00."
Write-Host "Si el equipo está apagado, Windows intentará ejecutarla cuando vuelva a estar disponible."
Write-Host ""

$downloadNow = Read-Host "¿Quieres comprobar y descargar ahora? [S/n]"
if ([string]::IsNullOrWhiteSpace($downloadNow) -or $downloadNow.Trim().ToLowerInvariant() -in @("s", "si", "sí", "y", "yes")) {
    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $updaterTarget -ConfigPath $configPath
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "La actualización no terminó correctamente. Consulta actualizacion-kiwix.log en la carpeta de destino."
    }
}

Write-Host ""
Write-Host "Terminado. Puedes cerrar esta ventana."
Read-Host "Pulsa Intro"
