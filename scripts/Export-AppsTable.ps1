#Requires -Version 5.1
<#
.SYNOPSIS
    Regenera docs/APPS.md a partir de config.yml.
.DESCRIPTION
    La taula de paritat macOS <-> Windows no s'escriu a mà: surt del catàleg.
    Executa'l cada cop que afegeixis o treguis un paquet.
#>
[CmdletBinding()]
param(
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $OutFile) { $OutFile = Join-Path $RepoRoot 'docs\APPS.md' }

Import-Module powershell-yaml -ErrorAction Stop
$config = ConvertFrom-Yaml (Get-Content (Join-Path $RepoRoot 'config.yml') -Raw -Encoding UTF8)

$defaultGroups = @($config.default_groups)
$lines = New-Object System.Collections.ArrayList

function Add-Line { param([string]$Text = '') [void]$lines.Add($Text) }

Add-Line '# Paritat d''aplicacions: `ansible-mac` ↔ `ansible-win`'
Add-Line ''
Add-Line '> Generat automàticament per `scripts/Export-AppsTable.ps1` a partir de'
Add-Line '> `config.yml`. No l''editis a mà.'
Add-Line ''
Add-Line 'La columna **A ansible-mac** és la fórmula o el cask del repo de macOS.'
Add-Line 'Serveix per comprovar d''un cop d''ull que cap app del Mac s''ha quedat pel camí.'
Add-Line ''

$total = 0
$missing = New-Object System.Collections.ArrayList

foreach ($group in @($config.packages.Keys | Sort-Object)) {
    $entries = @($config.packages[$group] | Where-Object { $_ })
    if ($entries.Count -eq 0) { continue }
    $total += $entries.Count

    $suffix = ' _(opcional)_'
    if ($defaultGroups -contains $group) { $suffix = '' }

    Add-Line ''
    Add-Line "## ``$group``$suffix"
    Add-Line ''
    Add-Line '| A ansible-mac | A Windows | winget | Chocolatey | Scoop |'
    Add-Line '| --- | --- | --- | --- | --- |'

    foreach ($pkg in ($entries | Sort-Object { "$($_.mac)" })) {
        $cell = {
            param($v)
            if ($v) { return "``$v``" }
            return '—'
        }

        $mac = $pkg.mac
        if ($mac) { $mac = "``$mac``" } else { $mac = '—' }

        # Sense cap proveïdor = l'app no existeix a Windows. El 'note' explica
        # per què i quin és el substitut.
        $hasProvider = [bool]($pkg.winget -or $pkg.choco -or $pkg.scoop)
        if ($hasProvider) {
            $windows = $pkg.name
        } else {
            $windows = "**sense equivalent** — $($pkg.note)"
            [void]$missing.Add([pscustomobject]@{ Group = $group; Mac = $pkg.mac; Note = $pkg.note })
        }

        Add-Line ("| {0} | {1} | {2} | {3} | {4} |" -f `
            $mac,
            $windows,
            (& $cell $pkg.winget),
            (& $cell $pkg.choco),
            (& $cell $pkg.scoop))
    }
}

Add-Line ''
Add-Line '---'
Add-Line ''
Add-Line "**$total entrades** en $(@($config.packages.Keys).Count) categories, de les quals"
Add-Line "**$($total - $missing.Count) s'instal·len** i **$($missing.Count) no tenen equivalent** a Windows."
Add-Line ''
Add-Line 'Les que no en tenen surten com a `skipped` quan executes `run.ps1`, amb el'
Add-Line 'motiu al costat: no són errors, són decisions documentades.'
Add-Line ''

$dir = Split-Path -Parent $OutFile
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
Set-Content -LiteralPath $OutFile -Value ($lines -join "`n") -Encoding UTF8

Write-Host "Escrit: $OutFile  ($total paquets)" -ForegroundColor Green
