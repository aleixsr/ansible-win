# Ajustos del sistema

Què toca `ansible-win` de Windows, i per què. El catàleg de tot plegat és a
[`config.yml`](../config.yml), secció `system:`; aquí hi ha el raonament.

Torna al [README](../README.md).

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
