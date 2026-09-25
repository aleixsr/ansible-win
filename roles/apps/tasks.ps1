<#
.SYNOPSIS
    Rol apps: instal·la el catàleg d'aplicacions de config.yml.
#>
param(
    [Parameter(Mandatory)]$Config,
    [string]$RepoRoot,
    [string[]]$Groups = @(),
    [string[]]$Optional = @(),
    [switch]$AllOptional,
    [switch]$Upgrade
)

Set-ProvisionContext -Role 'apps'

# El @() no es decoratiu: amb un sol paquet, PowerShell desempaqueta l'array i
# ens deixa el hashtable pelat. Aleshores $packages.Count compta les CLAUS del
# paquet (id, name, desc...) en comptes dels paquets, i el banner menteix.
$packages = @(Select-CatalogPackages -Config $Config -Groups $Groups `
                                     -Optional $Optional -AllOptional:$AllOptional)

if (-not $packages -or $packages.Count -eq 0) {
    Write-TaskResult -Task 'catàleg' -Status 'skipped' -Message 'cap paquet seleccionat'
    return
}

# -ExpandProperty no serveix: els paquets són hashtables, no objectes.
$groupList = ($packages | ForEach-Object { $_.group } | Select-Object -Unique) -join ', '
Write-Banner "apps: $($packages.Count) paquets en $groupList"

# Sense privilegis només fem el que no en demana: scoop, les apps MSIX de la
# Store i tot el que ja estigui instal·lat. La resta s'apunta i la fa la passada
# elevada del final, amb un sol UAC. Així ningú ha de clicar quinze diàlegs.
if (-not (Test-Elevated) -and -not (Get-ProvisionCheckMode)) {
    Write-Info 'Sense privilegis: el que necessiti admin s''apunta per al bloc elevat del final.'
}

$currentGroup = $null
foreach ($pkg in $packages) {
    if ($pkg.group -ne $currentGroup) {
        $currentGroup = $pkg.group
        Set-ProvisionContext -Role "apps/$currentGroup"
    }
    Install-CatalogPackage -Package $pkg -ProviderOrder $Config.provider_order -Upgrade:$Upgrade
}

Set-ProvisionContext -Role 'apps'
Update-SessionPath

# -----------------------------------------------------------------------------
# Decisions pendents
# -----------------------------------------------------------------------------
# Les entrades que només són del Mac no s'instal·len mai aquí, i les que ja tenen
# `win_equivalent` no cal ni mencionar-les: ja sabem qui els fa la feina. Les que
# queden són forats de veritat, i val més veure'ls que no pas amagar-los entre
# cinquanta 'skipped'.
$undecided = @(Get-UndecidedPackages -Config $Config -Groups $Groups)
if ($undecided.Count -gt 0) {
    Write-Host ''
    Write-Host 'PENDENT DE DECIDIR ------------------------------------------------------------' -ForegroundColor Yellow
    Write-Host "Aquestes $($undecided.Count) apps del catàleg del Mac no tenen res assignat a Windows:" -ForegroundColor Yellow
    foreach ($pkg in $undecided) {
        Write-Host ''
        Write-Host ("  {0}  ({1})" -f $pkg.name, $pkg.group) -ForegroundColor White
        if ($pkg.note) { Write-Host ("    {0}" -f $pkg.note) -ForegroundColor DarkGray }
    }
    Write-Host ''
    Write-Host 'Digues què hi posem i afegeix-ho a config.yml, a l''entrada del paquet:' -ForegroundColor Yellow
    Write-Host '  winget: <id>            si hi ha app de Windows i la volem instal·lar' -ForegroundColor DarkGray
    Write-Host '  win_equivalent: <text>  si ja ho cobreix una altra app o el mateix Windows' -ForegroundColor DarkGray
    Write-Host '-------------------------------------------------------------------------------' -ForegroundColor Yellow
}
