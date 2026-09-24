<#
.SYNOPSIS
    Rol debloat: treu el programari preinstal·lat que no volem a Windows 11.
.DESCRIPTION
    Tres feines, en aquest ordre:

      1. Paquets AppX de l'usuari actual. No cal admin.
      2. Els mateixos paquets de la imatge (aprovisionats), que és el que evita
         que tornin quan es crea un perfil nou. Això sí que cal admin.
      3. Els ajustos que impedeixen que Windows se'ls reinstal·li sol.

    La llista viu a `config.yml`, a la secció `debloat:`. Aquí no hi ha cap nom
    de paquet escrit a mà.

    Idempotent: el que ja no hi és surt com a `ok`, no com a error.
#>
param(
    [Parameter(Mandatory)]$Config,
    [string]$RepoRoot,
    [switch]$Upgrade
)

Set-ProvisionContext -Role 'debloat'

$cfg = $Config.debloat
if (-not $cfg) {
    Write-TaskResult -Task 'configuració' -Status 'skipped' -Message 'cap secció debloat: a la configuració' -NotApplicable
    return
}

$checkMode = Get-ProvisionCheckMode

# -----------------------------------------------------------------------------
# Paquets AppX
# -----------------------------------------------------------------------------
# Get-AppxPackage costa un segon llarg; el demanem una sola vegada i busquem
# sobre la llista, en comptes de fer una crida per paquet.
$installats = @{}
foreach ($p in (Get-AppxPackage -ErrorAction SilentlyContinue)) {
    $installats[$p.Name] = $p
}

# Els aprovisionats només es poden llegir elevat. Sense privilegis no sabem si
# n'hi ha, o sigui que ens ho guardem per a la passada d'admin.
$aprovisionats = @{}
$potLlegirImatge = (Test-Elevated) -or $checkMode
if ($cfg.remove_provisioned -and (Test-Elevated)) {
    try {
        foreach ($p in (Get-AppxProvisionedPackage -Online -ErrorAction Stop)) {
            $aprovisionats[$p.DisplayName] = $p
        }
    } catch {
        Write-TaskResult -Task 'paquets aprovisionats' -Status 'failed' -Message $_.Exception.Message
        $potLlegirImatge = $false
    }
}

foreach ($app in @($cfg.appx)) {
    if (-not $app) { continue }
    if ($app.ContainsKey('enabled') -and -not $app.enabled) { continue }

    $id = $app.id
    $hiEsUsuari = $installats.ContainsKey($id)
    $hiEsImatge = $aprovisionats.ContainsKey($id)

    if (-not $hiEsUsuari -and -not $hiEsImatge) {
        # Si som elevats sabem del cert que no hi és enlloc. Si no ho som, no hem
        # pogut mirar la imatge, però tampoc podem fer-hi res: ja ho dirà la
        # passada d'admin.
        Write-TaskResult -Task $id -Status 'ok' -Message 'no hi és'
        continue
    }

    $on = @()
    if ($hiEsUsuari) { $on += 'usuari' }
    if ($hiEsImatge) { $on += 'imatge' }
    $ones = $on -join ' + '

    if ($checkMode) {
        Write-TaskResult -Task $id -Status 'changed' -Message "esborraria ($ones)"
        continue
    }

    # Treure'l de l'usuari no demana privilegis; de la imatge, sí. Fem el que
    # puguem ara i deixem la resta per al bloc elevat.
    $fet = @()
    $pendent = $false

    if ($hiEsUsuari) {
        try {
            Remove-AppxPackage -Package $installats[$id].PackageFullName -ErrorAction Stop
            $fet += 'usuari'
        } catch {
            Write-TaskResult -Task $id -Status 'failed' -Message (Get-OutputTail $_.Exception.Message)
            continue
        }
    }

    if ($hiEsImatge) {
        if (Test-Elevated) {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $aprovisionats[$id].PackageName -ErrorAction Stop | Out-Null
                $fet += 'imatge'
            } catch {
                # 0x80070003 = ruta no trobada. Passa amb entrades òrfenes: el paquet
                # consta a la imatge però els fitxers ja no hi són, o sigui que no hi
                # ha res a esborrar. El `dism /remove-provisionedappxpackage` hi falla
                # igual, amb el mateix error 3: no és cosa nostra i no té arranjament
                # des d'aquí. Només molesta si algun dia es crea un perfil nou, i
                # aleshores l'app tampoc s'hi podrà instal·lar.
                $orfe = ($_.Exception.HResult -eq -2147024893) -or
                        ("$($_.Exception.Message)" -match '0x80070003')
                if ($orfe) {
                    $missatge = 'entrada òrfena a la imatge (error 3): no hi ha fitxers per esborrar'
                    if ($fet.Count -gt 0) { $missatge = "esborrat de l'usuari; a la imatge, $missatge" }
                    Write-TaskResult -Task $id -Status 'skipped' -Message $missatge
                } else {
                    Write-TaskResult -Task $id -Status 'failed' -Message (Get-OutputTail $_.Exception.Message)
                }
                continue
            }
        } else {
            $pendent = $true
        }
    }

    if ($pendent) {
        Register-AdminWork -Task "$id (de la imatge)"
        Write-TaskResult -Task $id -Status 'changed' `
            -Message "esborrat de l'usuari; la imatge es fara al bloc elevat del final"
    } else {
        Write-TaskResult -Task $id -Status 'changed' -Message "esborrat ($($fet -join ' + '))"
    }
}

# Sense privilegis no hem pogut ni mirar la imatge: ho apuntem un sol cop, no
# paquet per paquet, que si no el run s'omple.
if ($cfg.remove_provisioned -and -not (Test-Elevated)) {
    Register-AdminWork -Task 'repassar els paquets aprovisionats (perquè no tornin)'
}

# -----------------------------------------------------------------------------
# Programes de sempre
# -----------------------------------------------------------------------------
$UNINSTALL_KEYS = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

<#
.SYNOPSIS
    Busca una entrada de Programes i característiques pel nom exacte.
#>
function Get-UninstallEntry {
    param([Parameter(Mandatory)][string]$DisplayName)
    foreach ($key in $UNINSTALL_KEYS) {
        $hit = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue |
               Where-Object { $_.DisplayName -eq $DisplayName } |
               Select-Object -First 1
        if ($hit) { return $hit }
    }
    return $null
}

foreach ($prog in @($cfg.win32)) {
    if (-not $prog) { continue }
    if ($prog.ContainsKey('enabled') -and -not $prog.enabled) { continue }

    $nom = $prog.id
    $entry = Get-UninstallEntry -DisplayName $nom

    if (-not $entry) {
        Write-TaskResult -Task $nom -Status 'ok' -Message 'no instal·lat' -NotApplicable
        continue
    }

    # QuietUninstallString ja porta el modificador de silenci. Si no n'hi ha,
    # afegim el que digui el catàleg (els instal·ladors NSIS fan servir /S, els
    # d'Inno Setup /SILENT). Sense cap dels dos no ho intentem: un desinstal·lador
    # interactiu enmig d'un run desatès es queda penjat per sempre.
    $cmd = $entry.QuietUninstallString
    if (-not $cmd -and $prog.silent_flag) {
        $cmd = '"{0}" {1}' -f $entry.UninstallString.Trim('"'), $prog.silent_flag
    }

    if (-not $cmd) {
        Write-TaskResult -Task $nom -Status 'skipped' `
            -Message "no té desinstal·lador silenciós; posa-li silent_flag al catàleg o treu-lo a mà"
        continue
    }

    if ($checkMode) {
        if (-not (Test-Elevated)) { Register-AdminWork -Task $nom }
        Write-TaskResult -Task $nom -Status 'changed' -Message "desinstal·laria: $cmd"
        continue
    }

    Invoke-AdminWork -Task $nom -Action {
        try {
            $r = Invoke-NativeCommand -FilePath 'cmd.exe' -Arguments @('/c', $cmd)
            # Molts desinstal·ladors retornen 0 encara que no facin res, i n'hi ha
            # que no retornen res. Comprovem el resultat mirant el registre.
            if (Get-UninstallEntry -DisplayName $nom) {
                Write-TaskResult -Task $nom -Status 'failed' `
                    -Message "el desinstal·lador ha acabat pero el programa encara hi es: $(Get-OutputTail $r.Output)"
            } else {
                Write-TaskResult -Task $nom -Status 'changed' -Message 'desinstal·lat'
            }
        } catch {
            Write-TaskResult -Task $nom -Status 'failed' -Message $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# Que no tornin
# -----------------------------------------------------------------------------
# Esborrar les apps no n'hi ha prou: Windows en reinstal·la soles un grapat a la
# primera ocasió. Aquests valors són els que ho aturen.
$st = $cfg.settings
if ($st) {

    <#
    .SYNOPSIS
        Ajust d'HKLM: el fa ara si pot, i si no l'apunta per al bloc elevat.
    #>
    function Set-MachineTweak {
        param([string]$Task, [string]$Path, [string]$Name, $Value)
        Invoke-AdminWork -Task $Task -AlreadyDone {
            Test-RegistryValue -Path $Path -Name $Name -Value $Value
        } -Action {
            try {
                $changed = Set-RegistryValue -Path $Path -Name $Name -Value $Value
                $status = 'ok'; if ($changed) { $status = 'changed' }
                Write-TaskResult -Task $Task -Status $status -Message "$Name = $Value"
            } catch {
                Write-TaskResult -Task $Task -Status 'failed' -Message $_.Exception.Message
            }
        }
    }

    <#
    .SYNOPSIS
        Ajust d'HKCU: no cal admin.
    #>
    function Set-UserTweak {
        param([string]$Task, [string]$Path, [string]$Name, $Value)
        try {
            $changed = Set-RegistryValue -Path $Path -Name $Name -Value $Value
            $status = 'ok'; if ($changed) { $status = 'changed' }
            Write-TaskResult -Task $Task -Status $status -Message "$Name = $Value"
        } catch {
            Write-TaskResult -Task $Task -Status 'failed' -Message $_.Exception.Message
        }
    }

    $ADVANCED = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

    if ($st.disable_consumer_features) {
        Set-MachineTweak -Task 'no reinstal·lis apps promocionades' `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' `
            -Name 'DisableWindowsConsumerFeatures' -Value 1
    }

    if ($st.disable_recall) {
        Set-MachineTweak -Task 'Recall (captures de Windows AI)' `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' `
            -Name 'DisableAIDataAnalysis' -Value 1
    }

    if ($st.disable_copilot) {
        Set-MachineTweak -Task 'Copilot' `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' `
            -Name 'TurnOffWindowsCopilot' -Value 1
    }

    if ($st.disable_widgets) {
        # Els Widgets són el paquet MicrosoftWindows.Client.WebExperience, i hi ha
        # builds de Windows 11 que ja no el porten. En aquestes, la clau de política existeix
        # però està bloquejada per ACL: escriure-hi peta amb UnauthorizedAccessException
        # fins i tot com a administrador. No és un problema de permisos del run, és
        # que no hi ha res a desactivar.
        $widgets = $null
        try {
            $widgets = Get-AppxPackage -Name 'MicrosoftWindows.Client.WebExperience' -ErrorAction SilentlyContinue
        } catch { }

        if (-not $widgets) {
            Write-TaskResult -Task 'Widgets' -Status 'skipped' `
                -Message 'aquesta build de Windows no porta Widgets' -NotApplicable
        } else {
            Set-MachineTweak -Task 'Widgets' `
                -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' `
                -Name 'AllowNewsAndInterests' -Value 0
        }
    }

    if ($st.hide_start_recommendations) {
        # N'hi ha dos: la política de màquina i la preferència d'usuari. La
        # política només l'obeeixen les edicions Pro/Enterprise, i la preferència
        # només algunes builds, o sigui que posem les dues.
        Set-MachineTweak -Task 'bloc Recomanat del menú Inici' `
            -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' `
            -Name 'HideRecommendedSection' -Value 1
        Set-UserTweak -Task 'suggeriments al menú Inici' `
            -Path $ADVANCED -Name 'Start_IrisRecommendations' -Value 0
    }

    if ($st.hide_explorer_ads) {
        Set-UserTweak -Task 'anuncis a l''Explorador' `
            -Path $ADVANCED -Name 'ShowSyncProviderNotifications' -Value 0
    }
}
