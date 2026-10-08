#!/bin/bash
#
# Industrial Video Server - initial network setup
# Ubuntu Server 18.04, local console only.


set -u

NETPLAN_FILE="/etc/netplan/99-video-server-network.yaml"
NETPLAN_TMP="/etc/netplan/.99-video-server-network.yaml.tmp"
BACKUP_BASE="/var/backups/video-server-network"
CLOUD_CFG="/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"

BACKUP_DIR=""
BACKUP_HAD_FILES=0
CONFIG_CHANGED=0
CLOUD_CFG_CREATED=0
FOREIGN_FILES=""

PHYSICAL_INTERFACES=()
SELECTED_INTERFACES=()
declare -A ADDR_BY_IFACE=()

NETWORK_INT=0
BROADCAST_INT=0
IP_INT=0


die() {
    echo
    echo "ERROR: $1"
    exit 1
}


ask() {
    local prompt="$1"
    local var

    read -r -p "$prompt" var || {
        echo
        echo "Input closed. Exiting."
        exit 1
    }

    REPLY_VALUE="$var"
}



confirm() {
    ask "$1 [Y/n]: "

    case "$REPLY_VALUE" in
        n|N|no|NO|No) return 1 ;;
        *) return 0 ;;
    esac
}


confirm_no() {
    ask "$1 [y/N]: "

    case "$REPLY_VALUE" in
        y|Y|yes|YES|Yes) return 0 ;;
        *) return 1 ;;
    esac
}

require_root() {
    [ "$(id -u)" -eq 0 ] || die "This script must be run as root."
}

check_commands() {
    local cmd
    local commands="ip awk sort head grep cat cp mv rm mkdir chmod date sleep netplan reboot basename"

    for cmd in $commands; do
        command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
    done
}

check_os() {
    local version_id=""
    local id=""

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        id="$(. /etc/os-release && echo "${ID:-}")"
        # shellcheck disable=SC1091
        version_id="$(. /etc/os-release && echo "${VERSION_ID:-}")"
    fi

    if [ "$id" != "ubuntu" ] || [ "$version_id" != "18.04" ]; then
        echo
        echo "WARNING: this script is intended for Ubuntu Server 18.04."
        echo "Detected: ${id:-unknown} ${version_id:-unknown}"
        echo
        confirm_no "Continue anyway?" || {
            echo "Cancelled."
            exit 0
        }
    fi
}

is_remote_session() {
    local w

    [ -n "${SSH_CONNECTION:-}" ] && return 0
    [ -n "${SSH_CLIENT:-}" ] && return 0
    [ -n "${SSH_TTY:-}" ] && return 0


    if command -v who >/dev/null 2>&1; then
        w="$(who am i 2>/dev/null)"
        case "$w" in
            *"(:"*) ;;                 # local X display, not remote
            *"("*")"*) return 0 ;;     # (hostname or IP) => remote login
        esac
    fi

    return 1
}

check_remote_session() {
    if is_remote_session; then
        echo
        echo "WARNING: this looks like a remote (SSH) session."
        echo "Applying the new network configuration will most likely"
        echo "drop your connection and may leave the server unreachable."
        echo
        confirm_no "Continue anyway?" || {
            echo "Cancelled."
            exit 0
        }
    fi
}


restore_backup() {
    local file
    local name
    local old_dir=""

    echo
    echo "Restoring previous Netplan configuration..."

    rm -f "$NETPLAN_FILE" "$NETPLAN_TMP"

    if [ -n "$BACKUP_DIR" ]; then
        old_dir="$BACKUP_DIR/old-config"
    fi

    if [ -n "$old_dir" ] && [ -d "$old_dir" ]; then
        shopt -s nullglob

        for file in "$old_dir"/*.yaml "$old_dir"/*.yml; do
            [ -f "$file" ] || continue
            name="$(basename "$file")"
            mv "$file" "/etc/netplan/$name"
        done

        shopt -u nullglob
    fi

    if [ "$CLOUD_CFG_CREATED" -eq 1 ]; then
        rm -f "$CLOUD_CFG"
        CLOUD_CFG_CREATED=0
    fi

    if ! netplan generate >/dev/null 2>&1; then
        echo "WARNING: 'netplan generate' failed after restore. Check /etc/netplan manually."
    fi

    if ! netplan apply >/dev/null 2>&1; then
        echo "WARNING: 'netplan apply' failed after restore. Check the network manually."
    fi

    CONFIG_CHANGED=0

    echo "Previous configuration restored."
    if [ -n "$BACKUP_DIR" ]; then
        echo "Backup copy is kept in: $BACKUP_DIR"
    fi
}

on_interrupt() {
    echo
    echo "Interrupted."

    rm -f "$NETPLAN_TMP"

    if [ "$CONFIG_CHANGED" -eq 1 ]; then
        restore_backup
    fi

    exit 1
}

trap on_interrupt INT TERM HUP


get_interfaces() {
    local path
    local iface
    local sorted

    PHYSICAL_INTERFACES=()

    for path in /sys/class/net/*; do
        [ -e "$path" ] || continue

        iface="${path##*/}"

        # Exclude loopback and virtual interfaces.
        [ "$iface" = "lo" ] && continue
        [ -e "/sys/class/net/$iface/device" ] || continue

        # Exclude Wi-Fi.
        [ -d "/sys/class/net/$iface/wireless" ] && continue
        [ -d "/sys/class/net/$iface/phy80211" ] && continue

        # ARPHRD_ETHER
        [ "$(cat "/sys/class/net/$iface/type" 2>/dev/null)" = "1" ] || continue

        PHYSICAL_INTERFACES+=("$iface")
    done

    [ "${#PHYSICAL_INTERFACES[@]}" -gt 0 ] ||
        die "No physical Ethernet interfaces were detected."

    sorted="$(printf '%s\n' "${PHYSICAL_INTERFACES[@]}" | sort -V)"

    PHYSICAL_INTERFACES=()
    while IFS= read -r iface; do
        [ -n "$iface" ] && PHYSICAL_INTERFACES+=("$iface")
    done <<< "$sorted"
}


bring_links_up() {
    local iface
    local t all_up

    echo
    echo "Bringing Ethernet links up to detect cable state..."

    for iface in "${PHYSICAL_INTERFACES[@]}"; do
        ip link set dev "$iface" up >/dev/null 2>&1 || true
    done

    # Auto-negotiation can take several seconds. Wait up to 8 s,
    # stop early if every link is already up.
    for t in 1 2 3 4 5 6 7 8; do
        sleep 1

        all_up=1
        for iface in "${PHYSICAL_INTERFACES[@]}"; do
            if [ "$(get_link_status "$iface")" != "UP" ]; then
                all_up=0
                break
            fi
        done

        [ "$all_up" -eq 1 ] && break
    done
}

get_mac() {
    cat "/sys/class/net/$1/address" 2>/dev/null
}

get_link_status() {
    local iface="$1"
    local carrier_file="/sys/class/net/$iface/carrier"

    if [ "$(cat "$carrier_file" 2>/dev/null)" = "1" ]; then
        echo "UP"
    else
        echo "DOWN"
    fi
}

get_ipv4() {
    ip -o -4 addr show dev "$1" 2>/dev/null |
        awk '{print $4}' |
        head -n 1
}


mac_usable_for_match() {
    local iface="$1"
    local mac other count=0

    mac="$(get_mac "$iface")"

    [[ "$mac" =~ ^([0-9a-f]{2}:){5}[0-9a-f]{2}$ ]] || return 1
    [ "$mac" != "00:00:00:00:00:00" ] || return 1

    for other in "${PHYSICAL_INTERFACES[@]}"; do
        [ "$(get_mac "$other")" = "$mac" ] && count=$((count + 1))
    done

    [ "$count" -eq 1 ]
}

show_interfaces() {
    local i iface mac link ipv4

    echo
    echo "============================================================"
    echo " Detected physical Ethernet interfaces"
    echo "============================================================"
    printf "%-4s %-12s %-8s %-20s %-18s\n" \
        "#" "Interface" "Link" "MAC" "IPv4"
    echo "------------------------------------------------------------"

    for i in "${!PHYSICAL_INTERFACES[@]}"; do
        iface="${PHYSICAL_INTERFACES[$i]}"
        mac="$(get_mac "$iface")"
        link="$(get_link_status "$iface")"
        ipv4="$(get_ipv4 "$iface")"

        [ -n "$ipv4" ] || ipv4="-"

        printf "%-4s %-12s %-8s %-20s %-18s\n" \
            "$((i + 1))" "$iface" "$link" "$mac" "$ipv4"
    done

    echo "============================================================"
    echo
}


valid_ipv4_octet() {
    local value="$1"

    [[ "$value" =~ ^(0|[1-9][0-9]{0,2})$ ]] || return 1
    [ "$value" -le 255 ] || return 1

    return 0
}

ipv4_to_int() {
    local a b c d

    IFS='.' read -r a b c d <<< "$1"

    echo $(( (10#$a << 24) + (10#$b << 16) + (10#$c << 8) + 10#$d ))
}


get_network_info() {
    local cidr="$1"
    local ip="${cidr%/*}"
    local prefix="${cidr#*/}"
    local host_bits mask

    IP_INT="$(ipv4_to_int "$ip")"

    host_bits=$((32 - 10#$prefix))
    mask=$(( (0xFFFFFFFF << host_bits) & 0xFFFFFFFF ))

    NETWORK_INT=$((IP_INT & mask))
    BROADCAST_INT=$((NETWORK_INT + (1 << host_bits) - 1))
}


validate_ipv4_cidr() {
    local cidr="$1"
    local ip prefix
    local a b c d

    [[ "$cidr" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]] || {
        echo "Invalid format. Use a.b.c.d/prefix, for example 172.20.111.22/24."
        return 1
    }

    ip="${cidr%/*}"
    prefix="${cidr#*/}"

    IFS='.' read -r a b c d <<< "$ip"

    valid_ipv4_octet "$a" && valid_ipv4_octet "$b" &&
    valid_ipv4_octet "$c" && valid_ipv4_octet "$d" || {
        echo "Invalid IPv4 address (octets must be 0-255, no leading zeros)."
        return 1
    }

    [[ "$prefix" =~ ^(0|[1-9][0-9]?)$ ]] || {
        echo "Invalid prefix (no leading zeros)."
        return 1
    }

    if [ "$prefix" -lt 8 ] || [ "$prefix" -gt 30 ]; then
        echo "Prefix must be between /8 and /30."
        return 1
    fi

    if [ "$a" -eq 0 ] || [ "$a" -eq 127 ] || [ "$a" -ge 224 ]; then
        echo "Address range not allowed (0.x, 127.x, multicast and reserved)."
        return 1
    fi

    if [ "$a" -eq 169 ] && [ "$b" -eq 254 ]; then
        echo "Link-local range 169.254.x.x is not allowed."
        return 1
    fi

    get_network_info "$cidr"

    if [ "$IP_INT" -eq "$NETWORK_INT" ]; then
        echo "This is the network address, not a host address."
        return 1
    fi

    if [ "$IP_INT" -eq "$BROADCAST_INT" ]; then
        echo "This is the broadcast address, not a host address."
        return 1
    fi

    return 0
}

subnets_overlap() {
    local net1 broad1 net2 broad2

    get_network_info "$1"
    net1="$NETWORK_INT"
    broad1="$BROADCAST_INT"

    get_network_info "$2"
    net2="$NETWORK_INT"
    broad2="$BROADCAST_INT"

    [ "$net1" -le "$broad2" ] && [ "$net2" -le "$broad1" ]
}


select_interfaces() {
    local selection token index iface i valid found

    while true; do
        echo
        echo "Select Ethernet interfaces to configure."
        echo
        echo "Examples:"
        echo "  all       - configure all detected interfaces"
        echo "  1 2       - configure interfaces 1 and 2"
        echo "  1 3 4     - configure interfaces 1, 3 and 4"
        echo "  q         - quit"
        echo

        ask "Selection: "
        selection="$REPLY_VALUE"

        [ -n "$selection" ] || continue

        if [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
            echo "Cancelled."
            exit 0
        fi

        SELECTED_INTERFACES=()

        if [ "$selection" = "all" ] || [ "$selection" = "ALL" ]; then
            SELECTED_INTERFACES=("${PHYSICAL_INTERFACES[@]}")
            return
        fi

        valid=1

        for token in $selection; do
            if ! [[ "$token" =~ ^[1-9][0-9]*$ ]]; then
                valid=0
                break
            fi

            index=$((token - 1))

            if [ "$index" -ge "${#PHYSICAL_INTERFACES[@]}" ]; then
                valid=0
                break
            fi

            iface="${PHYSICAL_INTERFACES[$index]}"

            found=0
            for i in "${SELECTED_INTERFACES[@]}"; do
                if [ "$i" = "$iface" ]; then
                    found=1
                    break
                fi
            done

            [ "$found" -eq 0 ] && SELECTED_INTERFACES+=("$iface")
        done

        if [ "$valid" -eq 1 ] && [ "${#SELECTED_INTERFACES[@]}" -gt 0 ]; then
            return
        fi

        echo
        echo "Invalid selection."
    done
}


configure_addresses() {
    local iface address configured_iface conflict

    ADDR_BY_IFACE=()

    for iface in "${SELECTED_INTERFACES[@]}"; do
        echo
        echo "------------------------------------------------------------"
        echo "Configuration for: $iface"
        echo "MAC:  $(get_mac "$iface")"
        echo "Link: $(get_link_status "$iface")"
        echo "------------------------------------------------------------"
        echo
        echo "Enter static IPv4 address in CIDR format (prefix /8 - /30)."
        echo "Example: 172.20.111.22/24"
        echo

        while true; do
            ask "IPv4 for $iface: "
            address="$REPLY_VALUE"

            [ -n "$address" ] || continue

            validate_ipv4_cidr "$address" || continue

            conflict=""

            for configured_iface in "${!ADDR_BY_IFACE[@]}"; do
                if subnets_overlap "$address" "${ADDR_BY_IFACE[$configured_iface]}"; then
                    conflict="$configured_iface (${ADDR_BY_IFACE[$configured_iface]})"
                    break
                fi
            done

            if [ -n "$conflict" ]; then
                echo
                echo "This network overlaps with $conflict."
                echo "Each configured Ethernet interface must use a separate network."
                echo
                continue
            fi

            break
        done

        ADDR_BY_IFACE["$iface"]="$address"
    done
}


is_selected() {
    [ -n "${ADDR_BY_IFACE[$1]:-}" ]
}

# Detect existing Netplan sections that this script will remove.
detect_foreign_config() {
    local file

    FOREIGN_FILES=""

    shopt -s nullglob

    for file in /etc/netplan/*.yaml /etc/netplan/*.yml; do
        [ -f "$file" ] || continue
        [ "$file" = "$NETPLAN_FILE" ] && continue

        if grep -qE '^[[:space:]]*(bridges|bonds|vlans|wifis|tunnels|vrfs):' "$file" 2>/dev/null; then
            FOREIGN_FILES="$FOREIGN_FILES $file"
        fi
    done

    shopt -u nullglob
}

show_summary() {
    local iface
    local unselected=0
    local nomatch=0

    echo
    echo "============================================================"
    echo " Network configuration summary"
    echo "============================================================"
    echo
    printf "%-12s %-18s %-8s %-6s\n" "Interface" "IPv4" "Link" "Match"
    echo "------------------------------------------------------------"

    for iface in "${PHYSICAL_INTERFACES[@]}"; do
        local match="name"
        mac_usable_for_match "$iface" && match="MAC"
        [ "$match" = "name" ] && nomatch=1

        if is_selected "$iface"; then
            printf "%-12s %-18s %-8s %-6s\n" \
                "$iface" "${ADDR_BY_IFACE[$iface]}" "$(get_link_status "$iface")" "$match"
        else
            printf "%-12s %-18s %-8s %-6s\n" \
                "$iface" "not configured" "$(get_link_status "$iface")" "$match"
            unselected=1
        fi
    done

    echo "------------------------------------------------------------"
    echo "DHCP4:       disabled"
    echo "DHCP6:       disabled"
    echo "IPv6 RA:     disabled"
    echo "Gateway:     none"
    echo "DNS:         none"
    echo "Boot wait:   disabled for Ethernet links (optional: true)"
    echo "Renderer:    systemd-networkd"
    echo "cloud-init:  network configuration will be disabled"
    echo "Matching:    by MAC address where possible (stable across renames)"
    echo "============================================================"

    if [ "$nomatch" -eq 1 ]; then
        echo
        echo "NOTE: interfaces marked 'name' have a missing or duplicate MAC,"
        echo "so they will be matched by interface name only."
    fi

    if [ "$unselected" -eq 1 ]; then
        echo
        echo "WARNING: interfaces marked 'not configured' will have NO IP"
        echo "address after this change (all old network settings are removed)."
    fi

    detect_foreign_config

    if [ -n "$FOREIGN_FILES" ]; then
        echo
        echo "WARNING: existing Netplan files contain bridges/bonds/vlans/wifis/"
        echo "tunnels/vrfs that will be REMOVED from the active configuration:"
        for f in $FOREIGN_FILES; do
            echo "  $f"
        done
    fi

    echo
}


backup_netplan() {
    local timestamp file
    local found=0

    timestamp="$(date '+%Y%m%d-%H%M%S')"
    BACKUP_DIR="$BACKUP_BASE/$timestamp"

    mkdir -p "$BACKUP_DIR/old-config" || die "Cannot create backup directory."
    chmod 700 "$BACKUP_BASE" "$BACKUP_DIR" 2>/dev/null || true

    shopt -s nullglob

    for file in /etc/netplan/*.yaml /etc/netplan/*.yml; do
        [ -f "$file" ] || continue

        found=1
        cp -a "$file" "$BACKUP_DIR/" || die "Failed to backup $file"
    done

    shopt -u nullglob

    BACKUP_HAD_FILES="$found"

    if [ "$found" -eq 1 ]; then
        echo "Existing Netplan configuration backed up to:"
        echo "  $BACKUP_DIR"
    else
        echo "No existing Netplan YAML files found."
    fi
}


generate_netplan_tmp() {
    local iface mac

    rm -f "$NETPLAN_TMP"

    cat > "$NETPLAN_TMP" <<EOF || die "Cannot write $NETPLAN_TMP"
network:
  version: 2
  renderer: networkd
  ethernets:
EOF

    for iface in "${PHYSICAL_INTERFACES[@]}"; do
        cat >> "$NETPLAN_TMP" <<EOF
    $iface:
EOF

        if mac_usable_for_match "$iface"; then
            mac="$(get_mac "$iface")"
            cat >> "$NETPLAN_TMP" <<EOF
      match:
        macaddress: "$mac"
EOF
        fi

        cat >> "$NETPLAN_TMP" <<EOF
      dhcp4: false
      dhcp6: false
      accept-ra: false
      optional: true
EOF

        if is_selected "$iface"; then
            cat >> "$NETPLAN_TMP" <<EOF
      addresses:
        - ${ADDR_BY_IFACE[$iface]}
EOF
        fi

        echo >> "$NETPLAN_TMP"
    done

    chmod 600 "$NETPLAN_TMP"
}


install_new_config() {
    local file name
    local old_dir="$BACKUP_DIR/old-config"

    # From this point on, a rollback may be required.
    CONFIG_CHANGED=1

    shopt -s nullglob

    # Move ALL existing YAML files (including a previous version of our own
    # file) into old-config so that restore_backup can bring them back.
    for file in /etc/netplan/*.yaml /etc/netplan/*.yml; do
        [ -f "$file" ] || continue

        name="$(basename "$file")"

        mv "$file" "$old_dir/$name" || {
            shopt -u nullglob
            return 1
        }
    done

    shopt -u nullglob

    mv "$NETPLAN_TMP" "$NETPLAN_FILE" || return 1

    echo
    echo "Generated configuration:"
    echo "------------------------------------------------------------"
    cat "$NETPLAN_FILE"
    echo "------------------------------------------------------------"

    return 0
}


disable_cloud_init_network() {
    if [ -d /etc/cloud ]; then
        mkdir -p /etc/cloud/cloud.cfg.d

        if [ ! -e "$CLOUD_CFG" ]; then
            echo 'network: {config: disabled}' > "$CLOUD_CFG" &&
                CLOUD_CFG_CREATED=1
        fi
    fi
}


apply_netplan() {
    echo
    echo "Validating Netplan configuration..."

    if ! netplan generate; then
        echo
        echo "Netplan validation failed."
        echo "Hint: an outdated netplan may not support some options"
        echo "(match, accept-ra). Try: apt install --only-upgrade netplan.io"
        return 1
    fi

    echo "Netplan configuration is valid."
    echo
    echo "Applying network configuration..."

    if ! netplan apply; then
        echo
        echo "Netplan apply failed."
        return 1
    fi

    echo
    echo "Network configuration applied successfully."

    return 0
}



verify_result() {
    local iface expected found tries
    local problems=0

    echo
    echo "Verifying applied addresses..."

    for iface in "${SELECTED_INTERFACES[@]}"; do
        expected="${ADDR_BY_IFACE[$iface]}"
        found=0

        for tries in 1 2 3 4 5 6; do
            if ip -o -4 addr show dev "$iface" 2>/dev/null |
                awk '{print $4}' | grep -qx "$expected"; then
                found=1
                break
            fi

            # No cable: networkd will not assign the address yet, no point waiting.
            [ "$(get_link_status "$iface")" = "UP" ] || break

            sleep 1
        done

        if [ "$found" -eq 1 ]; then
            echo "  OK       $iface  $expected"
        elif [ "$(get_link_status "$iface")" != "UP" ]; then
            echo "  PENDING  $iface  $expected (no cable; address will appear when link is up)"
        else
            echo "  FAILED   $iface  $expected (address not present)"
            problems=1
        fi
    done

    if [ "$problems" -eq 1 ]; then
        echo
        echo "WARNING: some addresses were not applied. Check 'ip -br addr',"
        echo "'networkctl status' and 'journalctl -u systemd-networkd'."
    fi
}


show_result() {
    echo
    echo "============================================================"
    echo " Current network status"
    echo "============================================================"
    echo

    ip -br addr

    echo
    echo "Routes:"
    ip route

    echo
    echo "============================================================"
}

show_rollback_info() {
    echo
    echo "Backup of the previous configuration: $BACKUP_DIR"

    if [ "$BACKUP_HAD_FILES" -eq 1 ]; then
        echo "To roll back manually:"
        echo "  rm -f $NETPLAN_FILE"
        echo "  cp -a $BACKUP_DIR/*.y*ml /etc/netplan/"
        echo "  rm -f $CLOUD_CFG   # only if you want cloud-init to manage the network again"
        echo "  netplan apply"
    else
        echo "There was no previous Netplan configuration to restore."
    fi
}

ask_reboot() {
    echo
    echo "A reboot is recommended: 'netplan apply' may leave old addresses"
    echo "(for example from DHCP) on interfaces until the next boot."
    echo

    if confirm "Reboot the server now?"; then
        echo
        echo "Rebooting..."
        sleep 2
        reboot
    else
        echo
        echo "Configuration is applied and persistent."
        echo "Reboot manually when ready."
    fi
}


require_root
check_commands

clear 2>/dev/null || true

echo "============================================================"
echo " Industrial Video Server Network Setup"
echo " Ubuntu Server 18.04"
echo "============================================================"
echo
echo "This script configures physical Ethernet interfaces using"
echo "Netplan and systemd-networkd."
echo
echo "Static IPv4 only. DHCP, gateway and DNS will not be configured."
echo "IPv6 DHCP and Router Advertisements will be disabled."
echo "All existing Netplan configuration will be replaced"
echo "(a backup is saved in $BACKUP_BASE)."
echo
echo "This script is intended to be run from the local console."
echo

check_remote_session
check_os

confirm "Continue?" || {
    echo "Cancelled."
    exit 0
}

get_interfaces
bring_links_up
show_interfaces

select_interfaces
configure_addresses

show_summary

confirm_no "Apply this configuration?" || {
    echo "Cancelled. Netplan configuration was not changed."
    echo "(Links brought up for cable detection are not persistent.)"
    exit 0
}

echo
echo "Creating Netplan backup..."
backup_netplan

generate_netplan_tmp

echo
echo "Replacing old Netplan configuration..."

if ! install_new_config; then
    restore_backup
    die "Failed to install the new Netplan configuration."
fi

disable_cloud_init_network

if ! apply_netplan; then
    restore_backup
    die "Network configuration was not applied. Previous configuration restored."
fi

CONFIG_CHANGED=0

verify_result
show_result
show_rollback_info
ask_reboot