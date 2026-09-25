#Requires -Version 5.1
<#
.SYNOPSIS
    Regenera docs/APPS.md i les seccions generades del README a partir de config.yml.
.DESCRIPTION
    Ni el catàleg d'aplicacions del README ni la taula de paritat amb ansible-mac
    s'escriuen a mà: surten de `config.yml`, que és l'única font. Si afegeixes un
    paquet o li canvies la descripció, executa aquest script i commita el resultat.

    Al README hi ha dos blocs delimitats per marques HTML. Tot el que hi ha entre
    les marques es reescriu; la resta del fitxer no es toca.

      <!-- INDEX:INICI -->  ...  <!-- INDEX:FI -->   index de seccions
      <!-- APPS:INICI -->   ...  <!-- APPS:FI -->    catàleg d'aplicacions
.EXAMPLE
    .\scripts\Export-AppsTable.ps1
.EXAMPLE
    .\scripts\Export-AppsTable.ps1 -Check
    No escriu res; diu si els fitxers estarien al dia. Per a un hook o CI.
#>
[CmdletBinding()]
param(
    [string]$OutFile,
    [string]$ReadmeFile,
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $OutFile) { $OutFile = Join-Path $RepoRoot 'docs\APPS.md' }
if (-not $ReadmeFile) { $ReadmeFile = Join-Path $RepoRoot 'README.md' }

Import-Module powershell-yaml -ErrorAction Stop
$config = ConvertFrom-Yaml (Get-Content (Join-Path $RepoRoot 'config.yml') -Raw -Encoding UTF8)

$defaultGroups = @($config.default_groups)

# Noms llegibles dels grups. Si un grup no hi és, es fa servir la clau tal qual.
$GroupTitles = @{
    development         = 'Desenvolupament'
    clouddevops         = 'Núvol i DevOps'
    networking          = 'Xarxa (línia d''ordres)'
    networkingvpn       = 'Xarxa i VPN'
    remoteaccess        = 'Accés remot'
    systemutilities     = 'Utilitats de sistema'
    browsers            = 'Navegadors'
    terminal            = 'Terminals'
    communication       = 'Comunicació'
    productivity        = 'Productivitat'
    filemanagementcloud = 'Fitxers i núvol'
    microsoftsuite      = 'Entorn Microsoft'
    media               = 'Àudio i vídeo'
    documents           = 'Documents'
    hardware            = 'Maquinari'
    store               = 'Microsoft Store'
    fonts               = 'Tipografies'
}

$WIN_KEYS = @('winget', 'choco', 'scoop', 'url')

function Get-GroupTitle {
    param([string]$Key)
    if ($GroupTitles.ContainsKey($Key)) { return $GroupTitles[$Key] }
    return $Key
}

function Test-HasProvider {
    param($Package)
    foreach ($k in $WIN_KEYS) {
        if ($Package.ContainsKey($k) -and $Package[$k]) { return $true }
    }
    return $false
}

<#
.SYNOPSIS
    D'on surt el paquet, en text curt per a la taula.
#>
function Get-SourceCell {
    param($Package)
    if ($Package.source -eq 'msstore') { return 'Store' }
    if ($Package.url) { return 'descàrrega directa' }
    foreach ($k in @('winget', 'choco', 'scoop')) {
        if ($Package.ContainsKey($k) -and $Package[$k]) { return $k }
    }
    return '—'
}

function Escape-Cell {
    param([string]$Text)
    if (-not $Text) { return '' }
    return $Text.Replace('|', '\|')
}

# =============================================================================
# Catàleg per al README
# =============================================================================
$appLines = New-Object System.Collections.ArrayList
function Add-App { param([string]$Text = '') [void]$appLines.Add($Text) }

$ordre = @($config.packages.Keys | Sort-Object { if ($defaultGroups -contains $_) { $defaultGroups.IndexOf($_) } else { 999 } })

$installables = 0
$opcionals = 0
$senseEquivalent = New-Object System.Collections.ArrayList

foreach ($group in $ordre) {
    $entries = @($config.packages[$group] | Where-Object { $_ })
    $ambProveidor = @($entries | Where-Object { Test-HasProvider $_ })
    if ($ambProveidor.Count -eq 0) { continue }
    $installables += $ambProveidor.Count
    $opcionals += @($ambProveidor | Where-Object { $_.optional }).Count

    foreach ($pkg in $entries) {
        if (-not (Test-HasProvider $pkg)) { [void]$senseEquivalent.Add($pkg) }
    }

    $suffix = ''
    if ($defaultGroups -notcontains $group) { $suffix = ' _(no és als grups per defecte)_' }

    Add-App ''
    Add-App ("### {0}{1}" -f (Get-GroupTitle $group), $suffix)
    Add-App ''
    Add-App ("Grup ``{0}``. {1} aplicacions." -f $group, $ambProveidor.Count)
    Add-App ''
    Add-App '| App | Per a què serveix | D''on surt | |'
    Add-App '| --- | --- | --- | --- |'
    foreach ($pkg in $ambProveidor) {
        $marca = ''
        if ($pkg.optional) { $marca = 'opcional' }
        Add-App ("| **{0}** | {1} | {2} | {3} |" -f `
            (Escape-Cell $pkg.name), (Escape-Cell $pkg.desc), (Get-SourceCell $pkg), $marca)
    }
}

# Les entrades que només són del Mac: no s'instal·len ni surten al run, però
# documenten qui els fa la feina aquí.
if ($senseEquivalent.Count -gt 0) {
    Add-App ''
    Add-App '### Del catàleg del Mac, no s''instal·len'
    Add-App ''
    Add-App 'Aquestes entrades vénen d''`ansible-mac` i a Windows no tenen res a fer. No'
    Add-App 'surten quan executes `run.ps1`; són aquí per no perdre la traça de què les'
    Add-App 'substitueix.'
    Add-App ''
    Add-App '| Al Mac | Què ho cobreix a Windows |'
    Add-App '| --- | --- |'
    foreach ($pkg in ($senseEquivalent | Sort-Object { "$($_.name)" })) {
        $equiv = $pkg.win_equivalent
        if (-not $equiv) { $equiv = '**pendent de decidir**' }
        Add-App ("| {0} | {1} — `{2}` |" -f `
            (Escape-Cell $pkg.name), (Escape-Cell $pkg.desc), $equiv)
    }
}

Add-App ''
Add-App ("**{0} aplicacions** en {1} categories, de les quals **{2} són opcionals**: no" -f `
    $installables, $ordre.Count, $opcionals)
Add-App ("s'instal·len si no les tries en llançar el run. {0} entrades més són del" -f `
    $senseEquivalent.Count)
Add-App 'catàleg del Mac i no apliquen aquí.'

# =============================================================================
# docs/APPS.md: paritat amb ansible-mac
# =============================================================================
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
foreach ($group in @($config.packages.Keys | Sort-Object)) {
    $entries = @($config.packages[$group] | Where-Object { $_ })
    if ($entries.Count -eq 0) { continue }
    $total += $entries.Count

    $suffix = ' _(opcional)_'
    if ($defaultGroups -contains $group) { $suffix = '' }

    Add-Line ''
    Add-Line "## ``$group``$suffix"
    Add-Line ''
    Add-Line '| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |'
    Add-Line '| --- | --- | --- | --- | --- | --- |'

    foreach ($pkg in ($entries | Sort-Object { "$($_.mac)" })) {
        $cell = {
            param($v)
            if ($v) { return "``$v``" }
            return '—'
        }

        $mac = $pkg.mac
        if ($mac) { $mac = "``$mac``" } else { $mac = '—' }

        if (Test-HasProvider $pkg) {
            $windows = $pkg.name
        } else {
            $equiv = $pkg.win_equivalent
            if (-not $equiv) { $equiv = 'PENDENT DE DECIDIR' }
            $windows = "_no s'instal·la_ — ``$equiv``"
        }

        Add-Line ("| {0} | {1} | {2} | {3} | {4} | {5} |" -f `
            $mac,
            $windows,
            (Escape-Cell $pkg.desc),
            (& $cell $pkg.winget),
            (& $cell $pkg.choco),
            (& $cell $pkg.scoop))
    }
}

Add-Line ''
Add-Line '---'
Add-Line ''
Add-Line "**$total entrades** en $(@($config.packages.Keys).Count) categories, de les quals"
Add-Line "**$installables s'instal·len** i **$($senseEquivalent.Count) són només del Mac**."
Add-Line ''
Add-Line 'Les que són només del Mac porten `win_equivalent`, que diu qui els fa la feina'
Add-Line 'aquí. No surten al `run.ps1`: `Select-CatalogPackages` les deixa fora perquè no'
Add-Line 'hi ha res a instal·lar. Si alguna es queda sense `win_equivalent`, el rol `apps`'
Add-Line 'la reclama al final del run com a decisió pendent.'
Add-Line ''

# =============================================================================
# Índex del README
# =============================================================================
$readme = Get-Content -LiteralPath $ReadmeFile -Raw -Encoding UTF8

<#
.SYNOPSIS
    Ancora de GitHub per a un títol de Markdown.
.DESCRIPTION
    Minúscules, fora tot el que no sigui lletra/xifra/espai/guio, i els espais a
    guions. Els accents i el punt volat es conserven, que és el que fa GitHub.
#>
function Get-Anchor {
    param([string]$Heading)
    $a = $Heading.ToLowerInvariant()
    $a = $a -replace '[`*_\[\]()<>.,:;!?''"/\\+#&]', ''
    $a = $a.Trim() -replace '\s+', '-'
    return $a
}

$indexLines = New-Object System.Collections.ArrayList
[void]$indexLines.Add('## Índex')
[void]$indexLines.Add('')

# El README amb el catàleg nou dins: així l'índex ja inclou les seccions generades.
$readmeAmbApps = $readme
$appBlock = ($appLines -join "`n")
if ($readmeAmbApps -match '(?s)<!-- APPS:INICI -->.*?<!-- APPS:FI -->') {
    $readmeAmbApps = [regex]::Replace($readmeAmbApps,
        '(?s)<!-- APPS:INICI -->.*?<!-- APPS:FI -->',
        { param($m) "<!-- APPS:INICI -->`n" + $appBlock + "`n<!-- APPS:FI -->" })
}

foreach ($line in ($readmeAmbApps -split "`r?`n")) {
    if ($line -match '^(#{2,3})\s+(.*?)\s*$') {
        $nivell = $Matches[1].Length
        $titol = $Matches[2]
        if ($titol -eq 'Índex') { continue }
        $sagnat = '  ' * ($nivell - 2)
        $net = $titol -replace '[`*]', ''
        [void]$indexLines.Add("$sagnat- [$net](#$(Get-Anchor $titol))")
    }
}

# =============================================================================
# Escriure
# =============================================================================
function Set-Block {
    param([string]$Text, [string]$Marca, [string]$Contingut)
    $patro = "(?s)<!-- $Marca`:INICI -->.*?<!-- $Marca`:FI -->"
    if ($Text -notmatch $patro) {
        throw "No trobo les marques <!-- $Marca`:INICI --> / <!-- $Marca`:FI --> al README. Afegeix-les on vulguis el bloc."
    }
    return [regex]::Replace($Text, $patro,
        { param($m) "<!-- $Marca`:INICI -->`n" + $Contingut + "`n<!-- $Marca`:FI -->" })
}

$readmeNou = Set-Block -Text $readme -Marca 'APPS' -Contingut $appBlock
$readmeNou = Set-Block -Text $readmeNou -Marca 'INDEX' -Contingut (($indexLines -join "`n"))

$appsNou = ($lines -join "`n")
$appsVell = ''
if (Test-Path -LiteralPath $OutFile) {
    $appsVell = Get-Content -LiteralPath $OutFile -Raw -Encoding UTF8
}

<#
.SYNOPSIS
    Normalitza per comparar: mateixos finals de linia i sense la cua de salts.
.DESCRIPTION
    Set-Content sempre acaba el fitxer amb un salt de linia, i Get-Content -Raw
    el torna. Sense normalitzar, el fitxer semblaria desactualitzat sempre i el
    -Check no serviria de res.
#>
function Get-Normalized {
    param([AllowNull()][string]$Text)
    if (-not $Text) { return '' }
    return $Text.Replace("`r`n", "`n").TrimEnd("`n")
}

$calCanviar = ((Get-Normalized $appsVell) -ne (Get-Normalized $appsNou)) -or
              ((Get-Normalized $readme) -ne (Get-Normalized $readmeNou))

if ($Check) {
    if ($calCanviar) {
        Write-Host 'Els documents NO estan al dia. Executa scripts\Export-AppsTable.ps1' -ForegroundColor Red
        exit 1
    }
    Write-Host 'Documents al dia.' -ForegroundColor Green
    exit 0
}

$dir = Split-Path -Parent $OutFile
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
# -NoNewline i un unic salt final posat a ma: Set-Content, sense aixo, afegeix
# un salt cada vegada i el fitxer creix una linia a cada execucio.
Set-Content -LiteralPath $OutFile -Value ((Get-Normalized $appsNou) + "`n") -Encoding UTF8 -NoNewline
Set-Content -LiteralPath $ReadmeFile -Value ((Get-Normalized $readmeNou) + "`n") -Encoding UTF8 -NoNewline

Write-Host "Escrit: $OutFile" -ForegroundColor Green
Write-Host "Escrit: $ReadmeFile  (index i cataleg)" -ForegroundColor Green
Write-Host "$installables aplicacions, $($senseEquivalent.Count) entrades nomes del Mac" -ForegroundColor DarkGray
