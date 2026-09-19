#Requires -Version 5.1
<#
.SYNOPSIS
    Motor de provisionament d'ansible-win.
.DESCRIPTION
    Helpers idempotents d'estil Ansible: cada tasca reporta ok / changed / skipped /
    failed i el run acaba amb un PLAY RECAP. Compatible amb Windows PowerShell 5.1
    (el que ve de sèrie a Windows) i amb PowerShell 7+.
#>

$script:Results = New-Object System.Collections.ArrayList
$script:CurrentRole = 'general'
$script:CheckMode = $false

#region ---------------------------------------------------------------- sortida

$script:Palette = @{
    ok      = 'Green'
    changed = 'Yellow'
    skipped = 'Cyan'
    failed  = 'Red'
    info    = 'Gray'
}

function Set-ProvisionContext {
    param(
        [string]$Role,
        [nullable[bool]]$CheckMode
    )
    if ($Role) { $script:CurrentRole = $Role }
    if ($null -ne $CheckMode) { $script:CheckMode = [bool]$CheckMode }
}

function Get-ProvisionCheckMode { return $script:CheckMode }

function Write-Play {
    param([Parameter(Mandatory)][string]$Name)
    Write-Host ''
    Write-Host ("PLAY [{0}] " -f $Name).PadRight(78, '*') -ForegroundColor Magenta
}

function Write-Banner {
    param([Parameter(Mandatory)][string]$Text)
    Write-Host ''
    Write-Host $Text -ForegroundColor White
    Write-Host ('-' * [Math]::Min($Text.Length, 78)) -ForegroundColor DarkGray
}

function Write-Info {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "       $Message" -ForegroundColor $script:Palette.info
}

<#
.SYNOPSIS
    Registra el resultat d'una tasca i l'imprimeix en format Ansible.
#>
function Write-TaskResult {
    param(
        [Parameter(Mandatory)][string]$Task,
        [Parameter(Mandatory)][ValidateSet('ok', 'changed', 'skipped', 'failed')][string]$Status,
        [string]$Message
    )

    Write-Host ''
    Write-Host ("TASK [{0} : {1}] " -f $script:CurrentRole, $Task).PadRight(78, '*') -ForegroundColor DarkGray

    $line = $Status
    if ($Message) { $line = "{0}: {1}" -f $Status, $Message }
    Write-Host $line -ForegroundColor $script:Palette[$Status]

    [void]$script:Results.Add([pscustomobject]@{
        Role    = $script:CurrentRole
        Task    = $Task
        Status  = $Status
        Message = $Message
    })
}

<#
.SYNOPSIS
    Imprimeix el resum final i retorna el nombre de tasques fallides.
#>
function Write-PlayRecap {
    Write-Host ''
    Write-Host ('PLAY RECAP ').PadRight(78, '*') -ForegroundColor Magenta

    $failed = @($script:Results | Where-Object { $_.Status -eq 'failed' })

    foreach ($role in ($script:Results | Select-Object -ExpandProperty Role -Unique)) {
        $inRole = @($script:Results | Where-Object { $_.Role -eq $role })
        $counts = @{}
        foreach ($s in 'ok', 'changed', 'skipped', 'failed') {
            $counts[$s] = @($inRole | Where-Object { $_.Status -eq $s }).Count
        }
        $text = "{0,-14} : ok={1}  changed={2}  skipped={3}  failed={4}" -f `
            $role, $counts.ok, $counts.changed, $counts.skipped, $counts.failed
        $color = 'Green'
        if ($counts.failed -gt 0) { $color = 'Red' }
        elseif ($counts.changed -gt 0) { $color = 'Yellow' }
        Write-Host $text -ForegroundColor $color
    }

    if ($failed.Count -gt 0) {
        Write-Host ''
        Write-Host 'Tasques fallides:' -ForegroundColor Red
        foreach ($f in $failed) {
            Write-Host ("  - [{0}] {1}: {2}" -f $f.Role, $f.Task, $f.Message) -ForegroundColor Red
        }
    }

    if ($script:CheckMode) {
        Write-Host ''
        Write-Host 'Mode --check: no s''ha modificat res al sistema.' -ForegroundColor Cyan
    }

    return $failed.Count
}

function Get-ProvisionResults { return $script:Results.ToArray() }

function Clear-ProvisionResults { $script:Results.Clear() }

#endregion

#region ------------------------------------------------------------- privilegis

<#
.SYNOPSIS
    Cert si el procés actual té privilegis d'administrador.
#>
function Test-Elevated {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

<#
.SYNOPSIS
    Executa un scriptblock elevat via gsudo si cal, o directament si ja som admin.
#>
function Invoke-Elevated {
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [object[]]$ArgumentList = @()
    )

    if (Test-Elevated) {
        return & $ScriptBlock @ArgumentList
    }

    $gsudo = Get-Command gsudo -ErrorAction SilentlyContinue
    if (-not $gsudo) {
        throw 'Cal elevació i gsudo no està disponible. Executa el run com a administrador.'
    }

    return & $gsudo.Source -d powershell -NoProfile -Command $ScriptBlock.ToString()
}

#endregion

#region ---------------------------------------------------------------- utilitat

function Test-CommandExists {
    param([Parameter(Mandatory)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

<#
.SYNOPSIS
    Refresca el PATH del procés actual des del registre (màquina + usuari).
.DESCRIPTION
    Necessari després d'instal·lar paquets: l'installer actualitza el registre però
    no el procés que ja corre.
#>
function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

<#
.SYNOPSIS
    Afegeix un directori al PATH persistent si encara no hi és.
.OUTPUTS
    $true si ha calgut canviar res.
#>
function Add-PathEntry {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [ValidateSet('User', 'Machine')][string]$Scope = 'User',
        [switch]$Prepend
    )

    $current = [Environment]::GetEnvironmentVariable('Path', $Scope)
    if (-not $current) { $current = '' }

    $entries = @($current -split ';' | Where-Object { $_ })
    $normalized = $entries | ForEach-Object { $_.TrimEnd('\').ToLowerInvariant() }
    if ($normalized -contains $Directory.TrimEnd('\').ToLowerInvariant()) {
        return $false
    }

    if ($script:CheckMode) { return $true }

    if ($Prepend) { $entries = @($Directory) + $entries }
    else { $entries = $entries + @($Directory) }

    [Environment]::SetEnvironmentVariable('Path', ($entries -join ';'), $Scope)
    Update-SessionPath
    return $true
}

<#
.SYNOPSIS
    Escriu un fitxer només si el contingut difereix (idempotent).
.OUTPUTS
    $true si el fitxer ha canviat.
#>
function Set-FileContent {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content,
        [string]$Encoding = 'UTF8'
    )

    if (Test-Path -LiteralPath $Path) {
        # Llegim amb la MATEIXA codificació amb què escriurem: si no, a Windows
        # PowerShell 5.1 (que per defecte llegeix en ANSI) tot fitxer amb accents
        # sortiria sempre com a "changed".
        $existing = Get-Content -LiteralPath $Path -Raw -Encoding $Encoding -ErrorAction SilentlyContinue
        if ($null -eq $existing) { $existing = '' }
        # Set-Content -Encoding UTF8 escriu BOM a PS 5.1; Get-Content no el treu.
        $existing = $existing.TrimStart([char]0xFEFF)
        if ($existing.Replace("`r`n", "`n") -eq $Content.Replace("`r`n", "`n")) {
            return $false
        }
    }

    if ($script:CheckMode) { return $true }

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $Content -Encoding $Encoding -NoNewline
    return $true
}

<#
.SYNOPSIS
    Assegura un valor concret al registre. Retorna $true si ha canviat.
#>
function Set-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [string]$Type = 'DWord'
    )

    $existing = $null
    if (Test-Path -LiteralPath $Path) {
        $prop = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
        if ($prop) { $existing = $prop.$Name }
    }

    if ($null -ne $existing -and "$existing" -eq "$Value") { return $false }
    if ($script:CheckMode) { return $true }

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    return $true
}

<#
.SYNOPSIS
    Crea un enllaç simbòlic (o una còpia si no es pot) de forma idempotent.
#>
function Set-SymbolicLink {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Target
    )

    if (-not (Test-Path -LiteralPath $Target)) {
        throw "L'origen no existeix: $Target"
    }

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'SymbolicLink') {
        $currentTarget = @($item.Target)[0]
        if ($currentTarget -and (Resolve-Path $currentTarget -ErrorAction SilentlyContinue).Path -eq (Resolve-Path $Target).Path) {
            return $false
        }
    }

    if ($script:CheckMode) { return $true }

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    if ($item) {
        $backup = "$Path.bak-$(Get-Date -Format yyyyMMddHHmmss)"
        Move-Item -LiteralPath $Path -Destination $backup -Force
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target -Force -ErrorAction Stop | Out-Null
    } catch {
        # Sense mode desenvolupador ni admin no es poden crear symlinks: copiem.
        Copy-Item -LiteralPath $Target -Destination $Path -Force
    }
    return $true
}

#endregion

#region ------------------------------------------------------- gestors de paquets

function Test-WingetAvailable { return (Test-CommandExists 'winget') }
function Test-ChocoAvailable { return (Test-CommandExists 'choco') }
function Test-ScoopAvailable { return (Test-CommandExists 'scoop') }

<#
.SYNOPSIS
    Comprova si un paquet ja està instal·lat amb el proveïdor indicat.
#>
function Test-PackageInstalled {
    param(
        [Parameter(Mandatory)][ValidateSet('winget', 'choco', 'scoop')][string]$Provider,
        [Parameter(Mandatory)][string]$Id,
        [string]$Source
    )

    switch ($Provider) {
        'winget' {
            if (-not (Test-WingetAvailable)) { return $false }
            $listArgs = @('list', '--id', $Id, '--exact', '--accept-source-agreements')
            if ($Source) { $listArgs += @('--source', $Source) }
            $null = & winget @listArgs 2>$null
            return ($LASTEXITCODE -eq 0)
        }
        'choco' {
            if (-not (Test-ChocoAvailable)) { return $false }
            $out = & choco list --exact --limit-output $Id 2>$null
            return [bool](@($out | Where-Object { $_ -like "$Id|*" }).Count)
        }
        'scoop' {
            if (-not (Test-ScoopAvailable)) { return $false }
            $appDir = Join-Path $env:USERPROFILE "scoop\apps\$Id"
            if (Test-Path -LiteralPath $appDir) { return $true }
            $globalDir = Join-Path $env:ProgramData "scoop\apps\$Id"
            return (Test-Path -LiteralPath $globalDir)
        }
    }
    return $false
}

<#
.SYNOPSIS
    Instal·la un paquet amb el proveïdor indicat, en silenci i sense interacció.
#>
function Install-ProviderPackage {
    param(
        [Parameter(Mandatory)][ValidateSet('winget', 'choco', 'scoop')][string]$Provider,
        [Parameter(Mandatory)][string]$Id,
        [string]$Scope,
        [string]$Source,
        [string[]]$ExtraArgs = @(),
        [switch]$Upgrade
    )

    switch ($Provider) {
        'winget' {
            $verb = 'install'
            if ($Upgrade) { $verb = 'upgrade' }
            $wingetArgs = @(
                $verb, '--id', $Id, '--exact', '--silent',
                '--accept-package-agreements', '--accept-source-agreements',
                '--disable-interactivity'
            )
            # Les apps de la Microsoft Store (l'equivalent de `mas` al Mac) cal
            # demanar-les explícitament a la font msstore.
            if ($Source) { $wingetArgs += @('--source', $Source) }
            if ($Scope) { $wingetArgs += @('--scope', $Scope) }
            $wingetArgs += $ExtraArgs
            $output = & winget @wingetArgs 2>&1 | Out-String
            # 0x8A15002B = cap actualització disponible; no és un error.
            if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189 -and $LASTEXITCODE -ne -1978335212) {
                throw "winget $verb $Id ha fallat (codi $LASTEXITCODE): $($output.Trim())"
            }
            return
        }
        'choco' {
            $verb = 'install'
            if ($Upgrade) { $verb = 'upgrade' }
            $chocoArgs = @($verb, $Id, '-y', '--no-progress', '--limit-output') + $ExtraArgs
            $output = & choco @chocoArgs 2>&1 | Out-String
            # 3010 = cal reiniciar; 1641 = reinici iniciat. Cap dels dos és un error.
            if ($LASTEXITCODE -notin 0, 3010, 1641) {
                throw "choco $verb $Id ha fallat (codi $LASTEXITCODE): $($output.Trim())"
            }
            return
        }
        'scoop' {
            $verb = 'install'
            if ($Upgrade) { $verb = 'update' }
            $output = & scoop $verb $Id 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) {
                throw "scoop $verb $Id ha fallat (codi $LASTEXITCODE): $($output.Trim())"
            }
            return
        }
    }
}

<#
.SYNOPSIS
    Resol quin proveïdor s'ha de fer servir per a un paquet del catàleg.
.DESCRIPTION
    Respecta el camp 'provider' del paquet si hi és; si no, segueix l'ordre global
    de preferència i tria el primer proveïdor que (a) estigui disponible i
    (b) tingui un id definit per al paquet.
#>
function Resolve-PackageProvider {
    param(
        [Parameter(Mandatory)][hashtable]$Package,
        [string[]]$ProviderOrder = @('winget', 'choco', 'scoop')
    )

    $candidates = $ProviderOrder
    if ($Package.provider) { $candidates = @($Package.provider) }

    foreach ($p in $candidates) {
        if (-not $Package.ContainsKey($p) -or -not $Package[$p]) { continue }
        $available = switch ($p) {
            'winget' { Test-WingetAvailable }
            'choco' { Test-ChocoAvailable }
            'scoop' { Test-ScoopAvailable }
            default { $false }
        }
        if ($available) {
            return [pscustomobject]@{ Provider = $p; Id = $Package[$p] }
        }
    }
    return $null
}

<#
.SYNOPSIS
    Instal·la (o actualitza) una entrada del catàleg de paquets de forma idempotent.
.DESCRIPTION
    Escriu el resultat com a tasca Ansible. Mai llança: els errors es reporten com
    a 'failed' perquè un paquet trencat no aturi tot el provisionament.
#>
function Install-CatalogPackage {
    param(
        [Parameter(Mandatory)][hashtable]$Package,
        [string[]]$ProviderOrder = @('winget', 'choco', 'scoop'),
        [switch]$Upgrade
    )

    $label = $Package.name
    if (-not $label) { $label = $Package.id }

    $resolved = Resolve-PackageProvider -Package $Package -ProviderOrder $ProviderOrder
    if (-not $resolved) {
        # Paquets del catàleg del Mac que a Windows no existeixen: porten 'note'
        # explicant per què i quin és el substitut. No són un error.
        $why = $Package.note
        if (-not $why) { $why = 'cap proveïdor disponible per a aquest paquet' }
        Write-TaskResult -Task $label -Status 'skipped' -Message $why
        return
    }

    # Drecera barata: si la comanda que aporta el paquet ja existeix, no consultem
    # el gestor (les consultes a winget són lentes).
    $alreadyThere = $false
    if ($Package.test -and (Test-CommandExists $Package.test)) {
        $alreadyThere = $true
    } elseif (Test-PackageInstalled -Provider $resolved.Provider -Id $resolved.Id -Source $Package.source) {
        $alreadyThere = $true
    }

    if ($alreadyThere -and -not $Upgrade) {
        Write-TaskResult -Task $label -Status 'ok' -Message "$($resolved.Provider):$($resolved.Id) ja instal·lat"
        return
    }

    if ($script:CheckMode) {
        $what = 'instal·laria'
        if ($alreadyThere) { $what = 'actualitzaria' }
        Write-TaskResult -Task $label -Status 'changed' -Message "$what $($resolved.Provider):$($resolved.Id)"
        return
    }

    try {
        $extra = @()
        if ($Package.args) { $extra = @($Package.args) }
        Install-ProviderPackage -Provider $resolved.Provider -Id $resolved.Id `
            -Scope $Package.scope -Source $Package.source -ExtraArgs $extra -Upgrade:$Upgrade
        Update-SessionPath
        $verb = 'instal·lat'
        if ($Upgrade -and $alreadyThere) { $verb = 'actualitzat' }
        Write-TaskResult -Task $label -Status 'changed' -Message "$($resolved.Provider):$($resolved.Id) $verb"
    } catch {
        Write-TaskResult -Task $label -Status 'failed' -Message $_.Exception.Message
    }
}

#endregion

#region ------------------------------------------------------------ configuració

<#
.SYNOPSIS
    Carrega config.yml i hi fusiona config.local.yml si existeix.
#>
function Import-ProvisionConfig {
    param([Parameter(Mandatory)][string]$Root)

    if (-not (Get-Module -ListAvailable powershell-yaml)) {
        throw "Falta el mòdul powershell-yaml. Executa bootstrap.ps1 primer."
    }
    Import-Module powershell-yaml -ErrorAction Stop

    $allPath = Join-Path $Root 'config.yml'
    if (-not (Test-Path -LiteralPath $allPath)) {
        throw "No trobo el catàleg: $allPath"
    }
    # -Encoding UTF8 explícit: PS 5.1 llegeix en ANSI per defecte i es carregaria
    # els accents del catàleg.
    $config = ConvertFrom-Yaml (Get-Content -LiteralPath $allPath -Raw -Encoding UTF8)

    $localPath = Join-Path $Root 'config.local.yml'
    if (Test-Path -LiteralPath $localPath) {
        $local = ConvertFrom-Yaml (Get-Content -LiteralPath $localPath -Raw -Encoding UTF8)
        $config = Merge-Hashtable -Base $config -Override $local
    }

    return $config
}

<#
.SYNOPSIS
    Fusió recursiva de dues taules hash. Els valors d'Override guanyen.
#>
function Merge-Hashtable {
    param(
        [Parameter(Mandatory)][hashtable]$Base,
        [Parameter(Mandatory)][hashtable]$Override
    )

    $result = $Base.Clone()
    foreach ($key in $Override.Keys) {
        if ($result.ContainsKey($key) -and
            $result[$key] -is [hashtable] -and
            $Override[$key] -is [hashtable]) {
            $result[$key] = Merge-Hashtable -Base $result[$key] -Override $Override[$key]
        } else {
            $result[$key] = $Override[$key]
        }
    }
    return $result
}

<#
.SYNOPSIS
    Aplana el catàleg de paquets a una llista filtrada per grups.
.PARAMETER Groups
    Grups a incloure. Buit = tots els grups llistats a 'default_groups'.
#>
function Select-CatalogPackages {
    param(
        [Parameter(Mandatory)]$Config,
        [string[]]$Groups = @()
    )

    $catalog = $Config.packages
    if (-not $catalog) { return @() }

    $wanted = $Groups
    if (-not $wanted -or $wanted.Count -eq 0) {
        $wanted = $Config.default_groups
    }
    if (-not $wanted -or $wanted.Count -eq 0) {
        $wanted = @($catalog.Keys)
    }

    $selected = New-Object System.Collections.ArrayList
    foreach ($group in $wanted) {
        if (-not $catalog.ContainsKey($group)) {
            Write-Warning "Grup de paquets desconegut: $group"
            continue
        }
        foreach ($pkg in @($catalog[$group])) {
            if ($null -eq $pkg) { continue }
            $entry = @{} + $pkg
            $entry['group'] = $group
            [void]$selected.Add($entry)
        }
    }
    return $selected.ToArray()
}

#endregion

Export-ModuleMember -Function `
    Set-ProvisionContext, Get-ProvisionCheckMode, Write-Play, Write-Banner, Write-Info,
    Write-TaskResult, Write-PlayRecap, Get-ProvisionResults, Clear-ProvisionResults,
    Test-Elevated, Invoke-Elevated, Test-CommandExists, Update-SessionPath, Add-PathEntry,
    Set-FileContent, Set-RegistryValue, Set-SymbolicLink,
    Test-WingetAvailable, Test-ChocoAvailable, Test-ScoopAvailable,
    Test-PackageInstalled, Install-ProviderPackage, Resolve-PackageProvider,
    Install-CatalogPackage, Import-ProvisionConfig, Merge-Hashtable, Select-CatalogPackages
