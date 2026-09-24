#!/bin/bash

set -e

# =========================================================
# Employee Management System
# Docker 環境安裝與專案部署腳本
#
# 測試環境：
#   - WSL2 Ubuntu 22.04
#   - Ubuntu 24.04 Server
#
# 執行方式：
#   sudo bash install_docker_tools.sh
# =========================================================


# =========================================================
# 基本設定
# =========================================================

# 取得此腳本所在的專案目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

JDK_FILE="jdk17.tar.gz"
JAR_FILE="myWeb.jar"

JDK_URL="https://mega.nz/file/F4gGmBjC#TJqBitRWbdWubIB7fRTsCzLQoe0XxkYWWWCKXXc-Be4"
JAR_URL="https://mega.nz/file/t8AGkDjb#OV5jHhOqXnL8xsQu77aqHeMMds6HdBkiBuzCkp3C25A"


# =========================================================
# 顯示訊息
# =========================================================

info() {
    echo
    echo "============================================================"
    echo "[INFO] $1"
    echo "============================================================"
}

success() {
    echo "[OK] $1"
}

warning() {
    echo "[WARNING] $1"
}

error() {
    echo "[ERROR] $1" >&2
}


# =========================================================
# 發生錯誤時顯示資訊
# =========================================================

trap 'error "Deployment failed at line $LINENO."' ERR


# =========================================================
# 檢查 Root 權限
# =========================================================

if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root."
    echo
    echo "Please run:"
    echo "sudo bash install_docker_tools.sh"
    exit 1
fi


# =========================================================
# 切換到專案目錄
# =========================================================

cd "$SCRIPT_DIR"

info "Project directory"

echo "$SCRIPT_DIR"


# =========================================================
# 檢查 Docker Compose 設定檔
# =========================================================

info "Checking project files..."

if [ -f "docker-compose.yml" ] || \
   [ -f "docker-compose.yaml" ] || \
   [ -f "compose.yml" ] || \
   [ -f "compose.yaml" ]; then

    success "Docker Compose configuration found."

else

    error "Docker Compose configuration not found."
    echo
    echo "Please make sure this script is inside the"
    echo "Employee Management System project directory."
    exit 1

fi


# =========================================================
# 更新 Ubuntu 套件清單
# =========================================================

info "Updating package list..."

apt update

success "Package list updated."


# =========================================================
# 安裝 Docker / Compose / Buildx / MEGA Tools
# =========================================================

info "Installing required packages..."

apt install -y \
    docker.io \
    docker-compose-v2 \
    docker-buildx \
    megatools

success "Required packages installed."


# =========================================================
# 啟動 Docker
# =========================================================

info "Starting Docker service..."

if command -v systemctl >/dev/null 2>&1 && \
   systemctl is-system-running >/dev/null 2>&1; then

    systemctl enable docker >/dev/null 2>&1 || true
    systemctl start docker

    success "Docker started using systemctl."

elif command -v service >/dev/null 2>&1; then

    service docker start

    success "Docker started using service."

else

    error "Unable to start Docker automatically."
    echo
    echo "Please start Docker manually and run this script again."
    exit 1

fi


# =========================================================
# 確認 Docker Daemon
# =========================================================

info "Checking Docker daemon..."

if docker info >/dev/null 2>&1; then

    success "Docker daemon is running."

else

    error "Docker daemon is not running."
    exit 1

fi


# =========================================================
# 顯示 Docker 版本
# =========================================================

info "Docker version"

docker --version


# =========================================================
# 確認 Docker Compose
# =========================================================

info "Checking Docker Compose..."

if docker compose version >/dev/null 2>&1; then

    docker compose version
    success "Docker Compose is available."

else

    error "Docker Compose is not available."
    exit 1

fi


# =========================================================
# 確認 MEGA Tools
# =========================================================

info "Checking MEGA Tools..."

if command -v megatools >/dev/null 2>&1; then

    success "MEGA Tools is available."

else

    error "MEGA Tools installation failed."
    exit 1

fi


# =========================================================
# 下載 JDK 17
# =========================================================

if [ -f "$SCRIPT_DIR/$JDK_FILE" ]; then

    info "Checking $JDK_FILE..."

    success "$JDK_FILE already exists. Skip download."

else

    info "Downloading $JDK_FILE from MEGA..."

    megatools dl "$JDK_URL"

    if [ -f "$SCRIPT_DIR/$JDK_FILE" ]; then

        success "$JDK_FILE downloaded successfully."

    else

        error "Failed to download $JDK_FILE."
        exit 1

    fi

fi


# =========================================================
# 下載 Backend JAR
# =========================================================

if [ -f "$SCRIPT_DIR/$JAR_FILE" ]; then

    info "Checking $JAR_FILE..."

    success "$JAR_FILE already exists. Skip download."

else

    info "Downloading $JAR_FILE from MEGA..."

    megatools dl "$JAR_URL"

    if [ -f "$SCRIPT_DIR/$JAR_FILE" ]; then

        success "$JAR_FILE downloaded successfully."

    else

        error "Failed to download $JAR_FILE."
        exit 1

    fi

fi


# =========================================================
# Pull Docker Images
# =========================================================

info "Pulling nginx:1.28.0..."

docker pull nginx:1.28.0

success "nginx:1.28.0 ready."


info "Pulling mysql:8..."

docker pull mysql:8

success "mysql:8 ready."


# =========================================================
# 檢查 Docker Compose 設定
# =========================================================

info "Validating Docker Compose configuration..."

docker compose config >/dev/null

success "Docker Compose configuration is valid."


# =========================================================
# Build + 啟動專案
# =========================================================

info "Building and starting Employee Management System..."

docker compose up -d --build

success "Employee Management System started."


# =========================================================
# 顯示 Container 狀態
# =========================================================

info "Container status"

docker compose ps


# =========================================================
# 取得 Linux IP
# =========================================================

LINUX_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

if [ -z "$LINUX_IP" ]; then
    LINUX_IP="<Linux-IP>"
fi


# =========================================================
# 部署完成
# =========================================================

echo
echo "============================================================"
echo " Employee Management System"
echo " Deployment completed successfully"
echo "============================================================"
echo
echo "Project directory:"
echo "  $SCRIPT_DIR"
echo
echo "Linux IP:"
echo "  $LINUX_IP"
echo
echo "Browser:"
echo "  http://$LINUX_IP"
echo
echo "------------------------------------------------------------"
echo "MySQL"
echo "------------------------------------------------------------"
echo
echo "Host:"
echo "  $LINUX_IP"
echo
echo "Port:"
echo "  3307"
echo
echo "User:"
echo "  root"
echo
echo "Password:"
echo "  321321321"
echo
echo "Database:"
echo "  restful"
echo
echo "MySQL CLI:"
echo "  mysql -h $LINUX_IP -P3307 -u root -p"
echo
echo "------------------------------------------------------------"
echo "Docker Compose"
echo "------------------------------------------------------------"
echo
echo "Start:"
echo "  sudo docker compose up -d"
echo
echo "Stop:"
echo "  sudo docker compose down"
echo
echo "Status:"
echo "  sudo docker compose ps"
echo
echo "Logs:"
echo "  sudo docker compose logs -f"
echo
echo "Rebuild:"
echo "  sudo docker compose up -d --build"
echo
echo "============================================================"
