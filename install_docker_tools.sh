#!/bin/bash

set -Eeuo pipefail

# =========================================================
# Employee Management System
# Docker 環境安裝與專案部署腳本
#
# Git Repository:
# https://github.com/NeedMoreCrack/employee-management-system
#
# 測試環境：
#   - WSL2 Ubuntu 22.04
#   - Ubuntu 24.04 Server
#
# 執行方式：
#   sudo bash install_docker_tools.sh
#
# 部署位置：
#   /usr/local/app
# =========================================================


# =========================================================
# 基本設定
# =========================================================

# Git Clone 下來的專案位置
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 實際 Docker 部署位置
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

warning() {
    echo "[WARNING] $1"
}

error() {
    echo "[ERROR] $1" >&2
}


# =========================================================
# 錯誤處理
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
# 顯示路徑
# =========================================================

info "Deployment information"

echo "Source directory:"
echo "  $SOURCE_DIR"
echo
echo "Deployment directory:"
echo "  $APP_DIR"


# =========================================================
# 檢查來源專案
# =========================================================

info "Checking source project..."

if [ ! -f "$SOURCE_DIR/docker-compose.yml" ] &&
   [ ! -f "$SOURCE_DIR/docker-compose.yaml" ] &&
   [ ! -f "$SOURCE_DIR/compose.yml" ] &&
   [ ! -f "$SOURCE_DIR/compose.yaml" ]; then

    error "Docker Compose configuration not found."
    echo
    echo "Source directory:"
    echo "  $SOURCE_DIR"
    exit 1
fi


if [ ! -f "$SOURCE_DIR/Dockerfile" ]; then
    error "Dockerfile not found:"
    echo "  $SOURCE_DIR/Dockerfile"
    exit 1
fi


if [ ! -f "$SOURCE_DIR/nginx/conf/nginx.conf" ]; then
    error "Nginx configuration not found:"
    echo "  $SOURCE_DIR/nginx/conf/nginx.conf"
    exit 1
fi

success "Source project structure is valid."


# =========================================================
# 更新 Ubuntu 套件
# =========================================================

info "Updating package list..."

apt update

success "Package list updated."


# =========================================================
# 安裝必要工具
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

if command -v systemctl >/dev/null 2>&1 &&
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
# 檢查 Docker Daemon
# =========================================================

info "Checking Docker daemon..."

if docker info >/dev/null 2>&1; then
    success "Docker daemon is running."
else
    error "Docker daemon is not running."
    exit 1
fi


# =========================================================
# Docker 版本
# =========================================================

info "Docker version"

docker --version


# =========================================================
# Docker Compose
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
# Docker Buildx
# =========================================================

info "Checking Docker Buildx..."

if docker buildx version >/dev/null 2>&1; then
    docker buildx version
    success "Docker Buildx is available."
else
    error "Docker Buildx is not available."
    exit 1
fi


# =========================================================
# MEGA Tools
# =========================================================

info "Checking MEGA Tools..."

if command -v megatools >/dev/null 2>&1; then
    success "MEGA Tools is available."
else
    error "MEGA Tools installation failed."
    exit 1
fi


# =========================================================
# 停止舊版 Container
# =========================================================

if [ -f "$APP_DIR/docker-compose.yml" ] ||
   [ -f "$APP_DIR/docker-compose.yaml" ] ||
   [ -f "$APP_DIR/compose.yml" ] ||
   [ -f "$APP_DIR/compose.yaml" ]; then

    info "Stopping existing containers..."

    cd "$APP_DIR"

    docker compose down || warning "Unable to stop existing containers."

    success "Existing containers stopped."

fi


# =========================================================
# 建立部署目錄
# =========================================================

info "Preparing deployment directory..."

mkdir -p "$APP_DIR"

success "Deployment directory ready."


# =========================================================
# 部署專案
#
# 注意：
#   mysql/data 為 MySQL 持久化資料。
#   更新部署時不刪除此目錄。
# =========================================================

info "Copying project files to $APP_DIR..."

# Dockerfile
cp -f "$SOURCE_DIR/Dockerfile" "$APP_DIR/"


# Docker Compose
if [ -f "$SOURCE_DIR/docker-compose.yml" ]; then
    cp -f "$SOURCE_DIR/docker-compose.yml" "$APP_DIR/"
fi

if [ -f "$SOURCE_DIR/docker-compose.yaml" ]; then
    cp -f "$SOURCE_DIR/docker-compose.yaml" "$APP_DIR/"
fi

if [ -f "$SOURCE_DIR/compose.yml" ]; then
    cp -f "$SOURCE_DIR/compose.yml" "$APP_DIR/"
fi

if [ -f "$SOURCE_DIR/compose.yaml" ]; then
    cp -f "$SOURCE_DIR/compose.yaml" "$APP_DIR/"
fi


# Nginx
rm -rf "$APP_DIR/nginx"
cp -a "$SOURCE_DIR/nginx" "$APP_DIR/nginx"


# MySQL 設定
mkdir -p "$APP_DIR/mysql"

rm -rf "$APP_DIR/mysql/conf"
rm -rf "$APP_DIR/mysql/init"

if [ -d "$SOURCE_DIR/mysql/conf" ]; then
    cp -a "$SOURCE_DIR/mysql/conf" "$APP_DIR/mysql/conf"
fi

if [ -d "$SOURCE_DIR/mysql/init" ]; then
    cp -a "$SOURCE_DIR/mysql/init" "$APP_DIR/mysql/init"
fi


# MySQL Data 必須保留
mkdir -p "$APP_DIR/mysql/data"


# 如果專案還有其他一般檔案，複製到部署目錄
# 排除：
#   .git
#   nginx
#   mysql
#   jdk17.tar.gz
#   myWeb.jar
#
# 大型檔案由 MEGA 下載。

for item in "$SOURCE_DIR"/* "$SOURCE_DIR"/.[!.]* "$SOURCE_DIR"/..?*; do

    [ -e "$item" ] || continue

    name="$(basename "$item")"

    case "$name" in

        ".git"|"nginx"|"mysql"|"$JDK_FILE"|"$JAR_FILE")
            continue
            ;;

        "Dockerfile"|"docker-compose.yml"|"docker-compose.yaml"|"compose.yml"|"compose.yaml")
            continue
            ;;

    esac

    if [ -d "$item" ]; then

        rm -rf "$APP_DIR/$name"
        cp -a "$item" "$APP_DIR/$name"

    elif [ -f "$item" ]; then

        cp -f "$item" "$APP_DIR/$name"

    fi

done


success "Project files deployed to $APP_DIR."


# =========================================================
# 確認部署後 Nginx 設定
# =========================================================

info "Checking deployed Nginx configuration..."

if [ ! -f "$APP_DIR/nginx/conf/nginx.conf" ]; then
    error "Nginx configuration deployment failed:"
    echo "  $APP_DIR/nginx/conf/nginx.conf"
    exit 1
fi

success "Nginx configuration is ready."


# =========================================================
# 下載 JDK 17
# =========================================================

cd "$APP_DIR"

if [ -f "$APP_DIR/$JDK_FILE" ]; then

    info "Checking $JDK_FILE..."

    success "$JDK_FILE already exists. Skip download."

else

    info "Downloading $JDK_FILE from MEGA..."

    megatools dl "$JDK_URL"

    if [ -f "$APP_DIR/$JDK_FILE" ]; then
        success "$JDK_FILE downloaded successfully."
    else
        error "Failed to download $JDK_FILE."
        exit 1
    fi

fi


# =========================================================
# 下載 Backend JAR
# =========================================================

if [ -f "$APP_DIR/$JAR_FILE" ]; then

    info "Checking $JAR_FILE..."

    success "$JAR_FILE already exists. Skip download."

else

    info "Downloading $JAR_FILE from MEGA..."

    megatools dl "$JAR_URL"

    if [ -f "$APP_DIR/$JAR_FILE" ]; then
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
# 驗證 Docker Compose
# =========================================================

info "Validating Docker Compose configuration..."

cd "$APP_DIR"

docker compose config >/dev/null

success "Docker Compose configuration is valid."


# =========================================================
# Build + 啟動專案
# =========================================================

info "Building and starting Employee Management System..."

docker compose up -d --build

success "Employee Management System started."


# =========================================================
# Container 狀態
# =========================================================

info "Container status"

docker compose ps


# =========================================================
# 取得 Linux IP
# =========================================================

LINUX_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"

if [ -z "$LINUX_IP" ]; then
    LINUX_IP="<Linux-IP>"
fi


# =========================================================
# 完成
# =========================================================

echo
echo "============================================================"
echo " Employee Management System"
echo " Deployment completed successfully"
echo "============================================================"
echo
echo "Source directory:"
echo "  $SOURCE_DIR"
echo
echo "Deployment directory:"
echo "  $APP_DIR"
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
echo "Deployment directory:"
echo "  cd $APP_DIR"
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
