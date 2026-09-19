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

$apps = @($Config.startup_apps)
if ($apps.Count -eq 0) {
    Write-TaskResult -Task 'aplicacions d''inici' -Status 'skipped' -Message 'startup_apps buit'
    return
}

$RUN_KEY = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

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

    try {
        $changed = Set-RegistryValue -Path $RUN_KEY -Name $app.name -Value $value -Type 'String'
        $status = 'ok'; if ($changed) { $status = 'changed' }
        Write-TaskResult -Task $app.name -Status $status -Message $path
    } catch {
        Write-TaskResult -Task $app.name -Status 'failed' -Message $_.Exception.Message
    }
}
