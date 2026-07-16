[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $env:LOCALAPPDATA "KiwixUpdater\config.json")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO", "AVISO", "ERROR")][string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    Write-Host $line

    if ($script:LogPath) {
        Add-Content -LiteralPath $script:LogPath -Value $line -Encoding UTF8
    }
}

try {
    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        throw "No se encuentra el archivo de configuración: $ConfigPath"
    }

    $config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

    $edition = [string]$config.edition
    $destination = [Environment]::ExpandEnvironmentVariables([string]$config.destination)
    $keepVersions = [int]$config.keepVersions

    if ($edition -notin @("mini", "nopic", "maxi")) {
        throw "Edición no válida: '$edition'. Debe ser mini, nopic o maxi."
    }

    if ($keepVersions -lt 1) {
        $keepVersions = 1
    }

    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $script:LogPath = Join-Path $destination "actualizacion-kiwix.log"

    Write-Log "Comprobando si existe una Wikipedia en español más reciente. Edición: $edition."

    $indexUrl = "https://download.kiwix.org/zim/wikipedia/"
    $response = Invoke-WebRequest -Uri $indexUrl -UseBasicParsing -TimeoutSec 180

    $pattern = "wikipedia_es_all_$([regex]::Escape($edition))_(?<date>\d{4}-\d{2})\.zim"
    $matches = [regex]::Matches($response.Content, $pattern)

    if ($matches.Count -eq 0) {
        throw "No se ha encontrado ninguna versión que coincida con $pattern en el catálogo oficial."
    }

    $versions = $matches | ForEach-Object {
        [PSCustomObject]@{
            File = $_.Value
            Date = [datetime]::ParseExact($_.Groups["date"].Value, "yyyy-MM", $null)
        }
    } | Sort-Object File -Unique | Sort-Object Date -Descending

    $latest = $versions | Select-Object -First 1
    $finalPath = Join-Path $destination $latest.File
    $partialPath = "$finalPath.descarga"
    $downloadUrl = "$indexUrl$($latest.File)"

    if (Test-Path -LiteralPath $finalPath) {
        Write-Log "Ya tienes la versión más reciente: $($latest.File). No se descarga nada."
        exit 0
    }

    $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if (-not $curl) {
        throw "No se encuentra curl.exe. Windows 10/11 suele incluirlo de serie."
    }

    Write-Log "Nueva versión encontrada: $($latest.File)."
    Write-Log "Descargando en: $partialPath"
    Write-Log "Si la conexión se corta, la siguiente ejecución intentará continuar la descarga."

    $curlArguments = @(
        "--location",
        "--fail",
        "--retry", "10",
        "--retry-delay", "30",
        "--continue-at", "-",
        "--output", $partialPath,
        $downloadUrl
    )

    & $curl.Source @curlArguments
    if ($LASTEXITCODE -ne 0) {
        throw "curl terminó con el código $LASTEXITCODE. La descarga parcial se conserva para poder reanudarla."
    }

    $downloadedFile = Get-Item -LiteralPath $partialPath
    if ($downloadedFile.Length -lt 1MB) {
        throw "El archivo descargado es anormalmente pequeño. No se sustituirá la versión anterior."
    }

    Move-Item -LiteralPath $partialPath -Destination $finalPath -Force
    Write-Log "Descarga terminada correctamente: $finalPath"

    $installedVersions = Get-ChildItem -LiteralPath $destination -File |
        Where-Object { $_.Name -match "^wikipedia_es_all_$([regex]::Escape($edition))_\d{4}-\d{2}\.zim$" } |
        Sort-Object Name -Descending

    $oldVersions = $installedVersions | Select-Object -Skip $keepVersions
    foreach ($old in $oldVersions) {
        Write-Log "Eliminando versión antigua: $($old.Name)"
        Remove-Item -LiteralPath $old.FullName -Force
    }

    $status = @"
Última comprobación: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Edición: $edition
Versión disponible: $($latest.File)
Carpeta: $destination
"@
    Set-Content -LiteralPath (Join-Path $destination "ULTIMA_VERSION.txt") -Value $status -Encoding UTF8

    Write-Log "Actualización completada."
    exit 0
}
catch {
    try {
        Write-Log $_.Exception.Message "ERROR"
    }
    catch {
        Write-Error $_.Exception.Message
    }
    exit 1
}
