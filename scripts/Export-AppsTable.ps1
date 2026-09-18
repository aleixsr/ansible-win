#Requires -Version 5.1
<#
.SYNOPSIS
    Regenera docs/APPS.md a partir de group_vars/all.yml.
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
$config = ConvertFrom-Yaml (Get-Content (Join-Path $RepoRoot 'group_vars\all.yml') -Raw -Encoding UTF8)

$defaultGroups = @($config.default_groups)
$lines = New-Object System.Collections.ArrayList

function Add-Line { param([string]$Text = '') [void]$lines.Add($Text) }

Add-Line '# Paritat d''aplicacions: macOS ↔ Windows'
Add-Line ''
Add-Line '> Generat automàticament per `scripts/Export-AppsTable.ps1` a partir de'
Add-Line '> `group_vars/all.yml`. No l''editis a mà.'
Add-Line ''
Add-Line 'La columna **Homebrew** és l''equivalent a `ansible_mac`. Serveix per veure'
Add-Line 'd''un cop d''ull què té paritat real, què té un substitut i què no existeix'
Add-Line 'per a l''altra plataforma.'
Add-Line ''

$total = 0
foreach ($group in @($config.packages.Keys | Sort-Object)) {
    $entries = @($config.packages[$group] | Where-Object { $_ })
    if ($entries.Count -eq 0) { continue }
    $total += $entries.Count

    $suffix = ' _(opcional)_'
    if ($defaultGroups -contains $group) { $suffix = '' }

    Add-Line ''
    Add-Line "## ``$group``$suffix"
    Add-Line ''
    Add-Line '| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |'
    Add-Line '| --- | --- | --- | --- | --- |'

    foreach ($pkg in ($entries | Sort-Object { $_.name })) {
        $cell = {
            param($v)
            if ($v) { return "``$v``" }
            return '—'
        }
        $brew = $pkg.brew
        if (-not $brew) { $brew = '—' }
        elseif ($brew -notmatch '^\(') { $brew = "``$brew``" }

        Add-Line ("| {0} | {1} | {2} | {3} | {4} |" -f `
            $pkg.name,
            (& $cell $pkg.winget),
            (& $cell $pkg.choco),
            (& $cell $pkg.scoop),
            $brew)
    }
}

Add-Line ''
Add-Line '---'
Add-Line ''
Add-Line "**$total paquets** en $(@($config.packages.Keys).Count) grups."
Add-Line ''
Add-Line 'Llegenda de la columna Homebrew:'
Add-Line ''
Add-Line '- `` `nom` `` — mateixa aplicació a les dues plataformes.'
Add-Line '- `(alternativa)` — no existeix a l''altra plataforma; entre parèntesis, el substitut habitual.'
Add-Line '- `(n/a)` — específic d''una plataforma, sense equivalent.'
Add-Line ''

$dir = Split-Path -Parent $OutFile
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
Set-Content -LiteralPath $OutFile -Value ($lines -join "`n") -Encoding UTF8

Write-Host "Escrit: $OutFile  ($total paquets)" -ForegroundColor Green
