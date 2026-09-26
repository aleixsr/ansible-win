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

<!-- INDEX:INICI -->
## Índex

- [Què fa](#què-fa)
- [Requisits](#requisits)
- [Instal·lació](#instal·lació)
- [Ús](#ús)
- [Configuració](#configuració)
- [Software que instal·la](#software-que-instal·la)
  - [Índex d'aplicacions](#índex-daplicacions)
  - [Desenvolupament](#desenvolupament)
  - [Núvol i DevOps](#núvol-i-devops)
  - [Xarxa (línia d'ordres)](#xarxa-línia-dordres)
  - [Utilitats de sistema](#utilitats-de-sistema)
  - [Navegadors](#navegadors)
  - [Terminals](#terminals)
  - [Comunicació](#comunicació)
  - [Productivitat](#productivitat)
  - [Xarxa i VPN](#xarxa-i-vpn)
  - [Accés remot](#accés-remot)
  - [Fitxers i núvol](#fitxers-i-núvol)
  - [Entorn Microsoft](#entorn-microsoft)
  - [Àudio i vídeo](#àudio-i-vídeo)
  - [Documents](#documents)
  - [Maquinari](#maquinari)
  - [Microsoft Store](#microsoft-store)
  - [Tipografies](#tipografies)
  - [Del catàleg del Mac, no s'instal·len](#del-catàleg-del-mac-no-sinstal·len)
  - [Aplicacions d'inici](#aplicacions-dinici)
  - [Aplicacions que NO volem a l'inici](#aplicacions-que-no-volem-a-linici)
  - [Com es tracten les apps que només són del Mac](#com-es-tracten-les-apps-que-només-són-del-mac)
  - [Descartats a propòsit](#descartats-a-propòsit)
- [Paquets que no són a cap gestor](#paquets-que-no-són-a-cap-gestor)
- [Posar les apps al dia](#posar-les-apps-al-dia)
- [Software opcional](#software-opcional)
  - [Marcar-ne un](#marcar-ne-un)
- [Treure el bloatware de Windows 11](#treure-el-bloatware-de-windows-11)
  - [Què treu](#què-treu)
  - [Què NO treu, a posta](#què-no-treu-a-posta)
  - [Per què no n'hi ha prou d'esborrar-les](#per-què-no-nhi-ha-prou-desborrar-les)
  - [Afegir-hi o treure'n](#afegir-hi-o-treuren)
- [Ajustos que aplica](#ajustos-que-aplica)
  - [D'on surt cada ajust](#don-surt-cada-ajust)
  - [Explorador de fitxers](#explorador-de-fitxers)
  - [Barra de tasques](#barra-de-tasques)
  - [Aparença](#aparença)
  - [Privadesa](#privadesa)
  - [Entrada (ratolí i touchpad) — [mac]](#entrada-ratolí-i-touchpad-—-mac)
  - [Ajustos de desenvolupament](#ajustos-de-desenvolupament)
  - [Energia: treballar amb la tapa tancada](#energia-treballar-amb-la-tapa-tancada)
- [Les dues fases del run](#les-dues-fases-del-run)
- [sudo sense la g](#sudo-sense-la-g)
- [Equivalències amb ansible-mac](#equivalències-amb-ansible-mac)
- [Estructura del projecte](#estructura-del-projecte)
- [Notes](#notes)
- [Llicència](#llicència)
<!-- INDEX:FI -->

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
   - **Fusiona** la configuració de Windows Terminal: el repo mana sobre el que
     declara i la resta es respecta. El Terminal escriu claus pròpies cada cop
     que s'obre (`keybindings`, `newTabMenu`, `themes`); sobreescriure el fitxer
     sencer no convergiria mai. Fa còpia a `.ansible-win.bak` el primer cop
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

**Llança'l sense administrador.** El run fa primer tot el que pot com a usuari
i, si li queda feina que necessita privilegis, t'ensenya quina és i demana l'UAC
un sol cop al final. Vegés [Les dues fases del run](#les-dues-fases-del-run).

## Ús

```powershell
.\run.ps1                                       # tot
.\run.ps1 -Check                                # simulació (com --check)
.\run.ps1 -Upgrade                              # posa al dia el que tens instal·lat
.\run.ps1 -ListPackages                         # ensenya el catàleg sencer
.\run.ps1 -Full                                 # instal·la també tot l'opcional
.\run.ps1 -Optional obsidian,tailscale          # l'essencial i aquests dos
.\run.ps1 -NoElevate                            # no demanis l'UAC: el que calgui admin se salta
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

Aquesta secció **es genera** a partir de `config.yml` amb
`scripts/Export-AppsTable.ps1`. No l'editis a mà: canvia el `desc:` del paquet al
catàleg i torna a executar l'script.

> **Microsoft 365 no és al catàleg.** El manifest `Microsoft.Office` de winget té
> el hash trencat de forma crònica i, a més, la suite ofimàtica aquí la cobreix
> **ONLYOFFICE**, que sí que s'instal·la.

> **yt-dlp arrossega dues dependències.** El seu paquet de winget declara
> `DenoLand.Deno` i `yt-dlp.FFmpeg`, i winget les instal·la soles sense
> preguntar. Deno no és sobrer: yt-dlp el fa servir per resoldre els reptes de
> JavaScript de YouTube. Si no en vols cap, el que has de treure del catàleg és
> **yt-dlp**, no Deno.

<!-- APPS:INICI -->

### Índex d'aplicacions

[7-Zip](#app-keka) · [Adobe Acrobat Reader](#app-acrobat-reader) · [Apache Directory Studio](#app-apache-directory-studio) · [Azure CLI](#app-azure-cli) · [Azure Storage Explorer](#app-azure-storage-explorer) · [Azure VPN Client](#app-azure-vpn-client) · [balenaEtcher](#app-balenaetcher) · [Box Drive](#app-box-drive) · [Brave](#app-brave) · [Calcator](#app-numi) · [Charmy: Hot Corners](#app-hotcorners) · [Chromium](#app-chromium) · [Claude Desktop](#app-claude) · [DBeaver Community](#app-dbeaver) · [draw.io](#app-drawio) · [FFmpeg](#app-ffmpeg) · [Git](#app-git) · [GitHub CLI](#app-gh) · [GitHub Copilot CLI](#app-copilot-cli) · [GitHub Desktop](#app-github-desktop) · [Google Chrome](#app-chrome) · [HandBrake](#app-handbrake) · [HWiNFO](#app-stats) · [iperf3](#app-iperf3) · [LocalSend](#app-localsend) · [Logi Options+](#app-logi-options) · [mailsend-go](#app-swaks) · [Mailspring](#app-mailspring) · [Mark Text](#app-marktext) · [Meslo LG Nerd Font](#app-font-meslo) · [Microsoft Edge](#app-edge) · [Microsoft Teams](#app-teams) · [Microsoft To Do](#app-microsoft-todo) · [Modern CSV](#app-modern-csv) · [Mozilla Firefox](#app-firefox) · [mpv](#app-mpv) · [Nmap](#app-nmap) · [Node.js LTS](#app-node) · [Notepad++](#app-notepadplusplus) · [Novabench](#app-novabench) · [Obsidian](#app-obsidian) · [OCI CLI (Oracle Cloud)](#app-oci-cli) · [ONLYOFFICE Desktop Editors](#app-onlyoffice) · [Open TV](#app-opentv) · [OpenVPN Connect](#app-openvpn) · [PDF24 Creator](#app-pdf24) · [PeaZip](#app-peazip) · [PingoMeter](#app-ping-status) · [PowerShell 7](#app-powershell) · [PowerToys](#app-powertoys) · [Python 3.14](#app-python) · [Royal TS](#app-royal-ts) · [RustDesk](#app-rustdesk) · [RustScan](#app-rustscan) · [ScreenToGif](#app-screentogif) · [ShareX](#app-shottr) · [SoapUI](#app-soapui) · [Speedtest CLI](#app-speedtest) · [Sublime Text](#app-sublime-text) · [SwitchHosts](#app-switchhosts) · [Synology Drive Client](#app-synology-drive) · [Tabby](#app-tabby) · [Tailscale](#app-tailscale) · [tcping](#app-tcping) · [Telegram](#app-telegram) · [Visual Studio Code](#app-vscode) · [Visual Studio Code Insiders](#app-vscode-insiders) · [VLC](#app-vlc) · [Wave Terminal](#app-wave) · [wget](#app-wget) · [WhatsApp](#app-whatsapp) · [Windows Terminal](#app-windows-terminal) · [WinMTR](#app-mtr) · [WireGuard](#app-wireguard) · [WizTree](#app-wiztree) · [XCA](#app-xca) · [Zoho Mail](#app-zoho-mail)

Cada app enllaça amb la seva fila; des d'allà, el nom porta al web del projecte.

### Desenvolupament

Grup `development`. 14 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-gh"></a>**[GitHub CLI](https://cli.github.com/)** | Client de GitHub per a la terminal: PRs, issues i releases sense obrir el navegador. | winget |  |
| <a id="app-git"></a>**[Git](https://gitforwindows.org/)** | El control de versions. Porta Git Bash i Git Credential Manager. | winget |  |
| <a id="app-node"></a>**[Node.js LTS](https://nodejs.org/)** | Runtime de JavaScript, versió LTS. Arrossega npm, que fa falta per a Tabby i per a les eines globals. | winget |  |
| <a id="app-python"></a>**[Python 3.14](https://www.python.org/)** | Intèrpret de Python 3.14, amb pip i el llançador py. | winget |  |
| <a id="app-apache-directory-studio"></a>**[Apache Directory Studio](https://directory.apache.org/studio/)** | Navegador i editor de directoris LDAP. Per mirar l'Active Directory sense endevinar filtres. | winget |  |
| <a id="app-copilot-cli"></a>**[GitHub Copilot CLI](https://github.com/github/copilot-cli)** | GitHub Copilot a la terminal: explica i suggereix ordres. | winget |  |
| <a id="app-dbeaver"></a>**[DBeaver Community](https://dbeaver.io/download/)** | Client SQL universal: PostgreSQL, MySQL, SQL Server, Oracle i companyia amb un sol client. | winget |  |
| <a id="app-drawio"></a>**[draw.io](https://github.com/jgraph/drawio-desktop)** | Diagrames d'arquitectura i xarxa en local, sense compte ni núvol. | winget |  |
| <a id="app-github-desktop"></a>**[GitHub Desktop](https://github.com/apps/desktop)** | GitHub amb finestres, per als repos on no vols pensar en ordres. | winget |  |
| <a id="app-soapui"></a>**[SoapUI](http://www.soapui.org/)** | Proves de serveis web SOAP i REST. Encara fa falta per als SOAP de sempre. | choco |  |
| <a id="app-notepadplusplus"></a>**[Notepad++](https://notepad-plus-plus.org/)** | Editor de text ràpid, per a un cop d'ull o una edició de quatre línies. | winget |  |
| <a id="app-sublime-text"></a>**[Sublime Text](https://www.sublimetext.com/)** | Editor lleuger que obre fitxers de centenars de MB sense ofegar-se. | winget |  |
| <a id="app-vscode"></a>**[Visual Studio Code](https://code.visualstudio.com/)** | L'editor principal: extensions, depurador i terminal integrada. | winget |  |
| <a id="app-vscode-insiders"></a>**[Visual Studio Code Insiders](https://code.visualstudio.com/insiders/)** | La branca diària de VS Code, en paral·lel a l'estable. Per provar coses sense trencar l'entorn de feina. | winget |  |

### Núvol i DevOps

Grup `clouddevops`. 2 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-azure-cli"></a>**[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)** | CLI d'Azure: subscripcions, recursos i tot el tenant des de la terminal. | winget |  |
| <a id="app-oci-cli"></a>**[OCI CLI (Oracle Cloud)](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)** | CLI d'Oracle Cloud Infrastructure. | choco |  |

### Xarxa (línia d'ordres)

Grup `networking`. 8 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-iperf3"></a>**[iperf3](https://github.com/ar51an/iperf3-win-builds)** | Mesura l'ample de banda real entre dos punts. L'eina per demostrar si la lentitud és de la xarxa. | winget |  |
| <a id="app-rustscan"></a>**[RustScan](https://github.com/bee-san/RustScan)** | Escàner de ports molt ràpid; encadena amb Nmap per al detall. | winget |  |
| <a id="app-mtr"></a>**[WinMTR](https://github.com/White-Tiger/WinMTR)** | traceroute i ping alhora, en continu: ensenya en quin salt es perden els paquets. | choco |  |
| <a id="app-nmap"></a>**[Nmap](https://nmap.org)** | Descoberta de xarxa i escaneig de ports i serveis. | winget |  |
| <a id="app-speedtest"></a>**[Speedtest CLI](https://www.speedtest.net/apps/cli)** | Speedtest d'Ookla per a la terminal, per deixar-ne constància en un log. | winget |  |
| <a id="app-swaks"></a>**[mailsend-go](https://github.com/muquit/mailsend-go)** | Envia correu des de la línia d'ordres per provar SMTP, relays i autenticació. | winget |  |
| <a id="app-tcping"></a>**[tcping](https://www.elifulkerson.com/projects/tcping.php)** | Ping contra un port TCP. Per quan l'ICMP està bloquejat, que és gairebé sempre. | choco |  |
| <a id="app-wget"></a>**[wget](https://eternallybored.org/misc/wget/)** | Descàrregues no interactives, amb reintents i recursivitat. | winget |  |

### Utilitats de sistema

Grup `systemutilities`. 7 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-powershell"></a>**[PowerShell 7](https://microsoft.com/PowerShell)** | PowerShell 7, al costat del 5.1 que ve amb Windows. Multiplataforma i molt més ràpid. | winget |  |
| <a id="app-balenaetcher"></a>**[balenaEtcher](https://etcher.balena.io/)** | Grava imatges ISO i IMG a USB, verificant el resultat. | winget |  |
| <a id="app-wiztree"></a>**[WizTree](https://diskanalyzer.com/)** | Què t'ocupa el disc, llegint la MFT: analitza un disc sencer en segons. | winget |  |
| <a id="app-powertoys"></a>**[PowerToys](https://github.com/microsoft/PowerToys)** | La caixa d'eines de Microsoft: FancyZones, PowerToys Run, Awake, Video Conference Mute i selector de colors. | winget |  |
| <a id="app-screentogif"></a>**[ScreenToGif](https://www.screentogif.com/)** | Grava un tros de pantalla i el desa com a GIF o MP4. Per ensenyar un error sense escriure tres paràgrafs. | winget |  |
| <a id="app-novabench"></a>**[Novabench](https://novabench.com)** | Benchmark ràpid de CPU, GPU, RAM i disc. | winget |  |
| <a id="app-xca"></a>**[XCA](https://www.hohnstaedt.de/xca/)** | Gestor d'autoritats de certificació i certificats X.509, amb interfície. | choco |  |

### Navegadors

Grup `browsers`. 5 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-brave"></a>**[Brave](https://brave.com/download)** | Navegador Chromium amb bloqueig d'anuncis i de seguiment de sèrie. | winget |  |
| <a id="app-chromium"></a>**[Chromium](https://github.com/Hibbiki/chromium-win64)** | Chromium net, sense els serveis de Google. Útil per provar comportaments del motor. | winget |  |
| <a id="app-firefox"></a>**[Mozilla Firefox](https://www.mozilla.org/firefox/)** | Motor Gecko: el segon motor que cal tenir per comprovar que una web funciona de debò. | winget |  |
| <a id="app-chrome"></a>**[Google Chrome](https://www.google.com/chrome/)** | Google Chrome, per al que només va bé a Chrome i per a les seves DevTools. | winget |  |
| <a id="app-edge"></a>**[Microsoft Edge](https://www.microsoft.com/en-us/edge)** | Ve amb Windows; el catàleg només se n'assegura la versió. És el que millor s'entén amb els portals de Microsoft 365. | winget |  |

### Terminals

Grup `terminal`. 3 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-windows-terminal"></a>**[Windows Terminal](https://docs.microsoft.com/windows/terminal)** | El terminal de Windows: pestanyes, panells i perfils per a PowerShell, cmd i WSL. | winget |  |
| <a id="app-tabby"></a>**[Tabby](https://tabby.sh/)** | Terminal amb gestor de connexions SSH i sincronització de la configuració. | winget |  |
| <a id="app-wave"></a>**[Wave Terminal](https://waveterm.dev/)** | Terminal per blocs: desa la sortida de cada ordre perquè la puguis rellegir i compartir. | winget |  |

### Comunicació

Grup `communication`. 5 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-mailspring"></a>**[Mailspring](https://getmailspring.com/)** | Client de correu d'escriptori per a diversos comptes IMAP. | choco | opcional |
| <a id="app-teams"></a>**[Microsoft Teams](https://www.microsoft.com/microsoft-teams/group-chat-software)** | Microsoft Teams: xat, reunions i trucades del tenant. | winget | opcional |
| <a id="app-telegram"></a>**[Telegram](https://desktop.telegram.org/)** | Telegram d'escriptori. | winget | opcional |
| <a id="app-whatsapp"></a>**[WhatsApp](http://whatsapp.com/)** | WhatsApp d'escriptori (paquet MSIX de la Store). | Store | opcional |
| <a id="app-zoho-mail"></a>**[Zoho Mail](https://www.zoho.com/mail/desktop/)** | Client d'escriptori de Zoho Mail. | winget | opcional |

### Productivitat

Grup `productivity`. 8 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-claude"></a>**[Claude Desktop](https://claude.ai/download)** | Claude d'escriptori. | winget |  |
| <a id="app-keka"></a>**[7-Zip](https://7-zip.org/)** | 7-Zip: compressió i descompressió de gairebé qualsevol format. | winget |  |
| <a id="app-peazip"></a>**[PeaZip](https://peazip.github.io/)** | Gestor d'arxius amb interfície, xifratge i comparació de continguts. | winget |  |
| <a id="app-obsidian"></a>**[Obsidian](https://obsidian.md/)** | Notes en Markdown desades com a fitxers locals, amb enllaços entre elles. Fa la feina que al Mac fa Notion. | winget | opcional |
| <a id="app-numi"></a>**[Calcator](https://calcator.app/)** | Calculadora de text: escrius «3 GB / 40 min» i respon. | descàrrega directa | opcional |
| <a id="app-hotcorners"></a>**[Charmy: Hot Corners](https://yourordinarycat.com/Charmy)** | Accions en portar el cursor a una cantonada de la pantalla. | Store | opcional |
| <a id="app-shottr"></a>**[ShareX](https://getsharex.com/)** | ShareX: captures, gravació, anotacions i pujada automàtica. | winget |  |
| <a id="app-stats"></a>**[HWiNFO](http://www.hwinfo.com/)** | HWiNFO: sensors de temperatura, rellotges i consum de tot el maquinari. | choco |  |

### Xarxa i VPN

Grup `networkingvpn`. 3 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-switchhosts"></a>**[SwitchHosts](https://github.com/oldj/SwitchHosts)** | Canvia de fitxer hosts amb un clic. Per apuntar un domini a preproducció i tornar enrere. | winget |  |
| <a id="app-tailscale"></a>**[Tailscale](https://tailscale.com/download)** | VPN de malla sobre WireGuard: connecta els teus equips sense obrir ports. | winget | opcional |
| <a id="app-openvpn"></a>**[OpenVPN Connect](https://openvpn.net/client/)** | Client d'OpenVPN, per als túnels dels clients que el fan servir. | winget |  |

### Accés remot

Grup `remoteaccess`. 2 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-royal-ts"></a>**[Royal TS](https://www.royalapps.com/ts/win/download)** | Gestor de connexions remotes: RDP, SSH, VNC i webs, en un arbre amb credencials. | winget |  |
| <a id="app-rustdesk"></a>**[RustDesk](https://rustdesk.com/)** | Escriptori remot obert, amb servidor propi si el vols. Alternativa a TeamViewer. | choco |  |

### Fitxers i núvol

Grup `filemanagementcloud`. 3 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-box-drive"></a>**[Box Drive](https://www.box.com/)** | Munta Box com una unitat de xarxa, amb els fitxers sota demanda. | winget |  |
| <a id="app-localsend"></a>**[LocalSend](https://localsend.org/)** | Envia fitxers entre dispositius de la mateixa xarxa, sense núvol ni comptes. | winget |  |
| <a id="app-synology-drive"></a>**[Synology Drive Client](https://kb.synology.com/DSM/help/SynologyDriveClient/synologydriveclient)** | Sincronitza carpetes amb un NAS de Synology. | winget | opcional |

### Entorn Microsoft

Grup `microsoftsuite`. 1 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-azure-storage-explorer"></a>**[Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer)** | Explora blobs, cues, taules i fitxers d'Azure Storage amb interfície. | winget |  |

### Àudio i vídeo

Grup `media`. 5 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-handbrake"></a>**[HandBrake](https://handbrake.fr/)** | Recodifica vídeo amb perfils ja fets: per abaixar el pes d'un MP4 sense pensar-hi. | winget |  |
| <a id="app-vlc"></a>**[VLC](https://www.videolan.org/vlc/)** | Reprodueix qualsevol cosa sense haver d'instal·lar còdecs. | winget |  |
| <a id="app-mpv"></a>**[mpv](https://github.com/shinchiro/mpv-winbuild-cmake)** | Reproductor mínim i molt ràpid, controlat per teclat i scripts. | winget |  |
| <a id="app-ffmpeg"></a>**[FFmpeg](https://www.gyan.dev/ffmpeg/builds/)** | La navalla suïssa de l'àudio i el vídeo: converteix, retalla i transmet. | winget |  |
| <a id="app-opentv"></a>**[Open TV](https://github.com/Fredolx/open-tv)** | Reproductor de llistes IPTV M3U. | descàrrega directa | opcional |

### Documents

Grup `documents`. 5 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-acrobat-reader"></a>**[Adobe Acrobat Reader](https://www.adobe.com/products/reader.html)** | Lector de PDF de referència, per als formularis i les signatures que només hi funcionen. | winget |  |
| <a id="app-marktext"></a>**[Mark Text](https://marktext.app/)** | Editor de Markdown amb la previsualització al mateix lloc on escrius. | choco |  |
| <a id="app-modern-csv"></a>**[Modern CSV](https://www.moderncsv.com/)** | Obre i edita CSV de milions de línies sense que l'Excel se'ls inventi. | winget |  |
| <a id="app-onlyoffice"></a>**[ONLYOFFICE Desktop Editors](https://www.onlyoffice.com/en/desktop.aspx)** | Suite ofimàtica compatible amb els formats de Microsoft. El substitut de l'Office al catàleg. | winget |  |
| <a id="app-pdf24"></a>**[PDF24 Creator](https://www.pdf24.org/en/)** | Eines de PDF en local: unir, partir, comprimir, convertir i signar. | winget | opcional |

### Maquinari

Grup `hardware`. 1 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-logi-options"></a>**[Logi Options+](https://www.logitech.com/software/logi-options-plus)** | Configura teclats i ratolins Logitech: botons, gestos i canvi entre equips. | winget | opcional |

### Microsoft Store

Grup `store`. 4 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-ping-status"></a>**[PingoMeter](https://github.com/JustinGrote/PingoMeter)** | Latència a la barra de tasques, per veure d'un cop d'ull si la connexió va bé. | winget |  |
| <a id="app-microsoft-todo"></a>**[Microsoft To Do](https://to-do.microsoft.com/)** | Tasques de Microsoft To Do, sincronitzades amb el compte de feina. | Store |  |
| <a id="app-azure-vpn-client"></a>**[Azure VPN Client](https://apps.microsoft.com/detail/9NP355QT2SQB)** | Client oficial per a les VPN Point-to-Site d'Azure. | Store |  |
| <a id="app-wireguard"></a>**[WireGuard](https://www.wireguard.com/install/)** | Client de WireGuard, per als túnels que no passen per Tailscale. | winget |  |

### Tipografies

Grup `fonts`. 1 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-font-meslo"></a>**[Meslo LG Nerd Font](https://github.com/ryanoasis/nerd-fonts)** | Meslo amb les icones de Nerd Fonts. Fa falta perquè el prompt d'Starship es vegi bé. | choco |  |

### Del catàleg del Mac, no s'instal·len

Aquestes entrades vénen d'`ansible-mac` i a Windows no tenen res a fer. No
surten quan executes `run.ps1`; són aquí per no perdre la traça de què les
substitueix.

| Al Mac | Què ho cobreix a Windows |
| --- | --- |
| AltTab | Canviador de finestres de macOS. A Windows, Alt+Tab de sèrie. — Alt+Tab (natiu) |
| BetterDisplay | Gestió de monitors de macOS. El substitut de Windows, Twinkle Tray, només fa brillantor per DDC/CI. — Configuració de pantalla (natiu) |
| Bluesnooze | Evita que el Bluetooth desperti el Mac. A Windows es mira des de l'Administrador de dispositius. — Administrador de dispositius |
| Caffeine | Impedeix que l'equip s'adormi. A Windows, PowerToys Awake. — powertoys (Awake) |
| DockDoor | Previsualització de finestres del dock. A Windows ja hi és, a la barra de tasques. — natiu (barra de tasques) |
| Escriptori remot (mstsc) | Client RDP. A Windows ja hi és: mstsc.exe. — mstsc.exe (natiu) |
| FancyZones (PowerToys) | Col·loca finestres per zones. A Windows, FancyZones i Win+fletxes. — powertoys (FancyZones) |
| htop | Monitor de processos de terminal. A Windows no el volem: l'Administrador de tasques i PowerToys ja hi arriben. — Administrador de tasques (natiu) |
| Mac App Store CLI | CLI de la Mac App Store. A Windows, winget --source msstore. — winget --source msstore |
| Maccy | Historial del porta-retalls. A Windows, Win+V. — Win+V (natiu) |
| MacDown | Editor de Markdown de macOS. Aquí el cobreix Mark Text. — marktext |
| macFUSE | Sistemes de fitxers en espai d'usuari. A Windows ho faria WinFsp, però només cal si en muntes. — WinFsp (a mà, si cal) |
| Microsoft AutoUpdate | Actualitzador de l'Office per a macOS. A Windows ho fa Click-to-Run. — Windows Update |
| MuteKey | Silencia el micròfon amb una tecla. A Windows, Win+Maj+A de PowerToys. — powertoys (Video Conference Mute) |
| Resolutionator | Canvi ràpid de resolució. A Windows, Win+P i la configuració de pantalla. — Win+P (natiu) |
| Shortwave | Client de Gmail només per a macOS i web. Aquí fem servir Mailspring. — mailspring |
| SuperDuper! | Clonatge del disc d'arrencada a macOS. El substitut, Veeam Agent, és backup empresarial. — Còpies de seguretat de Windows |
| Warp | Terminal amb funcions d'IA. Al Mac s'instal·la; aquí no el volem. — windows-terminal |
| Wins | Canviador de finestres de macOS. A Windows, Alt+Tab i PowerToys. — Alt+Tab (natiu) |

**77 aplicacions** en 17 categories, de les quals **13 són opcionals**: no
s'instal·len si no les tries en llançar el run. 19 entrades més són del
catàleg del Mac i no apliquen aquí.
<!-- APPS:FI -->

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

### Com es tracten les apps que només són del Mac

No desapareixen del catàleg: hi queden amb `desc:` i `win_equivalent:`, que diuen
què eren i qui els fa la feina aquí. La taula és a
[Del catàleg del Mac, no s'instal·len](#del-catàleg-del-mac-no-sinstal·len), més
amunt, i a [`docs/APPS.md`](docs/APPS.md).

El `run.ps1` **no les llista**: `Select-CatalogPackages` deixa fora tota entrada
sense cap clau `winget`/`choco`/`scoop`/`url`, que és el que passa amb les que
només porten `mac:`. Així el run no s'omple de línies que no aporten res.

El filtre mira només si la clau hi és, no si el gestor està disponible: un paquet
amb `winget:` en un equip sense winget sí que surt com a `skipped`, que és
informació que vols veure.

Si una entrada es queda **sense `win_equivalent`**, el rol `apps` la reclama al
final del run perquè decideixis què hi poses:

```
PENDENT DE DECIDIR ------------------------------------------------------------
Aquestes 1 apps del catàleg del Mac no tenen res assignat a Windows:

  Zoho Mail  (communication)
```

### Descartats a propòsit

Aquestes sí que existeixen a Windows d'una manera o altra, però el substitut no
valia la pena. Tenen entrada a `config.yml` amb `win_equivalent`, o sigui que
surten a la taula de més amunt i a [`docs/APPS.md`](docs/APPS.md) però **no
s'instal·len mai**:

| Al Mac | El substitut descartat | Per què |
|---|---|---|
| `htop` | btop4win | El port a Windows està abandonat. L'Administrador de tasques ja hi arriba |
| `betterdisplay` | Twinkle Tray | Només fa brillantor i contrast per DDC/CI; no cobreix resolucions ni escalat |
| `macfuse` | WinFsp | No cal si no muntes sistemes de fitxers en espai d'usuari. Instal·la'l a mà si algun dia et fa falta |
| `superduper` | Veeam Agent | Backup empresarial, no clonatge d'arrencada simple |
| `warp` | — | Aquí el terminal és Windows Terminal, Tabby i Wave |

**Notion** és un cas a part: al Mac s'instal·la i aquí la seva feina la fa
**Obsidian**, que és l'entrada que porta `mac: notion`. No és una divergència,
és una substitució.

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

## Posar les apps al dia

```powershell
.\run.ps1 -Upgrade
```

Passa per tot el catàleg i actualitza el que ja tens. El que et falti, te
l'instal·la; el que no tinguis i sigui opcional, el deixa estar.

Això últim és la diferència amb un run normal: **en mode `-Upgrade` els opcionals
hi entren encara que no els demanis**, però només per posar-los al dia. Una app
opcional que tens al disc s'ha de poder actualitzar sense haver de recordar-ne
l'id cada vegada; una que no tens no s'ha d'instal·lar per la porta del darrere.

```
3 opcionals: nomes s'actualitzaran els que ja tinguis (obsidian, numi, hotcorners)
```

La major part de paquets són d'àmbit màquina, o sigui que el gruix de la feina
anirà a la fase elevada i et demanarà l'UAC **un sol cop**. Com sempre, `-Check`
abans t'ensenya què actualitzaria sense tocar res.

## Software opcional

No tot el catàleg s'instal·la sempre. Els paquets marcats amb `optional: true`
només hi entren si els demanes:

```powershell
.\run.ps1                                 # només l'essencial
.\run.ps1 -Full                           # també tot l'opcional
.\run.ps1 -Optional obsidian,tailscale    # l'essencial i aquests dos
```

**El run no pregunta mai res.** És desatès sempre: el pots posar en una tasca
programada, en un CI o en la primera arrencada d'una màquina sense que es quedi
esperant ningú. Per contra, has de dir què vols: sense `-Full` ni `-Optional`,
l'opcional no s'instal·la.

Per si de cas, el run et diu què s'ha deixat fora:

```
14 paquets opcionals no s'instal·len: mailspring, teams, telegram, whatsapp,
zoho-mail, obsidian, numi, hotcorners, tailscale, synology-drive, opentv,
pdf24, logi-options
Amb -Full hi entren tots; amb -Optional <ids>, només els que diguis.
```

Sense aquest avís, que una app no aparegui semblaria un error del playbook quan
en realitat és el comportament demanat.

Un id que no existeixi atura el run i et llista els que hi ha. Val més això que
no pas acabar buscant per què no s'ha instal·lat una cosa que mai s'ha demanat.

La tria es passa a la passada elevada per paràmetre, o sigui que no es deixa pel
camí els opcionals que necessiten administrador.

### Marcar-ne un

```yaml
- id: obsidian
  name: Obsidian
  optional: true
  winget: Obsidian.Obsidian
```

Sense `optional:`, el paquet s'instal·la sempre.

## Treure el bloatware de Windows 11

El rol `debloat` esborra les apps preinstal·lades que no volem i, sobretot, deixa
Windows configurat perquè **no se les torni a instal·lar sol**. La llista és a
`config.yml`; aquí no hi ha cap nom de paquet escrit dins del codi.

### Què treu

| Grup | Paquets |
|---|---|
| Publicitat i jocs | Solitaire Collection, Bing News, Bing Weather, Office Hub, Suggeriments |
| Retirats per Microsoft | Mixed Reality Portal, Skype, Cortana, Contactes, Mapes, Dev Home, Correu i Calendari |
| Assistents i telemetria | Copilot, Edge Game Assist, Centre de comentaris, Obtenir ajuda |
| Redundants amb el catàleg | Reproductor multimèdia i Pel·lícules i TV (tenim VLC i mpv) |
| Xbox | Game Bar i els 4 paquets que l'acompanyen |
| Phone Link | Your Phone i Cross Device |

### Què NO treu, a posta

`Microsoft.DesktopAppInstaller` **és winget**, i tot el repo se'n depèn. Tampoc es
toquen la Store, el Terminal, PowerShell, la Seguretat de Windows, el paquet
d'idioma ni **cap còdec** (`HEIF`, `AV1`, `VP9`, `WebP`, `MPEG2`): treure'ls trenca
la reproducció i la previsualització d'imatges.

Tres decisions més que val la pena saber:

- **Fotos es queda.** Si el treus, en fer doble clic a un PNG no s'obre res, i al
  catàleg no hi ha cap altre visor d'imatges.
- **Thunderbolt Control Center es queda.** És qui gestiona la dock USB-C.
- **El programari del fabricant es queda.** El rol només treu apps de Microsoft:
  la frontera entre bloat i controlador és massa fina per decidir-la des d'un
  catàleg que ha de valer per a màquines diferents.
- **Microsoft To Do es queda**, perquè el catàleg l'instal·la. Instal·lar-lo i
  esborrar-lo al mateix run no té cap sentit.

### Per què no n'hi ha prou d'esborrar-les

Dues raons, i el rol cobreix totes dues:

1. **Els paquets aprovisionats.** Esborrar una app la treu del teu perfil, però es
   queda a la imatge i torna amb cada usuari nou. El rol els treu també de la
   imatge, cosa que necessita administrador.
2. **Els «consumer features».** Windows reinstal·la sol un grapat d'apps
   promocionades a la primera ocasió. `DisableWindowsConsumerFeatures` és el que
   ho atura; sense això, la neteja dura fins al pròxim reinici.

```yaml
debloat:
  settings:
    disable_consumer_features: true   # el que reinstal·la jocs i apps promocionades
    disable_recall: true              # captures contínues de Windows AI
    disable_copilot: true
    disable_widgets: true
    hide_start_recommendations: true  # el bloc "Recomanat" del menú Inici
    hide_explorer_ads: true           # "notificacions de proveïdors de sincronització"
```

### Afegir-hi o treure'n

```yaml
debloat:
  appx:
  - id: Microsoft.BingNews
    desc: "Notícies de Bing."
  win32:
  - id: Nom exacte a Programes i característiques
    desc: "Què és i per què el treiem."
    silent_flag: /S          # només si el desinstal·lador no porta QuietUninstallString
    enabled: false           # `false` el deixa documentat però no el toca
```

Per saber com es diu un paquet:

```powershell
Get-AppxPackage | Where-Object { -not $_.IsFramework } | Select-Object Name | Sort-Object Name
```

Els programes de sempre es busquen pel **nom exacte** de Programes i
característiques. El rol només els desinstal·la si troba una ordre silenciosa: si
no en té cap, ho diu i no fa res, perquè un desinstal·lador interactiu enmig d'un
run desatès es queda penjat per sempre.

Passa-hi `-Check` abans: t'ensenya exactament què esborraria, un per un.

```powershell
.\run.ps1 -Roles debloat -Check
```

## Ajustos que aplica

Tots configurables a la secció `system:` de `config.yml`. Els que toquen `HKLM`
necessiten administrador; sense privilegis surten com a `skipped`, no fallen.

### D'on surt cada ajust

Això no és tot una traducció d'`ansible-mac`, i val més dir-ho clar. Cada bloc
de `system:` va marcat al `config.yml`:

| Marca | Què vol dir |
|---|---|
| `[mac]` | Ve del rol `desktop` d'`ansible-mac` i hi té equivalència directa |
| `[win]` | **No existeix a `ansible-mac`**: és criteri afegit només per a Windows |

| Bloc | Origen |
|---|---|
| `input` (trackpad i scroll) | `[mac]` |
| `explorer.hide_desktop_icons` | `[mac]` — `com.apple.finder CreateDesktop = false` |
| Resta d'`explorer` | `[win]` |
| `taskbar` | `[win]` |
| `appearance` | `[win]` |
| `privacy` | `[win]` |
| `developer` | `[win]` |

El rol `desktop` del Mac toca escriptori, Dock, hot corners, trackpad i teclat.
A Windows no hi ha ni Dock ni hot corners, i la resta de blocs són decisions
sobre com ha de quedar un Windows, no traduccions de res. **Si algun dia vols
que els dos repos siguin estrictes, el que s'ha de treure és tot el `[win]`.**

Del rol `desktop` del Mac queden sense portar, per falta d'equivalent a Windows:
so en canviar el volum, substitució de punt amb doble espai, clic silenciós i
Force Click (són del trackpad hàptic dels Mac) i F1–F12 com a tecles de funció
(a Windows ho mana la BIOS, no el sistema operatiu).

### Explorador de fitxers

| Ajust | Per defecte | |
|---|---|---|
| Icones de l'escriptori | **visibles** — al Mac s'amaguen, aquí no | `[mac]` |

> `HideIcons` no es pot escriure i prou: l'Explorador se'l guarda en memòria i
> el reescriu, tant mentre corre com en sortir. El rol l'**atura primer**,
> escriu després i el torna a obrir. A l'inrevés no enganxa.

| Mostrar les extensions de fitxer | sí | `[win]` |
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

### Entrada (ratolí i touchpad) — `[mac]`

Tot aquest bloc ve del rol `desktop` d'`ansible-mac`.

| Ajust | Per defecte | A `ansible-mac` |
|---|---|---|
| `natural_scrolling` | `false` — gest o roda avall, la pàgina baixa | `com.apple.swipescrolldirection = false` |
| `tap_to_click` | `true` | `Clicking = 1` |
| `two_finger_right_click` | `true` | `TrackpadRightClick = true` |
| `corner_right_click` | `false` — amb dos dits, no per la cantonada | `TrackpadCornerSecondaryClick = 0` |
| `tap_and_drag` | `true` — arrossegar sense bloqueig | `Dragging = 1`, `DragLock = 0` |

Els del trackpad s'apliquen a `HKCU\...\PrecisionTouchPad`. En un equip sense
touchpad de precisió, la tasca surt com a `skipped`.

A macOS és una sola preferència. A Windows en calen dues, i **el `0` no vol dir
el mateix a totes dues**:

| Dispositiu | Clau | `0` | `1` |
|---|---|---|---|
| Touchpad de precisió | `HKCU\...\PrecisionTouchPad\ScrollDirection` | natural | clàssic |
| Ratolí (una per cada HID) | `HKLM\SYSTEM\CurrentControlSet\Enum\HID\...\Device Parameters\FlipFlopWheel` | clàssic | natural |

El canvi al touchpad és immediat. **El del ratolí no s'aplica fins que
desconnectis i tornis a connectar el dispositiu, o reiniciïs.** Si et queda al
revés, canvia el booleà i torna a executar `.\run.ps1 -Roles system`.

### Ajustos de desenvolupament

### Energia: treballar amb la tapa tancada

L'únic ajust d'energia que toca el repo és **què passa en tancar la tapa**, per
poder treballar amb el portàtil tancat sobre una dock USB-C i els monitors
externs:

```yaml
system:
  power:
    lid_action_ac: 0   # endollat: no facis res
    lid_action_dc: 1   # amb bateria: suspèn
```

Els valors són els de `LIDACTION` de `powercfg`: `0` no fer res, `1` suspendre,
`2` hibernar, `3` apagar. Equival a:

```
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1
powercfg /setactive SCHEME_CURRENT
```

Detalls que val la pena saber:

- **Cal admin**, i només s'aplica a l'**esquema actiu**. Si canvies de pla
  d'energia, el pla nou porta els seus propis valors: torna a passar el rol.
- El `/setactive` final no és decoratiu. Sense ell els índexs queden escrits
  però no s'apliquen a la sessió.
- `powercfg /query SCHEME_CURRENT SUB_BUTTONS LIDACTION` **no ensenya el valor**:
  ve amagat de fàbrica. Per això la tasca comprova l'estat llegint
  `HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\<pla>\...`, que
  és d'on powercfg ho treu. En sobretaula aquesta clau no existeix i la tasca
  surt com a `skipped`.
- Amb `0` i la tapa tancada **sense cap monitor extern connectat**, l'equip
  segueix engegat i cec. És el preu de l'ajust.

**La resta d'energia no la gestiona el repo.** Hi havia un bloc `power` que posava
el pla «Alt rendiment» i desactivava la suspensió, i es va treure: en un portàtil
té conseqüències reals sobre el ventilador i la bateria, i a Windows els temps
d'apagar pantalla i de suspensió són **propietats del pla**, no ajustos
independents, així que treure'n un vol dir treure'ls tots. L'acció de tapa és
l'excepció perquè és un interruptor aïllat: no arrossega cap altre paràmetre.
Els temps es gestionen des de Configuració > Sistema > Energia.

| Ajust | Per defecte |
|---|---|
| Mode desenvolupador | activat |
| Rutes llargues (>260 caràcters) | activades |
| Servidor OpenSSH | desactivat |

Alguns canvis de l'Explorador no es veuen fins que el reinicies:

```powershell
Stop-Process -Name explorer -Force
```

## Les dues fases del run

`run.ps1` **s'ha de llançar sense administrador**. No perquè sigui més segur, sinó
perquè una part de la feina *només* es pot fer sense privilegis: les apps MSIX de
la Microsoft Store s'instal·len per usuari i des d'un procés elevat fallen sempre.

```
$ .\run.ps1

  FASE 1 - sense privilegis
    Tot el que es pot fer com a usuari: apps de la Store, paquets de Scoop,
    ajustos d'HKCU, perfils, dotfiles... Les tasques que necessiten admin no
    peten ni se salten en silenci: s'apunten.

  ARA VE LA PART QUE NECESSITA ADMINISTRADOR (4 tasques)
    [core]   - prioritat PATH (sudo -> gsudo)
    [system] - mode desenvolupador
               rutes llargues (>260 car.)
               scroll del ratolí (clàssic)

  [UAC, un sol cop]

  FASE 2 - elevada
    Repassa els mateixos rols amb privilegis. El que ja estava fet surt com a
    `ok`, i el que faltava s'aplica.
```

Què va a cada fase:

| Fase 1 (usuari) | Fase 2 (admin) |
|---|---|
| Apps MSIX de la Store | Paquets de winget, Chocolatey i installers per URL |
| Paquets de Scoop | Chocolatey mateix, si falta |
| Ajustos d'HKCU (Explorador, barra de tasques, tema, privadesa, touchpad) | Ajustos d'HKLM (mode dev, rutes llargues, OpenSSH, tapa tancada, scroll del ratolí) |
| Perfils, dotfiles, Tabby, apps d'inici | PATH de màquina (prioritat de `sudo`) |

Detalls:

- **Els paquets d'àmbit màquina ni s'intenten a la fase 1.** Podrien instal·lar-se
  obrint un UAC per paquet; val més apuntar-los i fer-los tots de cop. El que ja
  està instal·lat es detecta igualment a la fase 1 i surt com a `ok`.
- **Un sol UAC.** Si no queda res pendent, no se'n demana cap.
- `-NoElevate` es queda a la fase 1 i diu què ha deixat per fer.
- `-Check` no eleva mai.
- Si el llances **ja elevat**, el run t'avisa: les apps de la Store se saltaran.
- Si dius que no a l'UAC, la fase 1 es dóna per bona i t'ho diu. Torna-hi quan
  vulguis: és idempotent.

## `sudo` sense la `g`

Windows 11 porta el seu propi `C:\Windows\System32\sudo.exe`. Com que el `PATH`
de màquina s'avalua abans que el d'usuari, posar `gsudo` al `PATH` no n'hi ha
prou: el de Microsoft sempre guanyaria.

El rol `core` ho resol per dues bandes:

1. **A PowerShell** — genera `files/profile.d/10-sudo.ps1` amb una *funció*
   `sudo`. A PowerShell les funcions tenen precedència sobre els executables del
   `PATH`, així que `sudo` és `gsudo` i punt. També deixa `s` com a abreviatura
2. **A `cmd.exe` i companyia** — mou `C:\tools\gsudo\Current` **davant de
   `System32`** al `PATH` de màquina. gsudo ja hi instal·la el seu propi
   `sudo.exe`, o sigui que amb l'ordre correcte `sudo` és gsudo a `cmd.exe`, als
   `.bat`, al diàleg Executar i a les tasques programades

```yaml
sudo:
  provider: gsudo        # 'native' deixa el sudo de Microsoft
  powershell_alias: true
  path_priority: true    # gsudo davant de System32 al PATH de màquina
  cmd_shim: false        # shim bin\sudo.cmd (històric, vegeu avall)
```

`path_priority` toca el `PATH` de màquina, o sigui que **cal el run elevat**
(`run.ps1` s'eleva sol). Abans d'escriure desa el valor anterior a
`logs\path-machine-<data>.bak`. Els canvis no arriben a les consoles ja obertes:
cal reobrir-les.

> **Compte:** posar un directori de tercers davant de `System32` fa que tot el
> que hi hagi pugui ocultar binaris del sistema. `C:\tools\gsudo` només és
> escrivible per administrador, però és un canvi global: té-ho present.

L'altra opció, `cmd_shim`, genera `bin\sudo.cmd`. És històrica i per defecte va
a `false`: `bin\` viu al `PATH` d'**usuari**, que s'avalua sempre després del de
màquina, o sigui que el shim mai pot guanyar el `sudo.exe` de System32. Amb
`cmd_shim: false` el rol esborra el fitxer si hi era.

El repo **no gestiona la cache de credencials** de gsudo. `CacheDuration` és un
ajust global del sistema que demana una elevació pròpia, i des d'un run que ja
corre elevat no es pot aplicar: la tasca sortiria com a pendent per sempre. Es
configura a mà, un sol cop:

```powershell
gsudo config CacheDuration 00:00:00
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
  debloat/tasks.ps1              Treu el programari preinstal·lat de Windows 11
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
  instal·lar sense elevar. És per això que el run comença sense privilegis i
  només s'eleva al final
- Treure un paquet del catàleg **no el desinstal·la** de les màquines on ja hi és:
  el repo declara què hi ha d'haver, no què no hi ha d'haver. Cal fer-ho a mà amb
  `winget uninstall` o `choco uninstall`
- Instal·lar el catàleg sencer en una màquina neta triga **hores**, no minuts:
  són desenes de descàrregues i instal·ladors MSI, que Windows serialitza

## Llicència

MIT. Vegeu [LICENSE](LICENSE).
