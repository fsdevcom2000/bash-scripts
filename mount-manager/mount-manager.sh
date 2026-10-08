#!/bin/bash
set -euo pipefail

sudo -v

FSTAB_BAK=$(mktemp /tmp/fstab.bak.XXXXXX)
FSTAB_MODIFIED=0

cleanup() {
    local rc=$?
    if [ "$FSTAB_MODIFIED" -eq 1 ]; then
        echo "Error occurred. Restoring original /etc/fstab..." >&2
        sudo cp "$FSTAB_BAK" /etc/fstab
        sudo systemctl daemon-reload 2>/dev/null || true
    fi
    rm -f "$FSTAB_BAK"
    exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

echo "==> Searching for ext4 partitions..."

mapfile -t PARTITIONS < <(lsblk -rpno NAME,FSTYPE | awk '$2=="ext4"{print $1}')

if [ ${#PARTITIONS[@]} -eq 0 ]; then
    echo "No ext4 partitions found."
    exit 1
fi

echo "Available ext4 partitions:"
lsblk -fp -o NAME,FSTYPE,SIZE,LABEL,MOUNTPOINT "${PARTITIONS[@]}"
echo

PARTITION=""
echo "Select a partition to mount:"
select PARTITION in "${PARTITIONS[@]}"; do
    if [ -n "${PARTITION:-}" ]; then
        break
    fi
    echo "Invalid selection, try again."
done

if [ -z "${PARTITION:-}" ]; then
    echo "No partition selected."
    exit 1
fi

if [ ! -b "$PARTITION" ]; then
    echo "Block device not found: $PARTITION"
    exit 1
fi

if findmnt -rn -S "$PARTITION" >/dev/null; then
    echo "$PARTITION is already mounted at: $(findmnt -rno TARGET -S "$PARTITION" | paste -sd, -)"
    exit 1
fi

echo
read -rp "Enter mount point [/mnt/data]: " MOUNTPOINT
MOUNTPOINT=${MOUNTPOINT:-/mnt/data}

while [ "${#MOUNTPOINT}" -gt 1 ] && [[ "$MOUNTPOINT" == */ ]]; do
    MOUNTPOINT=${MOUNTPOINT%/}
done

if [[ "$MOUNTPOINT" != /* || "$MOUNTPOINT" =~ [[:space:]] ]]; then
    echo "Mount point must be an absolute path without spaces."
    exit 1
fi

if [ "$MOUNTPOINT" = "/" ]; then
    echo "Refusing to use / as a mount point."
    exit 1
fi

if mountpoint -q "$MOUNTPOINT" 2>/dev/null; then
    echo "$MOUNTPOINT is already a mount point."
    exit 1
fi

if awk -v mp="$MOUNTPOINT" '$1 !~ /^#/ && $2 == mp { found=1 } END { exit !found }' /etc/fstab; then
    echo "$MOUNTPOINT is already used in /etc/fstab."
    exit 1
fi

if [ -d "$MOUNTPOINT" ] && [ -n "$(sudo ls -A "$MOUNTPOINT" 2>/dev/null)" ]; then
    read -rp "Mount point is not empty (contents will be hidden while mounted). Continue? [y/N]: " CONFIRM
    [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]] || exit 1
fi

UUID=$(sudo blkid -s UUID -o value "$PARTITION" || true)
if [ -z "$UUID" ]; then
    echo "Failed to obtain UUID for $PARTITION"
    exit 1
fi

if grep -qE "^[[:space:]]*UUID=$UUID[[:space:]]" /etc/fstab; then
    echo "Entry for this UUID already exists in /etc/fstab."
    exit 1
fi

echo "==> Creating mount point: $MOUNTPOINT"
sudo mkdir -p "$MOUNTPOINT"

echo "==> Backing up /etc/fstab"
sudo cp /etc/fstab "$FSTAB_BAK"
PERM_BAK="/etc/fstab.bak.$(date +%Y%m%d-%H%M%S)"
sudo cp -p /etc/fstab "$PERM_BAK"
echo "    Permanent backup: $PERM_BAK"

FSTAB_LINE="UUID=$UUID $MOUNTPOINT ext4 defaults,nofail 0 2"

echo "==> Adding fstab entry..."
FSTAB_MODIFIED=1
echo "$FSTAB_LINE" | sudo tee -a /etc/fstab >/dev/null

sudo systemctl daemon-reload 2>/dev/null || true

echo "==> Mounting..."
sudo mount "$MOUNTPOINT"

FSTAB_MODIFIED=0

echo
echo "Partition $PARTITION successfully mounted at $MOUNTPOINT."
echo "Automatic mounting enabled in /etc/fstab."