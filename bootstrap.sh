#!/usr/bin/env bash
# OmarchyBootstrapper — post-install setup for Omarchy (Arch Linux + Hyprland)
# Run on a fresh Omarchy install. Safe to re-run.

# Load credentials from .env if present (takes precedence over defaults below)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[[ -f "$SCRIPT_DIR/.env" ]] && source "$SCRIPT_DIR/.env"

# ============================================================
# PRE-CONFIGURATION
# Fill in these values to skip interactive prompts.
# Leave empty ("") to be prompted at runtime.
# Values set in .env override these defaults.
# ============================================================

MACHINE="${MACHINE:-}"          # "laptop" or "desktop"

SCHOOL_SSID="${SCHOOL_SSID:-}"  # School WiFi SSID
SCHOOL_USER="${SCHOOL_USER:-}"  # School WiFi username
SCHOOL_PASS="${SCHOOL_PASS:-}"  # School WiFi password (leave empty to always prompt)

# Packages to install from official repos (pacman -S)
PACMAN_PACKAGES=(
  # Examples — uncomment or add your own:
  # "git"
  # "curl"
  # "ripgrep"
  # "fd"
  "eog"
  "gnome-boxes"
)

# Packages to install from the AUR (via yay)
AUR_PACKAGES=(
  "visual-studio-code-bin"
  "dbeaver"
  "brave-bin"
  "nextcloud-client"
  "nwg-displays"
  # Examples — uncomment or add your own:
  # "spotify"
  # "discord"
  # "slack-desktop"
)

# ============================================================
# INTERNALS — do not edit below unless you know what you're doing
# ============================================================

LOG_FILE="$HOME/bootstrap.log"
HYPR_MONITORS="$HOME/.config/hypr/monitors.conf"
HYPR_BINDINGS="$HOME/.config/hypr/bindings.conf"
BOOTSTRAP_MARKER="# === BOOTSTRAP CUSTOM BINDINGS ==="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${BLUE}[INFO]${NC}  $*" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}[OK]${NC}    $*" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "$LOG_FILE"; }
err()     { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; }

ask_section() {
  local name="$1"
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  $name${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  read -rp "Run this section? [Y/n] " yn
  [[ "$yn" =~ ^[Nn] ]] && return 1 || return 0
}

prompt_value() {
  local -n _ref="$1"
  local msg="$2"
  local secret="${3:-false}"
  if [[ "$secret" == "true" ]]; then
    read -rsp "$msg: " _ref; echo ""
  else
    read -rp "$msg: " _ref
  fi
}

# ============================================================
# SECTION 1: PACKAGES
# ============================================================
install_packages() {
  log "Updating package database..."
  if ! sudo pacman -Sy --noconfirm >> "$LOG_FILE" 2>&1; then
    warn "Package database update failed. Continuing anyway."
  fi

  if [[ ${#PACMAN_PACKAGES[@]} -gt 0 ]]; then
    log "Installing official repo packages..."
    for pkg in "${PACMAN_PACKAGES[@]}"; do
      if pacman -Qi "$pkg" &>/dev/null; then
        log "$pkg — already installed, skipping."
      else
        log "Installing $pkg..."
        if sudo pacman -S --noconfirm "$pkg" >> "$LOG_FILE" 2>&1; then
          success "$pkg installed."
        else
          warn "Failed to install $pkg."
        fi
      fi
    done
  else
    log "No official repo packages configured."
  fi

  if [[ ${#AUR_PACKAGES[@]} -gt 0 ]]; then
    log "Installing AUR packages via yay..."
    if ! command -v yay &>/dev/null; then
      warn "yay not found. Skipping AUR packages."
      return
    fi
    for pkg in "${AUR_PACKAGES[@]}"; do
      if pacman -Qi "$pkg" &>/dev/null; then
        log "$pkg — already installed, skipping."
      else
        log "Installing $pkg (AUR)..."
        if yay -S --noconfirm "$pkg" >> "$LOG_FILE" 2>&1; then
          success "$pkg installed."
        else
          warn "Failed to install $pkg."
        fi
      fi
    done
  else
    log "No AUR packages configured."
  fi

  success "Package installation complete."
}

# ============================================================
# SECTION 2: DISPLAY CONFIGURATION
# ============================================================
configure_display() {
  if [[ -z "$MACHINE" ]]; then
    echo ""
    echo "Which machine is this?"
    echo "  1) laptop   (1920x1080, scale 1.25)"
    echo "  2) desktop  (3840x2160, scale 1.6)"
    read -rp "Enter choice [1/2]: " choice
    case "$choice" in
      1) MACHINE="laptop" ;;
      2) MACHINE="desktop" ;;
      *) warn "Invalid choice. Skipping display configuration."; return ;;
    esac
  fi

  local monitor_line=""
  case "$MACHINE" in
    laptop)  monitor_line="monitor=,1920x1080@60,auto,1.25" ;;
    desktop) monitor_line="monitor=,3840x2160@60,auto,1.6" ;;
    *)
      warn "Unknown MACHINE value '$MACHINE'. Use 'laptop' or 'desktop'."
      return
      ;;
  esac

  log "Writing monitor config for $MACHINE..."
  cat > "$HYPR_MONITORS" <<EOF
# Bootstrap monitor configuration — machine: ${MACHINE}
# nwg-displays will regenerate this file when used for GUI monitor management.
${monitor_line}
EOF
  success "Monitor config written to $HYPR_MONITORS."
}

# ============================================================
# SECTION 3: KEYBINDINGS
# ============================================================
configure_keybindings() {
  if grep -qF "$BOOTSTRAP_MARKER" "$HYPR_BINDINGS" 2>/dev/null; then
    warn "Bootstrap keybindings already present in $HYPR_BINDINGS. Skipping."
    return
  fi

  log "Appending custom keybinding section to $HYPR_BINDINGS..."
  cat >> "$HYPR_BINDINGS" <<'EOF'

# === BOOTSTRAP CUSTOM BINDINGS ===
# Add your personal keybinds here.
# Syntax: bindd = MODKEY, KEY, Description, exec, command
# To override an existing Omarchy bind, first unbind it:
#   unbind = MODKEY, KEY
#
# Examples:
#
# Override the browser shortcut to use Brave explicitly:
# unbind = SUPER SHIFT, B
# bindd = SUPER SHIFT, B, Brave Browser, exec, uwsm-app -- brave
#
# Open VSCode with a shortcut:
# bindd = SUPER SHIFT, V, VSCode, exec, uwsm-app -- code
#
# Screenshot a region to clipboard:
# bindd = SUPER ALT, S, Screenshot region, exec, hyprshot -m region --clipboard-only
#
# Lock the screen:
# bindd = SUPER, L, Lock screen, exec, hyprlock
# === END BOOTSTRAP CUSTOM BINDINGS ===
EOF
  success "Keybinding template appended to $HYPR_BINDINGS."
}

# ============================================================
# SECTION 4: SCHOOL WIFI
# ============================================================
configure_school_wifi() {
  if [[ -z "$SCHOOL_SSID" ]]; then
    prompt_value SCHOOL_SSID "School WiFi SSID"
  fi
  if [[ -z "$SCHOOL_SSID" ]]; then
    warn "No SSID provided. Skipping WiFi configuration."
    return
  fi

  local conn_file="/etc/NetworkManager/system-connections/${SCHOOL_SSID}.nmconnection"
  if [[ -f "$conn_file" ]]; then
    warn "Connection '$SCHOOL_SSID' already exists at $conn_file. Skipping."
    return
  fi

  if [[ -z "$SCHOOL_USER" ]]; then
    prompt_value SCHOOL_USER "Username for $SCHOOL_SSID"
  fi
  if [[ -z "$SCHOOL_USER" ]]; then
    warn "No username provided. Skipping WiFi configuration."
    return
  fi

  if [[ -z "$SCHOOL_PASS" ]]; then
    prompt_value SCHOOL_PASS "Password for $SCHOOL_SSID" "true"
  fi
  if [[ -z "$SCHOOL_PASS" ]]; then
    warn "No password provided. Skipping WiFi configuration."
    return
  fi

  log "Writing NetworkManager connection file for '$SCHOOL_SSID'..."
  sudo tee "$conn_file" > /dev/null <<EOF
[connection]
id=${SCHOOL_SSID}
type=wifi
autoconnect=true

[wifi]
ssid=${SCHOOL_SSID}
mode=infrastructure

[wifi-security]
key-mgmt=wpa-eap

[802-1x]
eap=ttls
identity=${SCHOOL_USER}
password=${SCHOOL_PASS}
phase2-auth=mschapv2

[ipv4]
method=auto

[ipv6]
method=auto
addr-gen-mode=default

[proxy]
EOF

  sudo chmod 600 "$conn_file"
  sudo chown root:root "$conn_file"
  success "Connection file written to $conn_file."

  log "Reloading NetworkManager..."
  if sudo nmcli connection reload; then
    success "NetworkManager reloaded. Connect with: nmcli connection up '${SCHOOL_SSID}'"
  else
    warn "Failed to reload NetworkManager. Run manually: sudo nmcli connection reload"
  fi
}

# ============================================================
# MAIN
# ============================================================
main() {
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║        OmarchyBootstrapper               ║${NC}"
  echo -e "${GREEN}║  Arch Linux + Hyprland post-install      ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
  echo ""

  : > "$LOG_FILE"
  log "Bootstrap started at $(date)"
  echo "Log file: $LOG_FILE"

  ask_section "1/4 — Package Installation"  && install_packages
  ask_section "2/4 — Display Configuration" && configure_display
  ask_section "3/4 — Keybindings"           && configure_keybindings
  ask_section "4/4 — School WiFi"           && configure_school_wifi

  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  Bootstrap complete!${NC}"
  echo -e "${GREEN}  Full log: $LOG_FILE${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  log "Bootstrap finished at $(date)"
}

main "$@"
