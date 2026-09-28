# Com funciona per dins

Les decisions que no es dedueixen llegint el codi: per què el run va en dues
fases, com es tria el software opcional, què es treu de Windows 11 i com es
manté la paritat amb `ansible-mac`.

Torna al [README](../README.md).

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
