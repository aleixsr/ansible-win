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

.PARAMETER Full
    Instal·la també el software opcional. Equival a -Optional all.

.PARAMETER Optional
    Quin software opcional s'instal·la, per id. Els paquets amb `optional: true`
    al catàleg no entren mai si no es demanen explícitament.

      -Optional obsidian,tailscale

    El run no pregunta mai res: sense -Full ni -Optional s'instal·la només
    l'essencial, i el recap diu què s'ha deixat fora.

.PARAMETER NoElevate
    No demanis privilegis encara que faltin. El que en necessiti se salta.

.PARAMETER AdminPhase
    Ús intern. Marca la segona passada, la que run.ps1 es llança a si mateix
    elevat per fer la feina que havia quedat pendent. No el posis a mà.

.NOTES
    LLANÇA'L SENSE ADMINISTRADOR. El run va en dues fases:

      1. Sense privilegis: tot el que es pot fer com a usuari, incloses les apps
         MSIX de la Microsoft Store, que ELEVADES FALLEN SEMPRE.
      2. Si ha quedat feina que necessita admin, diu exactament quina és i
         demana l'UAC un sol cop per fer-la tota de cop.

    Llançant-lo ja elevat, la fase 1 no pot instal·lar les apps de la Store.

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
    [string[]]$Optional,
    [switch]$Full,
    [switch]$ListPackages,
    [switch]$NoElevate,
    [switch]$AdminPhase
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

<#
.SYNOPSIS
    Parteix arguments de llista que arriben com un sol element separat per comes.
.DESCRIPTION
    Amb `powershell -File`, "-Groups a,b" NO es parteix en dos elements: arriba
    com la cadena "a,b" i no coincideix amb cap grup. I la passada elevada es
    rellança amb -File, així que sense això qualsevol run amb -Groups que
    arribés a la fase d'admin seleccionaria zero paquets, en silenci.
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
# Software opcional
# -----------------------------------------------------------------------------
# Els paquets amb `optional: true` no entren si ningú els demana. El run és
# desatès sempre: no pregunta res. Amb -Full hi entren tots; amb -Optional,
# només els que diguis. Sense cap dels dos, cap.
$optionalTriats = @()
$optionalTots = [bool]$Full

if ($Optional) {
    $optionalTriats = @(Split-ListArgument $Optional)
    if ($optionalTriats -contains 'all') {
        $optionalTots = $true
        $optionalTriats = @()
    } elseif ($optionalTriats -contains 'none') {
        $optionalTriats = @()
    } elseif (-not $AdminPhase) {
        # Un id mal escrit no ha de passar desapercebut: acabaries buscant per
        # què no s'ha instal·lat una cosa que mai s'ha arribat a demanar.
        $coneguts = @(Get-OptionalPackages -Config $config -Groups $Groups | ForEach-Object { $_.id })
        foreach ($id in $optionalTriats) {
            if ($coneguts -notcontains $id) {
                Write-Host ''
                Write-Host "No hi ha cap paquet opcional amb l'id '$id'." -ForegroundColor Red
                Write-Host "Opcionals disponibles: $($coneguts -join ', ')" -ForegroundColor Yellow
                exit 1
            }
        }
    }
}

# Dir què s'ha deixat fora. Sense això, que una app no apareixi sembla un error
# del playbook quan en realitat és el comportament demanat.
if (-not $ListPackages -and -not $AdminPhase -and -not $optionalTots) {
    $fora = @(Get-OptionalPackages -Config $config -Groups $Groups |
              Where-Object { $optionalTriats -notcontains $_.id })
    if ($fora.Count -gt 0) {
        Write-Host ''
        $llista = ($fora | ForEach-Object { $_.id }) -join ', '
        if ($Upgrade) {
            # En mode actualitzacio els opcionals hi entren igualment, pero nomes
            # per posar-los al dia si ja els tens. Dir "no s'instal·len" aqui seria
            # enganyos: el que no passa es que se n'instal·li cap de nou.
            Write-Host "$($fora.Count) opcionals: nomes s'actualitzaran els que ja tinguis ($llista)" -ForegroundColor DarkGray
        } else {
            Write-Host "$($fora.Count) paquets opcionals no s'instal·len: $llista" -ForegroundColor DarkGray
        }
        Write-Host 'Amb -Full hi entren tots; amb -Optional <ids>, només els que diguis.' -ForegroundColor DarkGray
    }
}

# -----------------------------------------------------------------------------
# Avís: elevat des de fora
# -----------------------------------------------------------------------------
# El run vol començar SENSE privilegis. Les apps MSIX de la Store s'instal·len
# per usuari i des d'un procés elevat fallen sempre, o sigui que si algu ens
# llança amb 'sudo .\run.ps1' aquestes es queden pel camí. La feina que necessita
# admin ja se la busca ella al final: no cal elevar res a mà.
if ((Test-Elevated) -and -not $AdminPhase -and -not $Check) {
    Write-Host ''
    Write-Host 'Avís: aquest run ja ve elevat.' -ForegroundColor Yellow
    Write-Host 'Les apps de la Microsoft Store no es poden instal·lar amb privilegis i se saltaran.' -ForegroundColor Yellow
    Write-Host 'Llança''l sense administrador: ell mateix demana l''UAC quan li cal.' -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# Execució dels rols
# -----------------------------------------------------------------------------
Set-ProvisionContext -CheckMode:([bool]$Check) -AdminPhase:([bool]$AdminPhase)

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
if ($AdminPhase) { $mode = "$mode — passada elevada" }

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
        $roleParams['Optional'] = @($optionalTriats)
        $roleParams['AllOptional'] = $optionalTots
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

# -----------------------------------------------------------------------------
# Fase 2: la feina que necessita privilegis
# -----------------------------------------------------------------------------
# Els rols no peten quan els falta admin: apunten la tasca amb Register-AdminWork
# i segueixen. Aquí mirem què ha quedat pendent i, si n'hi ha, ens tornem a
# llançar UNA sola vegada elevats. Un únic UAC per a tot, i dient abans què farà.
$pending = @(Get-PendingAdminWork)

if ($pending.Count -gt 0 -and -not $AdminPhase -and -not $Check -and -not $NoElevate) {
    Write-Host ''
    Write-Host ('=' * 78) -ForegroundColor Yellow
    Write-Host "ARA VE LA PART QUE NECESSITA ADMINISTRADOR ($($pending.Count) tasques)" -ForegroundColor Yellow
    Write-Host ('=' * 78) -ForegroundColor Yellow
    Write-Host 'Tot el que es pot fer com a usuari ja està fet. Només falta això, que' -ForegroundColor Gray
    Write-Host 'toca Program Files, HKLM o el PATH de màquina:' -ForegroundColor Gray
    Write-Host ''
    $lastRole = $null
    foreach ($item in $pending) {
        if ($item.Role -ne $lastRole) {
            $lastRole = $item.Role
            Write-Host "  [$lastRole]" -ForegroundColor Cyan
        }
        Write-Host "    - $($item.Task)" -ForegroundColor White
    }
    Write-Host ''

    $gsudo = Get-Command gsudo -ErrorAction SilentlyContinue
    if (-not $gsudo) {
        Write-Host 'No trobo gsudo per demanar l''elevació.' -ForegroundColor Red
        Write-Host 'Obre una consola com a administrador i executa:  .\run.ps1 -NoElevate' -ForegroundColor Yellow
    } else {
        Write-Host 'Accepta l''UAC i es fa tot de cop. És l''únic cop que el demanarà.' -ForegroundColor Yellow

        $relaunch = @('powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                      '-File', $MyInvocation.MyCommand.Path, '-AdminPhase')
        if ($Roles) { $relaunch += @('-Roles', ($Roles -join ',')) }
        if ($Groups) { $relaunch += @('-Groups', ($Groups -join ',')) }
        if ($Upgrade) { $relaunch += '-Upgrade' }
        # Sense això, la passada elevada tornaria a preguntar (o pitjor: no
        # instal·laria els opcionals que acabes de triar, que son justament els
        # que necessiten privilegis).
        if ($optionalTots) {
            $relaunch += @('-Optional', 'all')
        } elseif ($optionalTriats.Count -gt 0) {
            $relaunch += @('-Optional', ($optionalTriats -join ','))
        } else {
            $relaunch += @('-Optional', 'none')
        }

        # $ErrorActionPreference = 'Stop' i els executables natius es porten
        # malament a PowerShell 5.1: qualsevol cosa que gsudo escrigui a stderr
        # (com "operation was canceled by the user" quan es rebutja l'UAC)
        # avorta l'script aquí mateix, i el missatge d'ajuda de sota no s'arriba
        # a imprimir mai.
        $previousEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            & $gsudo.Source @relaunch
            $elevatedCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousEap
        }

        # 231 i 1223 volen dir que algú ha dit que no al diàleg d'UAC.
        if ($elevatedCode -eq 231 -or $elevatedCode -eq 1223) {
            Write-Host ''
            Write-Host 'UAC cancel·lat: la part que necessita admin no s''ha fet.' -ForegroundColor Red
            Write-Host 'La resta sí. Torna a executar .\run.ps1 quan vulguis acabar-ho.' -ForegroundColor Yellow
        }

        if ($LogFile) {
            Write-Host ''
            Write-Host "Registre complet: $LogFile" -ForegroundColor DarkGray
            try { Stop-Transcript | Out-Null } catch { }
        }
        exit $elevatedCode
    }
} elseif ($pending.Count -gt 0) {
    Write-Host ''
    if ($Check) {
        Write-Host "Caldrà administrador per a $($pending.Count) tasques:" -ForegroundColor Yellow
    } else {
        Write-Host "$($pending.Count) tasques necessiten administrador i no s'han fet:" -ForegroundColor Yellow
    }
    $lastRole = $null
    foreach ($item in $pending) {
        if ($item.Role -ne $lastRole) {
            $lastRole = $item.Role
            Write-Host "  [$lastRole]" -ForegroundColor Cyan
        }
        Write-Host "    - $($item.Task)" -ForegroundColor White
    }
    Write-Host ''
    if ($Check) {
        Write-Host 'En --check no s''eleva res. Al run de debo se''t demanarà l''UAC un sol cop.' -ForegroundColor Yellow
    } else {
        Write-Host 'Executa .\run.ps1 sense -NoElevate i accepta l''UAC.' -ForegroundColor Yellow
    }
}

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
