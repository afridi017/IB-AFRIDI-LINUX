# IB AFRIDI OS

**IB AFRIDI OS** is a user-level Bash startup branding project for Kali Linux and Debian-based systems. It creates a short, cinematic terminal welcome with a custom ASCII wordmark, real local system details, and a clean prompt.

> **This is a terminal customization, not a Linux distribution, security scanner, penetration-testing tool, or hacking simulator.** It does not claim to secure or inspect your machine.

**Creator:** Muhammad Ishaq · **Brand:** IB AFRIDI · **Tagline:** `SECURITY • CODE • BUILD`

## Features

- Custom ASCII **IB AFRIDI** wordmark, with a compact fallback for narrow terminals.
- A brief, presentation-only initialization animation; no fake scan or attack progress.
- Locally detected user, hostname, distribution, kernel, architecture, Bash version, Python version, and uptime.
- A truthful status panel: security is marked **NOT ASSESSED** because no security scan is run; network status reports whether a default route is configured, not whether the internet is reachable.
- Restrained terminal colors when supported; plain-text fallback and `NO_COLOR` support.
- A branded prompt that uses the actual current Bash username, hostname, directory, and root marker.
- Optional, user-only installation. No `sudo` or root access is required.
- Idempotent installer and uninstaller. The installer changes only the user's `~/.bashrc` and installs project files under `${XDG_DATA_HOME:-$HOME/.local/share}/ib-afridi-os`.

## Screenshots

*Screenshot placeholder — add a real terminal capture here after installation, for example `screenshots/ib-afridi-os.png`.*

## Requirements

- Bash (the startup hook is for interactive Bash shells).
- A Kali Linux or Debian-based Linux system is the primary target.
- Standard shell utilities used by the installer (`cp`, `grep`, `awk`, `cmp`, `mktemp`, and `chmod`).
- `tput`, `ip`, and Python are optional. They are checked before use; missing optional tools are handled without preventing startup.

The startup reads local operating-system and uptime information and, when available, local route configuration. It does not make network requests, change firewall or network settings, collect information, or run offensive security tools.

## Installation

Clone the project, then install it for your current user:

```bash
git clone https://github.com/afridi017/IB-AFRIDI-LINUX.git ib-afridi-os
cd ib-afridi-os
chmod +x install.sh
./install.sh
```

Open a **new interactive Bash terminal** to see the startup experience. The installer does not alter the currently running shell. If your terminal uses Zsh or another shell, the Bash hook will not run; this project does not change your login shell.

Installation is confined to your home directory. The project files go to `${XDG_DATA_HOME:-$HOME/.local/share}/ib-afridi-os`, and a marked source block is added to `~/.bashrc`. Existing shell configuration is backed up privately alongside the installed files so it can be restored on uninstall.

## Uninstallation

Run from the cloned project directory:

```bash
./uninstall.sh
```

The uninstaller removes the IB AFRIDI OS installation and its marked `~/.bashrc` block. If `.bashrc` has not changed since installation, it restores the pre-install configuration exactly (or removes `.bashrc` if the installer created it). If the file has since been edited, it removes only the marked block and preserves other edits.

If you installed with a custom absolute `XDG_DATA_HOME`, use the same value when uninstalling, for example:

```bash
XDG_DATA_HOME="$HOME/.local/share-custom" ./uninstall.sh
```

The prompt in an already-open shell may remain until that shell exits; open a new Bash terminal after uninstalling.

## Customization

- Edit `config/theme.sh` to change the displayed brand text and quote.
- Edit `assets/logo.txt` to change the ASCII wordmark.
- Run `./install.sh` again to copy changes into the installed user-level directory.
- Set `IB_AFRIDI_NO_ANIMATION=1` to skip the short animation.
- Set `IB_AFRIDI_NO_CLEAR=1` to keep existing terminal contents.
- Set `NO_COLOR` to disable color output.

The prompt displays the real shell username and hostname rather than forcing `ib@afridi`; it will look like that example only when those are the actual values on the machine.

## Troubleshooting

### Nothing appears in a new terminal

Confirm the terminal is running Bash and that the installer added its marked block to `~/.bashrc`. The startup is shown only in an interactive shell attached to a terminal. Start a new Bash session after installation.

### Colors are missing

This is expected when `NO_COLOR` is set, `TERM` is `dumb`, the output is not a TTY, or `tput` reports no color support. The startup remains readable without color.

### The logo is compact or some lines wrap

The wordmark switches to a compact version when the detected terminal is narrow. Widen the terminal to show the full ASCII logo. Long detected values may be shortened to fit.

### Python shows “Not installed”

Python is optional. The startup checks for `python3` and then `python`; it does not install either one.

### Uninstall reports an incomplete managed block

The uninstaller deliberately stops rather than guessing if the start/end markers in `~/.bashrc` are incomplete or duplicated. Restore a single complete block or remove the broken IB AFRIDI OS marker block manually, then run `./uninstall.sh` again.

## Safety and privacy

IB AFRIDI OS is a visual shell customization. It performs no security scan, does not claim `SECURITY: READY`, and does not test internet reachability. The network label refers only to locally detected default-route configuration. No data is collected or transmitted; no security settings are modified; and no offensive tools are started automatically.

## License

Released under the [MIT License](LICENSE).
