<#
.SYNOPSIS
    Rol system: ajustos de Windows.
.DESCRIPTION
    L'equivalent dels `defaults write` d'ansible_mac. Tot passa pel registre
    d'usuari (HKCU) excepte el que està marcat com a "cal admin".
#>
param(
    [Parameter(Mandatory)]$Config,
    [string]$RepoRoot,
    [switch]$Upgrade
)

Set-ProvisionContext -Role 'system'

$sys = $Config.system
if (-not $sys) {
    Write-TaskResult -Task 'configuració' -Status 'skipped' -Message 'cap secció system: a la configuració'
    return
}

$checkMode = Get-ProvisionCheckMode
$explorerNeedsRestart = $false

$ADVANCED = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$SEARCH   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
$THEMES   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

<#
.SYNOPSIS
    Aplica un valor de registre i el reporta com a tasca. Retorna $true si ha canviat.
#>
function Set-Tweak {
    param(
        [string]$Task,
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = 'DWord',
        [switch]$RestartsExplorer
    )
    try {
        $changed = Set-RegistryValue -Path $Path -Name $Name -Value $Value -Type $Type
        $status = 'ok'; if ($changed) { $status = 'changed' }
        Write-TaskResult -Task $Task -Status $status -Message "$Name = $Value"
        if ($changed -and $RestartsExplorer) { $script:explorerNeedsRestart = $true }
        return $changed
    } catch {
        Write-TaskResult -Task $Task -Status 'failed' -Message $_.Exception.Message
        return $false
    }
}

# -----------------------------------------------------------------------------
# Explorador de fitxers
# -----------------------------------------------------------------------------
$exp = $sys.explorer
if ($exp) {
    if ($null -ne $exp.show_file_extensions) {
        # HideFileExt està invertit: 0 = mostra les extensions.
        $v = 1; if ($exp.show_file_extensions) { $v = 0 }
        Set-Tweak -Task 'mostrar extensions de fitxer' -Path $ADVANCED -Name 'HideFileExt' -Value $v -RestartsExplorer | Out-Null
    }
    if ($null -ne $exp.show_hidden_files) {
        $v = 2; if ($exp.show_hidden_files) { $v = 1 }
        Set-Tweak -Task 'mostrar fitxers ocults' -Path $ADVANCED -Name 'Hidden' -Value $v -RestartsExplorer | Out-Null
    }
    if ($null -ne $exp.launch_to_this_pc) {
        # 1 = Aquest equip, 2 = Accés ràpid
        $v = 2; if ($exp.launch_to_this_pc) { $v = 1 }
        Set-Tweak -Task 'obrir a Aquest equip' -Path $ADVANCED -Name 'LaunchTo' -Value $v -RestartsExplorer | Out-Null
    }
    if ($null -ne $exp.show_full_path_in_title) {
        $v = 0; if ($exp.show_full_path_in_title) { $v = 1 }
        Set-Tweak -Task 'ruta completa al títol' `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState' `
            -Name 'FullPath' -Value $v -RestartsExplorer | Out-Null
    }
    if ($null -ne $exp.expand_to_open_folder) {
        $v = 0; if ($exp.expand_to_open_folder) { $v = 1 }
        Set-Tweak -Task 'expandir a la carpeta oberta' -Path $ADVANCED -Name 'NavPaneExpandToCurrentFolder' -Value $v -RestartsExplorer | Out-Null
    }
    if ($null -ne $exp.disable_recent_files) {
        $v = 1; if ($exp.disable_recent_files) { $v = 0 }
        Set-Tweak -Task 'fitxers recents' -Path $ADVANCED -Name 'Start_TrackDocs' -Value $v -RestartsExplorer | Out-Null
    }
}

# -----------------------------------------------------------------------------
# Barra de tasques
# -----------------------------------------------------------------------------
$tb = $sys.taskbar
if ($tb) {
    if ($null -ne $tb.align_left) {
        # 0 = esquerra, 1 = centre
        $v = 1; if ($tb.align_left) { $v = 0 }
        Set-Tweak -Task 'barra de tasques a l''esquerra' -Path $ADVANCED -Name 'TaskbarAl' -Value $v -RestartsExplorer | Out-Null
    }
    if ($null -ne $tb.hide_search_box) {
        # 0 = amagat, 1 = icona, 2 = caixa, 3 = caixa + etiqueta
        $v = 2; if ($tb.hide_search_box) { $v = 0 }
        Set-Tweak -Task 'caixa de cerca' -Path $SEARCH -Name 'SearchboxTaskbarMode' -Value $v -RestartsExplorer | Out-Null
    }
    if ($null -ne $tb.hide_task_view) {
        $v = 1; if ($tb.hide_task_view) { $v = 0 }
        Set-Tweak -Task 'botó de vista de tasques' -Path $ADVANCED -Name 'ShowTaskViewButton' -Value $v -RestartsExplorer | Out-Null
    }
    if ($null -ne $tb.hide_widgets) {
        # Els Widgets són un paquet a part (MicrosoftWindows.Client.WebExperience)
        # i hi ha builds de Windows 11 que ja no el porten. En aquestes, el
        # sistema bloqueja expressament l'escriptura de TaskbarDa amb un
        # UnauthorizedAccessException — i només d'aquest valor: crear qualsevol
        # altre nom nou a la mateixa clau funciona. Si no hi ha Widgets, no hi
        # ha res a amagar.
        $widgets = $null
        try {
            $widgets = Get-AppxPackage -Name 'MicrosoftWindows.Client.WebExperience' -ErrorAction SilentlyContinue
        } catch { }

        if (-not $widgets) {
            Write-TaskResult -Task 'widgets' -Status 'skipped' -Message 'aquesta build de Windows no porta Widgets'
        } else {
            $v = 1; if ($tb.hide_widgets) { $v = 0 }
            Set-Tweak -Task 'widgets' -Path $ADVANCED -Name 'TaskbarDa' -Value $v -RestartsExplorer | Out-Null
        }
    }
    if ($null -ne $tb.hide_chat) {
        $v = 1; if ($tb.hide_chat) { $v = 0 }
        Set-Tweak -Task 'botó de xat' -Path $ADVANCED -Name 'TaskbarMn' -Value $v -RestartsExplorer | Out-Null
    }
}

# -----------------------------------------------------------------------------
# Aparença
# -----------------------------------------------------------------------------
$ap = $sys.appearance
if ($ap) {
    if ($null -ne $ap.dark_mode) {
        $v = 1; if ($ap.dark_mode) { $v = 0 }
        Set-Tweak -Task 'tema fosc (aplicacions)' -Path $THEMES -Name 'AppsUseLightTheme' -Value $v -RestartsExplorer | Out-Null
        Set-Tweak -Task 'tema fosc (sistema)' -Path $THEMES -Name 'SystemUsesLightTheme' -Value $v -RestartsExplorer | Out-Null
    }
    if ($null -ne $ap.transparency) {
        $v = 0; if ($ap.transparency) { $v = 1 }
        Set-Tweak -Task 'efectes de transparència' -Path $THEMES -Name 'EnableTransparency' -Value $v | Out-Null
    }
    if ($null -ne $ap.accent_on_taskbar) {
        $v = 0; if ($ap.accent_on_taskbar) { $v = 1 }
        Set-Tweak -Task 'color d''accent a la barra' -Path $THEMES -Name 'ColorPrevalence' -Value $v -RestartsExplorer | Out-Null
    }
}

# -----------------------------------------------------------------------------
# Privadesa
# -----------------------------------------------------------------------------
$pv = $sys.privacy
if ($pv) {
    if ($pv.disable_advertising_id) {
        Set-Tweak -Task 'id de publicitat' `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' `
            -Name 'Enabled' -Value 0 | Out-Null
    }
    if ($pv.disable_start_web_search) {
        Set-Tweak -Task 'cerca web al menú Inici' `
            -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' `
            -Name 'DisableSearchBoxSuggestions' -Value 1 -RestartsExplorer | Out-Null
        Set-Tweak -Task 'Bing a la cerca' -Path $SEARCH -Name 'BingSearchEnabled' -Value 0 | Out-Null
    }
    if ($pv.disable_tailored_experiences) {
        Set-Tweak -Task 'experiències personalitzades' `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' `
            -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 0 | Out-Null
        Set-Tweak -Task 'contingut suggerit' `
            -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' `
            -Name 'SubscribedContent-338388Enabled' -Value 0 | Out-Null
    }
}

# -----------------------------------------------------------------------------
# Energia  (cal admin)
# -----------------------------------------------------------------------------
$pw = $sys.power
if ($pw) {
    $planGuids = @{
        balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
        high     = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
        ultimate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
    }

    if ($pw.plan -and $pw.plan -ne 'none') {
        $guid = $planGuids[$pw.plan]
        if (-not $guid) {
            Write-TaskResult -Task 'pla d''energia' -Status 'failed' -Message "pla desconegut: $($pw.plan)"
        } elseif ($checkMode) {
            Write-TaskResult -Task 'pla d''energia' -Status 'changed' -Message "activaria $($pw.plan)"
        } else {
            try {
                $active = (& powercfg /getactivescheme | Out-String)
                if ($active -match $guid) {
                    Write-TaskResult -Task 'pla d''energia' -Status 'ok' -Message $pw.plan
                } else {
                    # El pla Ultimate no existeix fins que es duplica; és idempotent.
                    if ($pw.plan -eq 'ultimate') { & powercfg -duplicatescheme $guid 2>&1 | Out-Null }
                    & powercfg /setactive $guid 2>&1 | Out-Null
                    if ($LASTEXITCODE -ne 0) { throw "powercfg ha retornat $LASTEXITCODE (cal admin?)" }
                    Write-TaskResult -Task 'pla d''energia' -Status 'changed' -Message $pw.plan
                }
            } catch {
                Write-TaskResult -Task 'pla d''energia' -Status 'failed' -Message $_.Exception.Message
            }
        }
    }

    <#
    .SYNOPSIS
        Llegeix el temps d'espera actual (endollat) en minuts, o $null.
    .DESCRIPTION
        `powercfg /change` no diu mai què hi havia abans, així que sense llegir
        el valor primer la tasca sortiria com a 'changed' a cada execució.
        La sortida de /query està traduïda, però els valors hexadecimals no: els
        dos últims són el d'AC i el de CC, per aquest ordre. Els anteriors són el
        mínim, el màxim i l'increment.
    #>
    function Get-PowerTimeoutMinutes {
        param([string]$SubGroup, [string]$Setting)
        $out = (& powercfg /query SCHEME_CURRENT $SubGroup $Setting 2>$null | Out-String)
        $hex = [regex]::Matches($out, '0x[0-9a-fA-F]{8}')
        if ($hex.Count -lt 2) { return $null }
        $seconds = [Convert]::ToInt64($hex[$hex.Count - 2].Value, 16)
        return [int]($seconds / 60)
    }

    foreach ($entry in @(
        @{ Key = 'monitor_timeout_ac'; Flag = 'monitor-timeout-ac'
           Sub = 'SUB_VIDEO'; Setting = 'VIDEOIDLE'; Task = 'apagar pantalla (endollat)' },
        @{ Key = 'standby_timeout_ac'; Flag = 'standby-timeout-ac'
           Sub = 'SUB_SLEEP'; Setting = 'STANDBYIDLE'; Task = 'suspensió (endollat)' }
    )) {
        $value = $pw[$entry.Key]
        if ($null -eq $value -or [int]$value -lt 0) {
            Write-TaskResult -Task $entry.Task -Status 'skipped' -Message 'valor -1: no es toca'
            continue
        }
        $value = [int]$value

        $current = Get-PowerTimeoutMinutes -SubGroup $entry.Sub -Setting $entry.Setting
        if ($null -ne $current -and $current -eq $value) {
            Write-TaskResult -Task $entry.Task -Status 'ok' -Message "$value min"
            continue
        }
        if ($checkMode) {
            Write-TaskResult -Task $entry.Task -Status 'changed' -Message "posaria $value min (ara: $current)"
            continue
        }
        try {
            & powercfg '/change' $entry.Flag "$value" 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "powercfg ha retornat $LASTEXITCODE (cal admin?)" }
            Write-TaskResult -Task $entry.Task -Status 'changed' -Message "$current -> $value min"
        } catch {
            Write-TaskResult -Task $entry.Task -Status 'failed' -Message $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# Entrada: direcció de l'scroll
# -----------------------------------------------------------------------------
# Equivalent a "Disable natural scrolling" del rol desktop d'ansible-mac. A
# macOS és una sola clau (com.apple.swipescrolldirection); aquí en calen dues,
# i amb conveni invertit l'una respecte l'altra.
$inp = $sys.input
if ($inp -and $null -ne $inp.natural_scrolling) {
    $natural = [bool]$inp.natural_scrolling
    $etiqueta = 'clàssic'
    if ($natural) { $etiqueta = 'natural' }

    # --- touchpad de precisió (HKCU, no cal admin) ---------------------------
    # 0 = natural (el contingut segueix els dits), 1 = clàssic.
    $ptpKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad'
    if (-not (Test-Path -LiteralPath $ptpKey)) {
        Write-TaskResult -Task 'scroll del touchpad' -Status 'skipped' -Message 'aquest equip no té touchpad de precisió'
    } else {
        $ptpValue = 1
        if ($natural) { $ptpValue = 0 }
        Set-Tweak -Task "scroll del touchpad ($etiqueta)" -Path $ptpKey `
            -Name 'ScrollDirection' -Value $ptpValue | Out-Null
    }

    # --- ratolins HID (HKLM, cal admin) --------------------------------------
    # 0 = clàssic, 1 = natural. La clau és per dispositiu: cal recórrer-los tots,
    # i n'hi ha un per cada ratolí que s'hagi connectat mai a l'equip.
    if (-not (Test-Elevated) -and -not $checkMode) {
        Write-TaskResult -Task "scroll del ratolí ($etiqueta)" -Status 'skipped' -Message 'cal admin'
    } else {
        $wheelValue = 0
        if ($natural) { $wheelValue = 1 }
        try {
            $devices = @(Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\HID\*\*\Device Parameters' `
                            -Name FlipFlopWheel -ErrorAction SilentlyContinue)
            if ($devices.Count -eq 0) {
                Write-TaskResult -Task "scroll del ratolí ($etiqueta)" -Status 'skipped' -Message 'cap dispositiu HID amb FlipFlopWheel'
            } else {
                $touched = 0
                foreach ($dev in $devices) {
                    $devPath = $dev.PSPath -replace '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE', 'HKLM:'
                    if (Set-RegistryValue -Path $devPath -Name 'FlipFlopWheel' -Value $wheelValue -Type 'DWord') {
                        $touched++
                    }
                }
                if ($touched -gt 0) {
                    Write-TaskResult -Task "scroll del ratolí ($etiqueta)" -Status 'changed' `
                        -Message "$touched de $($devices.Count) dispositius"
                    Write-Info 'El canvi al ratolí no s''aplica fins que el desconnectis i el tornis a connectar (o reiniciïs).'
                } else {
                    Write-TaskResult -Task "scroll del ratolí ($etiqueta)" -Status 'ok' `
                        -Message "$($devices.Count) dispositius ja correctes"
                }
            }
        } catch {
            Write-TaskResult -Task "scroll del ratolí ($etiqueta)" -Status 'failed' -Message $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# Desenvolupament  (cal admin)
# -----------------------------------------------------------------------------
$dv = $sys.developer
if ($dv) {
    if ($dv.enable_developer_mode) {
        if (-not (Test-Elevated) -and -not $checkMode) {
            Write-TaskResult -Task 'mode desenvolupador' -Status 'skipped' -Message 'cal admin'
        } else {
            Set-Tweak -Task 'mode desenvolupador' `
                -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
                -Name 'AllowDevelopmentWithoutDevLicense' -Value 1 | Out-Null
        }
    }

    if ($dv.enable_long_paths) {
        if (-not (Test-Elevated) -and -not $checkMode) {
            Write-TaskResult -Task 'rutes llargues (>260 car.)' -Status 'skipped' -Message 'cal admin'
        } else {
            Set-Tweak -Task 'rutes llargues (>260 car.)' `
                -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
                -Name 'LongPathsEnabled' -Value 1 | Out-Null
        }
    }

    if ($dv.enable_openssh_server) {
        if (-not (Test-Elevated) -and -not $checkMode) {
            Write-TaskResult -Task 'OpenSSH Server' -Status 'skipped' -Message 'cal admin'
        } elseif ($checkMode) {
            Write-TaskResult -Task 'OpenSSH Server' -Status 'changed' -Message 'instal·laria la capacitat'
        } else {
            try {
                $cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' -ErrorAction Stop |
                       Select-Object -First 1
                if ($cap.State -eq 'Installed') {
                    Write-TaskResult -Task 'OpenSSH Server' -Status 'ok'
                } else {
                    Add-WindowsCapability -Online -Name $cap.Name -ErrorAction Stop | Out-Null
                    Set-Service -Name sshd -StartupType Automatic
                    Start-Service sshd
                    Write-TaskResult -Task 'OpenSSH Server' -Status 'changed'
                }
            } catch {
                Write-TaskResult -Task 'OpenSSH Server' -Status 'failed' -Message $_.Exception.Message
            }
        }
    }
}

# -----------------------------------------------------------------------------
# Reinici de l'explorador perquè els canvis siguin visibles
# -----------------------------------------------------------------------------
if ($explorerNeedsRestart -and -not $checkMode) {
    Write-Info 'Alguns canvis necessiten reiniciar l''Explorador de Windows.'
    Write-Info 'Executa: Stop-Process -Name explorer -Force   (es torna a obrir sol)'
}
