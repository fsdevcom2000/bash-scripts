#!/usr/bin/env bash
# ====================================================================================================
# Name:        install_xeoma_autostart.sh
# Description: Install Xeoma and configure graphical autostart (autologin tty1 -> startx -> Xeoma client)
#              on Ubuntu  Server.
# Author: fsdevcom2000
# URL: https://github.com/fsdevcom2000/bash-scripts/tree/main/xeoma-install
#
# Usage:       sudo ./install_xeoma_autostart.sh [-u USER] [-y] [-h]
# Env:         XEOMA_URL     - override download URL
#              XEOMA_SHA256  - if set, the downloaded archive is verified against this checksum
# ====================================================================================================

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/var/log/xeoma-install.log"
readonly DEFAULT_URL="https://felenasoft.com/xeoma/downloads/2018-06-14/linux/xeoma_linux64.tgz"
readonly XEOMA_URL="${XEOMA_URL:-$DEFAULT_URL}"
readonly XEOMA_SHA256="${XEOMA_SHA256:-}"
readonly XEOMA_CORE="/usr/local/Xeoma/xeoma.app"
readonly MARKER_BEGIN="# >>> xeoma-autostart >>>"
readonly MARKER_END="# <<< xeoma-autostart <<<"

USER_NAME=""
ASSUME_YES=0
TMP_DIR=""

log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
warn() { log "WARNING: $*" >&2; }
die()  { log "ERROR: $*" >&2; exit 1; }

usage() {
    cat <<EOF
Usage: sudo $SCRIPT_NAME [-u USER] [-y] [-h]
  -u USER  user that will run Xeoma (prompted if omitted)
  -y       non-interactive: answer "yes" to all questions
  -h       show this help
EOF
}

cleanup() {
    [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}
on_error() {
    log "ERROR: failed at line $1 (exit code $2). See $LOG_FILE" >&2
}
trap cleanup EXIT
trap 'on_error "$LINENO" "$?"' ERR

confirm() {
    local prompt="$1" answer
    (( ASSUME_YES )) && return 0
    [[ -t 0 ]] || die "Interactive confirmation required but stdin is not a terminal. Use -y."
    read -r -p "$prompt (yes/no): " answer
    [[ "$answer" == "yes" ]]
}

backup_if_differs() {
    # backup_if_differs <existing_file> <new_file>
    local target="$1" new="$2"
    if [[ -f "$target" ]] && ! cmp -s "$target" "$new"; then
        cp -a "$target" "$target.bak.$(date +%Y%m%d%H%M%S)"
        log "Backup created: $target.bak.*"
    fi
}

# Args
while getopts ":u:yh" opt; do
    case "$opt" in
        u) USER_NAME="$OPTARG" ;;
        y) ASSUME_YES=1 ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

# Preconditions
[[ $EUID -eq 0 ]] || die "Run as root: sudo $SCRIPT_NAME"

mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

command -v apt-get >/dev/null 2>&1 || die "apt-get not found: only Debian/Ubuntu is supported."
command -v systemctl >/dev/null 2>&1 || die "systemd is required."

if [[ -z "$USER_NAME" ]]; then
    [[ -t 0 ]] || die "Username not specified. Use -u USER."
    read -r -p "Enter the username that will run Xeoma: " USER_NAME
fi
[[ -n "$USER_NAME" ]] || die "Empty username."
id "$USER_NAME" >/dev/null 2>&1 || die "User '$USER_NAME' does not exist (create: sudo adduser $USER_NAME)."

HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
[[ -n "$HOME_DIR" && -d "$HOME_DIR" ]] || die "Home directory of '$USER_NAME' not found."
USER_GROUP="$(id -gn "$USER_NAME")"
XEOMA_DIR="$HOME_DIR/Xeoma"
XEOMA_LOCAL="$XEOMA_DIR/xeoma.app"

log "Start: user=$USER_NAME home=$HOME_DIR url=$XEOMA_URL"

# Existing installation
if [[ -f "$XEOMA_CORE" || -f "$XEOMA_LOCAL" ]]; then
    warn "Xeoma appears to be already installed."
    [[ -f "$XEOMA_CORE"  ]] && log " - core:  $XEOMA_CORE"
    [[ -f "$XEOMA_LOCAL" ]] && log " - local: $XEOMA_LOCAL"
    confirm "Continue and REINSTALL Xeoma?" || { log "Aborted by user."; exit 0; }
fi

# Running instance
if pgrep -f 'xeoma\.app' >/dev/null 2>&1; then
    warn "Xeoma is currently running."
    if confirm "Stop Xeoma before installation?"; then
        [[ -x "$XEOMA_CORE" ]] && "$XEOMA_CORE" -stop || true
        pkill -f 'xeoma\.app' || true
        sleep 2
        if pgrep -f 'xeoma\.app' >/dev/null 2>&1; then
            warn "Processes did not stop gracefully, forcing termination (SIGKILL)."
            pkill -9 -f 'xeoma\.app' || true
        fi
        log "Xeoma stopped."
    else
        warn "Continuing without stopping Xeoma (not recommended)."
    fi
fi

# Packages
log "Installing X server and Openbox..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends xorg xinit openbox wget ca-certificates

# Download
TMP_DIR="$(mktemp -d)"
log "Downloading Xeoma..."
wget --tries=3 --timeout=30 --retry-connrefused -q -O "$TMP_DIR/xeoma.tgz" "$XEOMA_URL" \
    || die "Download failed: $XEOMA_URL"

if [[ -n "$XEOMA_SHA256" ]]; then
    echo "$XEOMA_SHA256  $TMP_DIR/xeoma.tgz" | sha256sum -c - >/dev/null \
        || die "SHA256 mismatch for downloaded archive."
    log "SHA256 verified."
else
    warn "XEOMA_SHA256 not set: archive integrity is not verified."
fi

tar -xzf "$TMP_DIR/xeoma.tgz" -C "$TMP_DIR" || die "Failed to extract archive."
[[ -f "$TMP_DIR/xeoma.app" ]] || die "xeoma.app not found in archive."

# Install
install -d -m 755 -o "$USER_NAME" -g "$USER_GROUP" "$XEOMA_DIR"
install -m 755 "$TMP_DIR/xeoma.app" "$XEOMA_LOCAL"

log "Installing Xeoma core (autostart service)..."
( cd "$XEOMA_DIR" && ./xeoma.app -install -coreauto )
[[ -x "$XEOMA_CORE" ]] || warn "Core binary not found at $XEOMA_CORE after installation; verify that the core is installed."

chown -R "$USER_NAME:$USER_GROUP" "$XEOMA_DIR"

# .xinitrc
log "Configuring .xinitrc..."
XINITRC="$HOME_DIR/.xinitrc"
XINITRC_NEW="$TMP_DIR/xinitrc"
cat > "$XINITRC_NEW" <<EOF
#!/bin/sh
openbox-session &
exec "$XEOMA_LOCAL" -client -fullscreen
EOF
backup_if_differs "$XINITRC" "$XINITRC_NEW"
install -m 755 -o "$USER_NAME" -g "$USER_GROUP" "$XINITRC_NEW" "$XINITRC"

# .profile (idempotent block)
log "Configuring .profile autostart of startx..."
PROFILE="$HOME_DIR/.profile"
if [[ ! -f "$PROFILE" ]]; then
    install -m 644 -o "$USER_NAME" -g "$USER_GROUP" /dev/null "$PROFILE"
fi
if grep -qF "$MARKER_BEGIN" "$PROFILE"; then
    log ".profile already configured, skipping."
else
    cat >> "$PROFILE" <<EOF

$MARKER_BEGIN
if [ -z "\${DISPLAY:-}" ] && [ "\$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
$MARKER_END
EOF
    chown "$USER_NAME:$USER_GROUP" "$PROFILE"
fi
if [[ -f "$HOME_DIR/.bash_profile" || -f "$HOME_DIR/.bash_login" ]]; then
    warn "~/.bash_profile or ~/.bash_login exists: bash will ignore ~/.profile. Add the startx block there manually."
fi

# Autologin on tty1
log "Configuring autologin on tty1..."
GETTY_DIR="/etc/systemd/system/getty@tty1.service.d"
GETTY_CONF="$GETTY_DIR/override.conf"
GETTY_NEW="$TMP_DIR/override.conf"
cat > "$GETTY_NEW" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF
mkdir -p "$GETTY_DIR"
backup_if_differs "$GETTY_CONF" "$GETTY_NEW"
install -m 644 "$GETTY_NEW" "$GETTY_CONF"

systemctl daemon-reload

log "Installation complete."
log "To show the client password run:"
log "  $XEOMA_LOCAL -showpassword"
log "Reboot required: reboot"
log "Log file: $LOG_FILE"