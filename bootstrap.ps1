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
      2. Chocolatey, gsudo i Git, que van a escala de maquina i per tant
         demanen UNA sola elevacio entre tots tres
      3. El modul powershell-yaml, que es el que llegeix el cataleg
      4. Clona el repo (o l'actualitza si ja hi es)
      5. Opcionalment, executa run.ps1 tot seguit

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
# 3. El que necessita privilegis: Chocolatey, gsudo i Git
# -----------------------------------------------------------------------------
# Els tres s'instal.len a escala de maquina. Chocolatey ni tan sols demana UAC:
# es nega amb un "requires Administrative permissions" i prou. winget, amb
# --disable-interactivity, tampoc no pot obrir el dialeg.
#
# Per aixo els agrupem i demanem UNA sola elevacio per als que faltin, igual que
# fa run.ps1. No elevem el bootstrap sencer a proposit: si l'usuari no es
# administrador, l'UAC demanaria credencials d'un altre compte i el clon del
# repo acabaria al perfil equivocat. Elevant nomes les instal.lacions, el clon i
# el modul de PowerShell es queden a la sessio de qui ho ha llancat.
Write-Step 'Eines de base'

$ADMIN_PS = @'
Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
'@

$pendents = New-Object System.Collections.ArrayList

if (Test-Cmd 'choco') {
    Write-Ok ('Chocolatey  ' + (Get-Command choco).Source)
} else {
    [void]$pendents.Add(@{
        Nom = 'Chocolatey'
        Cmd = "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    })
}

if (Test-Cmd 'gsudo') {
    Write-Ok ('gsudo       ' + (Get-Command gsudo).Source)
} elseif (Test-Cmd 'winget') {
    [void]$pendents.Add(@{
        Nom = 'gsudo'
        Cmd = "winget install --id gerardog.gsudo --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity"
    })
} else {
    [void]$pendents.Add(@{ Nom = 'gsudo'; Cmd = 'choco install gsudo -y --no-progress' })
}

if (Test-Cmd 'git') {
    Write-Ok ('Git         ' + (& git --version))
} elseif (Test-Cmd 'winget') {
    [void]$pendents.Add(@{
        Nom = 'Git'
        Cmd = "winget install --id Git.Git --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity"
    })
} else {
    [void]$pendents.Add(@{ Nom = 'Git'; Cmd = 'choco install git -y --no-progress' })
}

if ($pendents.Count -eq 0) {
    Write-Ok 'no falta res'
} elseif (Test-Admin) {
    foreach ($t in $pendents) {
        Write-Host ("    .. instal.lant " + $t.Nom)
        Invoke-Expression $t.Cmd
        Sync-Path
        Write-Ok ($t.Nom + ' instal.lat')
    }
} else {
    Write-Host ''
    Write-Host ('  Falten ' + $pendents.Count + ' eines que s.instal.len a escala de maquina:') -ForegroundColor Yellow
    foreach ($t in $pendents) { Write-Host ('     - ' + $t.Nom) -ForegroundColor White }
    Write-Host ''
    Write-Host '  Accepta l.UAC i es fan totes de cop. Es l.unic cop que el demanara.' -ForegroundColor Yellow

    $guio = $ADMIN_PS + "`n" + (($pendents | ForEach-Object { $_.Cmd }) -join "`n")
    $fitxer = Join-Path $env:TEMP ('aw-bootstrap-admin-' + [guid]::NewGuid().ToString('N') + '.ps1')
    Set-Content -LiteralPath $fitxer -Value $guio -Encoding UTF8

    try {
        $p = Start-Process powershell -Verb RunAs -Wait -PassThru -ArgumentList `
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $fitxer
        if ($p.ExitCode -ne 0) {
            Write-Warn ('la part elevada ha acabat amb codi ' + $p.ExitCode)
        }
    } catch {
        Write-Host ''
        Write-Warn 'UAC cancel.lat o sense permisos: no s.ha instal.lat res d.aixo.'
        Write-Warn 'Torna-hi, o obre una consola com a administrador i executa-ho alla.'
    } finally {
        Remove-Item -LiteralPath $fitxer -Force -ErrorAction SilentlyContinue
    }

    Sync-Path
    foreach ($t in $pendents) {
        $ordre = switch ($t.Nom) { 'Chocolatey' { 'choco' } 'gsudo' { 'gsudo' } 'Git' { 'git' } }
        if (Test-Cmd $ordre) { Write-Ok ($t.Nom + ' instal.lat') }
        else { Write-Warn ($t.Nom + ' segueix sense instal.lar') }
    }
}

# -----------------------------------------------------------------------------
# 4. powershell-yaml
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
# 5. El repo
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
    # git escriu "Cloning into..." a stderr, i amb ErrorActionPreference = Stop
    # Windows PowerShell 5.1 ho converteix en error terminant encara que el
    # clon vagi be. Nomes passa quan algu captura la sortida, pero aleshores es
    # un bootstrap que mor a l'ultim pas sense cap motiu visible.
    $eapAnterior = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & git clone $RepoUrl $Path
        $codi = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $eapAnterior
    }

    if ($codi -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $Path 'run.ps1'))) {
        throw "git clone ha fallat (codi $codi). Comprova la connexio i que $Path no existeixi ja."
    }
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
