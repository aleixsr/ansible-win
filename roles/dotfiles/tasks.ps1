<#
.SYNOPSIS
    Rol dotfiles: enllaça fitxers de configuració del repo a la seva destinació.
#>
param(
    [Parameter(Mandatory)]$Config,
    [string]$RepoRoot,
    [switch]$Upgrade
)

Set-ProvisionContext -Role 'dotfiles'

$links = @()
if ($Config.dotfiles -and $Config.dotfiles.links) { $links = @($Config.dotfiles.links) }

if ($links.Count -eq 0) {
    Write-TaskResult -Task 'enllaços' -Status 'skipped' -Message 'dotfiles.links buit' -NotApplicable
    return
}

foreach ($link in $links) {
    if (-not $link -or -not $link.src -or -not $link.dest) {
        Write-TaskResult -Task 'enllaç' -Status 'failed' -Message 'entrada sense src o dest'
        continue
    }

    $src = $link.src
    if (-not [System.IO.Path]::IsPathRooted($src)) {
        $src = Join-Path $RepoRoot $src
    }

    # El destí admet $env:NOM; l'expandim aquí perquè el YAML és text pla.
    $dest = [regex]::Replace($link.dest, '\$env:(\w+)', {
        param($m)
        $value = [Environment]::GetEnvironmentVariable($m.Groups[1].Value)
        if ($null -eq $value) { return $m.Value }
        return $value
    })
    $dest = [Environment]::ExpandEnvironmentVariables($dest)

    $label = "$($link.src) -> $dest"
    try {
        $changed = Set-SymbolicLink -Path $dest -Target $src
        $status = 'ok'; if ($changed) { $status = 'changed' }
        Write-TaskResult -Task $label -Status $status
    } catch {
        Write-TaskResult -Task $label -Status 'failed' -Message $_.Exception.Message
    }
}
