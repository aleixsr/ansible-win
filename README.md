# ansible-win

Provisionament personal d'una màquina Windows: paquets de winget/Chocolatey/Scoop,
apps de la Microsoft Store, aplicacions d'inici, configuració de la shell
(Starship + PowerShell), ajustos del sistema i `sudo` de debò.

És el germà de [`ansible-mac`](https://github.com/aleixsr/ansible-mac): mateix
`config.yml`, mateixes categories i, app per app, **les mateixes aplicacions**
sempre que existeixin per a Windows.

> **Nota sobre Ansible:** Ansible no pot córrer nativament a Windows — el node de
> control ha de ser Linux o macOS. Aquest repo manté l'*estructura* d'Ansible
> (`config.yml`, rols, sortida `ok`/`changed`/`skipped`, `PLAY RECAP`) però el
> motor és PowerShell. Vegeu [Equivalències](#equivalències-amb-ansible-mac).

## Què fa

Executar `.\run.ps1` fa, en aquest ordre:

1. **Prepara els gestors de paquets** (`roles/core`)
   - Comprova winget, instal·la Chocolatey si falta, i Scoop només si algun
     paquet el demana explícitament
   - Instal·la **gsudo** i fa que `sudo` (sense la `g`) hi apunti, tant a
     PowerShell com a `cmd.exe`. Vegeu [`sudo` sense la `g`](#sudo-sense-la-g)
2. **Instal·la les aplicacions** (`roles/apps` + `config.yml`)
   - Eines de línia d'ordres i apps gràfiques, per categories: development,
     cloud/DevOps, networking, system utilities, browsers, terminal,
     communication, productivity, networking/VPN, remote access, file
     management/cloud, Microsoft suite, media, documents, hardware
   - Apps de la **Microsoft Store** via `winget --source msstore` (l'equivalent
     de `mas` al Mac)
   - Nerd Fonts via Chocolatey
3. **Configura la shell** (`roles/shell`)
   - Instal·la Starship i els mòduls de PowerShell (`PSReadLine`,
     `Terminal-Icons`, `posh-git`, `powershell-yaml`)
   - Desplega `files/starship.toml`, **el mateix fitxer que a `ansible-mac`**
   - Instal·la el perfil de PowerShell: el que queda a `Documents\` és un
     carregador d'una línia, així que el contingut real viu al repo i un
     `git pull` ja actualitza el perfil
   - Aplica la configuració de Windows Terminal (fent còpia de la teva)
4. **Configura l'entorn de desenvolupament** (`roles/dev`)
   - `git config --global` (àlies, `pull.rebase`, `delta` com a pager si hi és)
   - Genera la clau SSH `ed25519` si no existeix
   - Paquets globals de npm, eines de Python amb `uv`, extensions de VS Code
5. **Instal·la els connectors de Tabby** (`roles/tabby`) desplegant
   [`files/tabby/package.json`](files/tabby/package.json) a
   `%APPDATA%\tabby\plugins` i executant-hi `npm install`. És el mateix fitxer
   que al Mac, així que tots dos equips acaben amb els mateixos connectors.
6. **Aplica els ajustos del sistema** (`roles/system`) — l'equivalent del rol
   `desktop` d'`ansible-mac`. Vegeu [Ajustos que aplica](#ajustos-que-aplica)
7. **Configura les aplicacions d'inici** (`roles/startup`) — el que al Mac són
   Login Items, aquí són valors a
   `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
8. **Enllaça els dotfiles** (`roles/dotfiles`) que declaris a `config.yml`

Tot és **idempotent**: executar-ho dues vegades seguides no canvia res la segona.

## Requisits

- Windows 10 21H2 o superior (provat a Windows 11)
- Windows PowerShell 5.1 (el que ve de sèrie) o PowerShell 7+
- [winget](https://aka.ms/getwinget) (App Installer). Si no el tens, instal·la
  "Instal·lador d'aplicacions" des de la Microsoft Store

La resta — Chocolatey, gsudo, Git i el mòdul `powershell-yaml` — els posa
`bootstrap.ps1`.

## Instal·lació

D'una màquina acabada d'instal·lar:

```powershell
irm https://raw.githubusercontent.com/aleixsr/ansible-win/main/bootstrap.ps1 | iex
cd ~\ansible-win
.\run.ps1
```

O, si ja tens el repo clonat:

```powershell
.\bootstrap.ps1        # prepara la màquina
.\run.ps1 -Check       # simulació: mira què faria
.\run.ps1              # provisiona de debò
```

`run.ps1` es reobre sol amb privilegis via `gsudo` quan li calen.

## Ús

```powershell
.\run.ps1                                       # tot
.\run.ps1 -Check                                # simulació (com --check)
.\run.ps1 -Upgrade                              # actualitza el que ja hi ha
.\run.ps1 -ListPackages                         # ensenya el catàleg sencer
.\run.ps1 -NoElevate                            # sense demanar privilegis
```

Executar només una part (l'equivalent dels `--tags` d'`ansible-mac`):

```powershell
# Només instal·lar aplicacions
.\run.ps1 -Roles apps

# Només algunes categories
.\run.ps1 -Roles apps -Groups browsers,terminal,documents

# Només la shell (Starship + perfil)
.\run.ps1 -Roles shell

# Només els ajustos del sistema
.\run.ps1 -Roles system

# Només les aplicacions d'inici
.\run.ps1 -Roles startup

# Només els connectors de Tabby
.\run.ps1 -Roles tabby
```

## Configuració

Tot el que instal·la i configura el repo és a [`config.yml`](config.yml). Edita
aquest fitxer per afegir o treure software sense tocar cap `.ps1`:

```yaml
packages:
  browsers:
    - id: brave
      name: Brave
      winget: Brave.Brave
      choco: brave
      mac: brave-browser        # d'on ve a ansible-mac

startup_apps:
  - name: ShareX
    path: $env:ProgramFiles\ShareX\ShareX.exe
    mac: Shottr
```

Per personalitzar una màquina concreta sense tocar el repo, copia
[`config.local.example.yml`](config.local.example.yml) a `config.local.yml`
(ignorat per git): es fusiona **recursivament** sobre `config.yml`.

Per trobar l'identificador exacte d'un paquet nou:

```powershell
winget search <nom>
choco search <nom>
```

## Software que instal·la

### Línia d'ordres i desenvolupament

| Categoria | Paquets |
|---|---|
| Development | GitHub CLI, Git, Node.js LTS, Python 3.14, Apache Directory Studio, GitHub Copilot CLI, DBeaver Community, draw.io, GitHub Desktop, SoapUI, Notepad++, Sublime Text, Visual Studio Code, Visual Studio Code Insiders |
| Cloud / DevOps | Azure CLI, OCI CLI |
| Networking | iperf3, RustScan, WinMTR, Nmap, Speedtest CLI, mailsend-go, tcping, wget |
| System utilities | PowerShell 7, balenaEtcher, WizTree, PowerToys, ScreenToGif, Novabench, XCA |
| Shell (via `roles/shell`) | Starship, PSReadLine, Terminal-Icons, posh-git, powershell-yaml |

### Aplicacions gràfiques

| Categoria | Apps |
|---|---|
| Browsers | Brave, Chromium, Firefox, Google Chrome, Microsoft Edge |
| Terminal | Windows Terminal, Tabby, Wave Terminal |
| Communication | Mailspring, Microsoft Teams, Telegram, WhatsApp |
| Productivity | Claude Desktop, 7-Zip, PeaZip, Obsidian, Calcator, Charmy (hot corners), ShareX, HWiNFO |
| Networking & VPN | SwitchHosts, Tailscale, OpenVPN Connect |
| Remote access | Royal TS, RustDesk |
| File management & cloud | Box Drive, LocalSend, Synology Drive Client |
| Microsoft suite | Azure Storage Explorer |
| Media | HandBrake, VLC, mpv, FFmpeg, yt-dlp, Open TV |

> **yt-dlp arrossega dues dependències.** El seu paquet de winget declara
> `DenoLand.Deno` i `yt-dlp.FFmpeg`, i winget les instal·la soles sense
> preguntar. Deno no és sobrer: yt-dlp el fa servir per resoldre els reptes de
> JavaScript de YouTube. Si no en vols cap, el que has de treure del catàleg és
> **yt-dlp**, no Deno.
| Documents | Adobe Acrobat Reader, Mark Text, Modern CSV, ONLYOFFICE, PDF24 Creator, Xournal++ |
| Hardware | Logi Options+ |
| Fonts (via `roles/shell`) | Meslo LG Nerd Font |

### Microsoft Store (via `winget --source msstore`)

| App | Id |
|---|---|
| Microsoft To Do | `9NBLGGH5R558` |
| Azure VPN Client | `9NP355QT2SQB` |
| WireGuard | `WireGuard.WireGuard` |
| Charmy: Hot Corners | `9P5PK6TVQXF7` |

> **Les apps MSIX de la Store no es poden instal·lar des d'un procés elevat.**
> Com que `run.ps1` s'auto-eleva, les instal·la **abans** d'elevar-se, mentre
> encara és al context d'usuari. Si n'executes una elevat, la tasca surt com a
> `skipped` amb la comanda a fer:
> `.
un.ps1 -Roles apps -Groups store -NoElevate`

### Aplicacions d'inici

ShareX, HWiNFO, PowerToys, OneDrive.

Només s'afegeixen si l'executable existeix: si encara no has instal·lat l'app, la
tasca surt com a `skipped` en comptes de deixar una entrada morta al registre.

Si ja hi ha una entrada que apunta al **mateix executable**, no s'hi toca. Moltes
apps s'hi posen soles amb arguments propis — OneDrive hi posa `/background` —
i reescriure-la els els prendria. El que es vol és que l'app arrenqui, no
imposar-hi una línia d'ordres. Per forçar-ne una, hi ha `args`:

```yaml
startup_apps:
  - name: OneDrive
    path: $env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe
    args: ["/background"]
```

### Aplicacions que NO volem a l'inici

Molts instal·ladors s'hi posen sols. `startup_disable` els treu:

```yaml
startup_disable:
  - PDF24          # valor de la clau Run
  - RustDesk Tray  # drecera de la carpeta d'Inici, sense el .lnk
  - Warp           # entrada morta d'una app ja desinstal·lada
```

El rol les busca a les dues claus `Run` (usuari i màquina) i a les dues carpetes
d'Inici, i **no esborra res**: escriu a `StartupApproved`, que és el mateix
mecanisme que la pestanya «Inici» de l'Administrador de tasques. Per tant el
canvi es pot desfer des d'allà, i l'instal·lador no el tomba a la propera
actualització (cosa que sí que passaria si li esborréssim l'entrada).

Això només toca la part visible: una app amb **servei** propi (RustDesk, PDF24)
el segueix tenint en marxa. Es fa a posta — el servei de RustDesk és el que
permet connectar-s'hi des de fora, i el de PDF24 és la impressora virtual.

### Apps del Mac sense equivalent a Windows

No desapareixen del catàleg: hi queden amb un `note` que diu per què i quin és el
substitut, i surten com a `skipped` quan executes `run.ps1`.

| Al Mac | Per què no hi és |
|---|---|
| `mas` | No cal: winget ja parla amb la Microsoft Store |
| `bluesnooze` | Específic de macOS. A Windows es gestiona des de l'Administrador de dispositius |
| `resolutionator` | Canvi de resolució natiu (Win+P) |
| `wins` | Alt+Tab natiu / PowerToys |
| `shortwave` | Només macOS i web |
| `zoho-mail` | Sense client d'escriptori; navegador o Outlook |
| `alt-tab` | Porta a macOS l'Alt+Tab de Windows. Aquí ja hi és |
| `caffeine` | PowerToys Awake |
| `dockdoor` | Previsualització de finestres, nativa a Windows |
| `maccy` | Historial de porta-retalls natiu: Win+V |
| `rectangle` | PowerToys FancyZones + Win+fletxes |
| `windows-app` | És el client RDP de Microsoft *per a macOS*. Aquí ja hi ha `mstsc.exe` |
| `microsoft-auto-update` | Click-to-Run / Windows Update |
| `macdown` | El cobreix Mark Text |
| `Ping Status` | Alternativa: PingInfoView o `Test-Connection` |
| `MuteKey` | PowerToys Video Conference Mute (Win+Maj+A) |

### Descartats a propòsit

Aquests quatre **existeixen** a Windows, però el substitut no valia la pena i
s'han tret del catàleg. No s'instal·len i no hi ha cap entrada a `config.yml`:

| Al Mac | El substitut descartat | Per què |
|---|---|---|
| `htop` | btop4win | El port a Windows està abandonat. Administrador de tasques o Process Explorer |
| `betterdisplay` | Twinkle Tray | Només fa brillantor i contrast per DDC/CI; no cobreix resolucions ni escalat |
| `macfuse` | WinFsp | No cal si no muntes sistemes de fitxers en espai d'usuari. Instal·la'l a mà si algun dia et fa falta |
| `superduper` | Veeam Agent | Backup empresarial, no clonatge d'arrencada simple |

Aquests dos **sí que s'instal·len a `ansible-mac`** i aquí no. És l'única
divergència volguda entre els dos repos:

| Al Mac | Per què no a Windows |
|---|---|
| `notion` | No es vol en aquesta màquina |
| `warp` | No es vol en aquesta màquina; el terminal aquí és Windows Terminal, Tabby i Wave |

I **Microsoft 365** hi és al Mac però aquí no s'instal·la: el manifest
`Microsoft.Office` de winget apunta a `officecdn.microsoft.com`, un fitxer que
Microsoft actualitza sense pujar el hash del manifest, i winget no deixa
ignorar-ho quan corre com a administrador. Instal·la'l des de `portal.office.com`.

La taula completa, paquet per paquet i amb els identificadors de cada gestor, és
a [docs/APPS.md](docs/APPS.md). Es regenera des de `config.yml` amb:

```powershell
.\scripts\Export-AppsTable.ps1
```

## Paquets que no són a cap gestor

Dos del catàleg no existeixen ni a winget, ni a Chocolatey, ni a Scoop:
**Calcator** i **Open TV**. Per a aquests hi ha el proveïdor `url`, que baixa
l'instal·lador i l'executa.

```yaml
# URL fixa: reproduïble, però s'ha de pujar la versió a mà
- id: numi
  name: Calcator
  provider: url
  url:
    source: https://calcator.app/downloads/Calcator_0.2.4_x64-setup.exe
    version: "0.2.4"
    sha256: "F3556BF2…"      # opcional; si hi és, es verifica
    args: ["/S"]             # per defecte /S (silenci d'NSIS)
    arp: "Calcator*"         # com es detecta que ja hi és

# Release de GitHub: es resol l'última, amb un patró per a l'asset
- id: opentv
  name: Open TV
  provider: url
  url:
    github: Fredolx/open-tv
    asset: "*_x64_en-US.msi"
    arp: "Fred TV*"
```

Quan un instal·lador acaba amb un codi d'error però `arp:` el troba, es dona per
bo: hi ha instal·ladors que menteixen sobre el seu codi de sortida.

El mode `github` existeix perquè els noms dels fitxers es podreixen: Open TV ja
va passar de `open-tv` a `Fred.TV` enmig de les releases, i una URL fixa hauria
petat.

**Aquest proveïdor és el punt feble del repo, i val més dir-ho.** Sense gestor de
paquets no hi ha a qui preguntar si una cosa està instal·lada, així que la
detecció va per `arp:`, el nom a «Programes i característiques» — que el
fabricant pot canviar quan vulgui. `provider: url` només per a coses que
realment no siguin a cap gestor.

## Ajustos que aplica

Tots configurables a la secció `system:` de `config.yml`. Els que toquen `HKLM`
necessiten administrador; sense privilegis surten com a `skipped`, no fallen.

### Explorador de fitxers

| Ajust | Per defecte |
|---|---|
| Mostrar les extensions de fitxer | sí |
| Mostrar els fitxers ocults | sí |
| Obrir a "Aquest equip" en comptes d'"Accés ràpid" | sí |
| Ruta completa a la barra de títol | sí |
| Expandir l'arbre fins a la carpeta oberta | sí |
| Desactivar els fitxers recents | no |

### Barra de tasques

| Ajust | Per defecte |
|---|---|
| Icones alineades a l'esquerra | sí |
| Amagar la caixa de cerca | sí |
| Amagar el botó de vista de tasques | sí |
| Amagar els widgets | sí |
| Amagar el botó de xat | sí |

### Aparença

| Ajust | Per defecte |
|---|---|
| Tema fosc (aplicacions i sistema) | sí |
| Efectes de transparència | sí |
| Color d'accent a la barra de tasques | no |

### Privadesa

| Ajust | Per defecte |
|---|---|
| Desactivar l'identificador de publicitat | sí |
| Desactivar la cerca web i els suggeriments de Bing al menú Inici | sí |
| Desactivar les experiències personalitzades i el contingut suggerit | sí |

### Entrada (ratolí i touchpad)

Equival al "Disable natural scrolling" del rol `desktop` d'`ansible-mac`
(`com.apple.swipescrolldirection = false`).

| Ajust | Per defecte |
|---|---|
| `natural_scrolling` | `false` — scroll clàssic: gest o roda avall, la pàgina baixa |

A macOS és una sola preferència. A Windows en calen dues, i **el `0` no vol dir
el mateix a totes dues**:

| Dispositiu | Clau | `0` | `1` |
|---|---|---|---|
| Touchpad de precisió | `HKCU\...\PrecisionTouchPad\ScrollDirection` | natural | clàssic |
| Ratolí (una per cada HID) | `HKLM\SYSTEM\CurrentControlSet\Enum\HID\...\Device Parameters\FlipFlopWheel` | clàssic | natural |

El canvi al touchpad és immediat. **El del ratolí no s'aplica fins que
desconnectis i tornis a connectar el dispositiu, o reiniciïs.** Si et queda al
revés, canvia el booleà i torna a executar `.\run.ps1 -Roles system`.

### Energia i desenvolupament

| Ajust | Per defecte |
|---|---|
| Pla d'energia | `high` (alt rendiment) |
| Temps per apagar la pantalla | `-1`, no s'hi toca |
| Temps per suspendre | `0`, mai |
| Mode desenvolupador | activat |
| Rutes llargues (>260 caràcters) | activades |
| Servidor OpenSSH | desactivat |

Alguns canvis de l'Explorador no es veuen fins que el reinicies:

```powershell
Stop-Process -Name explorer -Force
```

## `sudo` sense la `g`

Windows 11 porta el seu propi `C:\Windows\System32\sudo.exe`. Com que el `PATH`
de màquina s'avalua abans que el d'usuari, posar `gsudo` al `PATH` no n'hi ha
prou: el de Microsoft sempre guanyaria.

El rol `core` ho resol per dues bandes:

1. **A PowerShell** — genera `files/profile.d/10-sudo.ps1` amb una *funció*
   `sudo`. A PowerShell les funcions tenen precedència sobre els executables del
   `PATH`, així que `sudo` és `gsudo` i punt. També deixa `s` com a abreviatura
2. **A `cmd.exe` i companyia** — genera `bin\sudo.cmd`, que reenvia a `gsudo`, i
   posa `bin\` al davant del `PATH` d'usuari

```yaml
sudo:
  provider: gsudo        # 'native' deixa el sudo de Microsoft
  powershell_alias: true
  cmd_shim: true
  cache_seconds: 0       # >0 = no repeteix UAC durant N segons
```

```powershell
sudo choco upgrade all -y
sudo notepad C:\Windows\System32\drivers\etc\hosts
sudo !!                     # repeteix l'última comanda, elevada
```

## Equivalències amb `ansible-mac`

| `ansible-mac` | `ansible-win` |
|---|---|
| `config.yml` | `config.yml` |
| `main.yml` (playbook) | `run.ps1` |
| `roles/*/tasks/main.yml` | `roles/*/tasks.ps1` |
| `ansible-playbook main.yml` | `.\run.ps1` |
| `--check` | `-Check` |
| `--tags shell` | `-Roles shell` |
| `--tags casks,browsers` | `-Roles apps -Groups browsers` |
| `homebrew` / `homebrew_cask` | winget / Chocolatey / Scoop |
| `mas` (App Store) | `winget --source msstore` |
| `osx_defaults` | registre de Windows (`HKCU` / `HKLM`) |
| Login Items (`osascript`) | `HKCU\...\CurrentVersion\Run` |
| `~/.zshrc` | perfil de PowerShell |
| `roles/desktop` | `roles/system` |
| `roles/karabiner` | sense rèplica: s'instal·la PowerToys |

Les categories són les mateixes, fusionant els parells `packages<x>` +
`casks<x>` perquè a Windows no existeix la distinció fórmula/cask de Homebrew:

`packagesdevelopment` + `casksdevelopment` → `development`,
`packagessystemutilities` + `caskssystemutilities` → `systemutilities`,
`casksbrowsers` → `browsers`, `mas_apps` → `store`, i així amb la resta.

El rol `karabiner` del Mac no té rèplica a propòsit: les seves modificacions
(Home/End, F12 com a Print Screen, dreceres de Finder, intercanvi de la tecla
ISO…) són precisament per fer que el Mac es comporti com un Windows. Aquí
s'instal·la **PowerToys**, que és on viu el Keyboard Manager si algun dia cal
remapejar res.

## Estructura del projecte

```
bootstrap.ps1                    D'un Windows verge a poder executar run.ps1
run.ps1                          Punt d'entrada: el "ansible-playbook"
config.yml                       Catàleg centralitzat: apps + tota la config
config.local.example.yml         Plantilla d'overrides per màquina
roles/
  core/tasks.ps1                 Gestors de paquets, gsudo i `sudo`
  apps/tasks.ps1                 Instal·lació del catàleg
  shell/tasks.ps1                Starship, perfil, mòduls, Windows Terminal
  dev/tasks.ps1                  git, SSH, npm -g, uv, extensions de VS Code
  tabby/tasks.ps1                Connectors de Tabby via npm
  system/tasks.ps1               Ajustos de Windows (= rol desktop del Mac)
  startup/tasks.ps1              Aplicacions d'inici (= Login Items del Mac)
  dotfiles/tasks.ps1             Symlinks de configuració
files/
  profile.ps1                    El perfil de PowerShell (= .zshrc del Mac)
  starship.toml                  Idèntic al d'ansible-mac
  tabby/package.json             Idèntic al d'ansible-mac
  windows-terminal.settings.json Configuració de Windows Terminal
  profile.d/                     Fragments generats (sudo, prompt) — gitignored
lib/Provision.psm1               El motor: idempotència, proveïdors, sortida
scripts/Export-AppsTable.ps1     Regenera docs/APPS.md des de config.yml
docs/APPS.md                     Taula de paritat macOS ↔ Windows
```

## Notes

- Les tasques són idempotents: els fitxers només s'escriuen si el contingut
  difereix, els valors del registre només si el valor actual no és el desitjat, i
  els paquets es comproven abans d'instal·lar-los
- Un paquet que falla **no atura el run**: es reporta com a `failed` i el
  provisionament continua. El `PLAY RECAP` final llista tots els errors
- Els `.ps1` es guarden en **UTF-8 amb BOM** a propòsit: Windows PowerShell 5.1
  llegeix els scripts com a ANSI si no el troben, i els accents es trenquen
- Quan un paquet ofereix més d'un gestor, s'agafa el primer de `provider_order`
  (winget → Chocolatey → Scoop) que estigui disponible. Es pot forçar amb
  `provider:` — és el que fan les Nerd Fonts, que no són a winget
- El perfil de PowerShell s'instal·la a les rutes de Windows PowerShell 5.1 **i**
  de PowerShell 7, i també a les de OneDrive si té la carpeta Documents
  redirigida
- Els paquets MSIX (font `msstore`) i els d'àmbit d'usuari només es poden
  instal·lar sense elevar. És per això que `run.ps1` fa la categoria `store`
  abans d'auto-elevar-se
- Treure un paquet del catàleg **no el desinstal·la** de les màquines on ja hi és:
  el repo declara què hi ha d'haver, no què no hi ha d'haver. Cal fer-ho a mà amb
  `winget uninstall` o `choco uninstall`
- Instal·lar el catàleg sencer en una màquina neta triga **hores**, no minuts:
  són desenes de descàrregues i instal·ladors MSI, que Windows serialitza

## Llicència

MIT. Vegeu [LICENSE](LICENSE).
