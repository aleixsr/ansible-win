<#
.SYNOPSIS
    Rol core: gestors de paquets i `sudo`.
.DESCRIPTION
    Deixa la màquina en condicions per a la resta de rols:
      - winget / Chocolatey / Scoop disponibles
      - gsudo instal·lat
      - `sudo` (sense la g) apuntant a gsudo, tant a PowerShell com a cmd.exe
#>
param(
    [Parameter(Mandatory)]$Config,
    [string]$RepoRoot,
    [switch]$Upgrade
)

Set-ProvisionContext -Role 'core'

# -----------------------------------------------------------------------------
# winget
# -----------------------------------------------------------------------------
if (Test-WingetAvailable) {
    Write-TaskResult -Task 'winget disponible' -Status 'ok' -Message (Get-Command winget).Source
} else {
    Write-TaskResult -Task 'winget disponible' -Status 'failed' `
        -Message "winget no hi és. Instal·la 'Instal·lador de aplicaciones' des de Microsoft Store o https://aka.ms/getwinget"
}

# -----------------------------------------------------------------------------
# Chocolatey
# -----------------------------------------------------------------------------
if (Test-ChocoAvailable) {
    Write-TaskResult -Task 'Chocolatey' -Status 'ok' -Message (Get-Command choco).Source
} elseif (Get-ProvisionCheckMode) {
    Write-TaskResult -Task 'Chocolatey' -Status 'changed' -Message 'instal·laria Chocolatey'
} else {
    try {
        if (-not (Test-Elevated)) { throw 'cal executar el run com a administrador per instal·lar Chocolatey' }
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) | Out-Null
        Update-SessionPath
        Write-TaskResult -Task 'Chocolatey' -Status 'changed' -Message 'instal·lat'
    } catch {
        Write-TaskResult -Task 'Chocolatey' -Status 'failed' -Message $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# Scoop (opcional: només el fem servir per a paquets que no són a winget/choco)
# -----------------------------------------------------------------------------
$needsScoop = $false
foreach ($group in @($Config.packages.Keys)) {
    foreach ($pkg in @($Config.packages[$group])) {
        if ($null -eq $pkg) { continue }
        if ($pkg.provider -eq 'scoop') { $needsScoop = $true }
    }
}

if (Test-ScoopAvailable) {
    Write-TaskResult -Task 'Scoop' -Status 'ok' -Message 'ja instal·lat'
} elseif (-not $needsScoop) {
    Write-TaskResult -Task 'Scoop' -Status 'skipped' -Message 'cap paquet el requereix explícitament'
} elseif (Get-ProvisionCheckMode) {
    Write-TaskResult -Task 'Scoop' -Status 'changed' -Message 'instal·laria Scoop'
} else {
    try {
        # Scoop s'instal·la SENSE privilegis: és per disseny (tot a %USERPROFILE%\scoop).
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression | Out-Null
        Update-SessionPath
        Write-TaskResult -Task 'Scoop' -Status 'changed' -Message 'instal·lat'
    } catch {
        Write-TaskResult -Task 'Scoop' -Status 'failed' -Message $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# gsudo
# -----------------------------------------------------------------------------
$gsudoPkg = $null
foreach ($pkg in @($Config.packages.core)) {
    if ($pkg -and $pkg.id -eq 'gsudo') { $gsudoPkg = $pkg }
}
if (-not $gsudoPkg) {
    $gsudoPkg = @{ id = 'gsudo'; name = 'gsudo'; winget = 'gerardog.gsudo'; choco = 'gsudo'; test = 'gsudo' }
}
Install-CatalogPackage -Package $gsudoPkg -ProviderOrder $Config.provider_order -Upgrade:$Upgrade
Update-SessionPath

# -----------------------------------------------------------------------------
# `sudo` -> gsudo
# -----------------------------------------------------------------------------
# Windows 11 porta el seu propi sudo.exe a System32 i, com que el PATH de màquina
# va abans que el d'usuari, sempre guanyaria. Per això no n'hi ha prou amb posar
# gsudo al PATH: cal un àlies de PowerShell (que té precedència sobre qualsevol
# executable) i un shim .cmd per als contextos on no hi ha PowerShell.
$sudoCfg = $Config.sudo
if (-not $sudoCfg) { $sudoCfg = @{ provider = 'gsudo'; powershell_alias = $true; cmd_shim = $true } }

$gsudoCmd = Get-Command gsudo -ErrorAction SilentlyContinue
$nativeSudo = $null
$sysSudo = Join-Path $env:SystemRoot 'System32\sudo.exe'
if (Test-Path -LiteralPath $sysSudo) { $nativeSudo = $sysSudo }

if ($sudoCfg.provider -ne 'gsudo') {
    Write-TaskResult -Task 'sudo -> gsudo' -Status 'skipped' -Message "sudo.provider = $($sudoCfg.provider)"
} elseif (-not $gsudoCmd) {
    Write-TaskResult -Task 'sudo -> gsudo' -Status 'failed' -Message 'gsudo no és al PATH; reobre la consola i torna-ho a executar'
} else {

    # --- shim per a cmd.exe / Executar / tasques programades -------------------
    if ($sudoCfg.cmd_shim) {
        $binDir = Join-Path $RepoRoot 'bin'
        $shimPath = Join-Path $binDir 'sudo.cmd'
        # Here-string literal + substitució: així els backticks i els $ del
        # contingut no els interpreta PowerShell.
        $shim = @'
@echo off
rem Generat per ansible-win (rol core). No editar a ma.
rem Redirigeix "sudo" a gsudo, evitant el sudo.exe natiu de Windows 11.
"__GSUDO__" %*
'@.Replace('__GSUDO__', $gsudoCmd.Source)
        try {
            if (-not (Test-Path -LiteralPath $binDir)) {
                New-Item -ItemType Directory -Path $binDir -Force | Out-Null
            }
            $shimChanged = Set-FileContent -Path $shimPath -Content $shim -Encoding ASCII
            # Prepend: el PATH d'usuari s'avalua després del de màquina, però dins
            # del PATH d'usuari volem ser els primers.
            $pathChanged = Add-PathEntry -Directory $binDir -Scope 'User' -Prepend

            if ($shimChanged -or $pathChanged) {
                Write-TaskResult -Task 'shim sudo.cmd' -Status 'changed' -Message $shimPath
            } else {
                Write-TaskResult -Task 'shim sudo.cmd' -Status 'ok' -Message $shimPath
            }

            if ($nativeSudo) {
                Write-Info "Nota: Windows porta $nativeSudo i el PATH de màquina va primer."
                Write-Info "A PowerShell mana l'àlies del perfil; a cmd.exe crida 'gsudo' directament si dubtes."
            }
        } catch {
            Write-TaskResult -Task 'shim sudo.cmd' -Status 'failed' -Message $_.Exception.Message
        }
    } else {
        Write-TaskResult -Task 'shim sudo.cmd' -Status 'skipped' -Message 'sudo.cmd_shim = false'
    }

    # --- àlies de PowerShell ---------------------------------------------------
    # El fitxer real s'escriu al rol `shell` (dins del perfil). Aquí només deixem
    # el fragment perquè el perfil el pugui carregar i informem de l'estat.
    if ($sudoCfg.powershell_alias) {
        $snippetDir = Join-Path $RepoRoot 'files\profile.d'
        $snippetPath = Join-Path $snippetDir '10-sudo.ps1'
        $snippet = @'
# Generat per ansible-win (rol core). No editar a mà.
# "sudo" -> gsudo. Una funció de PowerShell té precedència sobre qualsevol
# executable del PATH, també sobre C:\Windows\System32\sudo.exe.
$script:GsudoPath = '__GSUDO__'

function sudo {
    if (Test-Path -LiteralPath $script:GsudoPath) {
        & $script:GsudoPath @args
    } else {
        & gsudo @args
    }
}

Set-Alias -Name s -Value sudo -Scope Global -Force -ErrorAction SilentlyContinue
'@.Replace('__GSUDO__', $gsudoCmd.Source)
        try {
            if (-not (Test-Path -LiteralPath $snippetDir)) {
                New-Item -ItemType Directory -Path $snippetDir -Force | Out-Null
            }
            $changed = Set-FileContent -Path $snippetPath -Content $snippet
            $status = 'ok'
            if ($changed) { $status = 'changed' }
            Write-TaskResult -Task 'àlies sudo (PowerShell)' -Status $status -Message $snippetPath
        } catch {
            Write-TaskResult -Task 'àlies sudo (PowerShell)' -Status 'failed' -Message $_.Exception.Message
        }
    } else {
        Write-TaskResult -Task 'àlies sudo (PowerShell)' -Status 'skipped' -Message 'sudo.powershell_alias = false'
    }

    # --- cache de credencials --------------------------------------------------
    $cache = 0
    if ($null -ne $sudoCfg.cache_seconds) { $cache = [int]$sudoCfg.cache_seconds }
    $value = "$cache"
    if ($cache -le 0) { $value = 'Disabled' }

    if (Get-ProvisionCheckMode) {
        Write-TaskResult -Task 'cache de gsudo' -Status 'changed' -Message "posaria CacheDuration = $value"
    } else {
        try {
            $current = (& $gsudoCmd.Source config CacheDuration 2>$null | Out-String).Trim()
            if ($current -match [regex]::Escape($value)) {
                Write-TaskResult -Task 'cache de gsudo' -Status 'ok' -Message $current
            } else {
                & $gsudoCmd.Source config CacheDuration $value | Out-Null
                Write-TaskResult -Task 'cache de gsudo' -Status 'changed' -Message "CacheDuration = $value"
            }
        } catch {
            Write-TaskResult -Task 'cache de gsudo' -Status 'failed' -Message $_.Exception.Message
        }
    }
}
