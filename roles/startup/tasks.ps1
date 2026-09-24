<#
.SYNOPSIS
    Rol startup: aplicacions que s'obren en iniciar la sessió.
.DESCRIPTION
    Equivalent al rol `startup` d'ansible-mac, que afegeix Login Items amb
    osascript. A Windows són valors a
    HKCU:\Software\Microsoft\Windows\CurrentVersion\Run.

    Només s'hi afegeix una app si l'executable existeix: així, si encara no
    l'has instal·lada, la tasca surt com a 'skipped' en comptes de deixar una
    entrada d'inici trencada al registre.
#>
param(
    [Parameter(Mandatory)]$Config,
    [string]$RepoRoot,
    [switch]$Upgrade
)

Set-ProvisionContext -Role 'startup'

$RUN_KEY = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

# -----------------------------------------------------------------------------
# Desactivar coses que s'han posat soles a l'inici
# -----------------------------------------------------------------------------
# No s'esborra res: s'escriu a StartupApproved, que és el mateix mecanisme que
# fa servir la pestanya "Inici" de l'Administrador de tasques. Així el canvi és
# reversible des de la interfície de Windows i l'instal·lador no el desfà a la
# propera actualització, cosa que sí que passaria si li esborréssim l'entrada.
#   primer byte 0x02 = activat, 0x03 = desactivat
$APPROVED_DISABLED = [byte[]](0x03, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

<#
.SYNOPSIS
    Marca una entrada d'inici com a desactivada. Retorna 'ok', 'changed' o $null
    si l'entrada no existeix en aquest lloc.
#>
function Disable-StartupEntry {
    param(
        [Parameter(Mandatory)][string]$ApprovedKey,
        [Parameter(Mandatory)][string]$ValueName
    )

    $current = $null
    if (Test-Path -LiteralPath $ApprovedKey) {
        $prop = Get-ItemProperty -LiteralPath $ApprovedKey -Name $ValueName -ErrorAction SilentlyContinue
        if ($prop) { $current = $prop.$ValueName }
    }
    if ($current -and $current[0] -eq 0x03) { return 'ok' }

    if (Get-ProvisionCheckMode) { return 'changed' }

    if (-not (Test-Path -LiteralPath $ApprovedKey)) {
        New-Item -Path $ApprovedKey -Force | Out-Null
    }
    New-ItemProperty -LiteralPath $ApprovedKey -Name $ValueName `
        -Value $APPROVED_DISABLED -PropertyType Binary -Force | Out-Null
    return 'changed'
}

$toDisable = @($Config.startup_disable)
foreach ($entry in $toDisable) {
    if (-not $entry) { continue }
    $name = "$entry"

    # On pot estar registrada: les dues claus Run i les dues carpetes d'Inici.
    $places = @(
        @{ Kind = 'run';      Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
           Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
           Value = $name; Admin = $false },
        @{ Kind = 'run';      Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
           Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
           Value = $name; Admin = $true },
        @{ Kind = 'shortcut'; Key = [Environment]::GetFolderPath('Startup')
           Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder'
           Value = "$name.lnk"; Admin = $false },
        @{ Kind = 'shortcut'; Key = [Environment]::GetFolderPath('CommonStartup')
           Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder'
           Value = "$name.lnk"; Admin = $true }
    )

    $found = $false
    foreach ($place in $places) {
        # Existeix aquí?
        if ($place.Kind -eq 'run') {
            if (-not (Test-Path -LiteralPath $place.Key)) { continue }
            $p = Get-ItemProperty -LiteralPath $place.Key -Name $name -ErrorAction SilentlyContinue
            if (-not $p) { continue }
        } else {
            if (-not $place.Key) { continue }
            $lnk = Join-Path $place.Key $place.Value
            if (-not (Test-Path -LiteralPath $lnk)) { continue }
        }
        $found = $true

        if ($place.Admin -and -not (Test-Elevated) -and -not (Get-ProvisionCheckMode)) {
            Write-TaskResult -Task "no arrencar $name" -Status 'skipped' -Message 'cal admin'
            continue
        }
        try {
            $status = Disable-StartupEntry -ApprovedKey $place.Approved -ValueName $place.Value
            Write-TaskResult -Task "no arrencar $name" -Status $status -Message "$($place.Kind): $($place.Value)"
        } catch {
            Write-TaskResult -Task "no arrencar $name" -Status 'failed' -Message $_.Exception.Message
        }
    }

    if (-not $found) {
        Write-TaskResult -Task "no arrencar $name" -Status 'ok' -Message 'no és a cap lloc d''inici'
    }
}

# -----------------------------------------------------------------------------
# Aplicacions que SÍ volem a l'inici
# -----------------------------------------------------------------------------
$apps = @($Config.startup_apps)
if ($apps.Count -eq 0) {
    Write-TaskResult -Task 'aplicacions d''inici' -Status 'skipped' -Message 'startup_apps buit' -NotApplicable
    return
}

foreach ($app in $apps) {
    if (-not $app -or -not $app.name -or -not $app.path) {
        Write-TaskResult -Task 'aplicació d''inici' -Status 'failed' -Message 'entrada sense name o path'
        continue
    }

    # El YAML és text pla: expandim $env:NOM i les %VARIABLES% aquí.
    $path = [regex]::Replace($app.path, '\$env:(\w+)', {
        param($m)
        $value = [Environment]::GetEnvironmentVariable($m.Groups[1].Value)
        if ($null -eq $value) { return $m.Value }
        return $value
    })
    $path = [Environment]::ExpandEnvironmentVariables($path)

    if (-not (Test-Path -LiteralPath $path)) {
        Write-TaskResult -Task $app.name -Status 'skipped' -Message "no trobat: $path"
        continue
    }

    # El valor del registre ha d'anar entre cometes: hi ha rutes amb espais.
    $value = '"{0}"' -f $path
    if ($app.args) { $value = '"{0}" {1}' -f $path, (@($app.args) -join ' ') }

    # Si ja hi ha una entrada que apunta al MATEIX executable, no la toquem.
    # Moltes apps s'hi posen soles amb arguments propis -- OneDrive hi posa
    # /background -- i reescriure-la els els prendria. El que volem és que
    # l'app arrenqui, no imposar-hi la nostra línia d'ordres.
    $existing = $null
    $prop = Get-ItemProperty -LiteralPath $RUN_KEY -Name $app.name -ErrorAction SilentlyContinue
    if ($prop) { $existing = "$($prop.($app.name))" }

    if ($existing -and -not $app.args) {
        $existingExe = $existing.Trim()
        if ($existingExe.StartsWith('"')) {
            $end = $existingExe.IndexOf('"', 1)
            if ($end -gt 0) { $existingExe = $existingExe.Substring(1, $end - 1) }
        } elseif ($existingExe.Contains(' ')) {
            $existingExe = $existingExe.Substring(0, $existingExe.IndexOf(' '))
        }
        if ($existingExe -ieq $path) {
            Write-TaskResult -Task $app.name -Status 'ok' -Message "ja hi és: $existing"
            continue
        }
    }

    try {
        $changed = Set-RegistryValue -Path $RUN_KEY -Name $app.name -Value $value -Type 'String'
        $status = 'ok'; if ($changed) { $status = 'changed' }
        Write-TaskResult -Task $app.name -Status $status -Message $value
    } catch {
        Write-TaskResult -Task $app.name -Status 'failed' -Message $_.Exception.Message
    }
}
