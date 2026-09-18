<#
.SYNOPSIS
    Rol shell: perfil de PowerShell, prompt, mòduls i Windows Terminal.
#>
param(
    [Parameter(Mandatory)]$Config,
    [string]$RepoRoot,
    [switch]$Upgrade
)

Set-ProvisionContext -Role 'shell'

$shellCfg = $Config.shell
if (-not $shellCfg) {
    Write-TaskResult -Task 'configuració' -Status 'skipped' -Message 'cap secció shell: a la configuració'
    return
}

$checkMode = Get-ProvisionCheckMode
Update-SessionPath

# -----------------------------------------------------------------------------
# mòduls de PowerShell
# -----------------------------------------------------------------------------
$modules = @($shellCfg.modules)
if ($modules.Count -gt 0) {
    # PSGallery ha d'estar com a repositori de confiança o Install-Module preguntarà.
    if (-not $checkMode) {
        try {
            $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
            if ($repo -and $repo.InstallationPolicy -ne 'Trusted') {
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            }
        } catch { }
    }

    foreach ($m in $modules) {
        $present = Get-Module -ListAvailable -Name $m -ErrorAction SilentlyContinue
        if ($present -and -not $Upgrade) {
            Write-TaskResult -Task "mòdul $m" -Status 'ok' -Message "v$(@($present)[0].Version)"
            continue
        }
        if ($checkMode) {
            Write-TaskResult -Task "mòdul $m" -Status 'changed' -Message 'instal·laria / actualitzaria'
            continue
        }
        try {
            # -AllowClobber: PSReadLine ve amb Windows i cal poder-lo substituir.
            Install-Module -Name $m -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -ErrorAction Stop
            Write-TaskResult -Task "mòdul $m" -Status 'changed'
        } catch {
            Write-TaskResult -Task "mòdul $m" -Status 'failed' -Message $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# prompt
# -----------------------------------------------------------------------------
$prompt = $shellCfg.prompt
if (-not $prompt) { $prompt = 'none' }

switch ($prompt) {
    'oh-my-posh' {
        $pkg = @{ id = 'oh-my-posh'; name = 'oh-my-posh'; winget = 'JanDeDobbeleer.OhMyPosh'; choco = 'oh-my-posh'; test = 'oh-my-posh'; scope = 'user' }
        Install-CatalogPackage -Package $pkg -ProviderOrder $Config.provider_order -Upgrade:$Upgrade
    }
    'starship' {
        $pkg = @{ id = 'starship'; name = 'Starship'; winget = 'Starship.Starship'; choco = 'starship'; test = 'starship' }
        Install-CatalogPackage -Package $pkg -ProviderOrder $Config.provider_order -Upgrade:$Upgrade
    }
    default {
        Write-TaskResult -Task 'prompt' -Status 'skipped' -Message "shell.prompt = $prompt"
    }
}

# -----------------------------------------------------------------------------
# fragment de prompt per al perfil
# -----------------------------------------------------------------------------
$snippetDir = Join-Path $RepoRoot 'files\profile.d'
if (-not (Test-Path -LiteralPath $snippetDir) -and -not $checkMode) {
    New-Item -ItemType Directory -Path $snippetDir -Force | Out-Null
}

$theme = $shellCfg.oh_my_posh_theme
if (-not $theme) { $theme = 'jandedobbeleer' }

$promptSnippet = switch ($prompt) {
    'oh-my-posh' {
        @'
# Generat per ansible_windows (rol shell). No editar a mà.
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $themeFile = Join-Path $env:POSH_THEMES_PATH '__THEME__.omp.json'
    if (Test-Path -LiteralPath $themeFile) {
        oh-my-posh init pwsh --config $themeFile | Invoke-Expression
    } else {
        oh-my-posh init pwsh | Invoke-Expression
    }
}
'@.Replace('__THEME__', $theme)
    }
    'starship' {
        @'
# Generat per ansible_windows (rol shell). No editar a mà.
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
'@
    }
    default { "# shell.prompt = none`n" }
}

$changed = Set-FileContent -Path (Join-Path $snippetDir '20-prompt.ps1') -Content $promptSnippet
$status = 'ok'; if ($changed) { $status = 'changed' }
Write-TaskResult -Task 'fragment de prompt' -Status $status -Message "shell.prompt = $prompt"

# -----------------------------------------------------------------------------
# perfil de PowerShell
# -----------------------------------------------------------------------------
if (-not $shellCfg.install_profile) {
    Write-TaskResult -Task 'perfil de PowerShell' -Status 'skipped' -Message 'shell.install_profile = false'
} else {
    $sourceProfile = Join-Path $RepoRoot 'files\profile.ps1'
    if (-not (Test-Path -LiteralPath $sourceProfile)) {
        Write-TaskResult -Task 'perfil de PowerShell' -Status 'failed' -Message "no trobo $sourceProfile"
    } else {
        # El perfil instal·lat és un carregador d'una sola línia: així el contingut
        # real viu al repo i un `git pull` ja actualitza el perfil.
        $loader = @'
# Generat per ansible_windows (rol shell). No editar a mà: edita el repo.
$AnsibleWindowsRoot = '__ROOT__'
$profileSource = Join-Path $AnsibleWindowsRoot 'files\profile.ps1'
if (Test-Path -LiteralPath $profileSource) { . $profileSource }
'@.Replace('__ROOT__', $RepoRoot)

        # Windows PowerShell 5.1 i PowerShell 7 fan servir carpetes diferents.
        $targets = New-Object System.Collections.ArrayList
        [void]$targets.Add((Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'))
        [void]$targets.Add((Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'))
        # OneDrive redirigeix "Documents" en molts equips corporatius.
        if ($env:OneDrive -and (Test-Path -LiteralPath (Join-Path $env:OneDrive 'Documents'))) {
            [void]$targets.Add((Join-Path $env:OneDrive 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'))
            [void]$targets.Add((Join-Path $env:OneDrive 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'))
        }

        $anyChanged = $false
        foreach ($target in $targets) {
            try {
                if (Set-FileContent -Path $target -Content $loader) { $anyChanged = $true }
            } catch {
                Write-TaskResult -Task 'perfil de PowerShell' -Status 'failed' -Message $_.Exception.Message
            }
        }
        $status = 'ok'; if ($anyChanged) { $status = 'changed' }
        Write-TaskResult -Task 'perfil de PowerShell' -Status $status -Message "$($targets.Count) ubicacions"
    }
}

# -----------------------------------------------------------------------------
# Windows Terminal
# -----------------------------------------------------------------------------
if (-not $shellCfg.configure_terminal) {
    Write-TaskResult -Task 'Windows Terminal' -Status 'skipped' -Message 'shell.configure_terminal = false'
} else {
    $source = Join-Path $RepoRoot 'files\windows-terminal.settings.json'
    $settingsDir = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'

    if (-not (Test-Path -LiteralPath $source)) {
        Write-TaskResult -Task 'Windows Terminal' -Status 'skipped' -Message 'no hi ha settings al repo'
    } elseif (-not (Test-Path -LiteralPath $settingsDir)) {
        Write-TaskResult -Task 'Windows Terminal' -Status 'skipped' -Message 'Windows Terminal no instal·lat (o encara no obert un cop)'
    } else {
        $target = Join-Path $settingsDir 'settings.json'
        try {
            $content = Get-Content -LiteralPath $source -Raw -Encoding UTF8
            $needsBackup = (Test-Path -LiteralPath $target) -and
                           -not (Test-Path -LiteralPath "$target.ansible_windows.bak")
            if ($needsBackup -and -not $checkMode) {
                Copy-Item -LiteralPath $target -Destination "$target.ansible_windows.bak" -Force
            }
            $changed = Set-FileContent -Path $target -Content $content
            $status = 'ok'; if ($changed) { $status = 'changed' }
            Write-TaskResult -Task 'Windows Terminal' -Status $status -Message $target
        } catch {
            Write-TaskResult -Task 'Windows Terminal' -Status 'failed' -Message $_.Exception.Message
        }
    }
}
