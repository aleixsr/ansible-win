#Requires -Version 5.1
# -----------------------------------------------------------------------------
# AQUEST FITXER ES ASCII PUR I SENSE BOM. NO HI POSIS ACCENTS.
# -----------------------------------------------------------------------------
# Es l'unic fitxer del repo amb aquesta restriccio, i te un motiu a cada banda:
#
#   Sense BOM, perque es baixa i s'executa amb `irm ... | iex`. Si hi hagues
#   BOM, `irm` el tornaria com un caracter mes dins de la cadena, s'enganxaria
#   al `#Requires` de la linia 1 i el parser petaria amb un "Unexpected token
#   'param'" que no diu res de la causa.
#
#   Sense accents, perque Windows PowerShell 5.1 llegeix en ANSI tot .ps1 que
#   no porti BOM. Els accents sortirien trencats ("instalA.lacio", "mAquina")
#   quan s'executa com a fitxer amb .\bootstrap.ps1.
#
# Les dues coses alhora nomes es compleixen amb ASCII i sense BOM. La resta del
# repo si que porta BOM i accents: alla no hi ha cap `iex` pel mig.
# -----------------------------------------------------------------------------
<#
.SYNOPSIS
    Prepara una maquina Windows acabada d'instal.lar per poder executar run.ps1.

.DESCRIPTION
    L'unica cosa que cal per comencar. Deixa llest:
      1. TLS 1.2 i politica d'execucio per a aquest proces
      2. Chocolatey (si falta)
      3. gsudo, perque la resta pugui elevar sense obrir mil UAC
      4. Git (perque el repo es pugui actualitzar amb git pull)
      5. El modul powershell-yaml, que es el que llegeix el cataleg
      6. Opcionalment, executa run.ps1 tot seguit

    Es pot executar directament des d'Internet:

        irm https://raw.githubusercontent.com/aleixsr/ansible-win/main/bootstrap.ps1 | iex

.PARAMETER Run
    Encadena run.ps1 quan el bootstrap acabi.

.PARAMETER RepoUrl
    D'on clonar si el bootstrap s'executa fora d'un clon del repo.

.PARAMETER Path
    On clonar el repo. Per defecte %USERPROFILE%\ansible-win.
#>
[CmdletBinding()]
param(
    [switch]$Run,
    [string]$RepoUrl = 'https://github.com/aleixsr/ansible-win.git',
    [string]$Path = (Join-Path $env:USERPROFILE 'ansible-win')
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Write-Step {
    param([string]$Message)
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    OK  $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    !!  $Message" -ForegroundColor Yellow
}

function Test-Cmd {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Sync-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host ''
Write-Host '  ansible-win - bootstrap' -ForegroundColor Magenta
Write-Host '  ---------------------------' -ForegroundColor DarkGray

# -----------------------------------------------------------------------------
# 1. Requisits del proces
# -----------------------------------------------------------------------------
Write-Step 'Preparant el proces'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy Bypass -Scope Process -Force
Write-Ok 'TLS 1.2 i ExecutionPolicy Bypass (nomes per a aquest proces)'

if (-not (Test-Admin)) {
    Write-Warn 'No ets administrador: Chocolatey i alguns paquets demanaran UAC.'
}

# -----------------------------------------------------------------------------
# 2. winget
# -----------------------------------------------------------------------------
Write-Step 'winget'
if (Test-Cmd 'winget') {
    Write-Ok (Get-Command winget).Source
} else {
    Write-Warn 'winget no hi es. Instal.la "Instal.lador de aplicaciones" des de'
    Write-Warn 'Microsoft Store o https://aka.ms/getwinget i torna a executar aixo.'
}

# -----------------------------------------------------------------------------
# 3. Chocolatey
# -----------------------------------------------------------------------------
Write-Step 'Chocolatey'
if (Test-Cmd 'choco') {
    Write-Ok (Get-Command choco).Source
} else {
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
        'https://community.chocolatey.org/install.ps1'))
    Sync-Path
    Write-Ok 'Chocolatey instal.lat'
}

# -----------------------------------------------------------------------------
# 4. gsudo  (i `sudo` sense la g)
# -----------------------------------------------------------------------------
Write-Step 'gsudo'
if (Test-Cmd 'gsudo') {
    Write-Ok (Get-Command gsudo).Source
} elseif (Test-Cmd 'winget') {
    & winget install --id gerardog.gsudo --exact --silent `
        --accept-package-agreements --accept-source-agreements --disable-interactivity
    Sync-Path
    Write-Ok 'gsudo instal.lat (winget)'
} else {
    & choco install gsudo -y --no-progress
    Sync-Path
    Write-Ok 'gsudo instal.lat (choco)'
}

# -----------------------------------------------------------------------------
# 5. Git
# -----------------------------------------------------------------------------
Write-Step 'Git'
if (Test-Cmd 'git') {
    Write-Ok (& git --version)
} elseif (Test-Cmd 'winget') {
    & winget install --id Git.Git --exact --silent `
        --accept-package-agreements --accept-source-agreements --disable-interactivity
    Sync-Path
    Write-Ok 'Git instal.lat'
} else {
    & choco install git -y --no-progress
    Sync-Path
    Write-Ok 'Git instal.lat'
}

# -----------------------------------------------------------------------------
# 6. powershell-yaml
# -----------------------------------------------------------------------------
Write-Step 'Modul powershell-yaml'
if (Get-Module -ListAvailable powershell-yaml) {
    Write-Ok 'ja instal.lat'
} else {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if ($repo -and $repo.InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    Install-Module powershell-yaml -Scope CurrentUser -Force -AllowClobber
    Write-Ok 'powershell-yaml instal.lat'
}

# -----------------------------------------------------------------------------
# 7. El repo
# -----------------------------------------------------------------------------
Write-Step 'Repositori'
$here = $null
if ($PSScriptRoot) { $here = $PSScriptRoot }

if ($here -and (Test-Path -LiteralPath (Join-Path $here 'run.ps1'))) {
    $repoPath = $here
    Write-Ok "ja hi som: $repoPath"
} elseif (Test-Path -LiteralPath (Join-Path $Path 'run.ps1')) {
    $repoPath = $Path
    Push-Location $repoPath
    try { & git pull --ff-only 2>&1 | Out-Null } catch { }
    Pop-Location
    Write-Ok "actualitzat: $repoPath"
} else {
    & git clone $RepoUrl $Path
    $repoPath = $Path
    Write-Ok "clonat a: $repoPath"
}

# -----------------------------------------------------------------------------
# Final
# -----------------------------------------------------------------------------
Write-Host ''
Write-Host '  Bootstrap llest.' -ForegroundColor Green
Write-Host ''

if ($Run) {
    & (Join-Path $repoPath 'run.ps1')
} else {
    Write-Host '  Seguents passos:' -ForegroundColor White
    Write-Host "     cd $repoPath"
    Write-Host '     .\run.ps1 -Check      # simulacio: mira que faria'
    Write-Host '     .\run.ps1             # provisiona de debo'
    Write-Host ''
}
