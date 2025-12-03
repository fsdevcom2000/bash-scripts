#!/bin/bash

set -e

# Ensure sudo session is active
sudo -v

echo "==> Searching for ext4 partitions..."

# Fetch ext4 partitions
PARTITIONS=($(lsblk -rpno NAME,FSTYPE | awk '$2=="ext4"{print $1}'))

# If nothing found, exit
if [ ${#PARTITIONS[@]} -eq 0 ]; then
    echo "No ext4 partitions found."
    exit 1
fi

echo "Available ext4 partitions:"
# Display nicely formatted list with size and label
lsblk -fp -o NAME,FSTYPE,SIZE,LABEL,MOUNTPOINT | grep "ext4"
echo

# Interactive selection using a menu
echo "Select a partition to mount:"
select PARTITION in "${PARTITIONS[@]}"; do
    if [ -n "$PARTITION" ]; then
        break
    fi
    echo "Invalid selection, try again."
done

# Validate block device
if [ ! -b "$PARTITION" ]; then
    echo "Block device not found: $PARTITION"
    exit 1
fi

echo
read -p "Enter mount point [/mnt/data]: " MOUNTPOINT
MOUNTPOINT=${MOUNTPOINT:-/mnt/data}

# Check if mount point already exists and not empty
if [ -d "$MOUNTPOINT" ] && [ -n "$(ls -A "$MOUNTPOINT" 2>/dev/null)" ]; then
    read -p "Mount point is not empty. Continue? [y/N]: " CONFIRM
    [[ "$CONFIRM" != "y" ]] && exit 1
fi

echo "==> Creating mount point: $MOUNTPOINT"
sudo mkdir -p "$MOUNTPOINT"

# Get partition UUID
UUID=$(blkid -s UUID -o value "$PARTITION")
if [ -z "$UUID" ]; then
    echo "Failed to obtain UUID for $PARTITION"
    exit 1
fi

# Prevent duplicate fstab entries
if grep -q "$UUID" /etc/fstab; then
    echo "Entry for this UUID already exists in /etc/fstab."
    exit 1
fi

echo "==> Backing up /etc/fstab -> /etc/fstab.bak"
sudo cp /etc/fstab /etc/fstab.bak

# Add a safe fstab entry
echo "==> Adding fstab entry..."
FSTAB_LINE="UUID=$UUID $MOUNTPOINT ext4 defaults 0 2"
echo "$FSTAB_LINE" | sudo tee -a /etc/fstab >/dev/null

echo "==> Mounting..."
if ! sudo mount "$MOUNTPOINT"; then
    echo "Mount failed. Restoring original fstab..."
    sudo mv /etc/fstab.bak /etc/fstab
    exit 1
fi

echo
echo "Partition $PARTITION successfully mounted at $MOUNTPOINT."
echo "Automatic mounting enabled in /etc/fstab."
