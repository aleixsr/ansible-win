# Aplicacions

Tot el que `ansible-win` instal·la, què fa cadascuna i d'on surt. Es genera des
de [`config.yml`](../config.yml) amb `scripts/Export-AppsTable.ps1`: **no
l'editis a mà**, canvia el catàleg i torna a executar l'script.

Torna al [README](../README.md).

<!-- APPS:INICI -->

### Índex d'aplicacions

[7-Zip](#app-keka) · [Adobe Acrobat Reader](#app-acrobat-reader) · [Apache Directory Studio](#app-apache-directory-studio) · [Azure CLI](#app-azure-cli) · [Azure Storage Explorer](#app-azure-storage-explorer) · [Azure VPN Client](#app-azure-vpn-client) · [balenaEtcher](#app-balenaetcher) · [Box Drive](#app-box-drive) · [Brave](#app-brave) · [Calcator](#app-numi) · [Charmy: Hot Corners](#app-hotcorners) · [Chromium](#app-chromium) · [Claude Desktop](#app-claude) · [DBeaver Community](#app-dbeaver) · [draw.io](#app-drawio) · [FFmpeg](#app-ffmpeg) · [Git](#app-git) · [GitHub CLI](#app-gh) · [GitHub Copilot CLI](#app-copilot-cli) · [GitHub Desktop](#app-github-desktop) · [Google Chrome](#app-chrome) · [HandBrake](#app-handbrake) · [HWiNFO](#app-stats) · [iperf3](#app-iperf3) · [LocalSend](#app-localsend) · [Logi Options+](#app-logi-options) · [mailsend-go](#app-swaks) · [Mailspring](#app-mailspring) · [Mark Text](#app-marktext) · [Meslo LG Nerd Font](#app-font-meslo) · [Microsoft Edge](#app-edge) · [Microsoft Teams](#app-teams) · [Microsoft To Do](#app-microsoft-todo) · [Modern CSV](#app-modern-csv) · [Mozilla Firefox](#app-firefox) · [mpv](#app-mpv) · [Nmap](#app-nmap) · [Node.js LTS](#app-node) · [Notepad++](#app-notepadplusplus) · [Novabench](#app-novabench) · [Nushell](#app-nushell) · [Obsidian](#app-obsidian) · [OCI CLI (Oracle Cloud)](#app-oci-cli) · [ONLYOFFICE Desktop Editors](#app-onlyoffice) · [Open TV](#app-opentv) · [OpenVPN Connect](#app-openvpn) · [PDF24 Creator](#app-pdf24) · [PeaZip](#app-peazip) · [PingoMeter](#app-ping-status) · [PowerShell 7](#app-powershell) · [PowerToys](#app-powertoys) · [Python 3.14](#app-python) · [Royal TS](#app-royal-ts) · [RustDesk](#app-rustdesk) · [RustScan](#app-rustscan) · [ScreenToGif](#app-screentogif) · [ShareX](#app-shottr) · [SoapUI](#app-soapui) · [Speedtest CLI](#app-speedtest) · [Sublime Text](#app-sublime-text) · [SwitchHosts](#app-switchhosts) · [Synology Drive Client](#app-synology-drive) · [Tabby](#app-tabby) · [Tailscale](#app-tailscale) · [tcping](#app-tcping) · [Telegram](#app-telegram) · [Visual Studio Code](#app-vscode) · [Visual Studio Code Insiders](#app-vscode-insiders) · [VLC](#app-vlc) · [Wave Terminal](#app-wave) · [wget](#app-wget) · [WhatsApp](#app-whatsapp) · [Windows Terminal](#app-windows-terminal) · [WinMTR](#app-mtr) · [WireGuard](#app-wireguard) · [WizTree](#app-wiztree) · [XCA](#app-xca) · [Zoho Mail](#app-zoho-mail)

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

Grup `terminal`. 4 aplicacions.

| App | Per a què serveix | D'on surt | |
| --- | --- | --- | --- |
| <a id="app-windows-terminal"></a>**[Windows Terminal](https://docs.microsoft.com/windows/terminal)** | El terminal de Windows: pestanyes, panells i perfils per a PowerShell, cmd i WSL. | winget |  |
| <a id="app-tabby"></a>**[Tabby](https://tabby.sh/)** | Terminal amb gestor de connexions SSH i sincronització de la configuració. | winget |  |
| <a id="app-nushell"></a>**[Nushell](https://www.nushell.sh/)** | Shell on tot són dades estructurades: la sortida de cada ordre és una taula que pots filtrar i ordenar. | winget | opcional |
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

**78 aplicacions** en 17 categories, de les quals **14 són opcionals**: no
s'instal·len si no les tries en llançar el run. 19 entrades més són del
catàleg del Mac i no apliquen aquí.
<!-- APPS:FI -->

### Com es tracten les apps que només són del Mac


No desapareixen del catàleg: hi queden amb `desc:` i `win_equivalent:`, que diuen
què eren i qui els fa la feina aquí. La taula és a
[Del catàleg del Mac, no s'instal·len](#del-catàleg-del-mac-no-sinstal·len), més
amunt, i a [`docs/APPS.md`](APPS.md).

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
surten a la taula de més amunt i a [`docs/APPS.md`](APPS.md) però **no
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
a [docs/APPS.md](APPS.md). Es regenera des de `config.yml` amb:

```powershell
.\scripts\Export-AppsTable.ps1
```

<!-- PARITAT:INICI -->

## Paritat amb `ansible-mac`

La columna **A ansible-mac** és la fórmula o el cask del repo de macOS.
Serveix per comprovar d'un cop d'ull que cap app del Mac s'ha quedat pel camí.


## `browsers`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `brave-browser` | [Brave](https://brave.com/download) | Navegador Chromium amb bloqueig d'anuncis i de seguiment de sèrie. | `Brave.Brave` | `brave` | — |
| `chromium` | [Chromium](https://github.com/Hibbiki/chromium-win64) | Chromium net, sense els serveis de Google. Útil per provar comportaments del motor. | `Hibbiki.Chromium` | `chromium` | — |
| `firefox` | [Mozilla Firefox](https://www.mozilla.org/firefox/) | Motor Gecko: el segon motor que cal tenir per comprovar que una web funciona de debò. | `Mozilla.Firefox` | `firefox` | — |
| `google-chrome` | [Google Chrome](https://www.google.com/chrome/) | Google Chrome, per al que només va bé a Chrome i per a les seves DevTools. | `Google.Chrome` | `googlechrome` | — |
| `microsoft-edge` | [Microsoft Edge](https://www.microsoft.com/en-us/edge) | Ve amb Windows; el catàleg només se n'assegura la versió. És el que millor s'entén amb els portals de Microsoft 365. | `Microsoft.Edge` | — | — |

## `clouddevops`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `azure-cli` | [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) | CLI d'Azure: subscripcions, recursos i tot el tenant des de la terminal. | `Microsoft.AzureCLI` | `azure-cli` | — |
| `oci-cli` | [OCI CLI (Oracle Cloud)](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm) | CLI d'Oracle Cloud Infrastructure. | — | `oci-cli` | — |

## `communication`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `mailspring` | [Mailspring](https://getmailspring.com/) | Client de correu d'escriptori per a diversos comptes IMAP. | — | `mailspring` | — |
| `microsoft-teams` | [Microsoft Teams](https://www.microsoft.com/microsoft-teams/group-chat-software) | Microsoft Teams: xat, reunions i trucades del tenant. | `Microsoft.Teams` | — | — |
| `shortwave` | _no s'instal·la_ — `mailspring` | Client de Gmail només per a macOS i web. Aquí fem servir Mailspring. | — | — | — |
| `telegram` | [Telegram](https://desktop.telegram.org/) | Telegram d'escriptori. | `Telegram.TelegramDesktop` | `telegram` | — |
| `whatsapp` | [WhatsApp](http://whatsapp.com/) | WhatsApp d'escriptori (paquet MSIX de la Store). | `9NKSQGP7F2NH` | — | — |
| `zoho-mail` | [Zoho Mail](https://www.zoho.com/mail/desktop/) | Client d'escriptori de Zoho Mail. | `Zoho.Mail` | — | — |

## `development`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `(no hi es a ansible-mac)` | [Notepad++](https://notepad-plus-plus.org/) | Editor de text ràpid, per a un cop d'ull o una edició de quatre línies. | `Notepad++.Notepad++` | `notepadplusplus` | — |
| `apache-directory-studio` | [Apache Directory Studio](https://directory.apache.org/studio/) | Navegador i editor de directoris LDAP. Per mirar l'Active Directory sense endevinar filtres. | `Apache.DirectoryStudio` | — | — |
| `copilot-cli` | [GitHub Copilot CLI](https://github.com/github/copilot-cli) | GitHub Copilot a la terminal: explica i suggereix ordres. | `GitHub.Copilot` | — | — |
| `dbeaver-community` | [DBeaver Community](https://dbeaver.io/download/) | Client SQL universal: PostgreSQL, MySQL, SQL Server, Oracle i companyia amb un sol client. | `DBeaver.DBeaver.Community` | `dbeaver` | — |
| `drawio` | [draw.io](https://github.com/jgraph/drawio-desktop) | Diagrames d'arquitectura i xarxa en local, sense compte ni núvol. | `JGraph.Draw` | `drawio` | — |
| `gh` | [GitHub CLI](https://cli.github.com/) | Client de GitHub per a la terminal: PRs, issues i releases sense obrir el navegador. | `GitHub.cli` | `gh` | — |
| `git` | [Git](https://gitforwindows.org/) | El control de versions. Porta Git Bash i Git Credential Manager. | `Git.Git` | `git` | — |
| `github` | [GitHub Desktop](https://github.com/apps/desktop) | GitHub amb finestres, per als repos on no vols pensar en ordres. | `GitHub.GitHubDesktop` | `github-desktop` | — |
| `node` | [Node.js LTS](https://nodejs.org/) | Runtime de JavaScript, versió LTS. Arrossega npm, que fa falta per a Tabby i per a les eines globals. | `OpenJS.NodeJS.LTS` | `nodejs-lts` | — |
| `python@3.14` | [Python 3.14](https://www.python.org/) | Intèrpret de Python 3.14, amb pip i el llançador py. | `Python.Python.3.14` | `python314` | — |
| `soapui` | [SoapUI](http://www.soapui.org/) | Proves de serveis web SOAP i REST. Encara fa falta per als SOAP de sempre. | — | `soapui` | — |
| `sublime-text` | [Sublime Text](https://www.sublimetext.com/) | Editor lleuger que obre fitxers de centenars de MB sense ofegar-se. | `SublimeHQ.SublimeText.4` | `sublimetext4` | — |
| `visual-studio-code` | [Visual Studio Code](https://code.visualstudio.com/) | L'editor principal: extensions, depurador i terminal integrada. | `Microsoft.VisualStudioCode` | `vscode` | — |
| `visual-studio-code@insiders` | [Visual Studio Code Insiders](https://code.visualstudio.com/insiders/) | La branca diària de VS Code, en paral·lel a l'estable. Per provar coses sense trencar l'entorn de feina. | `Microsoft.VisualStudioCode.Insiders` | `vscode-insiders` | — |

## `documents`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `adobe-acrobat-reader` | [Adobe Acrobat Reader](https://www.adobe.com/products/reader.html) | Lector de PDF de referència, per als formularis i les signatures que només hi funcionen. | `Adobe.Acrobat.Reader.64-bit` | `adobereader` | — |
| `macdown` | _no s'instal·la_ — `marktext` | Editor de Markdown de macOS. Aquí el cobreix Mark Text. | — | — | — |
| `mark-text` | [Mark Text](https://marktext.app/) | Editor de Markdown amb la previsualització al mateix lloc on escrius. | — | `marktext` | — |
| `modern-csv` | [Modern CSV](https://www.moderncsv.com/) | Obre i edita CSV de milions de línies sense que l'Excel se'ls inventi. | `PFOJEnterprisesLLC.ModernCSV` | — | — |
| `onlyoffice` | [ONLYOFFICE Desktop Editors](https://www.onlyoffice.com/en/desktop.aspx) | Suite ofimàtica compatible amb els formats de Microsoft. El substitut de l'Office al catàleg. | `ONLYOFFICE.DesktopEditors` | `onlyoffice` | — |
| `revpdf-editor` | [PDF24 Creator](https://www.pdf24.org/en/) | Eines de PDF en local: unir, partir, comprimir, convertir i signar. | `geeksoftwareGmbH.PDF24Creator` | `pdf24` | — |

## `filemanagementcloud`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `box-drive` | [Box Drive](https://www.box.com/) | Munta Box com una unitat de xarxa, amb els fitxers sota demanda. | `Box.Box` | — | — |
| `localsend` | [LocalSend](https://localsend.org/) | Envia fitxers entre dispositius de la mateixa xarxa, sense núvol ni comptes. | `LocalSend.LocalSend` | `localsend` | — |
| `synology-drive` | [Synology Drive Client](https://kb.synology.com/DSM/help/SynologyDriveClient/synologydriveclient) | Sincronitza carpetes amb un NAS de Synology. | `Synology.DriveClient` | — | — |

## `fonts`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `font-meslo-lg-nerd-font` | [Meslo LG Nerd Font](https://github.com/ryanoasis/nerd-fonts) | Meslo amb les icones de Nerd Fonts. Fa falta perquè el prompt d'Starship es vegi bé. | — | `nerd-fonts-meslo` | — |

## `hardware`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `logi-options+` | [Logi Options+](https://www.logitech.com/software/logi-options-plus) | Configura teclats i ratolins Logitech: botons, gestos i canvi entre equips. | `Logitech.OptionsPlus` | — | — |

## `media`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `(no hi es a ansible-mac)` | [mpv](https://github.com/shinchiro/mpv-winbuild-cmake) | Reproductor mínim i molt ràpid, controlat per teclat i scripts. | `shinchiro.mpv` | `mpv` | — |
| `(no hi es a ansible-mac)` | [FFmpeg](https://www.gyan.dev/ffmpeg/builds/) | La navalla suïssa de l'àudio i el vídeo: converteix, retalla i transmet. | `Gyan.FFmpeg` | `ffmpeg` | — |
| `(no hi es a ansible-mac)` | [Open TV](https://github.com/Fredolx/open-tv) | Reproductor de llistes IPTV M3U. | — | — | — |
| `handbrake-app` | [HandBrake](https://handbrake.fr/) | Recodifica vídeo amb perfils ja fets: per abaixar el pes d'un MP4 sense pensar-hi. | `HandBrake.HandBrake` | `handbrake` | — |
| `vlc` | [VLC](https://www.videolan.org/vlc/) | Reprodueix qualsevol cosa sense haver d'instal·lar còdecs. | `VideoLAN.VLC` | `vlc` | — |

## `microsoftsuite`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `microsoft-auto-update` | _no s'instal·la_ — `Windows Update` | Actualitzador de l'Office per a macOS. A Windows ho fa Click-to-Run. | — | — | — |
| `microsoft-azure-storage-explorer` | [Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer) | Explora blobs, cues, taules i fitxers d'Azure Storage amb interfície. | `Microsoft.Azure.StorageExplorer` | `microsoftazurestorageexplorer` | — |

## `networking`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `iperf3` | [iperf3](https://github.com/ar51an/iperf3-win-builds) | Mesura l'ample de banda real entre dos punts. L'eina per demostrar si la lentitud és de la xarxa. | `ar51an.iPerf3` | — | — |
| `mtr` | [WinMTR](https://github.com/White-Tiger/WinMTR) | traceroute i ping alhora, en continu: ensenya en quin salt es perden els paquets. | — | `winmtr-redux` | — |
| `nmap` | [Nmap](https://nmap.org) | Descoberta de xarxa i escaneig de ports i serveis. | `Insecure.Nmap` | `nmap` | — |
| `rustscan` | [RustScan](https://github.com/bee-san/RustScan) | Escàner de ports molt ràpid; encadena amb Nmap per al detall. | `bee-san.RustScan` | — | — |
| `speedtest` | [Speedtest CLI](https://www.speedtest.net/apps/cli) | Speedtest d'Ookla per a la terminal, per deixar-ne constància en un log. | `Ookla.Speedtest.CLI` | `speedtest` | — |
| `swaks` | [mailsend-go](https://github.com/muquit/mailsend-go) | Envia correu des de la línia d'ordres per provar SMTP, relays i autenticació. | `muquit.mailsend-go` | — | — |
| `tcping` | [tcping](https://www.elifulkerson.com/projects/tcping.php) | Ping contra un port TCP. Per quan l'ICMP està bloquejat, que és gairebé sempre. | — | `tcping` | — |
| `wget` | [wget](https://eternallybored.org/misc/wget/) | Descàrregues no interactives, amb reintents i recursivitat. | `JernejSimoncic.Wget` | `wget` | — |

## `networkingvpn`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `switchhosts` | [SwitchHosts](https://github.com/oldj/SwitchHosts) | Canvia de fitxer hosts amb un clic. Per apuntar un domini a preproducció i tornar enrere. | `oldj.switchhosts` | `switchhosts` | — |
| `tailscale-app` | [Tailscale](https://tailscale.com/download) | VPN de malla sobre WireGuard: connecta els teus equips sense obrir ports. | `Tailscale.Tailscale` | `tailscale` | — |
| `tunnelblick` | [OpenVPN Connect](https://openvpn.net/client/) | Client d'OpenVPN, per als túnels dels clients que el fan servir. | `OpenVPNTechnologies.OpenVPNConnect` | `openvpn-connect` | — |

## `productivity`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `(hot corners natius de macOS)` | [Charmy: Hot Corners](https://yourordinarycat.com/Charmy) | Accions en portar el cursor a una cantonada de la pantalla. | `9P5PK6TVQXF7` | — | — |
| `alt-tab` | _no s'instal·la_ — `Alt+Tab (natiu)` | Canviador de finestres de macOS. A Windows, Alt+Tab de sèrie. | — | — | — |
| `caffeine` | _no s'instal·la_ — `powertoys (Awake)` | Impedeix que l'equip s'adormi. A Windows, PowerToys Awake. | — | — | — |
| `claude` | [Claude Desktop](https://claude.ai/download) | Claude d'escriptori. | `Anthropic.Claude` | — | — |
| `dockdoor` | _no s'instal·la_ — `natiu (barra de tasques)` | Previsualització de finestres del dock. A Windows ja hi és, a la barra de tasques. | — | — | — |
| `keka` | [7-Zip](https://7-zip.org/) | 7-Zip: compressió i descompressió de gairebé qualsevol format. | `7zip.7zip` | `7zip` | — |
| `keka` | [PeaZip](https://peazip.github.io/) | Gestor d'arxius amb interfície, xifratge i comparació de continguts. | `Giorgiotani.Peazip` | `peazip` | — |
| `maccy` | _no s'instal·la_ — `Win+V (natiu)` | Historial del porta-retalls. A Windows, Win+V. | — | — | — |
| `notion` | [Obsidian](https://obsidian.md/) | Notes en Markdown desades com a fitxers locals, amb enllaços entre elles. Fa la feina que al Mac fa Notion. | `Obsidian.Obsidian` | `obsidian` | — |
| `numi` | [Calcator](https://calcator.app/) | Calculadora de text: escrius «3 GB / 40 min» i respon. | — | — | — |
| `rectangle` | _no s'instal·la_ — `powertoys (FancyZones)` | Col·loca finestres per zones. A Windows, FancyZones i Win+fletxes. | — | — | — |
| `shottr` | [ShareX](https://getsharex.com/) | ShareX: captures, gravació, anotacions i pujada automàtica. | `ShareX.ShareX` | `sharex` | — |
| `stats` | [HWiNFO](http://www.hwinfo.com/) | HWiNFO: sensors de temperatura, rellotges i consum de tot el maquinari. | — | `hwinfo.install` | — |

## `remoteaccess`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `royal-tsx` | [Royal TS](https://www.royalapps.com/ts/win/download) | Gestor de connexions remotes: RDP, SSH, VNC i webs, en un arbre amb credencials. | `RoyalApps.RoyalTS.7` | — | — |
| `rustdesk` | [RustDesk](https://rustdesk.com/) | Escriptori remot obert, amb servidor propi si el vols. Alternativa a TeamViewer. | — | `rustdesk` | — |
| `windows-app` | _no s'instal·la_ — `mstsc.exe (natiu)` | Client RDP. A Windows ja hi és: mstsc.exe. | — | — | — |

## `store`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `mas 1158928913 Ping Status` | [PingoMeter](https://github.com/JustinGrote/PingoMeter) | Latència a la barra de tasques, per veure d'un cop d'ull si la connexió va bé. | `JustinGrote.PingoMeter` | — | — |
| `mas 1274495053 Microsoft To Do` | [Microsoft To Do](https://to-do.microsoft.com/) | Tasques de Microsoft To Do, sincronitzades amb el compte de feina. | `9NBLGGH5R558` | — | — |
| `mas 1451685025 WireGuard` | [WireGuard](https://www.wireguard.com/install/) | Client de WireGuard, per als túnels que no passen per Tailscale. | `WireGuard.WireGuard` | `wireguard` | — |
| `mas 1509590766 MuteKey` | _no s'instal·la_ — `powertoys (Video Conference Mute)` | Silencia el micròfon amb una tecla. A Windows, Win+Maj+A de PowerToys. | — | — | — |
| `mas 1553936137 Azure VPN Client` | [Azure VPN Client](https://apps.microsoft.com/detail/9NP355QT2SQB) | Client oficial per a les VPN Point-to-Site d'Azure. | `9NP355QT2SQB` | — | — |

## `systemutilities`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `balenaetcher` | [balenaEtcher](https://etcher.balena.io/) | Grava imatges ISO i IMG a USB, verificant el resultat. | `Balena.Etcher` | `etcher` | — |
| `betterdisplay` | _no s'instal·la_ — `Configuració de pantalla (natiu)` | Gestió de monitors de macOS. El substitut de Windows, Twinkle Tray, només fa brillantor per DDC/CI. | — | — | — |
| `bluesnooze` | _no s'instal·la_ — `Administrador de dispositius` | Evita que el Bluetooth desperti el Mac. A Windows es mira des de l'Administrador de dispositius. | — | — | — |
| `disk-inventory-x` | [WizTree](https://diskanalyzer.com/) | Què t'ocupa el disc, llegint la MFT: analitza un disc sencer en segons. | `AntibodySoftware.WizTree` | `wiztree` | — |
| `htop` | _no s'instal·la_ — `Administrador de tasques (natiu)` | Monitor de processos de terminal. A Windows no el volem: l'Administrador de tasques i PowerToys ja hi arriben. | — | — | — |
| `karabiner-elements` | [PowerToys](https://github.com/microsoft/PowerToys) | La caixa d'eines de Microsoft: FancyZones, PowerToys Run, Awake, Video Conference Mute i selector de colors. | `Microsoft.PowerToys` | `powertoys` | — |
| `licecap` | [ScreenToGif](https://www.screentogif.com/) | Grava un tros de pantalla i el desa com a GIF o MP4. Per ensenyar un error sense escriure tres paràgrafs. | `NickeManarin.ScreenToGif` | `screentogif` | — |
| `macfuse` | _no s'instal·la_ — `WinFsp (a mà, si cal)` | Sistemes de fitxers en espai d'usuari. A Windows ho faria WinFsp, però només cal si en muntes. | — | — | — |
| `mas` | _no s'instal·la_ — `winget --source msstore` | CLI de la Mac App Store. A Windows, winget --source msstore. | — | — | — |
| `novabench` | [Novabench](https://novabench.com) | Benchmark ràpid de CPU, GPU, RAM i disc. | `NovabenchInc.Novabench` | — | — |
| `powershell` | [PowerShell 7](https://microsoft.com/PowerShell) | PowerShell 7, al costat del 5.1 que ve amb Windows. Multiplataforma i molt més ràpid. | `Microsoft.PowerShell` | `powershell-core` | — |
| `resolutionator` | _no s'instal·la_ — `Win+P (natiu)` | Canvi ràpid de resolució. A Windows, Win+P i la configuració de pantalla. | — | — | — |
| `superduper` | _no s'instal·la_ — `Còpies de seguretat de Windows` | Clonatge del disc d'arrencada a macOS. El substitut, Veeam Agent, és backup empresarial. | — | — | — |
| `wins` | _no s'instal·la_ — `Alt+Tab (natiu)` | Canviador de finestres de macOS. A Windows, Alt+Tab i PowerToys. | — | — | — |
| `xca` | [XCA](https://www.hohnstaedt.de/xca/) | Gestor d'autoritats de certificació i certificats X.509, amb interfície. | — | `xca` | — |

## `terminal`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `(no gestionat per ansible-mac)` | [Wave Terminal](https://waveterm.dev/) | Terminal per blocs: desa la sortida de cada ordre perquè la puguis rellegir i compartir. | `CommandLine.Wave` | — | — |
| `(no hi es a ansible-mac)` | [Nushell](https://www.nushell.sh/) | Shell on tot són dades estructurades: la sortida de cada ordre és una taula que pots filtrar i ordenar. | `Nushell.Nushell` | — | — |
| `iterm2` | [Windows Terminal](https://docs.microsoft.com/windows/terminal) | El terminal de Windows: pestanyes, panells i perfils per a PowerShell, cmd i WSL. | `Microsoft.WindowsTerminal` | — | — |
| `tabby` | [Tabby](https://tabby.sh/) | Terminal amb gestor de connexions SSH i sincronització de la configuració. | `Eugeny.Tabby` | `tabby` | — |
| `warp` | _no s'instal·la_ — `windows-terminal` | Terminal amb funcions d'IA. Al Mac s'instal·la; aquí no el volem. | — | — | — |

---

**97 entrades** en 17 categories, de les quals
**78 s'instal·len** i **19 són només del Mac**.

Les que són només del Mac porten `win_equivalent`, que diu qui els fa la feina
aquí. No surten al `run.ps1`: `Select-CatalogPackages` les deixa fora perquè no
hi ha res a instal·lar. Si alguna es queda sense `win_equivalent`, el rol `apps`
la reclama al final del run com a decisió pendent.

<!-- PARITAT:FI -->
