#Requires -Version 5.1
<#
.SYNOPSIS
    Prepara una màquina Windows acabada d'instal·lar per poder executar run.ps1.

.DESCRIPTION
    L'única cosa que cal per començar. Deixa llest:
      1. TLS 1.2 i política d'execució per a aquest procés
      2. Chocolatey (si falta)
      3. gsudo, perquè la resta pugui elevar sense obrir mil UAC
      4. Git (perquè el repo es pugui actualitzar amb git pull)
      5. El mòdul powershell-yaml, que és el que llegeix el catàleg
      6. Opcionalment, executa run.ps1 tot seguit

    Es pot executar directament des d'Internet:

        irm https://raw.githubusercontent.com/<usuari>/ansible_windows/main/bootstrap.ps1 | iex

.PARAMETER Run
    Encadena run.ps1 quan el bootstrap acabi.

.PARAMETER RepoUrl
    D'on clonar si el bootstrap s'executa fora d'un clon del repo.

.PARAMETER Path
    On clonar el repo. Per defecte %USERPROFILE%\ansible_windows.
#>
[CmdletBinding()]
param(
    [switch]$Run,
    [string]$RepoUrl = 'https://github.com/REPLACE_ME/ansible_windows.git',
    [string]$Path = (Join-Path $env:USERPROFILE 'ansible_windows')
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
Write-Host '  ansible_windows - bootstrap' -ForegroundColor Magenta
Write-Host '  ---------------------------' -ForegroundColor DarkGray

# -----------------------------------------------------------------------------
# 1. Requisits del procés
# -----------------------------------------------------------------------------
Write-Step 'Preparant el procés'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy Bypass -Scope Process -Force
Write-Ok 'TLS 1.2 i ExecutionPolicy Bypass (només per a aquest procés)'

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
    Write-Warn 'winget no hi és. Instal·la "Instal·lador de aplicaciones" des de'
    Write-Warn 'Microsoft Store o https://aka.ms/getwinget i torna a executar això.'
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
    Write-Ok 'Chocolatey instal·lat'
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
    Write-Ok 'gsudo instal·lat (winget)'
} else {
    & choco install gsudo -y --no-progress
    Sync-Path
    Write-Ok 'gsudo instal·lat (choco)'
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
    Write-Ok 'Git instal·lat'
} else {
    & choco install git -y --no-progress
    Sync-Path
    Write-Ok 'Git instal·lat'
}

# -----------------------------------------------------------------------------
# 6. powershell-yaml
# -----------------------------------------------------------------------------
Write-Step 'Mòdul powershell-yaml'
if (Get-Module -ListAvailable powershell-yaml) {
    Write-Ok 'ja instal·lat'
} else {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if ($repo -and $repo.InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    Install-Module powershell-yaml -Scope CurrentUser -Force -AllowClobber
    Write-Ok 'powershell-yaml instal·lat'
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
    if ($RepoUrl -like '*REPLACE_ME*') {
        Write-Warn 'RepoUrl no configurada. Clona el repo a mà i torna a executar bootstrap.ps1 des de dins.'
        exit 1
    }
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
    Write-Host '  Següents passos:' -ForegroundColor White
    Write-Host "     cd $repoPath"
    Write-Host '     .\run.ps1 -Check      # simulació: mira què faria'
    Write-Host '     .\run.ps1             # provisiona de debò'
    Write-Host ''
}
