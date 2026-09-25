# Paritat d'aplicacions: `ansible-mac` ↔ `ansible-win`

> Generat automàticament per `scripts/Export-AppsTable.ps1` a partir de
> `config.yml`. No l'editis a mà.

La columna **A ansible-mac** és la fórmula o el cask del repo de macOS.
Serveix per comprovar d'un cop d'ull que cap app del Mac s'ha quedat pel camí.


## `browsers`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `brave-browser` | Brave | Navegador Chromium amb bloqueig d'anuncis i de seguiment de sèrie. | `Brave.Brave` | `brave` | — |
| `chromium` | Chromium | Chromium net, sense els serveis de Google. Útil per provar comportaments del motor. | `Hibbiki.Chromium` | `chromium` | — |
| `firefox` | Mozilla Firefox | Motor Gecko: el segon motor que cal tenir per comprovar que una web funciona de debò. | `Mozilla.Firefox` | `firefox` | — |
| `google-chrome` | Google Chrome | Google Chrome, per al que només va bé a Chrome i per a les seves DevTools. | `Google.Chrome` | `googlechrome` | — |
| `microsoft-edge` | Microsoft Edge | Ve amb Windows; el catàleg només se n'assegura la versió. És el que millor s'entén amb els portals de Microsoft 365. | `Microsoft.Edge` | — | — |

## `clouddevops`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `azure-cli` | Azure CLI | CLI d'Azure: subscripcions, recursos i tot el tenant des de la terminal. | `Microsoft.AzureCLI` | `azure-cli` | — |
| `oci-cli` | OCI CLI (Oracle Cloud) | CLI d'Oracle Cloud Infrastructure. | — | `oci-cli` | — |

## `communication`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `mailspring` | Mailspring | Client de correu d'escriptori per a diversos comptes IMAP. | — | `mailspring` | — |
| `microsoft-teams` | Microsoft Teams | Microsoft Teams: xat, reunions i trucades del tenant. | `Microsoft.Teams` | — | — |
| `shortwave` | _no s'instal·la_ — `mailspring` | Client de Gmail només per a macOS i web. Aquí fem servir Mailspring. | — | — | — |
| `telegram` | Telegram | Telegram d'escriptori. | `Telegram.TelegramDesktop` | `telegram` | — |
| `whatsapp` | WhatsApp | WhatsApp d'escriptori (paquet MSIX de la Store). | `9NKSQGP7F2NH` | — | — |
| `zoho-mail` | Zoho Mail | Client d'escriptori de Zoho Mail. | `Zoho.Mail` | — | — |

## `development`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `(no hi es a ansible-mac)` | Notepad++ | Editor de text ràpid, per a un cop d'ull o una edició de quatre línies. | `Notepad++.Notepad++` | `notepadplusplus` | — |
| `apache-directory-studio` | Apache Directory Studio | Navegador i editor de directoris LDAP. Per mirar l'Active Directory sense endevinar filtres. | `Apache.DirectoryStudio` | — | — |
| `copilot-cli` | GitHub Copilot CLI | GitHub Copilot a la terminal: explica i suggereix ordres. | `GitHub.Copilot` | — | — |
| `dbeaver-community` | DBeaver Community | Client SQL universal: PostgreSQL, MySQL, SQL Server, Oracle i companyia amb un sol client. | `DBeaver.DBeaver.Community` | `dbeaver` | — |
| `drawio` | draw.io | Diagrames d'arquitectura i xarxa en local, sense compte ni núvol. | `JGraph.Draw` | `drawio` | — |
| `gh` | GitHub CLI | Client de GitHub per a la terminal: PRs, issues i releases sense obrir el navegador. | `GitHub.cli` | `gh` | — |
| `git` | Git | El control de versions. Porta Git Bash i Git Credential Manager. | `Git.Git` | `git` | — |
| `github` | GitHub Desktop | GitHub amb finestres, per als repos on no vols pensar en ordres. | `GitHub.GitHubDesktop` | `github-desktop` | — |
| `node` | Node.js LTS | Runtime de JavaScript, versió LTS. Arrossega npm, que fa falta per a Tabby i per a les eines globals. | `OpenJS.NodeJS.LTS` | `nodejs-lts` | — |
| `python@3.14` | Python 3.14 | Intèrpret de Python 3.14, amb pip i el llançador py. | `Python.Python.3.14` | `python314` | — |
| `soapui` | SoapUI | Proves de serveis web SOAP i REST. Encara fa falta per als SOAP de sempre. | — | `soapui` | — |
| `sublime-text` | Sublime Text | Editor lleuger que obre fitxers de centenars de MB sense ofegar-se. | `SublimeHQ.SublimeText.4` | `sublimetext4` | — |
| `visual-studio-code` | Visual Studio Code | L'editor principal: extensions, depurador i terminal integrada. | `Microsoft.VisualStudioCode` | `vscode` | — |
| `visual-studio-code@insiders` | Visual Studio Code Insiders | La branca diària de VS Code, en paral·lel a l'estable. Per provar coses sense trencar l'entorn de feina. | `Microsoft.VisualStudioCode.Insiders` | `vscode-insiders` | — |

## `documents`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `adobe-acrobat-reader` | Adobe Acrobat Reader | Lector de PDF de referència, per als formularis i les signatures que només hi funcionen. | `Adobe.Acrobat.Reader.64-bit` | `adobereader` | — |
| `macdown` | _no s'instal·la_ — `marktext` | Editor de Markdown de macOS. Aquí el cobreix Mark Text. | — | — | — |
| `mark-text` | Mark Text | Editor de Markdown amb la previsualització al mateix lloc on escrius. | — | `marktext` | — |
| `modern-csv` | Modern CSV | Obre i edita CSV de milions de línies sense que l'Excel se'ls inventi. | `PFOJEnterprisesLLC.ModernCSV` | — | — |
| `onlyoffice` | ONLYOFFICE Desktop Editors | Suite ofimàtica compatible amb els formats de Microsoft. El substitut de l'Office al catàleg. | `ONLYOFFICE.DesktopEditors` | `onlyoffice` | — |
| `revpdf-editor` | PDF24 Creator | Eines de PDF en local: unir, partir, comprimir, convertir i signar. | `geeksoftwareGmbH.PDF24Creator` | `pdf24` | — |

## `filemanagementcloud`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `box-drive` | Box Drive | Munta Box com una unitat de xarxa, amb els fitxers sota demanda. | `Box.Box` | — | — |
| `localsend` | LocalSend | Envia fitxers entre dispositius de la mateixa xarxa, sense núvol ni comptes. | `LocalSend.LocalSend` | `localsend` | — |
| `synology-drive` | Synology Drive Client | Sincronitza carpetes amb un NAS de Synology. | `Synology.DriveClient` | — | — |

## `fonts`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `font-meslo-lg-nerd-font` | Meslo LG Nerd Font | Meslo amb les icones de Nerd Fonts. Fa falta perquè el prompt d'Starship es vegi bé. | — | `nerd-fonts-meslo` | — |

## `hardware`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `logi-options+` | Logi Options+ | Configura teclats i ratolins Logitech: botons, gestos i canvi entre equips. | `Logitech.OptionsPlus` | — | — |

## `media`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `(no hi es a ansible-mac)` | mpv | Reproductor mínim i molt ràpid, controlat per teclat i scripts. | `shinchiro.mpv` | `mpv` | — |
| `(no hi es a ansible-mac)` | FFmpeg | La navalla suïssa de l'àudio i el vídeo: converteix, retalla i transmet. | `Gyan.FFmpeg` | `ffmpeg` | — |
| `(no hi es a ansible-mac)` | Open TV | Reproductor de llistes IPTV M3U. | — | — | — |
| `handbrake-app` | HandBrake | Recodifica vídeo amb perfils ja fets: per abaixar el pes d'un MP4 sense pensar-hi. | `HandBrake.HandBrake` | `handbrake` | — |
| `vlc` | VLC | Reprodueix qualsevol cosa sense haver d'instal·lar còdecs. | `VideoLAN.VLC` | `vlc` | — |

## `microsoftsuite`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `microsoft-auto-update` | _no s'instal·la_ — `Windows Update` | Actualitzador de l'Office per a macOS. A Windows ho fa Click-to-Run. | — | — | — |
| `microsoft-azure-storage-explorer` | Azure Storage Explorer | Explora blobs, cues, taules i fitxers d'Azure Storage amb interfície. | `Microsoft.Azure.StorageExplorer` | `microsoftazurestorageexplorer` | — |

## `networking`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `iperf3` | iperf3 | Mesura l'ample de banda real entre dos punts. L'eina per demostrar si la lentitud és de la xarxa. | `ar51an.iPerf3` | — | — |
| `mtr` | WinMTR | traceroute i ping alhora, en continu: ensenya en quin salt es perden els paquets. | — | `winmtr-redux` | — |
| `nmap` | Nmap | Descoberta de xarxa i escaneig de ports i serveis. | `Insecure.Nmap` | `nmap` | — |
| `rustscan` | RustScan | Escàner de ports molt ràpid; encadena amb Nmap per al detall. | `bee-san.RustScan` | — | — |
| `speedtest` | Speedtest CLI | Speedtest d'Ookla per a la terminal, per deixar-ne constància en un log. | `Ookla.Speedtest.CLI` | `speedtest` | — |
| `swaks` | mailsend-go | Envia correu des de la línia d'ordres per provar SMTP, relays i autenticació. | `muquit.mailsend-go` | — | — |
| `tcping` | tcping | Ping contra un port TCP. Per quan l'ICMP està bloquejat, que és gairebé sempre. | — | `tcping` | — |
| `wget` | wget | Descàrregues no interactives, amb reintents i recursivitat. | `JernejSimoncic.Wget` | `wget` | — |

## `networkingvpn`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `switchhosts` | SwitchHosts | Canvia de fitxer hosts amb un clic. Per apuntar un domini a preproducció i tornar enrere. | `oldj.switchhosts` | `switchhosts` | — |
| `tailscale-app` | Tailscale | VPN de malla sobre WireGuard: connecta els teus equips sense obrir ports. | `Tailscale.Tailscale` | `tailscale` | — |
| `tunnelblick` | OpenVPN Connect | Client d'OpenVPN, per als túnels dels clients que el fan servir. | `OpenVPNTechnologies.OpenVPNConnect` | `openvpn-connect` | — |

## `productivity`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `(hot corners natius de macOS)` | Charmy: Hot Corners | Accions en portar el cursor a una cantonada de la pantalla. | `9P5PK6TVQXF7` | — | — |
| `alt-tab` | _no s'instal·la_ — `Alt+Tab (natiu)` | Canviador de finestres de macOS. A Windows, Alt+Tab de sèrie. | — | — | — |
| `caffeine` | _no s'instal·la_ — `powertoys (Awake)` | Impedeix que l'equip s'adormi. A Windows, PowerToys Awake. | — | — | — |
| `claude` | Claude Desktop | Claude d'escriptori. | `Anthropic.Claude` | — | — |
| `dockdoor` | _no s'instal·la_ — `natiu (barra de tasques)` | Previsualització de finestres del dock. A Windows ja hi és, a la barra de tasques. | — | — | — |
| `keka` | 7-Zip | 7-Zip: compressió i descompressió de gairebé qualsevol format. | `7zip.7zip` | `7zip` | — |
| `keka` | PeaZip | Gestor d'arxius amb interfície, xifratge i comparació de continguts. | `Giorgiotani.Peazip` | `peazip` | — |
| `maccy` | _no s'instal·la_ — `Win+V (natiu)` | Historial del porta-retalls. A Windows, Win+V. | — | — | — |
| `notion` | Obsidian | Notes en Markdown desades com a fitxers locals, amb enllaços entre elles. Fa la feina que al Mac fa Notion. | `Obsidian.Obsidian` | `obsidian` | — |
| `numi` | Calcator | Calculadora de text: escrius «3 GB / 40 min» i respon. | — | — | — |
| `rectangle` | _no s'instal·la_ — `powertoys (FancyZones)` | Col·loca finestres per zones. A Windows, FancyZones i Win+fletxes. | — | — | — |
| `shottr` | ShareX | ShareX: captures, gravació, anotacions i pujada automàtica. | `ShareX.ShareX` | `sharex` | — |
| `stats` | HWiNFO | HWiNFO: sensors de temperatura, rellotges i consum de tot el maquinari. | — | `hwinfo.install` | — |

## `remoteaccess`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `royal-tsx` | Royal TS | Gestor de connexions remotes: RDP, SSH, VNC i webs, en un arbre amb credencials. | `RoyalApps.RoyalTS.7` | — | — |
| `rustdesk` | RustDesk | Escriptori remot obert, amb servidor propi si el vols. Alternativa a TeamViewer. | — | `rustdesk` | — |
| `windows-app` | _no s'instal·la_ — `mstsc.exe (natiu)` | Client RDP. A Windows ja hi és: mstsc.exe. | — | — | — |

## `store`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `mas 1158928913 Ping Status` | PingoMeter | Latència a la barra de tasques, per veure d'un cop d'ull si la connexió va bé. | `JustinGrote.PingoMeter` | — | — |
| `mas 1274495053 Microsoft To Do` | Microsoft To Do | Tasques de Microsoft To Do, sincronitzades amb el compte de feina. | `9NBLGGH5R558` | — | — |
| `mas 1451685025 WireGuard` | WireGuard | Client de WireGuard, per als túnels que no passen per Tailscale. | `WireGuard.WireGuard` | `wireguard` | — |
| `mas 1509590766 MuteKey` | _no s'instal·la_ — `powertoys (Video Conference Mute)` | Silencia el micròfon amb una tecla. A Windows, Win+Maj+A de PowerToys. | — | — | — |
| `mas 1553936137 Azure VPN Client` | Azure VPN Client | Client oficial per a les VPN Point-to-Site d'Azure. | `9NP355QT2SQB` | — | — |

## `systemutilities`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `balenaetcher` | balenaEtcher | Grava imatges ISO i IMG a USB, verificant el resultat. | `Balena.Etcher` | `etcher` | — |
| `betterdisplay` | _no s'instal·la_ — `Configuració de pantalla (natiu)` | Gestió de monitors de macOS. El substitut de Windows, Twinkle Tray, només fa brillantor per DDC/CI. | — | — | — |
| `bluesnooze` | _no s'instal·la_ — `Administrador de dispositius` | Evita que el Bluetooth desperti el Mac. A Windows es mira des de l'Administrador de dispositius. | — | — | — |
| `disk-inventory-x` | WizTree | Què t'ocupa el disc, llegint la MFT: analitza un disc sencer en segons. | `AntibodySoftware.WizTree` | `wiztree` | — |
| `htop` | _no s'instal·la_ — `Administrador de tasques (natiu)` | Monitor de processos de terminal. A Windows no el volem: l'Administrador de tasques i PowerToys ja hi arriben. | — | — | — |
| `karabiner-elements` | PowerToys | La caixa d'eines de Microsoft: FancyZones, PowerToys Run, Awake, Video Conference Mute i selector de colors. | `Microsoft.PowerToys` | `powertoys` | — |
| `licecap` | ScreenToGif | Grava un tros de pantalla i el desa com a GIF o MP4. Per ensenyar un error sense escriure tres paràgrafs. | `NickeManarin.ScreenToGif` | `screentogif` | — |
| `macfuse` | _no s'instal·la_ — `WinFsp (a mà, si cal)` | Sistemes de fitxers en espai d'usuari. A Windows ho faria WinFsp, però només cal si en muntes. | — | — | — |
| `mas` | _no s'instal·la_ — `winget --source msstore` | CLI de la Mac App Store. A Windows, winget --source msstore. | — | — | — |
| `novabench` | Novabench | Benchmark ràpid de CPU, GPU, RAM i disc. | `NovabenchInc.Novabench` | — | — |
| `powershell` | PowerShell 7 | PowerShell 7, al costat del 5.1 que ve amb Windows. Multiplataforma i molt més ràpid. | `Microsoft.PowerShell` | `powershell-core` | — |
| `resolutionator` | _no s'instal·la_ — `Win+P (natiu)` | Canvi ràpid de resolució. A Windows, Win+P i la configuració de pantalla. | — | — | — |
| `superduper` | _no s'instal·la_ — `Còpies de seguretat de Windows` | Clonatge del disc d'arrencada a macOS. El substitut, Veeam Agent, és backup empresarial. | — | — | — |
| `wins` | _no s'instal·la_ — `Alt+Tab (natiu)` | Canviador de finestres de macOS. A Windows, Alt+Tab i PowerToys. | — | — | — |
| `xca` | XCA | Gestor d'autoritats de certificació i certificats X.509, amb interfície. | — | `xca` | — |

## `terminal`

| A ansible-mac | A Windows | Per a què serveix | winget | Chocolatey | Scoop |
| --- | --- | --- | --- | --- | --- |
| `(no gestionat per ansible-mac)` | Wave Terminal | Terminal per blocs: desa la sortida de cada ordre perquè la puguis rellegir i compartir. | `CommandLine.Wave` | — | — |
| `iterm2` | Windows Terminal | El terminal de Windows: pestanyes, panells i perfils per a PowerShell, cmd i WSL. | `Microsoft.WindowsTerminal` | — | — |
| `tabby` | Tabby | Terminal amb gestor de connexions SSH i sincronització de la configuració. | `Eugeny.Tabby` | `tabby` | — |
| `warp` | _no s'instal·la_ — `windows-terminal` | Terminal amb funcions d'IA. Al Mac s'instal·la; aquí no el volem. | — | — | — |

---

**96 entrades** en 17 categories, de les quals
**77 s'instal·len** i **19 són només del Mac**.

Les que són només del Mac porten `win_equivalent`, que diu qui els fa la feina
aquí. No surten al `run.ps1`: `Select-CatalogPackages` les deixa fora perquè no
hi ha res a instal·lar. Si alguna es queda sense `win_equivalent`, el rol `apps`
la reclama al final del run com a decisió pendent.
