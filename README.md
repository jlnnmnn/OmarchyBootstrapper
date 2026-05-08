# OmarchyBootstrapper

Post-install bootstrap script for [Omarchy](https://omarchy.org) (Arch Linux + Hyprland).
Run once on a fresh install to configure your system — safe to re-run at any time.

## What it does

| Section | What gets configured |
|---|---|
| Packages | Installs apps from pacman and AUR via yay |
| Display | Writes Hyprland monitor config with the right resolution and scale |
| Keybindings | Appends a custom keybinding section to your Hyprland bindings config |
| School WiFi | Creates a WPA2 Enterprise (TTLS/MSCHAPv2) NetworkManager connection |

## Usage

```bash
bash bootstrap.sh
```

The script will ask before running each section. You can skip any section you don't need.

## Pre-configuration

Open `bootstrap.sh` and fill in the variables at the top to skip interactive prompts:

```bash
MACHINE=""        # "laptop" or "desktop" — determines monitor resolution and scale
SCHOOL_SSID=""    # School WiFi network name
SCHOOL_USER=""    # School WiFi username
SCHOOL_PASS=""    # School WiFi password (leave empty to always prompt)

PACMAN_PACKAGES=( ... )   # Official repo packages to install
AUR_PACKAGES=( ... )      # AUR packages to install via yay
```

Any value left empty will be asked for when the script runs.

> **Note:** Never commit `SCHOOL_PASS` with a real password to version control.

## Installed packages

Pre-configured AUR packages:

- `visual-studio-code-bin` — VSCode
- `dbeaver` — Database client
- `brave-bin` — Brave browser
- `nextcloud-client` — Nextcloud desktop sync
- `nwg-displays` — GUI monitor management for wlroots compositors

Add your own packages to `PACMAN_PACKAGES` or `AUR_PACKAGES` in the script.

## Display configuration

| Machine | Resolution | Scale |
|---|---|---|
| `laptop` | 1920×1080 @ 60Hz | 1.25 |
| `desktop` | 3840×2160 @ 60Hz | 1.6 |

After the initial setup, use `nwg-displays` to manage monitor layout when connecting external displays or a beamer.

## Logs

A full log of every action is written to `~/bootstrap.log` after each run.
