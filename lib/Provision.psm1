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
# El run va en dues fases: primer sense privilegis (fase 'user'), i despres, si
# ha quedat feina que en necessita, una sola elevacio (fase 'admin'). Durant la
# fase d'usuari les tasques que demanen admin no fallen ni se salten en silenci:
# s'apunten aqui, i run.ps1 decideix si cal demanar l'UAC.
$script:AdminPhase = $false
$script:PendingAdmin = New-Object System.Collections.ArrayList

#region --------------------------------------------------------- shell de Windows

# Hi ha ajustos que no n'hi ha prou d'escriure'ls al registre: l'Explorador es
# guarda el seu estat en memoria i, o be no se n'assabenta, o be el reescriu per
# sobre quan es tanca. Per a aquests cal parlar amb el shell directament.
#
# Aixo importa especialment en un Windows sense activar: el panell de
# Personalitzacio hi esta bloquejat, o sigui que aquest es l'unic cami que queda.
if (-not ('AnsibleWin.Shell' -as [type])) {
    Add-Type -Namespace AnsibleWin -Name Shell -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true)]
public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

[DllImport("user32.dll", SetLastError = true)]
public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr child, string cls, string win);

[DllImport("user32.dll", CharSet = CharSet.Auto)]
public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr wParam,
    string lParam, uint flags, uint timeout, out IntPtr result);
'@
}

<#
.SYNOPSIS
    La finestra SHELLDLL_DefView de l'escriptori, o IntPtr::Zero si no hi es.
.DESCRIPTION
    Normalment penja de Progman. Amb fons dinamic o presentacio, l'Explorador
    crea un WorkerW i l'hi mou; per aixo hi ha el segon intent.
#>
function Get-DesktopView {
    $progman = [AnsibleWin.Shell]::FindWindow('Progman', $null)
    if ($progman -ne [IntPtr]::Zero) {
        $dv = [AnsibleWin.Shell]::FindWindowEx($progman, [IntPtr]::Zero, 'SHELLDLL_DefView', $null)
        if ($dv -ne [IntPtr]::Zero) { return $dv }
    }

    $worker = [IntPtr]::Zero
    while ($true) {
        $worker = [AnsibleWin.Shell]::FindWindowEx([IntPtr]::Zero, $worker, 'WorkerW', $null)
        if ($worker -eq [IntPtr]::Zero) { break }
        $dv = [AnsibleWin.Shell]::FindWindowEx($worker, [IntPtr]::Zero, 'SHELLDLL_DefView', $null)
        if ($dv -ne [IntPtr]::Zero) { return $dv }
    }
    return [IntPtr]::Zero
}

<#
.SYNOPSIS
    Ensenya o amaga les icones de l'escriptori. Retorna 'ok', 'changed' o llanca.
.DESCRIPTION
    Escriure HideIcons al registre i prou NO funciona: l'Explorador el reescriu
    amb el seu valor en memoria. Reiniciar-lo tampoc es fiable, perque en morir
    torna a desar l'estat antic.

    El que si que funciona es enviar-li la mateixa ordre que el menu contextual
    "Visualitza > Mostra les icones de l'escriptori" (WM_COMMAND 0x7402). El
    shell aplica el canvi en calent i desa ell mateix el valor al registre.

    Com que es un commutador i no un interruptor, mirem primer el registre: es
    l'ultim estat que el shell hi ha desat.
#>
function Set-DesktopIconsVisible {
    param([Parameter(Mandatory)][bool]$Visible)

    $clau = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $vol = 1; if ($Visible) { $vol = 0 }       # HideIcons esta invertit

    $ara = (Get-ItemProperty -LiteralPath $clau -Name 'HideIcons' -ErrorAction SilentlyContinue).HideIcons
    if ($null -eq $ara) { $ara = 0 }
    if ($ara -eq $vol) { return 'ok' }

    if ($script:CheckMode) { return 'changed' }

    $dv = Get-DesktopView
    if ($dv -eq [IntPtr]::Zero) {
        # Sense escriptori (sessio de servei, Server Core) deixem el valor escrit
        # perque l'agafi la propera sessio, pero no podem aplicar-ho ara.
        Set-RegistryValue -Path $clau -Name 'HideIcons' -Value $vol | Out-Null
        throw "no trobo l'escriptori per aplicar-ho; el valor queda escrit per a la propera sessio"
    }

    [void][AnsibleWin.Shell]::SendMessage($dv, 0x0111, [IntPtr]0x7402, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 700

    $despres = (Get-ItemProperty -LiteralPath $clau -Name 'HideIcons' -ErrorAction SilentlyContinue).HideIcons
    if ($null -eq $despres) { $despres = 0 }
    if ($despres -ne $vol) {
        throw "el shell no ha agafat el canvi (HideIcons = $despres)"
    }
    return 'changed'
}

<#
.SYNOPSIS
    Avisa les finestres obertes que una configuracio ha canviat.
.DESCRIPTION
    Sense aquest avis, coses com el tema clar/fosc queden escrites al registre
    pero no s'apliquen fins a tancar i obrir sessio. Amb un Windows sense
    activar aixo es especialment moles: el panell de Personalitzacio esta
    bloquejat i no hi ha cap altra manera de refrescar-ho.

    S'usa SendMessageTimeout i no SendMessage: si alguna finestra penjada no
    respon, un SendMessage a HWND_BROADCAST bloquejaria el run per sempre.
#>
function Publish-SettingChange {
    param([string]$Area = 'ImmersiveColorSet')

    $HWND_BROADCAST = [IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x001A
    $SMTO_ABORTIFHUNG = 0x0002
    $resultat = [IntPtr]::Zero

    [void][AnsibleWin.Shell]::SendMessageTimeout(
        $HWND_BROADCAST, $WM_SETTINGCHANGE, [IntPtr]::Zero, $Area,
        $SMTO_ABORTIFHUNG, 3000, [ref]$resultat)
}

#endregion

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
        [nullable[bool]]$CheckMode,
        [nullable[bool]]$AdminPhase
    )
    if ($Role) { $script:CurrentRole = $Role }
    if ($null -ne $CheckMode) { $script:CheckMode = [bool]$CheckMode }
    if ($null -ne $AdminPhase) { $script:AdminPhase = [bool]$AdminPhase }
}

function Get-ProvisionCheckMode { return $script:CheckMode }

<#
.SYNOPSIS
    Cert si som a la segona passada, la que ja corre elevada.
#>
function Get-ProvisionAdminPhase { return $script:AdminPhase }

<#
.SYNOPSIS
    Apunta que una tasca necessita privilegis i no s'ha pogut fer en aquesta passada.
#>
function Register-AdminWork {
    param(
        [Parameter(Mandatory)][string]$Task,
        [string]$Role
    )
    if (-not $Role) { $Role = $script:CurrentRole }
    [void]$script:PendingAdmin.Add([pscustomobject]@{ Role = $Role; Task = $Task })
}

<#
.SYNOPSIS
    Feina apuntada que espera l'elevacio.
#>
function Get-PendingAdminWork { return $script:PendingAdmin.ToArray() }

<#
.SYNOPSIS
    Executa un bloc que necessita privilegis, o l'apunta per a la fase d'admin.
.DESCRIPTION
    El patro es sempre el mateix als rols: si som admin (o en --check, que no
    escriu res) fem la feina; si no, l'apuntem i ho diem clar. Aixi run.ps1 pot
    demanar una sola elevacio al final amb la llista del que falta, en comptes
    de deixar un reguitzell de 'skipped: cal admin' que ningu llegeix.
#>
function Invoke-AdminWork {
    param(
        [Parameter(Mandatory)][string]$Task,
        [Parameter(Mandatory)][scriptblock]$Action,
        [scriptblock]$AlreadyDone
    )

    if (Test-Elevated) {
        & $Action
        return
    }

    # Llegir HKLM no demana privilegis; nomes escriure-hi. Si el valor ja es el
    # que volem, el bloc no escriura res, o sigui que el podem executar tal qual
    # i reportar 'ok'. Sense aixo una maquina ja convergida demanaria l'UAC a
    # cada run per no fer res.
    if ($AlreadyDone -and (& $AlreadyDone)) {
        & $Action
        return
    }

    # Sense privilegis l'apuntem sempre, tambe en --check: una simulacio que no
    # digui que et demanara l'UAC no simula el run de debo.
    Register-AdminWork -Task $Task

    if ($script:CheckMode) {
        # En --check no escrivim res igualment, o sigui que podem deixar que el
        # bloc calculi i reporti que canviaria. El fet que calgui admin surt al
        # resum del final.
        & $Action
        return
    }

    Write-TaskResult -Task $Task -Status 'skipped' -Message 'cal admin: es fara al bloc elevat del final'
}

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
        [string]$Message,
        # La tasca no aplica en aquesta maquina (no hi ha el maquinari, la funcio
        # de Windows no hi es, o la config la desactiva). No es feina pendent: es
        # feina que no existeix. Ni s'imprimeix ni compta al recap -- un run ple
        # de blau que no vol dir res tapa el que si que importa.
        [switch]$NotApplicable
    )

    if ($NotApplicable) { return }

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
    $changed = @($script:Results | Where-Object { $_.Status -eq 'changed' })

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

    # Un "changed=1" perdut entre dues-centes linies de 'ok' no serveix de res:
    # per veure QUE ha canviat cal fer scroll fins a trobar-lo. Sobretot en
    # --check, que es precisament on nomes vols saber aixo.
    if ($changed.Count -gt 0) {
        Write-Host ''
        if ($script:CheckMode) {
            Write-Host 'Canviaria:' -ForegroundColor Yellow
        } else {
            Write-Host 'Tasques amb canvis:' -ForegroundColor Yellow
        }
        foreach ($c in $changed) {
            $line = "  - [{0}] {1}" -f $c.Role, $c.Task
            if ($c.Message) { $line = "{0}: {1}" -f $line, $c.Message }
            Write-Host $line -ForegroundColor Yellow
        }
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
    Les últimes línies útils de la sortida d'una ordre, per posar-les en un error.
.DESCRIPTION
    Els gestors de paquets són xerraires. `scoop install` actualitza els buckets
    i escup el git log sencer de cada repositori abans de dir res útil: centenars
    de línies de commits per acabar amb un "Couldn't find manifest". Ficar tot
    això dins del missatge d'error tapa la línia que importa i omple la pantalla.
    Aquí ens quedem amb el final, que és on hi ha el motiu de debo; la sortida
    sencera segueix sent al fitxer de logs/.

    Compte amb l'altre extrem: scoop escriu els seus errors amb Write-Host, que
    NO passa pel pipeline i no es pot capturar amb 2>&1. En aquests casos aquí
    no arriba res, tot i que el motiu sí que s'ha imprimès a la consola (i al
    log). Val més dir-ho que deixar un "(sense sortida)" que sembla un bug.
#>
function Get-OutputTail {
    param(
        [AllowEmptyString()][AllowNull()][string]$Output,
        [int]$Lines = 5,
        [int]$MaxLength = 500
    )

    $capNul = 'el motiu s''ha imprimès a la consola, just abans de la tasca; queda al log'

    if (-not $Output) { return $capNul }

    $useful = @($Output -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($useful.Count -eq 0) { return $capNul }

    $tail = @($useful | Select-Object -Last $Lines) -join ' | '
    if ($tail.Length -gt $MaxLength) {
        $tail = '...' + $tail.Substring($tail.Length - $MaxLength)
    }
    if ($useful.Count -gt $Lines) {
        $tail = "$tail  [+$($useful.Count - $Lines) línies més al log]"
    }
    return $tail
}

<#
.SYNOPSIS
    Crida un executable i retorna la seva sortida i el seu codi de sortida.
.DESCRIPTION
    A Windows PowerShell 5.1, amb $ErrorActionPreference = 'Stop', qualsevol
    cosa que un executable escrigui a stderr es converteix en error terminant i
    avorta l'script allà mateix -- encara que el programa hagi acabat bé amb
    codi 0. npm escriu avisos de paquets obsolets, gsudo escriu informació, i
    tots dos feien caure tasques que en realitat havien anat bé.

    L'única manera fiable de saber si un executable ha fallat és el seu codi de
    sortida, no si ha escrit alguna cosa a stderr.
#>
function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$Arguments = @()
    )

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $FilePath @Arguments 2>&1 | Out-String
        return [pscustomobject]@{
            Output   = $output
            ExitCode = $LASTEXITCODE
        }
    } finally {
        $ErrorActionPreference = $previous
    }
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
    Assegura que un directori del PATH va DAVANT d'un altre.
.DESCRIPTION
    Add-PathEntry només mira si el directori hi és, no en quina posició. Quan el
    que volem és guanyar una resolució (p. ex. que gsudo\sudo.exe mani sobre el
    de System32) cal poder reordenar entrades que ja hi són.

    Escriu directament al registre, no amb [Environment]::SetEnvironmentVariable:
    aquest expandeix els %VARS% i escriu sempre REG_SZ, cosa que trencaria un PATH
    guardat com a REG_EXPAND_SZ. Aquí es llegeix sense expandir i es torna a
    escriure amb el mateix tipus.
.OUTPUTS
    $true si ha calgut canviar res.
#>
function Set-PathEntryPriority {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string]$Before,
        [ValidateSet('User', 'Machine')][string]$Scope = 'Machine',
        [string]$BackupPath,
        # Nomes mirar si caldria moure res. Llegir el PATH no demana privilegis,
        # o sigui que aixi el rol pot saber si val la pena demanar l'UAC.
        [switch]$TestOnly
    )

    if ($Scope -eq 'Machine') {
        $keyPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    } else {
        $keyPath = 'HKCU:\Environment'
    }

    $key = Get-Item -LiteralPath $keyPath
    $current = $key.GetValue('Path', $null, 'DoNotExpandEnvironmentNames')
    if (-not $current) { return $false }
    $kind = $key.GetValueKind('Path')

    $entries = @($current -split ';' | Where-Object { $_ })
    $norm = { param($x) $x.Trim().TrimEnd([char]92).ToLowerInvariant() }

    $idxDir = -1
    $idxBefore = -1
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $e = & $norm $entries[$i]
        if ($idxDir -lt 0 -and $e -eq (& $norm $Directory)) { $idxDir = $i }
        if ($idxBefore -lt 0 -and $e -eq (& $norm $Before)) { $idxBefore = $i }
    }

    # Si la referència no hi és no hi ha res a guanyar: prou amb ser al PATH.
    if ($idxBefore -lt 0) { return $false }
    if ($idxDir -ge 0 -and $idxDir -lt $idxBefore) { return $false }

    if ($TestOnly -or $script:CheckMode) { return $true }

    if ($BackupPath) {
        $dir = Split-Path -Parent $BackupPath
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        Set-Content -LiteralPath $BackupPath -Value $current -Encoding ASCII -NoNewline
    }

    # Treiem les aparicions del directori i el reinserim just davant de $Before.
    $rest = @($entries | Where-Object { (& $norm $_) -ne (& $norm $Directory) })
    $at = -1
    for ($i = 0; $i -lt $rest.Count; $i++) {
        if ((& $norm $rest[$i]) -eq (& $norm $Before)) { $at = $i; break }
    }
    if ($at -lt 0) { $at = 0 }

    $new = @()
    if ($at -gt 0) { $new += $rest[0..($at - 1)] }
    $new += $Directory
    $new += $rest[$at..($rest.Count - 1)]

    Set-ItemProperty -LiteralPath $keyPath -Name 'Path' -Value ($new -join ';') -Type $kind
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
function Test-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value
    )

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $prop = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction SilentlyContinue
    if (-not $prop) { return $false }
    return ("$($prop.$Name)" -eq "$Value")
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

    if (Test-RegistryValue -Path $Path -Name $Name -Value $Value) { return $false }
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
    Busca una entrada de "Programes i característiques" pel seu nom visible.
.DESCRIPTION
    És l'única manera de saber si un paquet instal·lat per URL hi és: no hi ha
    cap gestor a qui preguntar-ho. El patró admet comodins (-like).
#>
function Get-ArpEntry {
    param([Parameter(Mandatory)][string]$Pattern)

    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    return @(Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
             Where-Object { $_.DisplayName -and $_.DisplayName -like $Pattern }) |
           Select-Object -First 1
}

<#
.SYNOPSIS
    Resol la secció url: d'un paquet a una descàrrega concreta.
.DESCRIPTION
    Dos modes:
      source: <url>              descàrrega fixa, reproduïble, però es podreix
      github: <owner/repo>       + asset: <patró> -> resol l'última release
    El mode github existeix perquè els noms dels fitxers canvien: OpenTV ja va
    passar de dir-se open-tv a Fred.TV enmig de les releases.
#>
function Resolve-UrlAsset {
    param([Parameter(Mandatory)][hashtable]$Spec)

    if ($Spec.source) {
        $clean = ($Spec.source -split '\?')[0]
        return [pscustomobject]@{
            Url      = $Spec.source
            FileName = [System.IO.Path]::GetFileName($clean)
            Version  = "$($Spec.version)"
        }
    }

    if ($Spec.github) {
        if (-not $Spec.asset) { throw "url.github necessita també url.asset (patró del fitxer)" }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $api = "https://api.github.com/repos/$($Spec.github)/releases/latest"
        $rel = Invoke-RestMethod -Uri $api -UseBasicParsing -Headers @{
            'User-Agent' = 'ansible-win'
            'Accept'     = 'application/vnd.github+json'
        }
        $asset = @($rel.assets | Where-Object { $_.name -like $Spec.asset }) | Select-Object -First 1
        if (-not $asset) {
            $noms = ($rel.assets | ForEach-Object { $_.name }) -join ', '
            throw "cap asset de $($Spec.github) coincideix amb '$($Spec.asset)'. Hi ha: $noms"
        }
        return [pscustomobject]@{
            Url      = $asset.browser_download_url
            FileName = $asset.name
            Version  = ($rel.tag_name -replace '^v', '')
        }
    }

    throw "la secció url: necessita 'source' o 'github'"
}

<#
.SYNOPSIS
    Descarrega i executa un instal·lador que no és a cap gestor de paquets.
#>
function Install-UrlPackage {
    param([Parameter(Mandatory)][hashtable]$Spec)

    $asset = Resolve-UrlAsset -Spec $Spec

    $cache = Join-Path $env:TEMP 'ansible-win-downloads'
    if (-not (Test-Path -LiteralPath $cache)) {
        New-Item -ItemType Directory -Path $cache -Force | Out-Null
    }
    $file = Join-Path $cache $asset.FileName

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    # Sense això, Invoke-WebRequest a PS 5.1 va ridículament lent per culpa de
    # la barra de progrés.
    $oldProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $asset.Url -OutFile $file -UseBasicParsing
    } finally {
        $ProgressPreference = $oldProgress
    }

    if ($Spec.sha256) {
        $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
        if ($hash -ne $Spec.sha256.ToUpperInvariant()) {
            Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
            throw "el checksum no coincideix. Esperat $($Spec.sha256.ToUpperInvariant()), obtingut $hash"
        }
    }

    $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
    if ($ext -eq '.msi') {
        $arguments = @('/i', "`"$file`"", '/qn', '/norestart')
        $proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru
    } else {
        # Per defecte /S, que és el silenci d'NSIS (i el que fa servir Tauri).
        $arguments = @('/S')
        if ($Spec.args) { $arguments = @($Spec.args) }
        $proc = Start-Process -FilePath $file -ArgumentList $arguments -Wait -PassThru
    }

    # 3010 i 1641 volen dir "cal reiniciar", no són errors.
    if ($proc.ExitCode -notin 0, 3010, 1641) {
        # Alguns instal·ladors retornen codis d'error tot i haver instal·lat bé
        # (Hot Corners, per exemple, torna 1 amb /VERYSILENT). Si el paquet ens
        # diu com comprovar-ho a Programes i característiques, aquesta és la
        # font de veritat: el codi de sortida no ho és.
        $confirmed = $false
        if ($Spec.arp) { $confirmed = [bool](Get-ArpEntry -Pattern $Spec.arp) }
        if (-not $confirmed) {
            throw "l'instal·lador ha retornat $($proc.ExitCode)"
        }
    }
    return $asset.Version
}

<#
.SYNOPSIS
    Comprova si un paquet ja està instal·lat amb el proveïdor indicat.
#>
function Test-PackageInstalled {
    param(
        [Parameter(Mandatory)][ValidateSet('winget', 'choco', 'scoop', 'url')][string]$Provider,
        [Parameter(Mandatory)][string]$Id,
        [string]$Source,
        [hashtable]$UrlSpec
    )

    switch ($Provider) {
        'url' {
            # Sense gestor, l'únic registre fiable és Programes i característiques.
            if (-not $UrlSpec -or -not $UrlSpec.arp) { return $false }
            return [bool](Get-ArpEntry -Pattern $UrlSpec.arp)
        }
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
        [Parameter(Mandatory)][ValidateSet('winget', 'choco', 'scoop', 'url')][string]$Provider,
        [Parameter(Mandatory)][string]$Id,
        [string]$Scope,
        [string]$Source,
        [hashtable]$UrlSpec,
        [string[]]$ExtraArgs = @(),
        [switch]$Upgrade
    )

    switch ($Provider) {
        'url' {
            if (-not $UrlSpec) { throw "el paquet no té secció url:" }
            $null = Install-UrlPackage -Spec $UrlSpec
            return
        }
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
                throw "winget $verb $Id ha fallat (codi $LASTEXITCODE): $(Get-OutputTail $output)"
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
                throw "choco $verb $Id ha fallat (codi $LASTEXITCODE): $(Get-OutputTail $output)"
            }
            return
        }
        'scoop' {
            $verb = 'install'
            if ($Upgrade) { $verb = 'update' }
            $output = & scoop $verb $Id 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0) {
                throw "scoop $verb $Id ha fallat (codi $LASTEXITCODE): $(Get-OutputTail $output)"
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
            'url' { $true }   # no depèn de cap gestor instal·lat
            default { $false }
        }
        if (-not $available) { continue }

        # Per a 'url', $Package['url'] és una taula: l'Id és només per ensenyar.
        $id = $Package[$p]
        if ($p -eq 'url') {
            if ($Package.url.github) { $id = "github:$($Package.url.github)" }
            elseif ($Package.url.source) { $id = $Package.url.source }
            else { $id = 'url' }
        }
        return [pscustomobject]@{ Provider = $p; Id = $id }
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

    # Els paquets MSIX de la Microsoft Store s'instal·len per usuari i fallen
    # sempre des d'un proces elevat. Per aixo el run comenca sense privilegis: la
    # primera passada els fa, i quan arribem aqui ja elevats nomes cal dir que ja
    # estan coberts.
    if ($Package.source -eq 'msstore' -and (Test-Elevated)) {
        $why = 'app de la Store: nomes s''instal·la sense privilegis'
        if ($script:AdminPhase) { $why = 'app de la Store: feta a la passada sense privilegis' }
        Write-TaskResult -Task $label -Status 'skipped' -Message $why
        return
    }

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
    } elseif (Test-PackageInstalled -Provider $resolved.Provider -Id $resolved.Id `
                                    -Source $Package.source -UrlSpec $Package.url) {
        $alreadyThere = $true
    }

    if ($alreadyThere -and -not $Upgrade) {
        Write-TaskResult -Task $label -Status 'ok' -Message "$($resolved.Provider):$($resolved.Id) ja instal·lat"
        return
    }

    # Opcional que no s'ha demanat i que no tens: en mode actualitzacio no s'ha
    # d'instal·lar. Nomes hi era per si calia posar-lo al dia.
    if ($Package.upgrade_only -and -not $alreadyThere) {
        Write-TaskResult -Task $label -Status 'skipped' -Message 'opcional no instal·lat' -NotApplicable
        return
    }

    # Falta instal·lar-lo de debo. winget, choco i els installers baixats per URL
    # escriuen a Program Files i al registre de maquina: sense privilegis obririen
    # un UAC per paquet. Scoop no (viu tot al perfil d'usuari) i els MSIX de la
    # Store tampoc (son per usuari i elevats fallen). Els que si que en necessiten
    # els apuntem i els fa la passada elevada, tots de cop.
    $userScope = ($resolved.Provider -eq 'scoop') -or ($Package.source -eq 'msstore')
    $needsAdmin = (-not $userScope) -and (-not (Test-Elevated))

    if ($needsAdmin) { Register-AdminWork -Task $label }

    if ($needsAdmin -and -not $script:CheckMode) {
        Write-TaskResult -Task $label -Status 'skipped' `
            -Message "cal admin: s'instal·lara al bloc elevat del final"
        return
    }

    if ($script:CheckMode) {
        $what = 'instal·laria'
        if ($alreadyThere) { $what = 'actualitzaria' }
        $msg = "$what $($resolved.Provider):$($resolved.Id)"
        if ($needsAdmin) { $msg = "$msg (caldra admin)" }
        Write-TaskResult -Task $label -Status 'changed' -Message $msg
        return
    }

    try {
        $extra = @()
        if ($Package.args) { $extra = @($Package.args) }
        # `winget upgrade` d'una cosa que no tens falla amb "no installed package
        # found". El verb ha de dependre de si hi es, no de si hem dit -Upgrade:
        # si no, un -Upgrade en una maquina nova peta a cada paquet que falti.
        Install-ProviderPackage -Provider $resolved.Provider -Id $resolved.Id `
            -Scope $Package.scope -Source $Package.source -UrlSpec $Package.url `
            -ExtraArgs $extra -Upgrade:($Upgrade -and $alreadyThere)
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
# Claus que indiquen que una entrada del catàleg es pot instal·lar a Windows. El
# catàleg és compartit amb el d'ansible-mac, i les entrades que només porten
# 'mac:' aquí no es poden instal·lar de cap manera.
$script:WindowsProviderKeys = @('winget', 'choco', 'scoop', 'url')

<#
.SYNOPSIS
    Entrades del catàleg que a Windows no es poden instal·lar i que encara no
    tenen substitut decidit.
.DESCRIPTION
    Una entrada només de Mac està "resolta" quan porta `win_equivalent`, que diu
    qui li fa la feina a Windows (una altra app del catàleg, o una funció nativa).
    Les que no en porten són decisions pendents: el run les ha d'ensenyar perquè
    alguí digui què hi posem.
#>
function Get-UndecidedPackages {
    param(
        [Parameter(Mandatory)]$Config,
        [string[]]$Groups = @()
    )

    $catalog = $Config.packages
    if (-not $catalog) { return @() }

    $wanted = $Groups
    if (-not $wanted -or $wanted.Count -eq 0) { $wanted = $Config.default_groups }
    if (-not $wanted -or $wanted.Count -eq 0) { $wanted = @($catalog.Keys) }

    $out = New-Object System.Collections.ArrayList
    foreach ($group in $wanted) {
        if (-not $catalog.ContainsKey($group)) { continue }
        foreach ($pkg in @($catalog[$group])) {
            if ($null -eq $pkg) { continue }
            $hasWin = $false
            foreach ($k in $script:WindowsProviderKeys) {
                if ($pkg.ContainsKey($k) -and $pkg[$k]) { $hasWin = $true; break }
            }
            if ($hasWin) { continue }
            if ($pkg.win_equivalent) { continue }

            $entry = @{} + $pkg
            $entry['group'] = $group
            [void]$out.Add($entry)
        }
    }
    return $out.ToArray()
}

function Select-CatalogPackages {
    param(
        [Parameter(Mandatory)]$Config,
        [string[]]$Groups = @(),
        [switch]$IncludeForeign,
        # Ids de paquets opcionals que s'han triat. Els marcats amb `optional: true`
        # que no siguin en aquesta llista es queden fora. Sense la llista no
        # n'entra cap: el comportament segur per a un run desates.
        [string[]]$Optional = @(),
        # Els opcionals entren tots, s'hagin triat o no.
        [switch]$AllOptional,
        # Mode actualitzacio: els opcionals que no s'han triat hi entren igualment,
        # pero marcats perque nomes se'ls actualitzi si JA estan instal·lats. Una
        # app opcional que tens al disc s'ha de poder actualitzar sense haver de
        # recordar el seu id cada vegada; una que no tens, no s'ha d'instal·lar
        # per la porta del darrere.
        [switch]$UpgradeMode
    )

    $winKeys = $script:WindowsProviderKeys

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

            if (-not $IncludeForeign) {
                $hasWin = $false
                foreach ($k in $winKeys) {
                    if ($pkg.ContainsKey($k) -and $pkg[$k]) { $hasWin = $true; break }
                }
                # Només filtrem per absència de clau, no per disponibilitat del
                # gestor: si un paquet té 'winget' i winget no hi és, això sí que
                # volem veure-ho com a 'skipped'.
                if (-not $hasWin) { continue }
            }

            $nomesSiHiEs = $false
            if ($pkg.optional -and -not $AllOptional -and ($Optional -notcontains $pkg.id)) {
                if (-not $UpgradeMode) { continue }
                $nomesSiHiEs = $true
            }

            $entry = @{} + $pkg
            $entry['group'] = $group
            if ($nomesSiHiEs) { $entry['upgrade_only'] = $true }
            [void]$selected.Add($entry)
        }
    }
    return $selected.ToArray()
}

<#
.SYNOPSIS
    Els paquets marcats com a opcionals que entren en aquesta selecció de grups.
.DESCRIPTION
    Serveix per preguntar què es vol instal·lar abans de començar. Torna només
    els que a Windows tenen algú que els instal·li: un opcional que aquí no
    existeix no té cap sentit oferir-lo.
#>
function Get-OptionalPackages {
    param(
        [Parameter(Mandatory)]$Config,
        [string[]]$Groups = @()
    )

    $catalog = $Config.packages
    if (-not $catalog) { return @() }

    $wanted = $Groups
    if (-not $wanted -or $wanted.Count -eq 0) { $wanted = $Config.default_groups }
    if (-not $wanted -or $wanted.Count -eq 0) { $wanted = @($catalog.Keys) }

    $out = New-Object System.Collections.ArrayList
    foreach ($group in $wanted) {
        if (-not $catalog.ContainsKey($group)) { continue }
        foreach ($pkg in @($catalog[$group])) {
            if ($null -eq $pkg -or -not $pkg.optional) { continue }

            $hasWin = $false
            foreach ($k in $script:WindowsProviderKeys) {
                if ($pkg.ContainsKey($k) -and $pkg[$k]) { $hasWin = $true; break }
            }
            if (-not $hasWin) { continue }

            $entry = @{} + $pkg
            $entry['group'] = $group
            [void]$out.Add($entry)
        }
    }
    return $out.ToArray()
}

#endregion

Export-ModuleMember -Function `
    Set-ProvisionContext, Get-ProvisionCheckMode, Write-Play, Write-Banner, Write-Info,
    Write-TaskResult, Write-PlayRecap, Get-ProvisionResults, Clear-ProvisionResults,
    Test-Elevated, Invoke-Elevated, Test-CommandExists, Invoke-NativeCommand, Get-OutputTail,
    Get-ProvisionAdminPhase, Register-AdminWork, Get-PendingAdminWork, Invoke-AdminWork,
    Update-SessionPath, Add-PathEntry, Set-PathEntryPriority,
    Get-DesktopView, Set-DesktopIconsVisible, Publish-SettingChange,
    Set-FileContent, Set-RegistryValue, Test-RegistryValue, Set-SymbolicLink,
    Test-WingetAvailable, Test-ChocoAvailable, Test-ScoopAvailable,
    Get-ArpEntry, Resolve-UrlAsset, Install-UrlPackage,
    Test-PackageInstalled, Install-ProviderPackage, Resolve-PackageProvider,
    Install-CatalogPackage, Import-ProvisionConfig, Merge-Hashtable, Select-CatalogPackages,
    Get-UndecidedPackages, Get-OptionalPackages
