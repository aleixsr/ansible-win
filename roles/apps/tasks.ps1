<#
.SYNOPSIS
    Rol apps: instal·la el catàleg d'aplicacions de config.yml.
#>
param(
    [Parameter(Mandatory)]$Config,
    [string]$RepoRoot,
    [string[]]$Groups = @(),
    [switch]$Upgrade
)

Set-ProvisionContext -Role 'apps'

$packages = Select-CatalogPackages -Config $Config -Groups $Groups

if (-not $packages -or $packages.Count -eq 0) {
    Write-TaskResult -Task 'catàleg' -Status 'skipped' -Message 'cap paquet seleccionat'
    return
}

# -ExpandProperty no serveix: els paquets són hashtables, no objectes.
$groupList = ($packages | ForEach-Object { $_.group } | Select-Object -Unique) -join ', '
Write-Banner "apps: $($packages.Count) paquets en $groupList"

# Les instal·lacions a escala de màquina demanen UAC per cada paquet. Si ja som
# admin, això no passa; si no, avisem una sola vegada en comptes de per paquet.
if (-not (Test-Elevated) -and -not (Get-ProvisionCheckMode)) {
    Write-Info 'No som administrador: winget/choco demanaran UAC. Millor: sudo .\run.ps1'
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
