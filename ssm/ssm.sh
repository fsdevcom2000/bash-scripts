#!/bin/bash
set -e

SERVICE_DIR="/etc/systemd/system"

print_menu() {
    echo
    echo "=== Systemd Service Manager ==="
    echo "1) Create service"
    echo "2) Delete service"
    echo "3) Restart service"
    echo "4) Reload systemd configuration"
    echo "5) Enable auto-start"
    echo "6) Disable auto-start"
    echo "0) Exit"
    echo
}

create_service() {
    echo "Enter service name (without .service):"
    read SERVICE_NAME

    if [[ -z "$SERVICE_NAME" ]]; then
        echo "Name cannot be empty."
        return
    fi
    
    SERVICE_FILE="$SERVICE_DIR/$SERVICE_NAME.service"

    if [[ -f "$SERVICE_FILE" ]]; then
        echo "Service '$SERVICE_NAME' already exists!"
        return
    fi

    echo "Enter service description:"
    read DESCRIPTION

    echo "Enter path to executable file/script:"
    read EXEC_PATH

    if [[ ! -f "$EXEC_PATH" ]]; then
        echo "File '$EXEC_PATH' not found. Continue anyway? (y/n)"
        read YN
        [[ "$YN" != "y" ]] && return
    fi

    echo "Enter user (default root):"
    read RUN_USER
    [[ -z "$RUN_USER" ]] && RUN_USER="root"

    echo "Creating service..."

    cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=$DESCRIPTION
After=network.target

[Service]
Type=simple
ExecStart=$EXEC_PATH
Restart=always
RestartSec=3
User=$RUN_USER

[Install]
WantedBy=multi-user.target
EOF

    echo "Service created: $SERVICE_FILE"

    echo "Reloading systemd..."
    sudo systemctl daemon-reload

    echo "Start service now? (y/n)"
    read START_NOW
    [[ "$START_NOW" == "y" ]] && sudo systemctl start "$SERVICE_NAME"

    echo "Enable auto-start? (y/n)"
    read ENABLE_NOW
    [[ "$ENABLE_NOW" == "y" ]] && sudo systemctl enable "$SERVICE_NAME"

    echo "Done."
}

delete_service() {
    echo "Enter service name to delete:"
    read SERVICE_NAME

    SERVICE_FILE="$SERVICE_DIR/$SERVICE_NAME.service"

    if [[ ! -f "$SERVICE_FILE" ]]; then
        echo "Service '$SERVICE_NAME' not found."
        return
    fi

    echo "Stopping and disabling service..."
    sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true

    echo "Deleting service file..."
    sudo rm -f "$SERVICE_FILE"

    sudo systemctl daemon-reload

    echo "Service '$SERVICE_NAME' deleted."
}

restart_service() {
    echo "Enter service name to restart:"
    read SERVICE_NAME

    sudo systemctl restart "$SERVICE_NAME" && echo "Done."
}

reload_systemd() {
    sudo systemctl daemon-reload
    echo "systemd reloaded."
}

enable_service() {
    echo "Enter service name:"
    read SERVICE_NAME
    sudo systemctl enable "$SERVICE_NAME" && echo "Auto-start enabled."
}

disable_service() {
    echo "Enter service name:"
    read SERVICE_NAME
    sudo systemctl disable "$SERVICE_NAME" && echo "Auto-start disabled."
}


# === MAIN LOOP ===

while true; do
    print_menu
    read -p "Select option: " choice
    case $choice in
        1) create_service ;;
        2) delete_service ;;
        3) restart_service ;;
        4) reload_systemd ;;
        5) enable_service ;;
        6) disable_service ;;
        0) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
done