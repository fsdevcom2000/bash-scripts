#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# log file path
LOG_FILE="$SCRIPT_DIR/cron_manager.log"

log() {
    local msg="$1"
    echo "$(date '+%F %T') - $msg" >> "$LOG_FILE"
}

error() {
    echo "Error: $1" >&2
    exit 1
}

ask() {
    local prompt="$1"
    local default="${2:-}"
    if [[ -n "$default" ]]; then
        read -rp "$prompt [$default]: " value
        echo "${value:-$default}"
    else
        read -rp "$prompt: " value
        echo "$value"
    fi
}

validate_cron_field() {
    local field="$1"
    [[ "$field" =~ ^(\*|[0-9]+|\*/[0-9]+|[0-9]+-[0-9]+)$ ]] || return 1
}

list_cron() {
    crontab -l 2>/dev/null | nl -w3 -s'. '
}

add_cron() {
    local cmd minute hour day month weekday comment cron_line tmp_cron

    if [[ -n "${CLI_CMD:-}" && -n "${CLI_CRON:-}" ]]; then
        cron_line="$CLI_CRON $CLI_CMD"
        tmp_cron=$(mktemp)
        crontab -l 2>/dev/null > "$tmp_cron" || true
        {
            [[ -n "${CLI_COMMENT:-}" ]] && echo "# $CLI_COMMENT"
            echo "$cron_line"
        } >> "$tmp_cron"
        crontab "$tmp_cron"
        rm -f "$tmp_cron"
        log "Task added (CLI): $cron_line (Comment: ${CLI_COMMENT:-})"
        echo "Task added."
        return
    fi

    echo "=== Interactive cron task addition ==="
    cmd=$(ask "Command to execute (full path!)")
    [[ -z "$cmd" ]] && error "Command cannot be empty"

    minute=$(ask "Minute (0-59 or *)" "*")
    hour=$(ask "Hour (0-23 or *)" "*")
    day=$(ask "Day of month (1-31 or *)" "*")
    month=$(ask "Month (1-12 or *)" "*")
    weekday=$(ask "Day of week (0-6, 0=Sun, or *)" "*")

    for field in "$minute" "$hour" "$day" "$month" "$weekday"; do
        validate_cron_field "$field" || error "Invalid cron field: $field"
    done

    comment=$(ask "Comment (optional)")

    cron_line="$minute $hour $day $month $weekday $cmd"
    tmp_cron=$(mktemp)
    crontab -l 2>/dev/null > "$tmp_cron" || true
    {
        [[ -n "$comment" ]] && echo "# $comment"
        echo "$cron_line"
    } >> "$tmp_cron"
    crontab "$tmp_cron"
    rm -f "$tmp_cron"

    log "Task added: $cron_line (Comment: $comment)"
    echo "Task successfully added."
}

remove_cron() {
    local num tmp_cron line_content prev_line tmp_file

    num="$1"
    [[ -z "$num" ]] && error "Please provide the line number (task) to remove"

    tmp_cron=$(mktemp)
    crontab -l 2>/dev/null > "$tmp_cron"

    if [[ "$num" -lt 1 ]] || [[ "$num" -gt $(wc -l < "$tmp_cron") ]]; then
        rm -f "$tmp_cron"
        error "Task #$num not found"
    fi

    line_content=$(sed -n "${num}p" "$tmp_cron")
    prev_line=""
    if [[ "$num" -gt 1 ]]; then
        local tmp_prev
        tmp_prev=$(sed -n "$((num-1))p" "$tmp_cron")
        [[ "$tmp_prev" =~ ^# ]] && prev_line="$tmp_prev"
    fi

    tmp_file=$(mktemp)
    awk -v task="$line_content" -v comment="$prev_line" '
        {
            gsub(/^[ \t]+/, ""); 
            if($0 != task && $0 != comment) print
        }
    ' "$tmp_cron" > "$tmp_file"

    crontab "$tmp_file"
    rm -f "$tmp_cron" "$tmp_file"

    log "Task #$num removed: $line_content"
    echo "Task #$num removed (comment removed if exists)."
}


edit_cron() {
    local num tmp_cron line_content comment_line new_line
    num="$1"
    [[ -z "$num" ]] && error "Please provide the line number to edit"

    tmp_cron=$(mktemp)
    crontab -l 2>/dev/null > "$tmp_cron"

    # check number
    if [[ "$num" -gt $(wc -l < "$tmp_cron") ]] || [[ "$num" -lt 1 ]]; then
        rm -f "$tmp_cron"
        error "Task #$num not found"
    fi

    line_content=$(sed -n "${num}p" "$tmp_cron")

    # previous line if comment
    comment_line=""
    if [[ "$num" -gt 1 ]]; then
        local prev_line=$(sed -n "$((num-1))p" "$tmp_cron")
        [[ "$prev_line" =~ ^# ]] && comment_line="$prev_line"
    fi

    echo "Current task: $line_content"

    # break cron into fields: the first 5 fields = schedule, the rest = command
    local current_min current_hour current_day current_month current_wd current_cmd
    current_min=$(echo "$line_content" | awk '{print $1}')
    current_hour=$(echo "$line_content" | awk '{print $2}')
    current_day=$(echo "$line_content" | awk '{print $3}')
    current_month=$(echo "$line_content" | awk '{print $4}')
    current_wd=$(echo "$line_content" | awk '{print $5}')
    current_cmd=$(echo "$line_content" | cut -d' ' -f6-)

    # entering new values
    local new_min new_hour new_day new_month new_wd new_cmd new_comment
    new_min=$(ask "Minute" "$current_min")
    new_hour=$(ask "Hour" "$current_hour")
    new_day=$(ask "Day of month" "$current_day")
    new_month=$(ask "Month" "$current_month")
    new_wd=$(ask "Day of week" "$current_wd")
    new_cmd=$(ask "Command" "$current_cmd")
    new_comment=$(ask "Comment (optional)" "${comment_line#\# }")

    new_line="$new_min $new_hour $new_day $new_month $new_wd $new_cmd"

    # create new crontab
    local new_tmp=$(mktemp)
    local line_num=1
    while IFS= read -r line; do
        if [[ "$line_num" -eq "$num" ]] || [[ -n "$comment_line" && "$line_num" -eq $((num-1)) ]]; then
            # skip the old task line and comment
            :
        else
            echo "$line" >> "$new_tmp"
        fi
        ((line_num++))
    done < "$tmp_cron"

    # add new lines
    [[ -n "$new_comment" ]] && echo "# $new_comment" >> "$new_tmp"
    echo "$new_line" >> "$new_tmp"

    crontab "$new_tmp"
    rm -f "$tmp_cron" "$new_tmp"

    log "Task #$num edited: $line_content -> $new_line (Comment: $new_comment)"
    echo "Task #$num edited."
}


template_cron() {
    local template="$1"

    case "$template" in
        "every_5_min") CLI_CRON="*/5 * * * *";;
        "every_15_min") CLI_CRON="*/15 * * * *";;
        "every_hour") CLI_CRON="0 * * * *";;
        "daily_3am") CLI_CRON="0 3 * * *";;
        "daily_6am") CLI_CRON="0 6 * * *";;
        "daily_noon") CLI_CRON="0 12 * * *";;
        "daily_midnight") CLI_CRON="0 0 * * *";;
        "weekdays_9am") CLI_CRON="0 9 * * 1-5";;
        "weekdays_5pm") CLI_CRON="0 17 * * 1-5";;
        "weekends_10am") CLI_CRON="0 10 * * 6,7";;
        "monday_8am") CLI_CRON="0 8 * * 1";;
        "friday_6pm") CLI_CRON="0 18 * * 5";;
        "first_day_of_month") CLI_CRON="0 0 1 * *";;
        "last_day_of_month") CLI_CRON="0 0 28-31 * * [ $(date +\%d -d tomorrow) -eq 01 ]";;
        "every_10_min") CLI_CRON="*/10 * * * *";;
        "every_30_min") CLI_CRON="*/30 * * * *";;
        *) error "Unknown template: $template";;
    esac

    if [[ -n "${CLI_CMD:-}" && -n "${CLI_CRON:-}" ]]; then
        add_cron
        return
    fi

    CLI_CMD=$(ask "Command to execute")
    CLI_COMMENT=$(ask "Comment (optional)")
    add_cron
}

interactive_menu() {
    while true; do
        echo ""
        echo "=== Cron Manager Menu ==="
        echo "1) Add task"
        echo "2) List tasks"
        echo "3) Remove task"
        echo "4) Edit task"
        echo "5) Add template task"
        echo "6) Exit"
        echo ""
        choice=$(ask "Select an option")
        case "$choice" in
            1) add_cron ;;
            2) list_cron ;;
            3) num=$(ask "Enter line number to remove"); remove_cron "$num" ;;
            4) num=$(ask "Enter line number to edit"); edit_cron "$num" ;;
            5) tmpl=$(ask "Enter template (every_5_min/daily_3am/weekdays_9am)"); template_cron "$tmpl" ;;
            6) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option, try again." ;;
        esac
    done
}

# ===== MAIN =====

# If no arguments, start MENU
if [[ $# -eq 0 ]]; then
    interactive_menu
    exit 0
fi

cmd="$1"
shift

# CLI args
while [[ $# -gt 0 ]]; do
    case $1 in
        --cmd) CLI_CMD="$2"; shift 2;;
        --cron) CLI_CRON="$2"; shift 2;;
        --comment) CLI_COMMENT="$2"; shift 2;;
        *) shift;;
    esac
done

case "$cmd" in
    add) add_cron;;
    list) list_cron;;
    remove) remove_cron "$1";;
    edit) edit_cron "$1";;
    template) template_cron "$1";;
    *)
        echo "Usage: $0 {add|list|remove|edit|template} [--cmd CMD --cron CRON --comment COMMENT]"
        exit 1
        ;;
esac
