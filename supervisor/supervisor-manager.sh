#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

_tmpfile=""
SELECTED_CONFIG=""

# Gloval variables
APP_NAME=""
FILE_NAME=""
APP_DIR=""
APP_FILE=""
AUTOSTART=false
AUTORESTART=false
RUN_USER=""

cleanup() {
    [[ -n "${_tmpfile}" && -f "${_tmpfile}" ]] && rm -f "${_tmpfile}"
}
trap cleanup EXIT

###############################################################################
# Privileged wrapper
###############################################################################
run_elev() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        "$@" || {
            echo "Failed to execute privileged command: $*"
            exit 1
        }
    fi
}

###############################################################################
# Supervisor check
###############################################################################
require_supervisor() {
    if ! command -v supervisorctl >/dev/null 2>&1; then
        echo "Supervisor is not installed."

        read -r -p "Install supervisor now? (y/N): " choice
        choice=${choice:-N}

        if [[ "${choice,,}" =~ ^y(es)?$ ]]; then
            run_elev apt update -y
            run_elev apt install -y supervisor
        else
            echo "Supervisor is required. Aborting."
            exit 1
        fi
    fi
}

ensure_supervisor_running() {
    if command -v systemctl >/dev/null 2>&1; then
        if ! run_elev systemctl is-active --quiet supervisor; then
            echo "Supervisor is not running. Starting..."
            run_elev systemctl enable --now supervisor
            sleep 1
        fi
    fi
}

###############################################################################
# CREATE CONFIG FUNCTIONS
###############################################################################
ask_app_info() {
    read -r -p "Enter program name: " APP_NAME
    [[ -z "$APP_NAME" ]] && { echo "Program name cannot be empty."; exit 1; }

    read -r -p "Enter config file name (without .conf) [${APP_NAME}]: " FILE_NAME
    FILE_NAME=${FILE_NAME:-$APP_NAME}

    read -r -p "Enter application directory: " APP_DIR
    APP_DIR=${APP_DIR%/}
    [[ ! -d "$APP_DIR" ]] && { echo "Directory not found: $APP_DIR"; exit 1; }

    read -r -p "Enter full path to .py file: " APP_FILE
    [[ ! -f "$APP_FILE" ]] && { echo "File not found: $APP_FILE"; exit 1; }

    read -r -p "Enable autostart? (y/N): " auto_in
    AUTOSTART=false
    [[ "${auto_in,,}" =~ ^y(es)?$ ]] && AUTOSTART=true

    read -r -p "Enable autorestart? (y/N): " restart_in
    AUTORESTART=false
    [[ "${restart_in,,}" =~ ^y(es)?$ ]] && AUTORESTART=true

    read -r -p "User to run under (default root): " RUN_USER
    RUN_USER=${RUN_USER:-root}
}

validate_user_exists() {
    if ! getent passwd "$RUN_USER" >/dev/null 2>&1; then
        echo "User '$RUN_USER' does not exist."
        exit 1
    fi
}

find_python() {
    command -v python3 || { echo "python3 not found"; exit 1; }
}

prepare_logs() {
    local app_name="$1"
    local run_user="$2"

    # make sure that the /var/log directory exists
    run_elev mkdir -p /var/log

    local stderr="/var/log/${app_name}.err.log"
    local stdout="/var/log/${app_name}.out.log"

    run_elev touch "$stderr" "$stdout"
    run_elev chown "${run_user}:${run_user}" "$stderr" "$stdout"
    run_elev chmod 0640 "$stderr" "$stdout"

    # return separate lines for mapfile
    echo "$stderr"
    echo "$stdout"
}

write_config() {
    local app_name="$1"
    local file_name="$2"
    local app_dir="$3"
    local app_file="$4"
    local autostart="$5"
    local autorestart="$6"
    local run_user="$7"
    local python_bin="$8"
    local stderr="$9"
    local stdout="${10}"

    local conf="/etc/supervisor/conf.d/${file_name}.conf"
    _tmpfile=$(mktemp)

    cat > "$_tmpfile" <<EOF
[program:${app_name}]
command=${python_bin} ${app_file}
directory=${app_dir}
autostart=${autostart}
autorestart=${autorestart}
stderr_logfile=${stderr}
stdout_logfile=${stdout}
user=${run_user}
redirect_stderr=true
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
EOF

    run_elev mv "$_tmpfile" "$conf"
    _tmpfile=""
    run_elev chmod 0644 "$conf"

    echo "$conf"
}

reload_supervisor() {
    run_elev supervisorctl reread
    run_elev supervisorctl update
}

start_program() {
    run_elev supervisorctl start "$1" || true
}

create_config_flow() {
    ask_app_info
    validate_user_exists

    PYTHON_BIN=$(find_python)
    mapfile -t LOGS < <(prepare_logs "$APP_NAME" "$RUN_USER")
    STDERR_LOG="${LOGS[0]}"
    STDOUT_LOG="${LOGS[1]}"

    CONF_PATH=$(write_config "$APP_NAME" "$FILE_NAME" "$APP_DIR" "$APP_FILE" "$AUTOSTART" "$AUTORESTART" "$RUN_USER" "$PYTHON_BIN" "$STDERR_LOG" "$STDOUT_LOG")

    reload_supervisor
    start_program "$APP_NAME"

    echo "Created and started: $APP_NAME"
}

###############################################################################
# DELETE CONFIG FUNCTIONS
###############################################################################
list_and_select_config() {
    shopt -s nullglob
    local files=(/etc/supervisor/conf.d/*.conf)

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No config files found in /etc/supervisor/conf.d/"
        shopt -u nullglob
        return 1
    fi

    echo "=== Available configs ==="
    local idx=1
    for f in "${files[@]}"; do
        local prog_name
        prog_name=$(basename "$f" .conf)
        local status
        status=$(supervisorctl status "$prog_name" 2>/dev/null || echo "UNKNOWN")
        echo "[$idx] $(basename "$f") — $status"
        idx=$((idx+1))
    done
    echo "[0] Cancel / Return to main menu"
    echo

    read -r -p "Enter number to delete (0 to cancel): " sel

    if ! [[ "$sel" =~ ^[0-9]+$ ]]; then
        echo "Invalid selection."
        shopt -u nullglob
        return 1
    fi

    if (( sel == 0 )); then
        echo "Action canceled, returning to main menu."
        shopt -u nullglob
        return 1
    fi

    if (( sel < 1 || sel >= idx )); then
        echo "Number out of range."
        shopt -u nullglob
        return 1
    fi

    SELECTED_CONFIG="${files[$((sel-1))]}"
    shopt -u nullglob
}

delete_config_flow() {
    list_and_select_config || return 0
    config="$SELECTED_CONFIG"
    program_name=$(basename "$config" .conf)

    echo "Selected: $config (program: $program_name)"

    status=$(supervisorctl status "$program_name" 2>/dev/null || echo "UNKNOWN")
    if [[ "$status" =~ RUNNING ]]; then
        echo "Program '$program_name' is running. Stopping..."
        run_elev supervisorctl stop "$program_name"
    fi

    read -r -p "Are you sure you want to delete this config? (y/N): " c
    c=${c:-N}

    if [[ "${c,,}" =~ ^y(es)?$ ]]; then
        # Define the names of the logs according to the template
        stderr="/var/log/${program_name}.err.log"
        stdout="/var/log/${program_name}.out.log"

        run_elev rm -f "$config"
        reload_supervisor
        echo "Config '$program_name' removed."

        # Ask, delete logs or not
        read -r -p "Delete associated log files ($stderr, $stdout)? (y/N): " lc
        lc=${lc:-N}
        if [[ "${lc,,}" =~ ^y(es)?$ ]]; then
            run_elev rm -f "$stderr" "$stdout"
            echo "Log files removed."
        else
            echo "Log files preserved."
        fi
    else
        echo "Canceled."
    fi
}

###############################################################################
# MENU
###############################################################################
menu() {
    echo "=============================="
    echo " Supervisor Manager"
    echo "=============================="
    echo "1) Create config"
    echo "2) Delete config"
    echo "3) Exit"
    echo "=============================="
    read -r -p "Select: " opt

    case "$opt" in
        1) create_config_flow ;;
        2) delete_config_flow ;;
        3) exit 0 ;;
        *) echo "Invalid option." ;;
    esac
}

###############################################################################
# MAIN LOOP
###############################################################################
main() {
    require_supervisor
    ensure_supervisor_running

    while true; do
        menu
        echo
    done
}

main "$@"
