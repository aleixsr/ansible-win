<#
.SYNOPSIS
    Rol dev: configuració de git, claus SSH i eines globals de llenguatges.
#>
param(
    [Parameter(Mandatory)]$Config,
    [string]$RepoRoot,
    [switch]$Upgrade
)

Set-ProvisionContext -Role 'dev'

$dev = $Config.dev
if (-not $dev) {
    Write-TaskResult -Task 'configuració' -Status 'skipped' -Message 'cap secció dev: a la configuració' -NotApplicable
    return
}

Update-SessionPath
$checkMode = Get-ProvisionCheckMode

# -----------------------------------------------------------------------------
# git
# -----------------------------------------------------------------------------
if (-not (Test-CommandExists 'git')) {
    Write-TaskResult -Task 'git' -Status 'skipped' -Message 'git no està instal·lat encara (executa el rol apps abans)'
} else {

    function Set-GitConfigValue {
        param([string]$Key, [string]$Value)
        $current = (& git config --global --get $Key 2>$null | Out-String).Trim()
        if ($current -eq $Value) { return $false }
        if ($checkMode) { return $true }
        & git config --global $Key $Value | Out-Null
        return $true
    }

    $gitCfg = $dev.git
    if ($gitCfg) {
        if ($gitCfg.user_name) {
            $changed = Set-GitConfigValue -Key 'user.name' -Value $gitCfg.user_name
            $status = 'ok'; if ($changed) { $status = 'changed' }
            Write-TaskResult -Task 'git user.name' -Status $status -Message $gitCfg.user_name
        } else {
            Write-TaskResult -Task 'git user.name' -Status 'skipped' -Message 'dev.git.user_name buit' -NotApplicable
        }

        if ($gitCfg.user_email) {
            $changed = Set-GitConfigValue -Key 'user.email' -Value $gitCfg.user_email
            $status = 'ok'; if ($changed) { $status = 'changed' }
            Write-TaskResult -Task 'git user.email' -Status $status -Message $gitCfg.user_email
        } else {
            Write-TaskResult -Task 'git user.email' -Status 'skipped' -Message 'dev.git.user_email buit' -NotApplicable
        }

        if ($gitCfg.config) {
            $changedKeys = New-Object System.Collections.ArrayList
            foreach ($key in @($gitCfg.config.Keys)) {
                $value = "$($gitCfg.config[$key])"
                # core.editor apunta a VS Code: si no hi és, no forcem res.
                if ($key -eq 'core.editor' -and $value -like 'code*' -and -not (Test-CommandExists 'code')) {
                    continue
                }
                if (Set-GitConfigValue -Key $key -Value $value) { [void]$changedKeys.Add($key) }
            }
            if ($changedKeys.Count -gt 0) {
                Write-TaskResult -Task 'git config global' -Status 'changed' -Message ($changedKeys -join ', ')
            } else {
                Write-TaskResult -Task 'git config global' -Status 'ok' -Message "$($gitCfg.config.Count) claus ja correctes"
            }
        }

        # delta com a pager de diff, si hi és.
        if (Test-CommandExists 'delta') {
            $deltaChanges = @(
                (Set-GitConfigValue -Key 'core.pager' -Value 'delta'),
                (Set-GitConfigValue -Key 'interactive.diffFilter' -Value 'delta --color-only'),
                (Set-GitConfigValue -Key 'delta.navigate' -Value 'true'),
                (Set-GitConfigValue -Key 'merge.conflictstyle' -Value 'zdiff3')
            )
            $status = 'ok'; if ($deltaChanges -contains $true) { $status = 'changed' }
            Write-TaskResult -Task 'git + delta' -Status $status
        }
    }
}

# -----------------------------------------------------------------------------
# clau SSH
# -----------------------------------------------------------------------------
$sshCfg = $dev.ssh
if (-not $sshCfg -or -not $sshCfg.generate_key) {
    Write-TaskResult -Task 'clau SSH' -Status 'skipped' -Message 'dev.ssh.generate_key = false' -NotApplicable
} else {
    $keyType = $sshCfg.key_type
    if (-not $keyType) { $keyType = 'ed25519' }
    $sshDir = Join-Path $env:USERPROFILE '.ssh'
    $keyPath = Join-Path $sshDir "id_$keyType"

    if (Test-Path -LiteralPath $keyPath) {
        Write-TaskResult -Task 'clau SSH' -Status 'ok' -Message $keyPath
    } elseif (-not (Test-CommandExists 'ssh-keygen')) {
        Write-TaskResult -Task 'clau SSH' -Status 'failed' -Message 'ssh-keygen no és al PATH'
    } elseif ($checkMode) {
        Write-TaskResult -Task 'clau SSH' -Status 'changed' -Message "generaria $keyPath"
    } else {
        try {
            if (-not (Test-Path -LiteralPath $sshDir)) {
                New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
            }
            $comment = $sshCfg.comment
            if (-not $comment) { $comment = "$env:USERNAME@$env:COMPUTERNAME" }
            & ssh-keygen -t $keyType -C $comment -f $keyPath -N '""' -q
            Write-TaskResult -Task 'clau SSH' -Status 'changed' -Message $keyPath
            Write-Info "Clau pública: $(Get-Content "$keyPath.pub" -Raw)"
        } catch {
            Write-TaskResult -Task 'clau SSH' -Status 'failed' -Message $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# paquets globals de npm
# -----------------------------------------------------------------------------
$npmGlobals = @($dev.npm_globals)
if ($npmGlobals.Count -eq 0) {
    Write-TaskResult -Task 'paquets globals npm' -Status 'skipped' -Message 'llista buida' -NotApplicable
} elseif (-not (Test-CommandExists 'npm')) {
    Write-TaskResult -Task 'paquets globals npm' -Status 'skipped' -Message 'npm no està instal·lat'
} else {
    $installed = @()
    try {
        $json = & npm ls -g --depth=0 --json 2>$null | Out-String
        if ($json) { $installed = @(($json | ConvertFrom-Json).dependencies.PSObject.Properties.Name) }
    } catch { }

    foreach ($p in $npmGlobals) {
        $pkgName = ($p -split '@')[0]
        if ($p.StartsWith('@')) { $pkgName = '@' + ($p.Substring(1) -split '@')[0] }
        if ($installed -contains $pkgName) {
            Write-TaskResult -Task "npm -g $p" -Status 'ok'
        } elseif ($checkMode) {
            Write-TaskResult -Task "npm -g $p" -Status 'changed' -Message 'instal·laria'
        } else {
            try {
                $r = Invoke-NativeCommand -FilePath 'npm' -Arguments @('install', '-g', $p)
                if ($r.ExitCode -ne 0) { throw "npm ha retornat $($r.ExitCode): $($r.Output.Trim())" }
                Write-TaskResult -Task "npm -g $p" -Status 'changed'
            } catch {
                Write-TaskResult -Task "npm -g $p" -Status 'failed' -Message $_.Exception.Message
            }
        }
    }
}

# -----------------------------------------------------------------------------
# eines de Python amb uv
# -----------------------------------------------------------------------------
$uvTools = @($dev.uv_tools)
if ($uvTools.Count -eq 0) {
    Write-TaskResult -Task 'eines uv' -Status 'skipped' -Message 'llista buida' -NotApplicable
} elseif (-not (Test-CommandExists 'uv')) {
    Write-TaskResult -Task 'eines uv' -Status 'skipped' -Message 'uv no està instal·lat'
} else {
    $listed = (& uv tool list 2>$null | Out-String)
    foreach ($t in $uvTools) {
        if ($listed -match "(?m)^$([regex]::Escape($t))\b") {
            Write-TaskResult -Task "uv tool $t" -Status 'ok'
        } elseif ($checkMode) {
            Write-TaskResult -Task "uv tool $t" -Status 'changed' -Message 'instal·laria'
        } else {
            try {
                $r = Invoke-NativeCommand -FilePath 'uv' -Arguments @('tool', 'install', $t)
                if ($r.ExitCode -ne 0) { throw "uv ha retornat $($r.ExitCode): $($r.Output.Trim())" }
                Write-TaskResult -Task "uv tool $t" -Status 'changed'
            } catch {
                Write-TaskResult -Task "uv tool $t" -Status 'failed' -Message $_.Exception.Message
            }
        }
    }
}

# -----------------------------------------------------------------------------
# extensions de VS Code
# -----------------------------------------------------------------------------
$extensions = @($dev.vscode_extensions)
if ($extensions.Count -eq 0) {
    Write-TaskResult -Task 'extensions de VS Code' -Status 'skipped' -Message 'llista buida' -NotApplicable
} elseif (-not (Test-CommandExists 'code')) {
    Write-TaskResult -Task 'extensions de VS Code' -Status 'skipped' -Message 'la comanda code no és al PATH'
} else {
    $installed = @(& code --list-extensions 2>$null)
    foreach ($ext in $extensions) {
        if ($installed -contains $ext) {
            Write-TaskResult -Task "code --install-extension $ext" -Status 'ok'
        } elseif ($checkMode) {
            Write-TaskResult -Task "code --install-extension $ext" -Status 'changed' -Message 'instal·laria'
        } else {
            try {
                $r = Invoke-NativeCommand -FilePath 'code' -Arguments @('--install-extension', $ext, '--force')
                if ($r.ExitCode -ne 0) { throw "code ha retornat $($r.ExitCode): $($r.Output.Trim())" }
                Write-TaskResult -Task "code --install-extension $ext" -Status 'changed'
            } catch {
                Write-TaskResult -Task "code --install-extension $ext" -Status 'failed' -Message $_.Exception.Message
            }
        }
    }
}
