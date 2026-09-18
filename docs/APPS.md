# Paritat d'aplicacions: macOS ↔ Windows

> Generat automàticament per `scripts/Export-AppsTable.ps1` a partir de
> `group_vars/all.yml`. No l'editis a mà.

La columna **Homebrew** és l'equivalent a `ansible_mac`. Serveix per veure
d'un cop d'ull què té paritat real, què té un substitut i què no existeix
per a l'altra plataforma.


## `browsers`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| Brave | `Brave.Brave` | `brave` | — | `brave-browser` |
| Google Chrome | `Google.Chrome` | `googlechrome` | — | `google-chrome` |
| Mozilla Firefox | `Mozilla.Firefox` | `firefox` | — | `firefox` |

## `cli`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| bat | `sharkdp.bat` | `bat` | — | `bat` |
| btop4win | `aristocratos.btop4win` | — | — | `btop` |
| curl | `cURL.cURL` | `curl` | — | `curl` |
| dust | `bootandy.dust` | — | `dust` | `dust` |
| eza | `eza-community.eza` | — | `eza` | `eza` |
| fd | `sharkdp.fd` | `fd` | — | `fd` |
| fzf | `junegunn.fzf` | `fzf` | — | `fzf` |
| Git | `Git.Git` | `git` | — | `git` |
| git-delta | `dandavison.delta` | `delta` | — | `git-delta` |
| GitHub CLI | `GitHub.cli` | `gh` | — | `gh` |
| GNU Make | `ezwinports.make` | `make` | — | `make` |
| Gpg4win | `GnuPG.Gpg4win` | `gpg4win` | — | `gnupg` |
| HTTPie | `HTTPie.HTTPie` | `httpie` | — | `httpie` |
| hyperfine | `sharkdp.hyperfine` | `hyperfine` | — | `hyperfine` |
| ImageMagick | `ImageMagick.ImageMagick` | `imagemagick` | — | `imagemagick` |
| jq | `jqlang.jq` | `jq` | — | `jq` |
| just | `Casey.Just` | `just` | — | `just` |
| lazygit | `JesseDuffield.lazygit` | `lazygit` | — | `lazygit` |
| micro | `zyedidia.micro` | `micro` | — | `micro` |
| Neovim | `Neovim.Neovim` | `neovim` | — | `neovim` |
| Nushell | `Nushell.Nushell` | `nushell` | — | `nushell` |
| OpenSSL | `FireDaemon.OpenSSL` | `openssl` | — | `openssl` |
| Pandoc | `JohnMacFarlane.Pandoc` | `pandoc` | — | `pandoc` |
| ripgrep | `BurntSushi.ripgrep.MSVC` | `ripgrep` | — | `ripgrep` |
| tldr (tlrc) | `tldr-pages.tlrc` | — | — | `tldr` |
| wget | `JernejSimoncic.Wget` | `wget` | — | `wget` |
| yq | `MikeFarah.yq` | `yq` | — | `yq` |
| zoxide | `ajeetdsouza.zoxide` | `zoxide` | — | `zoxide` |

## `communication`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| Discord | `Discord.Discord` | `discord` | — | `discord` |
| Microsoft Teams | `Microsoft.Teams` | — | — | `microsoft-teams` |
| Slack | `SlackTechnologies.Slack` | `slack` | — | `slack` |
| Telegram | `Telegram.TelegramDesktop` | `telegram` | — | `telegram` |
| Zoom | `Zoom.Zoom` | `zoom` | — | `zoom` |

## `core`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| 7-Zip | `7zip.7zip` | `7zip` | — | `p7zip` |
| gsudo | `gerardog.gsudo` | `gsudo` | — | (built-in sudo) |
| PowerShell 7 | `Microsoft.PowerShell` | `powershell-core` | — | `powershell` |
| Sysinternals Suite | `Microsoft.Sysinternals.Suite` | `sysinternals` | — | (n/a) |
| Visual C++ Redistributable | `Microsoft.VCRedist.2015+.x64` | `vcredist140` | — | (n/a) |
| Windows Terminal | `Microsoft.WindowsTerminal` | — | — | `iterm2` |

## `dev`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| .NET SDK 8 | `Microsoft.DotNet.SDK.8` | `dotnet-8.0-sdk` | — | `dotnet-sdk` |
| AWS CLI | `Amazon.AWSCLI` | `awscli` | — | `awscli` |
| Azure CLI | `Microsoft.AzureCLI` | `azure-cli` | — | `azure-cli` |
| Claude Code | `Anthropic.ClaudeCode` | — | — | `claude-code` |
| Claude Desktop | `Anthropic.Claude` | — | — | `claude` |
| DBeaver Community | `DBeaver.DBeaver.Community` | `dbeaver` | — | `dbeaver-community` |
| Docker Desktop | `Docker.DockerDesktop` | `docker-desktop` | — | `docker` |
| fnm (gestor de versions de Node) | `Schniz.fnm` | `fnm` | — | `fnm` |
| Go | `GoLang.Go` | `golang` | — | `go` |
| Helm | `Helm.Helm` | `kubernetes-helm` | — | `helm` |
| k9s | `Derailed.k9s` | `k9s` | — | `k9s` |
| kubectl | `Kubernetes.kubectl` | `kubernetes-cli` | — | `kubernetes-cli` |
| Node.js LTS | `OpenJS.NodeJS.LTS` | `nodejs-lts` | — | `node` |
| Postman | `Postman.Postman` | `postman` | — | `postman` |
| Python 3 | `Python.Python.3.13` | `python313` | — | `python@3.13` |
| Rust (rustup) | `Rustlang.Rustup` | `rustup.install` | — | `rustup` |
| Temurin JDK 21 | `EclipseAdoptium.Temurin.21.JDK` | `temurin21` | — | `temurin` |
| Terraform | `Hashicorp.Terraform` | `terraform` | — | `terraform` |
| uv | `astral-sh.uv` | — | `uv` | `uv` |
| Visual Studio Code | `Microsoft.VisualStudioCode` | `vscode` | — | `visual-studio-code` |
| WinMerge | `WinMerge.WinMerge` | `winmerge` | — | `meld` |

## `fonts`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| CascadiaCode Nerd Font | — | `nerd-fonts-cascadiacode` | — | `font-caskaydia-cove-nerd-font` |
| FiraCode Nerd Font | — | `nerd-fonts-firacode` | — | `font-fira-code-nerd-font` |
| JetBrainsMono Nerd Font | — | `nerd-fonts-jetbrainsmono` | — | `font-jetbrains-mono-nerd-font` |

## `gaming` _(opcional)_

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| Steam | `Valve.Steam` | `steam` | — | `steam` |

## `hardware` _(opcional)_

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| CrystalDiskInfo | `CrystalDewWorld.CrystalDiskInfo` | `crystaldiskinfo` | — | (n/a) |
| HWiNFO | `REALiX.HWiNFO` | `hwinfo` | — | (istat menus) |
| Novabench | `NovabenchInc.Novabench` | — | — | (n/a) |

## `media`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| FFmpeg | `Gyan.FFmpeg` | `ffmpeg` | — | `ffmpeg` |
| GIMP | `GIMP.GIMP` | `gimp` | — | `gimp` |
| HandBrake | `HandBrake.HandBrake` | `handbrake` | — | `handbrake` |
| Inkscape | `Inkscape.Inkscape` | `inkscape` | — | `inkscape` |
| OBS Studio | `OBSProject.OBSStudio` | `obs-studio` | — | `obs` |
| Spotify | `Spotify.Spotify` | `spotify` | — | `spotify` |
| VLC | `VideoLAN.VLC` | `vlc` | — | `vlc` |

## `productivity`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| Adobe Acrobat Reader | `Adobe.Acrobat.Reader.64-bit` | `adobereader` | — | `adobe-acrobat-reader` |
| LibreOffice | `TheDocumentFoundation.LibreOffice` | `libreoffice-fresh` | — | `libreoffice` |
| Microsoft 365 | `Microsoft.Office` | — | — | `microsoft-office` |
| Notepad++ | `Notepad++.Notepad++` | `notepadplusplus` | — | (n/a) |
| Notion | `Notion.Notion` | `notion` | — | `notion` |
| Obsidian | `Obsidian.Obsidian` | `obsidian` | — | `obsidian` |

## `remote`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| AnyDesk | `AnyDesk.AnyDesk` | `anydesk` | — | `anydesk` |
| FileZilla | — | `filezilla` | — | `filezilla` |
| PuTTY | `PuTTY.PuTTY` | `putty` | — | (ssh) |
| RustDesk | — | `rustdesk` | — | `rustdesk` |
| Tailscale | `Tailscale.Tailscale` | `tailscale` | — | `tailscale` |
| WinSCP | `WinSCP.WinSCP` | `winscp` | — | `cyberduck` |

## `security`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| Bitwarden | `Bitwarden.Bitwarden` | `bitwarden` | — | `bitwarden` |
| Cryptomator | `Cryptomator.Cryptomator` | `cryptomator` | — | `cryptomator` |
| KeePassXC | `KeePassXCTeam.KeePassXC` | `keepassxc` | — | `keepassxc` |
| VeraCrypt | `IDRIX.VeraCrypt` | `veracrypt` | — | `veracrypt` |
| Wireshark | `WiresharkFoundation.Wireshark` | `wireshark` | — | `wireshark` |

## `utilities`

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| AutoHotkey | `AutoHotkey.AutoHotkey` | `autohotkey` | — | `hammerspoon` |
| Everything | `voidtools.Everything` | `everything` | — | (spotlight) |
| Explorer++ | `derceg.Explorer++` | `explorerplusplus` | — | (finder) |
| PowerToys | `Microsoft.PowerToys` | `powertoys` | — | (rectangle/raycast) |
| qBittorrent | `qBittorrent.qBittorrent` | `qbittorrent` | — | `qbittorrent` |
| rclone | `Rclone.Rclone` | `rclone` | — | `rclone` |
| Rufus | `Rufus.Rufus` | `rufus` | — | `balenaetcher` |
| ShareX | `ShareX.ShareX` | `sharex` | — | `shottr` |
| Syncthing | `Syncthing.Syncthing` | `syncthing` | — | `syncthing` |
| WizTree | `AntibodySoftware.WizTree` | `wiztree` | — | `grandperspective` |

## `virtualization` _(opcional)_

| Aplicació | winget | Chocolatey | Scoop | Homebrew (mac) |
| --- | --- | --- | --- | --- |
| VirtualBox | `Oracle.VirtualBox` | `virtualbox` | — | `virtualbox` |

---

**105 paquets** en 14 grups.

Llegenda de la columna Homebrew:

- `` `nom` `` — mateixa aplicació a les dues plataformes.
- `(alternativa)` — no existeix a l'altra plataforma; entre parèntesis, el substitut habitual.
- `(n/a)` — específic d'una plataforma, sense equivalent.

