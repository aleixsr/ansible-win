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
> motor és PowerShell. Vegeu [Equivalències](docs/DISSENY.md#equivalències-amb-ansible-mac).

<!-- INDEX:INICI -->
## Índex

- [Què fa](#què-fa)
- [Requisits](#requisits)
- [Instal·lació](#instal·lació)
- [Ús](#ús)
- [Configuració](#configuració)
- [Què instal·la](#què-instal·la)
- [Què ajusta](#què-ajusta)
- [Documentació](#documentació)
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
     PowerShell com a `cmd.exe`. Vegeu [`sudo` sense la `g`](docs/AJUSTOS.md#sudo-sense-la-g)
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
   `desktop` d'`ansible-mac`. Vegeu [Ajustos que aplica](docs/AJUSTOS.md#ajustos-que-aplica)
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
un sol cop al final. El detall és a
[Les dues fases del run](docs/DISSENY.md#les-dues-fases-del-run).

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

## Què instal·la

<!-- APPS:INICI -->

El catàleg són **78 aplicacions** en 17 categories, de les quals **14 són
opcionals**: no s'instal·len si no les demanes. 19 entrades més vénen del
catàleg del Mac i aquí no apliquen.

La llista sencera, amb què fa cadascuna i un enllaç al seu projecte, és a
**[docs/APPS.md](docs/APPS.md)**.
<!-- APPS:FI -->

Per triar què entra i què no:

```powershell
.\run.ps1                                 # només l'essencial
.\run.ps1 -Full                           # també tot l'opcional
.\run.ps1 -Optional obsidian,tailscale    # l'essencial i aquests dos
.\run.ps1 -Upgrade                        # posa al dia el que ja tens
```

Vegeu [Software opcional](docs/DISSENY.md#software-opcional) i
[Posar les apps al dia](docs/DISSENY.md#posar-les-apps-al-dia).

## Què ajusta

Explorador de fitxers, barra de tasques, aparença, privadesa, ratolí i touchpad,
mode desenvolupador i l'acció en tancar la tapa del portàtil. També treu el
bloatware de Windows 11 i evita que torni.

Tot surt de la secció `system:` i `debloat:` de [`config.yml`](config.yml). El
raonament de cada ajust és a **[docs/AJUSTOS.md](docs/AJUSTOS.md)**; el del
bloatware, a
[Treure el bloatware](docs/DISSENY.md#treure-el-bloatware-de-windows-11).

## Documentació

| | |
|---|---|
| **[docs/APPS.md](docs/APPS.md)** | El catàleg sencer: què fa cada app, d'on surt i la paritat amb `ansible-mac` |
| **[docs/AJUSTOS.md](docs/AJUSTOS.md)** | Què es toca de Windows i per què, `sudo` inclòs |
| **[docs/DISSENY.md](docs/DISSENY.md)** | Les dues fases del run, el software opcional, el bloatware i els paquets que no són a cap gestor |

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
scripts/Export-AppsTable.ps1     Regenera docs/APPS.md i el README des de config.yml
docs/
  APPS.md                        El catàleg sencer i la paritat amb el Mac
  AJUSTOS.md                     Què es toca de Windows i per què
  DISSENY.md                     Les dues fases, l'opcional, el bloatware
```

## Notes

- Les tasques són idempotents: els fitxers només s'escriuen si el contingut
  difereix, els valors del registre només si el valor actual no és el desitjat, i
  els paquets es comproven abans d'instal·lar-los
- Un paquet que falla **no atura el run**: es reporta com a `failed` i el
  provisionament continua. El `PLAY RECAP` final llista tots els errors
- Els `.ps1` es guarden en **UTF-8 amb BOM** a propòsit: Windows PowerShell 5.1
  llegeix els scripts com a ANSI si no el troben, i els accents es trenquen.
  L'excepció és `bootstrap.ps1`, que és **ASCII i sense BOM**: com que es baixa
  i s'executa amb `irm ... | iex`, un BOM hi arribaria com un caràcter dins de
  la cadena i el parser petaria. Sense BOM, els accents es trencarien en
  executar-lo com a fitxer; per això no en té cap. Ho diu ell mateix al capdamunt
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
