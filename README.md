# ansible-win

Provisionament reproduïble d'una màquina Windows. És el germà de
[`ansible-mac`](https://github.com/aleixsr/ansible-mac): mateixes categories,
mateix catàleg centralitzat a `config.yml` i, app per app, **les mateixes
aplicacions** sempre que existeixin per a Windows.

D'una màquina acabada d'instal·lar a una màquina de treball amb una comanda.

```powershell
irm https://raw.githubusercontent.com/aleixsr/ansible-win/main/bootstrap.ps1 | iex
cd ~\ansible-win
.\run.ps1
```

---

## Per què no és Ansible de debò

Ansible **no pot córrer nativament a Windows**: el node de control ha de ser
Linux o macOS. Les opcions eren WSL2 + SSH cap al propi Windows (funciona, però
demana reinici, servidor SSH, claus, i `winget` no s'hi porta bé) o un motor
natiu.

Aquest repo tria el motor natiu: **PowerShell**, amb la *forma* d'Ansible.

| `ansible-mac`         | `ansible-win`                             |
| --------------------- | ----------------------------------------- |
| `config.yml`          | `config.yml` (mateix nom, mateixa idea)   |
| `roles/*/tasks/main.yml` | `roles/*/tasks.ps1`                    |
| `main.yml` (playbook) | `run.ps1`                                 |
| `ansible-playbook`    | `.\run.ps1`                               |
| `--check`             | `.\run.ps1 -Check`                        |
| `--tags browsers`     | `.\run.ps1 -Roles apps -Groups browsers`  |
| `ok / changed`        | mateixa sortida i mateix `PLAY RECAP`     |
| `homebrew` / `homebrew_cask` | winget / Chocolatey / Scoop        |
| `mas` (App Store)     | `winget --source msstore`                 |

Tot és **idempotent**: executar-lo dos cops seguits no canvia res la segona
vegada.

---

## Paritat amb `ansible-mac`

Les categories de `config.yml` són les mateixes. L'única diferència és que a
Windows no hi ha la distinció fórmula/cask de Homebrew, així que els parells
`packages<x>` + `casks<x>` s'han fusionat en una sola categoria:

| `ansible-mac`                                    | `ansible-win`         |
| ------------------------------------------------ | --------------------- |
| `packagesdevelopment` + `casksdevelopment`        | `development`         |
| `packagesclouddevops`                             | `clouddevops`         |
| `packagesnetworking`                              | `networking`          |
| `packagessystemutilities` + `caskssystemutilities`| `systemutilities`     |
| `casksbrowsers`                                   | `browsers`            |
| `casksterminal`                                   | `terminal`            |
| `caskscommunication`                              | `communication`       |
| `casksproductivity`                               | `productivity`        |
| `casksnetworkingvpn`                              | `networkingvpn`       |
| `casksremoteaccess`                               | `remoteaccess`        |
| `casksfilemanagementcloud`                        | `filemanagementcloud` |
| `casksmicrosoftsuite`                             | `microsoftsuite`      |
| `casksmedia`                                      | `media`               |
| `casksdocuments`                                  | `documents`           |
| `caskshardware`                                   | `hardware`            |
| `mas_apps`                                        | `store`               |
| `startup_apps`                                    | `startup_apps`        |

Cada paquet du anotat **d'on ve al Mac**, així que la paritat es pot auditar:

```yaml
- id: wiztree
  name: WizTree
  winget: AntibodySoftware.WizTree
  choco: wiztree
  mac: disk-inventory-x      # <- el cask equivalent a ansible-mac
```

Les apps del Mac **sense equivalent a Windows** no desapareixen del catàleg: hi
queden amb un `note` que diu per què i quin és el substitut, i surten com a
`skipped` quan executes `run.ps1`.

```yaml
- id: maccy
  name: Maccy
  mac: maccy
  note: "Historial de porta-retalls. A Windows és natiu: Win+V."
```

La taula completa és a [docs/APPS.md](docs/APPS.md), i es regenera amb
`.\scripts\Export-AppsTable.ps1`.

---

## El mateix prompt a les dues màquines

`files/starship.toml` és **byte a byte el mateix fitxer** que
`roles/shell/files/starship.toml` d'`ansible-mac` (Catppuccin Mocha), i starship
el busca a la mateixa ruta a les dues plataformes (`~/.config/starship.toml`).
El tema ja porta el símbol de Windows definit.

També s'hi instal·la la Meslo Nerd Font, com al Mac. El que al Mac fan
`zsh-autosuggestions` i `zsh-syntax-highlighting`, a Windows ho cobreix
PSReadLine, que ja ve de sèrie.

---

## Estructura

```
ansible-win/
├── bootstrap.ps1                 # d'un Windows verge a poder executar run.ps1
├── run.ps1                       # el "ansible-playbook"
├── config.yml                    # ÚNICA font de veritat: apps + tota la config
├── config.local.example.yml      # overrides per màquina (copia'l a config.local.yml)
├── roles/
│   ├── core/tasks.ps1            # winget · choco · scoop · gsudo · sudo
│   ├── apps/tasks.ps1            # instal·la el catàleg
│   ├── shell/tasks.ps1           # perfil · starship · mòduls · Windows Terminal
│   ├── dev/tasks.ps1             # git · SSH · npm -g · uv · extensions VS Code
│   ├── tabby/tasks.ps1           # connectors de Tabby (= rol tabby del Mac)
│   ├── system/tasks.ps1          # = rol desktop del Mac, en versió Windows
│   ├── startup/tasks.ps1         # = rol startup del Mac (Login Items -> Run)
│   └── dotfiles/tasks.ps1        # symlinks de configuració
├── files/
│   ├── profile.ps1               # el perfil de PowerShell (= .zshrc del Mac)
│   ├── starship.toml             # idèntic al d'ansible-mac
│   ├── tabby/package.json        # idèntic al d'ansible-mac
│   ├── profile.d/                # fragments generats (sudo, prompt) — gitignored
│   └── windows-terminal.settings.json
├── lib/Provision.psm1            # el motor: idempotència, proveïdors, sortida
├── scripts/Export-AppsTable.ps1  # regenera docs/APPS.md des de config.yml
└── docs/APPS.md                  # taula de paritat
```

---

## Ús

```powershell
.\run.ps1 -Check                             # simulació: què canviaria
.\run.ps1                                     # provisionament complet
.\run.ps1 -Upgrade                            # actualitza el que ja hi ha
.\run.ps1 -ListPackages                       # ensenya el catàleg sencer
.\run.ps1 -Roles apps                         # només instal·la aplicacions
.\run.ps1 -Roles apps -Groups browsers,terminal
.\run.ps1 -Roles system,shell                 # només els ajustos
```

`run.ps1` es reobre sol amb privilegis via `gsudo` si li calen. Amb `-NoElevate`
no ho fa (i els ajustos d'`HKLM` se salten amb `skipped`).

### Personalitzar sense tocar el repo

```powershell
Copy-Item config.local.example.yml config.local.yml
notepad config.local.yml
```

`config.local.yml` està al `.gitignore` i es fusiona **recursivament** sobre
`config.yml`.

---

## `sudo` sense la `g`

Windows 11 porta el seu propi `C:\Windows\System32\sudo.exe`. Com que el `PATH`
de màquina s'avalua abans que el d'usuari, posar `gsudo` al `PATH` no n'hi ha
prou: el de Microsoft sempre guanyaria.

El rol `core` ho resol per dues bandes:

1. **A PowerShell** — genera `files/profile.d/10-sudo.ps1` amb una *funció*
   `sudo`. A PowerShell, les funcions tenen precedència sobre els executables del
   `PATH`, així que `sudo` és `gsudo` i punt. També deixa `s` com a abreviatura.
2. **A `cmd.exe` i companyia** — genera `bin\sudo.cmd`, que reenvia a `gsudo`, i
   posa `bin\` al davant del `PATH` d'usuari.

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

---

## Afegir una aplicació

```powershell
winget search <nom>          # per trobar l'id exacte
choco search <nom>
```

Afegeix l'entrada a la categoria que toqui de `config.yml`, amb el camp `mac:`
apuntant al que hi ha al repo de macOS, i valida-ho abans d'aplicar:

```powershell
.\run.ps1 -Roles apps -Check
.\scripts\Export-AppsTable.ps1
```

---

## Ajustos del sistema

El rol `desktop` d'`ansible-mac` toca Dock, hot corners i trackpad. A Windows no
hi ha ni Dock ni hot corners, així que l'equivalent és el rol `system`: barra de
tasques, Explorer, tema fosc, privadesa, pla d'energia, mode desenvolupador i
rutes llargues.

Els que toquen `HKLM` necessiten administrador; sense privilegis surten com a
`skipped` en comptes de fallar. Alguns canvis d'Explorer només es veuen després
de reiniciar-lo:

```powershell
Stop-Process -Name explorer -Force
```

El rol `karabiner` del Mac no té rèplica: les seves modificacions (Home/End,
F12 com a Print Screen, drecera de Finder, intercanvi de la tecla ISO…) són
precisament per fer que el Mac es comporti com un Windows. Aquí s'instal·la
**PowerToys**, que és on viu el Keyboard Manager si algun dia cal remapejar res.

---

## Requisits

- Windows 10 21H2 o superior (provat a Windows 11)
- Windows PowerShell 5.1 (el que ve de sèrie) o PowerShell 7+
- `winget` (App Installer). Chocolatey i el mòdul `powershell-yaml` els posa
  `bootstrap.ps1`

---

## Llicència

MIT. Vegeu [LICENSE](LICENSE).
