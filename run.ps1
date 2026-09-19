#Requires -Version 5.1
<#
.SYNOPSIS
    Provisiona aquesta màquina Windows a partir de config.yml.

.DESCRIPTION
    Equivalent a `ansible-playbook playbook.yml` d'ansible_mac. Executa els rols
    en ordre, de forma idempotent: tornar-lo a executar no canvia res si ja tot
    està al seu lloc.

.PARAMETER Roles
    Rols a executar. Per defecte, els de `default_roles` del catàleg.

.PARAMETER Groups
    Grups de paquets per al rol `apps`. Per defecte, els de `default_groups`.

.PARAMETER Check
    Mode simulació: ensenya què canviaria sense tocar res (com `--check`).

.PARAMETER Upgrade
    Actualitza els paquets ja instal·lats en comptes de deixar-los com estan.

.PARAMETER ListPackages
    Ensenya el catàleg i surt.

.PARAMETER NoElevate
    No demanis privilegis encara que faltin.

.EXAMPLE
    .\run.ps1
    Provisionament complet.

.EXAMPLE
    .\run.ps1 -Check
    Simulació: què faria.

.EXAMPLE
    .\run.ps1 -Roles apps -Groups dev,cli

.EXAMPLE
    .\run.ps1 -Upgrade
    Actualitza tot el que ja hi ha instal·lat.
#>
[CmdletBinding()]
param(
    [string[]]$Roles,
    [string[]]$Groups,
    [switch]$Check,
    [switch]$Upgrade,
    [switch]$ListPackages,
    [switch]$NoElevate
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

<#
.SYNOPSIS
    Parteix arguments de llista que arriben com un sol element separat per comes.
.DESCRIPTION
    Amb `powershell -File`, "-Groups a,b" NO es parteix en dos elements: arriba
    com la cadena "a,b" i no coincideix amb cap grup. I l'auto-elevació d'aquest
    mateix script es rellança amb -File, així que sense això qualsevol run amb
    -Groups que s'elevés seleccionaria zero paquets, en silenci.
#>
function Split-ListArgument {
    param([string[]]$Value)
    if (-not $Value) { return @() }
    $out = New-Object System.Collections.ArrayList
    foreach ($item in $Value) {
        foreach ($piece in ($item -split ',')) {
            $trimmed = $piece.Trim()
            if ($trimmed) { [void]$out.Add($trimmed) }
        }
    }
    return $out.ToArray()
}

$Roles = Split-ListArgument $Roles
$Groups = Split-ListArgument $Groups

# -----------------------------------------------------------------------------
# Registre de la sessió
# -----------------------------------------------------------------------------
# Sense això, l'única còpia de la sortida d'un run és la consola de qui l'ha
# executat: si falla, no hi ha res per ensenyar a ningú. Els logs van al repo
# (ignorats per git) i es conserven els 20 últims.
$LogFile = $null
try {
    $logDir = Join-Path $RepoRoot 'logs'
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Get-ChildItem -LiteralPath $logDir -Filter 'run-*.log' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -Skip 20 |
        Remove-Item -Force -ErrorAction SilentlyContinue

    $LogFile = Join-Path $logDir ("run-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Start-Transcript -LiteralPath $LogFile -Force | Out-Null
} catch {
    # Un log és un extra: que no funcioni no ha d'aturar el provisionament.
    $LogFile = $null
}

# UTF-8 a la consola: si no, els accents surten trencats a Windows PowerShell.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

# -----------------------------------------------------------------------------
# Mòdul i configuració
# -----------------------------------------------------------------------------
Import-Module (Join-Path $RepoRoot 'lib\Provision.psm1') -Force -DisableNameChecking

if (-not (Get-Module -ListAvailable powershell-yaml)) {
    Write-Host 'Falta el mòdul powershell-yaml.' -ForegroundColor Red
    Write-Host 'Executa primer:  .\bootstrap.ps1' -ForegroundColor Yellow
    exit 1
}

$config = Import-ProvisionConfig -Root $RepoRoot

# -----------------------------------------------------------------------------
# --list-packages
# -----------------------------------------------------------------------------
if ($ListPackages) {
    foreach ($group in @($config.packages.Keys | Sort-Object)) {
        $isDefault = @($config.default_groups) -contains $group
        $marker = '  '
        if ($isDefault) { $marker = '* ' }
        Write-Host ''
        Write-Host "$marker$group" -ForegroundColor Cyan
        foreach ($pkg in @($config.packages[$group])) {
            if (-not $pkg) { continue }
            $resolved = Resolve-PackageProvider -Package $pkg -ProviderOrder $config.provider_order
            $via = 'cap proveïdor'
            if ($resolved) { $via = "$($resolved.Provider):$($resolved.Id)" }
            $brew = $pkg.brew
            if (-not $brew) { $brew = '?' }
            Write-Host ("    {0,-28} {1,-42} brew: {2}" -f $pkg.name, $via, $brew)
        }
    }
    Write-Host ''
    Write-Host '* = grup inclòs a default_groups' -ForegroundColor DarkGray
    exit 0
}

# -----------------------------------------------------------------------------
# Elevació
# -----------------------------------------------------------------------------
# Instal·lar a escala de màquina i tocar HKLM necessita admin. Sense elevació el
# run funciona igual, però cada paquet obre un UAC i els ajustos d'HKLM se salten.
if (-not (Test-Elevated) -and -not $NoElevate -and -not $Check) {
    $gsudo = Get-Command gsudo -ErrorAction SilentlyContinue
    if ($gsudo) {

        # Les apps de la Microsoft Store són MSIX i s'instal·len PER USUARI: des
        # d'un procés elevat fallen sempre. Com que tot seguit ens reobrim
        # elevats, les fem ara, que encara som al context d'usuari. Un cop
        # elevats, Install-CatalogPackage les salta amb un missatge explicatiu.
        $storePkgs = @(Select-CatalogPackages -Config $config -Groups $Groups |
                       Where-Object { $_.source -eq 'msstore' })
        # $rolesToRun encara no existeix aquí: mirem els paràmetres directament.
        # Sense -Roles s'executen els default_roles, que inclouen 'apps'.
        if ($storePkgs.Count -gt 0 -and (-not $Roles -or $Roles -contains 'apps')) {
            Write-Play "ansible-win - apps de la Microsoft Store (sense elevar)"
            Write-Info 'Els paquets MSIX no es poden instal·lar elevat: es fan abans.'
            Set-ProvisionContext -Role 'apps/store'
            foreach ($pkg in $storePkgs) {
                Install-CatalogPackage -Package $pkg -ProviderOrder $config.provider_order -Upgrade:$Upgrade
            }
            Clear-ProvisionResults
        }

        Write-Host ''
        Write-Host 'Reobrint el run amb privilegis via gsudo...' -ForegroundColor Yellow

        $relaunch = @('powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                      '-File', $MyInvocation.MyCommand.Path, '-NoElevate')
        if ($Roles) { $relaunch += @('-Roles', ($Roles -join ',')) }
        if ($Groups) { $relaunch += @('-Groups', ($Groups -join ',')) }
        if ($Upgrade) { $relaunch += '-Upgrade' }

        & $gsudo.Source @relaunch
        $elevatedCode = $LASTEXITCODE

        # 231 i 1223 volen dir que algú ha dit que no al diàleg d'UAC. Sense
        # això, el run mor amb un "Error: The operation was canceled by the
        # user" pelat i sense cap pista de què fer.
        if ($elevatedCode -eq 231 -or $elevatedCode -eq 1223) {
            Write-Host ''
            Write-Host 'UAC cancel·lat: no s''ha executat res.' -ForegroundColor Red
            Write-Host 'Torna-ho a provar acceptant el diàleg, o fes servir -NoElevate' -ForegroundColor Yellow
            Write-Host '(sense privilegis, els ajustos d''HKLM se salten).' -ForegroundColor Yellow
        }
        exit $elevatedCode
    }
    Write-Host ''
    Write-Host 'Avís: sense privilegis d''administrador.' -ForegroundColor Yellow
    Write-Host 'Cada instal·lació demanarà UAC i els ajustos d''HKLM se saltaran.' -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# Execució dels rols
# -----------------------------------------------------------------------------
Set-ProvisionContext -CheckMode:([bool]$Check)

$rolesToRun = $Roles
if (-not $rolesToRun -or $rolesToRun.Count -eq 0) {
    $rolesToRun = @($config.default_roles)
}
if (-not $rolesToRun -or $rolesToRun.Count -eq 0) {
    $rolesToRun = @('core', 'apps', 'dev', 'shell', 'system', 'dotfiles')
}

$mode = 'aplicant canvis'
if ($Check) { $mode = 'mode --check (simulació)' }
if ($Upgrade) { $mode = "$mode, amb -Upgrade" }

Write-Play "ansible-win - $([Environment]::MachineName)"
Write-Info "Repo    : $RepoRoot"
Write-Info "Rols    : $($rolesToRun -join ', ')"
Write-Info "Mode    : $mode"
Write-Info "Admin   : $(Test-Elevated)"

$started = Get-Date

foreach ($role in $rolesToRun) {
    $taskFile = Join-Path $RepoRoot "roles\$role\tasks.ps1"
    if (-not (Test-Path -LiteralPath $taskFile)) {
        Set-ProvisionContext -Role $role
        Write-TaskResult -Task 'rol' -Status 'failed' -Message "no trobo $taskFile"
        continue
    }

    $roleParams = @{ Config = $config; RepoRoot = $RepoRoot; Upgrade = $Upgrade }
    if ($role -eq 'apps') {
        $roleParams['Groups'] = @($Groups)
    }

    try {
        & $taskFile @roleParams
    } catch {
        Set-ProvisionContext -Role $role
        Write-TaskResult -Task 'rol' -Status 'failed' -Message $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# Resum
# -----------------------------------------------------------------------------
$failures = Write-PlayRecap
$elapsed = (Get-Date) - $started
Write-Host ''
Write-Host ("Temps: {0:mm\:ss}" -f $elapsed) -ForegroundColor DarkGray

if (-not $Check) {
    Write-Host ''
    Write-Host 'Obre una consola nova perquè el PATH i el perfil agafin els canvis.' -ForegroundColor Cyan
}

if ($LogFile) {
    Write-Host ''
    Write-Host "Registre complet: $LogFile" -ForegroundColor DarkGray
    try { Stop-Transcript | Out-Null } catch { }
}

if ($failures -gt 0) { exit 1 }
exit 0
