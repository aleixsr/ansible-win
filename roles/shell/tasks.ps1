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
    Write-TaskResult -Task 'configuració' -Status 'skipped' -Message 'cap secció shell: a la configuració' -NotApplicable
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
        Write-TaskResult -Task 'prompt' -Status 'skipped' -Message "shell.prompt = $prompt" -NotApplicable
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
# Generat per ansible-win (rol shell). No editar a mà.
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
# Generat per ansible-win (rol shell). No editar a mà.
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
# starship.toml
# -----------------------------------------------------------------------------
# És literalment el mateix fitxer que a ansible-mac, i starship el busca a la
# mateixa ruta a les dues plataformes (~/.config/starship.toml). Per tant, el
# prompt acaba sent idèntic al Mac i al Windows.
if (-not $shellCfg.install_starship_config) {
    Write-TaskResult -Task 'starship.toml' -Status 'skipped' -Message 'shell.install_starship_config = false' -NotApplicable
} else {
    $starshipSource = Join-Path $RepoRoot 'files\starship.toml'
    if (-not (Test-Path -LiteralPath $starshipSource)) {
        Write-TaskResult -Task 'starship.toml' -Status 'skipped' -Message 'no hi ha files\starship.toml'
    } else {
        $starshipTarget = Join-Path $env:USERPROFILE '.config\starship.toml'
        try {
            $content = Get-Content -LiteralPath $starshipSource -Raw -Encoding UTF8
            $changed = Set-FileContent -Path $starshipTarget -Content $content
            $status = 'ok'; if ($changed) { $status = 'changed' }
            Write-TaskResult -Task 'starship.toml' -Status $status -Message $starshipTarget
        } catch {
            Write-TaskResult -Task 'starship.toml' -Status 'failed' -Message $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# perfil de PowerShell
# -----------------------------------------------------------------------------
if (-not $shellCfg.install_profile) {
    Write-TaskResult -Task 'perfil de PowerShell' -Status 'skipped' -Message 'shell.install_profile = false' -NotApplicable
} else {
    $sourceProfile = Join-Path $RepoRoot 'files\profile.ps1'
    if (-not (Test-Path -LiteralPath $sourceProfile)) {
        Write-TaskResult -Task 'perfil de PowerShell' -Status 'failed' -Message "no trobo $sourceProfile"
    } else {
        # El perfil instal·lat és un carregador d'una sola línia: així el contingut
        # real viu al repo i un `git pull` ja actualitza el perfil.
        $loader = @'
# Generat per ansible-win (rol shell). No editar a mà: edita el repo.
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
    Write-TaskResult -Task 'Windows Terminal' -Status 'skipped' -Message 'shell.configure_terminal = false' -NotApplicable
} else {
    $source = Join-Path $RepoRoot 'files\windows-terminal.settings.json'
    $settingsDir = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'

    if (-not (Test-Path -LiteralPath $source)) {
        Write-TaskResult -Task 'Windows Terminal' -Status 'skipped' -Message 'no hi ha settings al repo'
    } elseif (-not (Test-Path -LiteralPath $settingsDir)) {
        Write-TaskResult -Task 'Windows Terminal' -Status 'skipped' -Message 'Windows Terminal no instal·lat (o encara no obert un cop)' -NotApplicable
    } else {
        $target = Join-Path $settingsDir 'settings.json'
        try {
            $needsBackup = (Test-Path -LiteralPath $target) -and
                           -not (Test-Path -LiteralPath "$target.ansible-win.bak")
            if ($needsBackup -and -not $checkMode) {
                Copy-Item -LiteralPath $target -Destination "$target.ansible-win.bak" -Force
            }

            $desired = Get-Content -LiteralPath $source -Raw -Encoding UTF8 | ConvertFrom-Json

            if (-not (Test-Path -LiteralPath $target)) {
                $changed = Set-FileContent -Path $target -Content ($desired | ConvertTo-Json -Depth 32)
                $status = 'ok'; if ($changed) { $status = 'changed' }
                Write-TaskResult -Task 'Windows Terminal' -Status $status -Message $target
            } else {
                # Fusionem en comptes de sobreescriure. Windows Terminal escriu
                # claus pròpies al seu settings.json cada cop que s'obre
                # (keybindings, newTabMenu, themes...). Si el sobreescrivíssim
                # sencer, la tasca sortiria com a 'changed' a CADA execució: el
                # repo les treu, l'app les torna a posar, i això no convergeix
                # mai. El repo mana sobre el que declara, i la resta es respecta.
                $current = Get-Content -LiteralPath $target -Raw -Encoding UTF8 | ConvertFrom-Json

                function Merge-JsonObject {
                    param($Base, $Override)
                    if ($null -eq $Override) { return $Base }
                    if ($Override -isnot [System.Management.Automation.PSCustomObject]) { return $Override }
                    if ($Base -isnot [System.Management.Automation.PSCustomObject]) { return $Override }

                    $result = $Base
                    foreach ($prop in $Override.PSObject.Properties) {
                        $existing = $result.PSObject.Properties[$prop.Name]
                        if ($existing) {
                            $result.PSObject.Properties[$prop.Name].Value =
                                Merge-JsonObject -Base $existing.Value -Override $prop.Value
                        } else {
                            $result | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
                        }
                    }
                    return $result
                }

                $before = $current | ConvertTo-Json -Depth 32
                $merged = Merge-JsonObject -Base $current -Override $desired
                $after = $merged | ConvertTo-Json -Depth 32

                if ($before -eq $after) {
                    Write-TaskResult -Task 'Windows Terminal' -Status 'ok' -Message $target
                } elseif ($checkMode) {
                    Write-TaskResult -Task 'Windows Terminal' -Status 'changed' -Message "fusionaria $target"
                } else {
                    Set-Content -LiteralPath $target -Value $after -Encoding UTF8 -NoNewline
                    Write-TaskResult -Task 'Windows Terminal' -Status 'changed' -Message $target
                }
            }
        } catch {
            Write-TaskResult -Task 'Windows Terminal' -Status 'failed' -Message $_.Exception.Message
        }
    }
}
