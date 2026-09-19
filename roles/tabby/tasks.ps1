<#
.SYNOPSIS
    Rol tabby: desplega els connectors de Tabby.
.DESCRIPTION
    Equivalent al rol `tabby` d'ansible-mac. L'única diferència és on viuen els
    connectors:
      macOS    ~/Library/Application Support/tabby/plugins
      Windows  %APPDATA%\tabby\plugins

    El package.json és exactament el mateix fitxer que al Mac, així que tots dos
    equips acaben amb els mateixos connectors.
#>
param(
    [Parameter(Mandatory)]$Config,
    [string]$RepoRoot,
    [switch]$Upgrade
)

Set-ProvisionContext -Role 'tabby'

$tabbyCfg = $Config.tabby
if (-not $tabbyCfg -or -not $tabbyCfg.install_plugins) {
    Write-TaskResult -Task 'connectors' -Status 'skipped' -Message 'tabby.install_plugins = false'
    return
}

$source = Join-Path $RepoRoot 'files\tabby\package.json'
if (-not (Test-Path -LiteralPath $source)) {
    Write-TaskResult -Task 'connectors' -Status 'skipped' -Message 'no hi ha files\tabby\package.json'
    return
}

Update-SessionPath
if (-not (Test-CommandExists 'npm')) {
    Write-TaskResult -Task 'connectors' -Status 'skipped' -Message 'npm no està instal·lat (cal Node.js)'
    return
}

$pluginsDir = Join-Path $env:APPDATA 'tabby\plugins'
$target = Join-Path $pluginsDir 'package.json'
$checkMode = Get-ProvisionCheckMode

try {
    if (-not (Test-Path -LiteralPath $pluginsDir)) {
        if ($checkMode) {
            Write-TaskResult -Task 'directori de connectors' -Status 'changed' -Message "crearia $pluginsDir"
        } else {
            New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null
            Write-TaskResult -Task 'directori de connectors' -Status 'changed' -Message $pluginsDir
        }
    } else {
        Write-TaskResult -Task 'directori de connectors' -Status 'ok' -Message $pluginsDir
    }

    $content = Get-Content -LiteralPath $source -Raw -Encoding UTF8
    $changed = Set-FileContent -Path $target -Content $content
    $status = 'ok'; if ($changed) { $status = 'changed' }
    Write-TaskResult -Task 'package.json' -Status $status -Message $target

    # Només reinstal·lem si el package.json ha canviat: `npm install` sincronitza
    # node_modules amb el package.json i treu els connectors eliminats.
    if (-not $changed) {
        Write-TaskResult -Task 'npm install' -Status 'ok' -Message 'package.json sense canvis'
    } elseif ($checkMode) {
        Write-TaskResult -Task 'npm install' -Status 'changed' -Message 'executaria npm install --legacy-peer-deps'
    } else {
        Push-Location $pluginsDir
        try {
            # npm escriu els avisos de paquets obsolets a stderr. Cridat
            # directament, això avortava la tasca encara que la instal·lació
            # hagués anat bé: el que compta és el codi de sortida.
            $npm = Invoke-NativeCommand -FilePath 'npm' -Arguments @('install', '--legacy-peer-deps')
            if ($npm.ExitCode -ne 0) {
                throw "npm ha retornat $($npm.ExitCode): $($npm.Output.Trim())"
            }
            Write-TaskResult -Task 'npm install' -Status 'changed'
        } finally {
            Pop-Location
        }
    }
} catch {
    Write-TaskResult -Task 'connectors' -Status 'failed' -Message $_.Exception.Message
}
