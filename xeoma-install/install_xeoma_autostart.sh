#!/bin/bash
set -e

USER_NAME="vmadmin"
HOME_DIR="/home/$USER_NAME"
XEOMA_DIR="$HOME_DIR/Xeoma"
XEOMA_URL="https://felenasoft.com/xeoma/downloads/2018-06-14/linux/xeoma_linux64.tgz"

echo "==> Installing X server and minimal Openbox environment..."
# Install Xorg, xinit and Openbox window manager
apt update
apt install -y xorg xinit openbox wget

echo "==> Downloading and installing Xeoma..."
# Create Xeoma directory
mkdir -p "$XEOMA_DIR"
cd /tmp

# Download and unpack Xeoma
wget -O xeoma.tgz "$XEOMA_URL"
tar -xvzf xeoma.tgz

# Move Xeoma to user's home directory
mv xeoma.app "$XEOMA_DIR/"
chmod +x "$XEOMA_DIR/xeoma.app"

# Install Xeoma as core service
cd "$XEOMA_DIR"
./xeoma.app -install -coreauto

echo "==> Setting ownership..."
# Ensure correct owner
chown -R "$USER_NAME:$USER_NAME" "$XEOMA_DIR"

echo "==> Creating .xinitrc..."
# Create xinitrc to launch Xeoma in fullscreen
cat > "$HOME_DIR/.xinitrc" <<EOF
#!/bin/sh
# Start Openbox session
openbox-session &
# Launch Xeoma client in fullscreen mode
exec $XEOMA_DIR/xeoma.app -client -fullscreen
EOF

chmod +x "$HOME_DIR/.xinitrc"
chown "$USER_NAME:$USER_NAME" "$HOME_DIR/.xinitrc"

echo "==> Configuring .profile autostart for startx..."
# Append startx auto-launch to .profile
cat >> "$HOME_DIR/.profile" <<'EOF'

# Auto-start X session on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF

chown "$USER_NAME:$USER_NAME" "$HOME_DIR/.profile"

echo "==> Configuring automatic login on tty1..."
# Create override configuration for autologin
mkdir -p /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

echo "==> Reloading systemd..."
# Reload systemd for changes to take effect
systemctl daemon-reexec

echo "==> Xeoma installed. To view the password for client connection run:"
echo "$XEOMA_DIR/xeoma.app -showpassword"

echo "==> Installation complete. Reboot required!"
echo "Run: reboot"
