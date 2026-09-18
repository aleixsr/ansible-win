# =============================================================================
#  Perfil de PowerShell - ansible_windows
# =============================================================================
#  El perfil que hi ha a Documents\ és només un carregador d'una línia que fa
#  dot-source d'aquest fitxer. Per tant, editar aquí (i fer commit) actualitza
#  el perfil de totes les màquines amb un `git pull`.
# =============================================================================

$AnsibleWindowsRoot = Split-Path -Parent $PSScriptRoot

# -----------------------------------------------------------------------------
# Fragments generats pels rols (sudo, prompt, ...)
# -----------------------------------------------------------------------------
$profileD = Join-Path $PSScriptRoot 'profile.d'
if (Test-Path -LiteralPath $profileD) {
    Get-ChildItem -LiteralPath $profileD -Filter '*.ps1' | Sort-Object Name | ForEach-Object {
        try { . $_.FullName } catch { Write-Warning "Perfil: ha fallat $($_.Name): $_" }
    }
}

# -----------------------------------------------------------------------------
# Consola
# -----------------------------------------------------------------------------
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch { }

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# -----------------------------------------------------------------------------
# PSReadLine
# -----------------------------------------------------------------------------
if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue

    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -BellStyle None

    # La predicció en línia només existeix a PSReadLine 2.2+.
    if ((Get-Module PSReadLine).Version -ge [version]'2.2.0') {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
    }

    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit
}

if (Get-Module -ListAvailable Terminal-Icons) {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
}
if (Get-Module -ListAvailable posh-git) {
    Import-Module posh-git -ErrorAction SilentlyContinue
}

# -----------------------------------------------------------------------------
# Àlies a l'estil Unix
# -----------------------------------------------------------------------------
# A PowerShell els ÀLIES tenen precedència sobre les FUNCIONS. Noms com ls, cat,
# gc (Get-Content), gp (Get-ItemProperty) o gl (Get-Location) ja són àlies de
# sèrie, i si no els traiem, les funcions d'aquí sota no s'arribarien a cridar.
foreach ($conflict in 'ls', 'cat', 'g', 'gs', 'ga', 'gc', 'gp', 'gl', 'gd', 'gb') {
    if (Test-Path "Alias:$conflict") {
        Remove-Item "Alias:$conflict" -Force -ErrorAction SilentlyContinue
    }
}

if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls { eza --icons --group-directories-first @args }
    function ll { eza -l --icons --group-directories-first --git @args }
    function la { eza -la --icons --group-directories-first --git @args }
    function lt { eza --tree --level=2 --icons @args }
} else {
    function ll { Get-ChildItem @args | Format-Table -AutoSize }
    function la { Get-ChildItem -Force @args | Format-Table -AutoSize }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat { bat --style=plain --paging=never @args }
    $env:BAT_THEME = 'ansi'
}

function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function which { param([string]$Name) (Get-Command $Name -ErrorAction SilentlyContinue).Source }
function touch { param([string]$Path) if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType File -Path $Path | Out-Null } }
function mkcd { param([string]$Path) New-Item -ItemType Directory -Path $Path -Force | Out-Null; Set-Location $Path }
function reload { . $PROFILE }

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
function g { git @args }
function gs { git status --short --branch }
function ga { git add @args }
function gc { git commit @args }
function gp { git push @args }
function gl { git log --oneline --graph --decorate -20 @args }
function gd { git diff @args }
function gco { git checkout @args }
function gb { git branch @args }
function lg { lazygit @args }

# -----------------------------------------------------------------------------
# ansible_windows
# -----------------------------------------------------------------------------
function prov {
    <#
    .SYNOPSIS
        Torna a provisionar la màquina des de qualsevol directori.
    #>
    & (Join-Path $AnsibleWindowsRoot 'run.ps1') @args
}

function prov-edit {
    <#
    .SYNOPSIS
        Obre el catàleg de paquets a l'editor.
    #>
    $catalog = Join-Path $AnsibleWindowsRoot 'group_vars\all.yml'
    if (Get-Command code -ErrorAction SilentlyContinue) { code $catalog }
    else { notepad $catalog }
}

# -----------------------------------------------------------------------------
# zoxide (cd intel·ligent)
# -----------------------------------------------------------------------------
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}

# -----------------------------------------------------------------------------
# fzf
# -----------------------------------------------------------------------------
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border --info=inline'
    if (Get-Command fd -ErrorAction SilentlyContinue) {
        $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
    }
}
