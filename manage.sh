#!/bin/bash

set -Eeuo pipefail

# =========================================================
# Employee Management System
# Docker Compose Management Script
#
# Usage:
#
# sudo bash manage.sh
#
# Deployment directory:
#
# /usr/local/app
# =========================================================


# =========================================================
# Configuration
# =========================================================

APP_DIR="/usr/local/app"

MYSQL_PORT="3307"
MYSQL_USER="root"
MYSQL_PASSWORD="321321321"
MYSQL_DATABASE="restful"


# =========================================================
# Output functions
# =========================================================

info() {
    echo
    echo "============================================================"
    echo "[INFO] $1"
    echo "============================================================"
}

success() {
    echo
    echo "[OK] $1"
}

warning() {
    echo
    echo "[WARNING] $1"
}

error() {
    echo
    echo "[ERROR] $1" >&2
}


# =========================================================
# Root check
# =========================================================

if [ "$EUID" -ne 0 ]; then

    error "This script must be run as root."

    echo
    echo "Please run:"
    echo
    echo "  sudo bash manage.sh"
    echo

    exit 1
fi


# =========================================================
# Check deployment directory
# =========================================================

if [ ! -d "$APP_DIR" ]; then

    error "Deployment directory does not exist."

    echo
    echo "Expected:"
    echo
    echo "  $APP_DIR"

    echo
    echo "Please deploy the project first:"
    echo
    echo "  sudo bash install_docker_tools.sh"
    echo

    exit 1
fi


# =========================================================
# Find Docker Compose file
# =========================================================

COMPOSE_FILE=""

for file in \
    "docker-compose.yml" \
    "docker-compose.yaml" \
    "compose.yml" \
    "compose.yaml"
do

    if [ -f "$APP_DIR/$file" ]; then

        COMPOSE_FILE="$APP_DIR/$file"

        break
    fi

done


if [ -z "$COMPOSE_FILE" ]; then

    error "Docker Compose configuration not found."

    echo
    echo "Deployment directory:"
    echo
    echo "  $APP_DIR"

    echo
    echo "Please run deployment again:"
    echo
    echo "  sudo bash install_docker_tools.sh"
    echo

    exit 1
fi


# =========================================================
# Check Docker
# =========================================================

if ! command -v docker >/dev/null 2>&1; then

    error "Docker is not installed."

    echo
    echo "Please run:"
    echo
    echo "  sudo bash install_docker_tools.sh"
    echo

    exit 1
fi


# =========================================================
# Check Docker daemon
# =========================================================

if ! docker info >/dev/null 2>&1; then

    error "Docker daemon is not running."

    echo
    echo "Try:"
    echo
    echo "  sudo systemctl start docker"
    echo

    exit 1
fi


# =========================================================
# Check Docker Compose
# =========================================================

if ! docker compose version >/dev/null 2>&1; then

    error "Docker Compose V2 is not available."

    exit 1
fi


# =========================================================
# Change to deployment directory
# =========================================================

cd "$APP_DIR"


# =========================================================
# Pause
# =========================================================

pause() {

    echo

    read -r -p "按 Enter 返回主選單..." _

}


# =========================================================
# Header
# =========================================================

show_header() {

    clear 2>/dev/null || true

    echo "============================================================"
    echo " Employee Management System"
    echo " Docker Management"
    echo "============================================================"

    echo
    echo "Deployment:"
    echo "  $APP_DIR"

    echo

}


# =========================================================
# Show menu
# =========================================================

show_menu() {

    echo "------------------------------------------------------------"
    echo "請選擇操作："
    echo "------------------------------------------------------------"

    echo
    echo "1) 啟動專案"
    echo "2) 關閉專案"
    echo "3) 重啟專案"
    echo "4) 查看 Container 狀態"
    echo
    echo "5) 查看全部 Log"
    echo "6) 查看 Backend Log"
    echo "7) 查看 Frontend Log"
    echo "8) 查看 MySQL Log"
    echo
    echo "9) Rebuild 專案"
    echo
    echo "0) 離開"

    echo

}


# =========================================================
# Get Linux IP
# =========================================================

get_linux_ip() {

    local linux_ip

    linux_ip="$(
        hostname -I 2>/dev/null |
        awk '{print $1}'
    )"

    if [ -z "$linux_ip" ]; then
        linux_ip="<Linux-IP>"
    fi

    echo "$linux_ip"
}


# =========================================================
# Show container status
# =========================================================

show_container_status() {

    info "Container status"

    docker compose ps

}


# =========================================================
# Show connection information
# =========================================================

show_connection_info() {

    local linux_ip

    linux_ip="$(get_linux_ip)"

    echo
    echo "============================================================"
    echo " Employee Management System"
    echo " Running successfully"
    echo "============================================================"

    echo

    echo "Deployment directory:"
    echo "  $APP_DIR"

    echo

    echo "Linux IP:"
    echo "  $linux_ip"

    echo

    echo "Browser:"
    echo "  http://$linux_ip"


    echo
    echo "------------------------------------------------------------"
    echo "MySQL"
    echo "------------------------------------------------------------"

    echo

    echo "Host:"
    echo "  $linux_ip"

    echo

    echo "Port:"
    echo "  $MYSQL_PORT"

    echo

    echo "User:"
    echo "  $MYSQL_USER"

    echo

    echo "Password:"
    echo "  $MYSQL_PASSWORD"

    echo

    echo "Database:"
    echo "  $MYSQL_DATABASE"

    echo

    echo "MySQL CLI:"
    echo "  mysql -h $linux_ip -P$MYSQL_PORT -u $MYSQL_USER -p"


    echo
    echo "------------------------------------------------------------"
    echo "Docker Compose"
    echo "------------------------------------------------------------"

    echo

    echo "Start:"
    echo "  sudo bash manage.sh"
    echo "  → 選擇 1"

    echo

    echo "Stop:"
    echo "  sudo bash manage.sh"
    echo "  → 選擇 2"

    echo

    echo "Restart:"
    echo "  sudo bash manage.sh"
    echo "  → 選擇 3"

    echo

    echo "Status:"
    echo "  sudo bash manage.sh"
    echo "  → 選擇 4"

    echo

    echo "Logs:"
    echo "  sudo bash manage.sh"
    echo "  → 選擇 5"

    echo

    echo "Rebuild:"
    echo "  sudo bash manage.sh"
    echo "  → 選擇 9"

    echo

    echo "============================================================"

}


# =========================================================
# Show project information
#
# Used after:
# Start / Restart / Rebuild
# =========================================================

show_project_info() {

    show_container_status

    show_connection_info

}


# =========================================================
# Start
# =========================================================

start_project() {

    info "Starting Employee Management System..."

    docker compose up -d

    success "Employee Management System started."

    show_project_info

}


# =========================================================
# Stop
# =========================================================

stop_project() {

    info "Stopping Employee Management System..."

    docker compose down

    success "Employee Management System stopped."

}


# =========================================================
# Restart
# =========================================================

restart_project() {

    info "Restarting Employee Management System..."

    echo
    echo "Stopping containers..."

    docker compose down

    echo
    echo "Starting containers..."

    docker compose up -d

    success "Employee Management System restarted."

    show_project_info

}


# =========================================================
# Status
# =========================================================

show_status() {

    show_container_status

}


# =========================================================
# All logs
# =========================================================

show_logs() {

    info "Employee Management System logs"

    echo
    echo "按 Ctrl + C 停止 Log 並返回主選單。"
    echo

    trap '' INT

    docker compose logs -f || true

    trap - INT

}


# =========================================================
# Backend logs
# =========================================================

show_backend_logs() {

    info "Backend logs"

    echo
    echo "按 Ctrl + C 停止 Log 並返回主選單。"
    echo

    trap '' INT

    docker compose logs -f backend || true

    trap - INT

}


# =========================================================
# Frontend logs
# =========================================================

show_frontend_logs() {

    info "Frontend logs"

    echo
    echo "按 Ctrl + C 停止 Log 並返回主選單。"
    echo

    trap '' INT

    docker compose logs -f frontend || true

    trap - INT

}


# =========================================================
# MySQL logs
# =========================================================

show_mysql_logs() {

    info "MySQL logs"

    echo
    echo "按 Ctrl + C 停止 Log 並返回主選單。"
    echo

    trap '' INT

    docker compose logs -f mysql || true

    trap - INT

}


# =========================================================
# Rebuild
# =========================================================

rebuild_project() {

    info "Building and starting Employee Management System..."

    docker compose up -d --build

    success "Employee Management System rebuilt and started."

    show_project_info

}


# =========================================================
# Confirmation
# =========================================================

confirm_action() {

    local message="$1"

    echo

    read -r -p "$message [y/N]: " answer

    case "$answer" in

        y|Y|yes|YES|Yes)
            return 0
            ;;

        *)
            return 1
            ;;

    esac

}


# =========================================================
# Main loop
# =========================================================

while true; do

    show_header
    show_menu

    read -r -p "請輸入選項 [0-9]: " choice

    case "$choice" in

        1)

            start_project

            pause

            ;;


        2)

            if confirm_action "確定要關閉 Employee Management System？"; then

                stop_project

            else

                warning "已取消關閉操作。"

            fi

            pause

            ;;


        3)

            if confirm_action "確定要重新啟動 Employee Management System？"; then

                restart_project

            else

                warning "已取消重新啟動操作。"

            fi

            pause

            ;;


        4)

            show_status

            pause

            ;;


        5)

            show_logs

            ;;


        6)

            show_backend_logs

            ;;


        7)

            show_frontend_logs

            ;;


        8)

            show_mysql_logs

            ;;


        9)

            if confirm_action "確定要重新 Build Employee Management System？"; then

                rebuild_project

            else

                warning "已取消 Rebuild。"

            fi

            pause

            ;;


        0)

            echo
            echo "Bye."
            echo

            exit 0

            ;;


        *)

            warning "無效選項：$choice"

            echo
            echo "請輸入 0 ~ 9。"

            sleep 1

            ;;

    esac

done
