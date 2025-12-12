#!/bin/bash
set -e

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Use: sudo bash install_xeoma_v2.sh"
    exit 1
fi

echo "==> Enter the username that will run Xeoma:"
read -r USER_NAME

# Check user exists
if ! id "$USER_NAME" >/dev/null 2>&1; then
    echo "ERROR: User '$USER_NAME' does not exist."
    echo "Create user with: sudo adduser <name>"
    exit 1
fi

HOME_DIR="/home/$USER_NAME"
XEOMA_DIR="$HOME_DIR/Xeoma"
XEOMA_URL="https://felenasoft.com/xeoma/downloads/2018-06-14/linux/xeoma_linux64.tgz"

# --- Check if Xeoma is already installed ---
echo "==> Checking existing Xeoma installation..."

XEOMA_CORE="/usr/local/Xeoma/xeoma.app"
XEOMA_LOCAL="$XEOMA_DIR/xeoma.app"

if [ -f "$XEOMA_CORE" ] || [ -f "$XEOMA_LOCAL" ]; then
    echo "WARNING: Xeoma appears to be already installed."

    if [ -f "$XEOMA_CORE" ]; then
        echo " - Core service found at: $XEOMA_CORE"
    fi

    if [ -f "$XEOMA_LOCAL" ]; then
        echo " - Local installation found at: $XEOMA_LOCAL"
    fi

    echo
    echo "Do you want to continue and REINSTALL Xeoma? (yes/no)"
    read -r answer
    if [ "$answer" != "yes" ]; then
        echo "Installation aborted."
        exit 0
    fi

    echo "Proceeding with reinstall..."
fi

# --- Check if Xeoma is currently running ---
echo "==> Checking if Xeoma is running..."

if pgrep -f "xeoma.app" >/dev/null 2>&1; then
    echo "WARNING: Xeoma is currently running on this system."

    echo "Do you want to stop Xeoma before installation? (yes/no)"
    read -r stop_answer

    if [ "$stop_answer" = "yes" ]; then
        echo "Stopping Xeoma core and client..."
        # Try standard stop
        if [ -f "$XEOMA_CORE" ]; then
            "$XEOMA_CORE" -stop || true
        fi

        # Kill any leftover processes
        pkill -f "xeoma.app" || true
        sleep 1

        echo "Xeoma stopped."
    else
        echo "Proceeding without stopping Xeoma (NOT recommended)."
    fi
else
    echo "Xeoma is not running."
fi

# ------------------------------------------------------------

echo "==> Installing X server and minimal Openbox environment..."
apt update
apt install -y xorg xinit openbox wget

echo "==> Downloading and installing Xeoma..."
mkdir -p "$XEOMA_DIR"
cd /tmp

wget -O xeoma.tgz "$XEOMA_URL"
tar -xvzf xeoma.tgz
mv xeoma.app "$XEOMA_DIR/"
chmod +x "$XEOMA_DIR/xeoma.app"

cd "$XEOMA_DIR"
./xeoma.app -install -coreauto

echo "==> Setting ownership..."
chown -R "$USER_NAME:$USER_NAME" "$XEOMA_DIR"

echo "==> Creating .xinitrc..."
cat > "$HOME_DIR/.xinitrc" <<EOF
#!/bin/sh
openbox-session &
exec $XEOMA_DIR/xeoma.app -client -fullscreen
EOF

chmod +x "$HOME_DIR/.xinitrc"
chown "$USER_NAME:$USER_NAME" "$HOME_DIR/.xinitrc"

echo "==> Configuring .profile autostart for startx..."
cat >> "$HOME_DIR/.profile" <<'EOF'

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF

chown "$USER_NAME:$USER_NAME" "$HOME_DIR/.profile"

echo "==> Configuring automatic login on tty1..."
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

echo "==> Reloading systemd..."
systemctl daemon-reexec

echo "==> Xeoma installed. To view the password for client connection run:"
echo "$XEOMA_DIR/xeoma.app -showpassword"

echo "==> Installation complete. Reboot required!"
echo "Run: reboot"

