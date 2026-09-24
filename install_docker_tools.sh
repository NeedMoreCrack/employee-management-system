#!/bin/bash

set -e

# =========================================================
# EmployeeManagementSystem
# Docker 環境安裝 + MEGA 檔案下載 + 專案啟動腳本
#
# 支援測試環境：
#   - WSL2 Ubuntu 22.04
#   - Ubuntu 24.04 Server
#
# 執行方式：
#   sudo bash install_docker_tools.sh
# =========================================================


# =========================================================
# 基本設定
# =========================================================

APP_DIR="/usr/local/app"

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

error() {
    echo "[ERROR] $1" >&2
}


# =========================================================
# 檢查 Root 權限
# =========================================================

if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root."
    echo
    echo "Please run:"
    echo "sudo bash $0"
    exit 1
fi


# =========================================================
# 更新套件
# =========================================================

info "Updating package list..."

apt update

success "Package list updated."


# =========================================================
# 安裝 Docker / Compose / Buildx / MEGA Tools
# =========================================================

info "Installing Docker and required tools..."

apt install -y \
    docker.io \
    docker-compose-v2 \
    docker-buildx \
    megatools

success "Docker and required tools installed."


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
    echo "Please start Docker manually."
    exit 1
fi


# =========================================================
# 確認 Docker 是否正常
# =========================================================

info "Checking Docker..."

if ! docker info >/dev/null 2>&1; then
    error "Docker daemon is not running."
    exit 1
fi

success "Docker is running."


# =========================================================
# 建立專案目錄
# =========================================================

info "Preparing application directory..."

mkdir -p "$APP_DIR"

success "Application directory: $APP_DIR"


# =========================================================
# 下載 JDK
# =========================================================

if [ -f "$APP_DIR/$JDK_FILE" ]; then

    success "$JDK_FILE already exists. Skip download."

else

    info "Downloading $JDK_FILE from MEGA..."

    cd "$APP_DIR"

    megatools dl "$JDK_URL"

    if [ ! -f "$APP_DIR/$JDK_FILE" ]; then
        error "Failed to download $JDK_FILE"
        exit 1
    fi

    success "$JDK_FILE downloaded."

fi


# =========================================================
# 下載 Backend JAR
# =========================================================

if [ -f "$APP_DIR/$JAR_FILE" ]; then

    success "$JAR_FILE already exists. Skip download."

else

    info "Downloading $JAR_FILE from MEGA..."

    cd "$APP_DIR"

    megatools dl "$JAR_URL"

    if [ ! -f "$APP_DIR/$JAR_FILE" ]; then
        error "Failed to download $JAR_FILE"
        exit 1
    fi

    success "$JAR_FILE downloaded."

fi


# =========================================================
# Pull Docker Images
# =========================================================

info "Pulling nginx:1.28.0..."

docker pull nginx:1.28.0

success "nginx:1.28.0 downloaded."


info "Pulling mysql:8..."

docker pull mysql:8

success "mysql:8 downloaded."


# =========================================================
# 檢查 Docker Compose
# =========================================================

info "Checking Docker Compose..."

if ! docker compose version >/dev/null 2>&1; then
    error "Docker Compose is not available."
    exit 1
fi

docker compose version


# =========================================================
# 檢查 compose.yaml / docker-compose.yml
# =========================================================

info "Checking Docker Compose configuration..."

cd "$APP_DIR"

if [ -f "compose.yaml" ] || \
   [ -f "compose.yml" ] || \
   [ -f "docker-compose.yaml" ] || \
   [ -f "docker-compose.yml" ]; then

    success "Docker Compose configuration found."

else

    error "Docker Compose configuration not found in:"
    echo "$APP_DIR"
    echo
    echo "Please put EmployeeManagementSystem project files into:"
    echo "$APP_DIR"
    exit 1

fi


# =========================================================
# 啟動專案
# =========================================================

info "Starting EmployeeManagementSystem..."

docker compose up -d

success "EmployeeManagementSystem started."


# =========================================================
# 顯示 Container 狀態
# =========================================================

info "Docker container status"

docker compose ps


# =========================================================
# 取得 Linux IP
# =========================================================

LINUX_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

if [ -z "$LINUX_IP" ]; then
    LINUX_IP="<Linux-IP>"
fi


# =========================================================
# 完成
# =========================================================

echo
echo "============================================================"
echo " Installation completed successfully"
echo "============================================================"
echo
echo "Application directory:"
echo "  $APP_DIR"
echo
echo "Linux IP:"
echo "  $LINUX_IP"
echo
echo "Browser:"
echo "  http://$LINUX_IP"
echo
echo "MySQL:"
echo "  Host     : $LINUX_IP"
echo "  Port     : 3307"
echo "  User     : root"
echo "  Password : 321321321"
echo "  Database : restful"
echo
echo "MySQL CLI:"
echo "  mysql -h $LINUX_IP -P3307 -u root -p"
echo
echo "Start project:"
echo "  cd $APP_DIR"
echo "  sudo docker compose up -d"
echo
echo "Stop project:"
echo "  cd $APP_DIR"
echo "  sudo docker compose down"
echo
echo "View containers:"
echo "  cd $APP_DIR"
echo "  sudo docker compose ps"
echo
echo "View logs:"
echo "  cd $APP_DIR"
echo "  sudo docker compose logs -f"
echo
echo "============================================================"
