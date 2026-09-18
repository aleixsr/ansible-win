# ansible_windows

Provisionament reproduïble d'una màquina Windows. És el germà de
[`ansible_mac`](https://github.com/REPLACE_ME/ansible_mac): mateixa idea, mateixa
estructura i, sempre que existeix versió per a Windows, les **mateixes
aplicacions**.

D'una màquina acabada d'instal·lar a una màquina de treball amb una comanda.

```powershell
irm https://raw.githubusercontent.com/REPLACE_ME/ansible_windows/main/bootstrap.ps1 | iex
cd ~\ansible_windows
.\run.ps1
```

---

## Per què no és Ansible de debò

Ansible **no pot córrer nativament a Windows**: el node de control ha de ser
Linux o macOS. Les opcions eren WSL2 + SSH cap al propi Windows (funciona, però
demana reinici, servidor SSH, claus, i `winget` no s'hi porta bé) o un motor
natiu.

Aquest repo tria el motor natiu: **PowerShell**, amb la *forma* d'Ansible.

| Ansible              | Aquí                                    |
| -------------------- | --------------------------------------- |
| `group_vars/all.yml` | `group_vars/all.yml` (mateix fitxer)    |
| `roles/*/tasks/`     | `roles/*/tasks.ps1`                     |
| `ansible-playbook`   | `.\run.ps1`                             |
| `--check`            | `.\run.ps1 -Check`                       |
| `--tags`             | `.\run.ps1 -Roles apps -Groups dev,cli`  |
| `ok / changed`       | mateixa sortida i mateix `PLAY RECAP`    |

Tot és **idempotent**: executar-lo dos cops seguits no canvia res la segona
vegada.

---

## Estructura

```
ansible_windows/
├── bootstrap.ps1                 # d'un Windows verge a poder executar run.ps1
├── run.ps1                       # entrada principal (el "ansible-playbook")
├── group_vars/
│   ├── all.yml                   # ÚNICA font de veritat: apps + tota la config
│   └── local.example.yml         # overrides per màquina (copia'l a local.yml)
├── roles/
│   ├── core/tasks.ps1            # winget · choco · scoop · gsudo · sudo
│   ├── apps/tasks.ps1            # instal·la el catàleg
│   ├── dev/tasks.ps1             # git · SSH · npm -g · uv · extensions VS Code
│   ├── shell/tasks.ps1           # perfil · prompt · mòduls · Windows Terminal
│   ├── system/tasks.ps1          # els "defaults write" de Windows
│   └── dotfiles/tasks.ps1        # symlinks de configuració
├── files/
│   ├── profile.ps1               # el perfil de PowerShell de veritat
│   ├── profile.d/                # fragments generats (sudo, prompt) — gitignored
│   └── windows-terminal.settings.json
├── lib/Provision.psm1            # el motor: idempotència, proveïdors, sortida
├── scripts/Export-AppsTable.ps1  # regenera docs/APPS.md des del catàleg
└── docs/APPS.md                  # taula de paritat macOS ↔ Windows
```

---

## Ús

```powershell
.\run.ps1 -Check                        # simulació: què canviaria
.\run.ps1                                # provisionament complet
.\run.ps1 -Upgrade                       # actualitza el que ja hi ha
.\run.ps1 -ListPackages                  # ensenya el catàleg sencer
.\run.ps1 -Roles apps                    # només instal·la aplicacions
.\run.ps1 -Roles apps -Groups dev,cli    # només aquests grups
.\run.ps1 -Roles system,shell            # només els ajustos
```

`run.ps1` es reobre sol amb privilegis via `gsudo` si li calen. Amb `-NoElevate`
no ho fa (i els ajustos d'`HKLM` se salten amb `skipped`).

### Personalitzar sense tocar el repo

```powershell
Copy-Item group_vars\local.example.yml group_vars\local.yml
notepad group_vars\local.yml
```

`local.yml` està al `.gitignore` i es fusiona **recursivament** sobre `all.yml`.

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

Exemples un cop provisionat:

```powershell
sudo choco upgrade all -y
sudo notepad C:\Windows\System32\drivers\etc\hosts
sudo !!                     # repeteix l'última comanda, elevada (gsudo)
```

---

## El catàleg d'aplicacions

Tot viu a `group_vars/all.yml`. Cada paquet declara el seu id a cada gestor i
**l'equivalent de Homebrew**, perquè la paritat amb `ansible_mac` es pugui
comprovar d'un cop d'ull:

```yaml
- id: ripgrep
  name: ripgrep
  winget: BurntSushi.ripgrep.MSVC
  choco: ripgrep
  brew: ripgrep          # <- el que hi ha a ansible_mac
  test: rg               # si `rg` ja és al PATH, no consultem el gestor
```

L'ordre de proveïdors és `winget → choco → scoop`: s'agafa el primer que estigui
instal·lat i tingui id per a aquest paquet. Es pot forçar amb `provider: choco`
(és el que fan les Nerd Fonts, que no són a winget).

Grups per defecte: `core`, `cli`, `dev`, `browsers`, `productivity`,
`communication`, `media`, `utilities`, `security`, `remote`, `fonts`.
Grups opcionals (només sota demanda): `virtualization`, `gaming`, `hardware`.

La taula completa de paritat és a [docs/APPS.md](docs/APPS.md), i es regenera
amb:

```powershell
.\scripts\Export-AppsTable.ps1
```

### Afegir una aplicació

```powershell
winget search <nom>          # per trobar l'id exacte
choco search <nom>
```

Afegeix l'entrada al grup que toqui de `group_vars/all.yml` i executa
`.\run.ps1 -Roles apps -Check` per validar-ho abans d'aplicar.

---

## Ajustos del sistema

L'equivalent dels `defaults write` de macOS, tot a `system:` del catàleg:
extensions de fitxer visibles, fitxers ocults, barra de tasques a l'esquerra,
tema fosc, sense cerca web al menú Inici, sense id de publicitat, pla d'energia,
mode desenvolupador i rutes llargues.

Els que toquen `HKLM` (mode desenvolupador, rutes llargues, OpenSSH Server, pla
d'energia) necessiten administrador; sense privilegis surten com a `skipped` en
comptes de fallar.

Alguns canvis d'Explorer només es veuen després de reiniciar-lo:

```powershell
Stop-Process -Name explorer -Force
```

---

## Requisits

- Windows 10 21H2 o superior (provat a Windows 11)
- Windows PowerShell 5.1 (el que ve de sèrie) o PowerShell 7+
- `winget` (App Installer). Chocolatey i el mòdul `powershell-yaml` els posa
  `bootstrap.ps1`

---

## Llicència

MIT. Vegeu [LICENSE](LICENSE).
