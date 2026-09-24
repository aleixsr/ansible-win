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
    Write-TaskResult -Task 'configuració' -Status 'skipped' -Message 'cap secció system: a la configuració' -NotApplicable
    return
}

$checkMode = Get-ProvisionCheckMode
$explorerNeedsRestart = $false
# Cert nomes si algun canvi NO enganxa sense reiniciar l'Explorador.
$restartExplorerRequired = $false

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
    # [mac] Equival a com.apple.finder CreateDesktop = false del rol desktop.
    # HideIcons no es pot escriure i prou: l'Explorador se'l guarda en memoria i
    # el torna a escriure, tant mentre corre com en sortir. Cal ATURAR-LO PRIMER,
    # escriure despres i tornar-lo a obrir. Provat: a l'inreves no enganxa.
    if ($null -ne $exp.hide_desktop_icons) {
        $wanted = 0; if ($exp.hide_desktop_icons) { $wanted = 1 }
        $currentIcons = $null
        $prop = Get-ItemProperty -LiteralPath $ADVANCED -Name 'HideIcons' -ErrorAction SilentlyContinue
        if ($prop) { $currentIcons = [int]$prop.HideIcons }

        if ($currentIcons -eq $wanted) {
            Write-TaskResult -Task 'icones de l''escriptori' -Status 'ok' -Message "HideIcons = $wanted"
        } elseif ($checkMode) {
            Write-TaskResult -Task 'icones de l''escriptori' -Status 'changed' -Message "posaria HideIcons = $wanted"
        } else {
            try {
                Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                New-ItemProperty -LiteralPath $ADVANCED -Name 'HideIcons' -Value $wanted `
                    -PropertyType DWord -Force | Out-Null
                Start-Sleep -Seconds 1
                if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
                    Start-Process explorer.exe
                }
                Write-TaskResult -Task 'icones de l''escriptori' -Status 'changed' `
                    -Message "HideIcons = $wanted (Explorador reiniciat)"
            } catch {
                Write-TaskResult -Task 'icones de l''escriptori' -Status 'failed' -Message $_.Exception.Message
            }
        }
    }
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
            Write-TaskResult -Task 'widgets' -Status 'skipped' -Message 'aquesta build de Windows no porta Widgets' -NotApplicable
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
# Entrada: direcció de l'scroll
# -----------------------------------------------------------------------------
# Equivalent a "Disable natural scrolling" del rol desktop d'ansible-mac. A
# macOS és una sola clau (com.apple.swipescrolldirection); aquí en calen dues,
# i amb conveni invertit l'una respecte l'altra.
$inp = $sys.input

# -----------------------------------------------------------------------------
# [mac] Trackpad: el rol desktop d'ansible-mac en configura sis coses. Aquestes
# quatre tenen equivalent al touchpad de precisió de Windows. Les altres dues
# (clic silenciós i Force Click) són del trackpad hàptic dels Mac i no existeixen.
# -----------------------------------------------------------------------------
$PTP = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad'
if ($inp -and (Test-Path -LiteralPath $PTP)) {
    foreach ($t in @(
        @{ Key = 'tap_to_click';          Name = 'TapsEnabled'
           Task = 'tocar per fer clic';   Mac = 'Clicking = 1' },
        @{ Key = 'two_finger_right_click'; Name = 'TwoFingerTapEnabled'
           Task = 'clic secundari amb dos dits'; Mac = 'TrackpadRightClick' },
        @{ Key = 'corner_right_click';    Name = 'RightClickZoneEnabled'
           Task = 'clic secundari per la cantonada'; Mac = 'TrackpadCornerSecondaryClick = 0' },
        @{ Key = 'tap_and_drag';          Name = 'TapAndDrag'
           Task = 'arrossegar sense bloqueig'; Mac = 'Dragging = 1, DragLock = 0' }
    )) {
        if ($null -eq $inp[$t.Key]) { continue }
        $v = 0; if ($inp[$t.Key]) { $v = 1 }
        Set-Tweak -Task $t.Task -Path $PTP -Name $t.Name -Value $v | Out-Null
    }
} elseif ($inp) {
    Write-TaskResult -Task 'trackpad' -Status 'skipped' -Message 'aquest equip no té touchpad de precisió' -NotApplicable
}

if ($inp -and $null -ne $inp.natural_scrolling) {
    $natural = [bool]$inp.natural_scrolling
    $etiqueta = 'clàssic'
    if ($natural) { $etiqueta = 'natural' }

    # --- touchpad de precisió (HKCU, no cal admin) ---------------------------
    # 0 = natural (el contingut segueix els dits), 1 = clàssic.
    $ptpKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad'
    if (-not (Test-Path -LiteralPath $ptpKey)) {
        Write-TaskResult -Task 'scroll del touchpad' -Status 'skipped' -Message 'aquest equip no té touchpad de precisió' -NotApplicable
    } else {
        $ptpValue = 1
        if ($natural) { $ptpValue = 0 }
        Set-Tweak -Task "scroll del touchpad ($etiqueta)" -Path $ptpKey `
            -Name 'ScrollDirection' -Value $ptpValue | Out-Null
    }

    # --- ratolins HID (HKLM, cal admin) --------------------------------------
    # 0 = clàssic, 1 = natural. La clau és per dispositiu: cal recórrer-los tots,
    # i n'hi ha un per cada ratolí que s'hagi connectat mai a l'equip.
    $tascaRatoli = "scroll del ratolí ($etiqueta)"
    $wheelValue = 0
    if ($natural) { $wheelValue = 1 }
    try {
        $devices = @(Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\HID\*\*\Device Parameters' `
                        -Name FlipFlopWheel -ErrorAction SilentlyContinue)

        # Llegir HKLM va sense privilegis: primer mirem quins dispositius estan
        # malament i nomes demanem l'UAC si n'hi ha cap. Si no, aquesta tasca
        # faria demanar elevacio a cada run per no tocar res.
        $pendents = @()
        foreach ($dev in $devices) {
            $devPath = $dev.PSPath -replace '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE', 'HKLM:'
            if (-not (Test-RegistryValue -Path $devPath -Name 'FlipFlopWheel' -Value $wheelValue)) {
                $pendents += $devPath
            }
        }

        if ($devices.Count -eq 0) {
            Write-TaskResult -Task $tascaRatoli -Status 'skipped' -Message 'cap dispositiu HID amb FlipFlopWheel' -NotApplicable
        } elseif ($pendents.Count -eq 0) {
            Write-TaskResult -Task $tascaRatoli -Status 'ok' -Message "$($devices.Count) dispositius ja correctes"
        } elseif (-not (Test-Elevated) -and -not $checkMode) {
            Register-AdminWork -Task $tascaRatoli
            Write-TaskResult -Task $tascaRatoli -Status 'skipped' -Message 'cal admin: es fara al bloc elevat del final'
        } elseif ($checkMode) {
            Write-TaskResult -Task $tascaRatoli -Status 'changed' `
                -Message "$($pendents.Count) de $($devices.Count) dispositius"
        } else {
            foreach ($devPath in $pendents) {
                Set-RegistryValue -Path $devPath -Name 'FlipFlopWheel' -Value $wheelValue -Type 'DWord' | Out-Null
            }
            Write-TaskResult -Task $tascaRatoli -Status 'changed' `
                -Message "$($pendents.Count) de $($devices.Count) dispositius"
            Write-Info 'El canvi al ratolí no s''aplica fins que el desconnectis i el tornis a connectar (o reiniciïs).'
        }
    } catch {
        Write-TaskResult -Task $tascaRatoli -Status 'failed' -Message $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# Energia: acció en tancar la tapa  (cal admin)
# -----------------------------------------------------------------------------
# Cas d'ús: portàtil connectat a una dock USB-C amb monitors externs. Amb la
# tapa tancada volem que segueixi treballant, no que se suspengui. Amb bateria
# mantenim el comportament normal (suspendre), que si no es cou a la motxilla.
#
# powercfg només toca l'ESQUEMA ACTIU. Si canvies de pla d'energia, el nou pla
# porta els seus propis valors i cal tornar a passar el rol.
#
# El valor no es pot llegir amb 'powercfg /query': LIDACTION ve amagat de
# fàbrica i la consulta no l'ensenya. Per saber si cal canviar res mirem
# directament el registre, que és d'on powercfg ho llegeix.
$pw = $sys.power
if ($pw) {
    $LID_SUBGROUP = '4f971e89-eebd-4455-a8de-9e59040e7347'   # SUB_BUTTONS
    $LID_SETTING  = '5ca83367-6e45-459f-a27b-476b1d01c936'   # LIDACTION
    $LID_NAMES = @{ 0 = 'no fer res'; 1 = 'suspendre'; 2 = 'hibernar'; 3 = 'apagar' }

    $wantAc = [int]$pw.lid_action_ac
    $wantDc = [int]$pw.lid_action_dc
    $etiqueta = "tapa tancada (endollat: $($LID_NAMES[$wantAc]) / bateria: $($LID_NAMES[$wantDc]))"

    $active = $null
    $out = (powercfg /getactivescheme) -join ' '
    if ($out -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
        $active = $Matches[1]
    }

    $lidKey = $null
    if ($active) {
        $lidKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$active\$LID_SUBGROUP\$LID_SETTING"
    }

    if (-not $active) {
        Write-TaskResult -Task 'tapa tancada' -Status 'failed' -Message 'no s''ha pogut llegir l''esquema d''energia actiu'
    } elseif (-not (Test-Path -LiteralPath $lidKey)) {
        # Els sobretaula no tenen aquesta clau: no hi ha tapa que tancar.
        Write-TaskResult -Task $etiqueta -Status 'skipped' -Message 'aquest equip no té acció de tapa (no és un portàtil)' -NotApplicable
    } else {
        $now = Get-ItemProperty -LiteralPath $lidKey -ErrorAction SilentlyContinue
        if ($now.ACSettingIndex -eq $wantAc -and $now.DCSettingIndex -eq $wantDc) {
            Write-TaskResult -Task $etiqueta -Status 'ok' -Message "AC=$wantAc DC=$wantDc"
        } elseif (-not (Test-Elevated) -and -not $checkMode) {
            Register-AdminWork -Task $etiqueta
            Write-TaskResult -Task $etiqueta -Status 'skipped' -Message 'cal admin: es fara al bloc elevat del final'
        } elseif ($checkMode) {
            Write-TaskResult -Task $etiqueta -Status 'changed' `
                -Message "AC=$($now.ACSettingIndex)->$wantAc DC=$($now.DCSettingIndex)->$wantDc"
        } else {
            try {
                foreach ($cmd in @(
                    @('/setacvalueindex', 'SCHEME_CURRENT', 'SUB_BUTTONS', 'LIDACTION', "$wantAc"),
                    @('/setdcvalueindex', 'SCHEME_CURRENT', 'SUB_BUTTONS', 'LIDACTION', "$wantDc")
                )) {
                    $r = Invoke-NativeCommand -FilePath 'powercfg' -Arguments $cmd
                    if ($r.ExitCode -ne 0) { throw "powercfg $($cmd -join ' ') ha fallat: $($r.Output.Trim())" }
                }
                # Sense /setactive els índex escrits no s'apliquen a la sessió.
                $r = Invoke-NativeCommand -FilePath 'powercfg' -Arguments @('/setactive', 'SCHEME_CURRENT')
                if ($r.ExitCode -ne 0) { throw "powercfg /setactive ha fallat: $($r.Output.Trim())" }

                Write-TaskResult -Task $etiqueta -Status 'changed' -Message "AC=$wantAc DC=$wantDc"
            } catch {
                Write-TaskResult -Task $etiqueta -Status 'failed' -Message $_.Exception.Message
            }
        }
    }
}

# -----------------------------------------------------------------------------
# Desenvolupament  (cal admin)
# -----------------------------------------------------------------------------
$dv = $sys.developer
if ($dv) {
    if ($dv.enable_developer_mode) {
        Invoke-AdminWork -Task 'mode desenvolupador' -AlreadyDone {
            Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
                -Name 'AllowDevelopmentWithoutDevLicense' -Value 1
        } -Action {
            Set-Tweak -Task 'mode desenvolupador' `
                -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' `
                -Name 'AllowDevelopmentWithoutDevLicense' -Value 1 | Out-Null
        }
    }

    if ($dv.enable_long_paths) {
        Invoke-AdminWork -Task 'rutes llargues (>260 car.)' -AlreadyDone {
            Test-RegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
                -Name 'LongPathsEnabled' -Value 1
        } -Action {
            Set-Tweak -Task 'rutes llargues (>260 car.)' `
                -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' `
                -Name 'LongPathsEnabled' -Value 1 | Out-Null
        }
    }

    if ($dv.enable_openssh_server) {
        if (-not (Test-Elevated) -and -not $checkMode) {
            Register-AdminWork -Task 'OpenSSH Server'
            Write-TaskResult -Task 'OpenSSH Server' -Status 'skipped' -Message 'cal admin: es fara al bloc elevat del final'
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
    # HideIcons és un cas a part: l'Explorador se'l guarda en memòria i el
    # reescriu al registre, així que escriure'l i prou no serveix de res --
    # el valor torna enrere sol. Per a aquest cal reiniciar l'Explorador sí o sí.
    if ($restartExplorerRequired) {
        try {
            Write-Info 'Reiniciant l''Explorador de Windows (les icones de l''escriptori ho necessiten)...'
            Stop-Process -Name explorer -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
            if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
                Start-Process explorer.exe
            }
            Write-Info 'Explorador reiniciat.'
        } catch {
            Write-Info "No s'ha pogut reiniciar l'Explorador: $($_.Exception.Message)"
            Write-Info 'Fes-ho a mà: Stop-Process -Name explorer -Force'
        }
    } else {
        Write-Info 'Alguns canvis necessiten reiniciar l''Explorador de Windows.'
        Write-Info 'Executa: Stop-Process -Name explorer -Force   (es torna a obrir sol)'
    }
}
