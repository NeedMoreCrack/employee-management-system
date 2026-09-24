#!/bin/bash

set -Eeuo pipefail

# =========================================================
# Employee Management System
# Docker Environment Installation & Deployment Script
#
# GitHub:
# https://github.com/NeedMoreCrack/employee-management-system
#
# Deployment directory:
# /usr/local/app
#
# Usage:
# sudo bash install_docker_tools.sh
# =========================================================


# =========================================================
# Basic configuration
# =========================================================

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_DIR="/usr/local/app"

JDK_FILE="jdk17.tar.gz"
JAR_FILE="myWeb.jar"

JDK_URL="https://mega.nz/file/F4gGmBjC#TJqBitRWbdWubIB7fRTsCzLQoe0XxkYWWWCKXXc-Be4"
JAR_URL="https://mega.nz/file/t8AGkDjb#OV5jHhOqXnL8xsQu77aqHeMMds6HdBkiBuzCkp3C25A"

NGINX_IMAGE="nginx:1.28.0"
MYSQL_IMAGE="mysql:8"


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
    echo "[OK] $1"
}

warning() {
    echo "[WARNING] $1"
}

error() {
    echo "[ERROR] $1" >&2
}


# =========================================================
# Error handling
# =========================================================

trap 'error "Deployment failed at line $LINENO."' ERR


# =========================================================
# Root check
# =========================================================

if [ "$EUID" -ne 0 ]; then

    error "This script must be run as root."

    echo
    echo "Please run:"
    echo
    echo "  sudo bash install_docker_tools.sh"
    echo

    exit 1
fi


# =========================================================
# Deployment information
# =========================================================

info "Deployment information"

echo "Source directory:"
echo "  $SOURCE_DIR"

echo

echo "Deployment directory:"
echo "  $APP_DIR"


# =========================================================
# Check source project
# =========================================================

info "Checking source project..."


# ---------------------------------------------------------
# Dockerfile
# ---------------------------------------------------------

if [ ! -f "$SOURCE_DIR/Dockerfile" ]; then

    error "Dockerfile not found:"
    echo "  $SOURCE_DIR/Dockerfile"

    exit 1
fi


# ---------------------------------------------------------
# Docker Compose
# ---------------------------------------------------------

COMPOSE_FOUND=false

for compose_file in \
    "docker-compose.yml" \
    "docker-compose.yaml" \
    "compose.yml" \
    "compose.yaml"
do

    if [ -f "$SOURCE_DIR/$compose_file" ]; then

        COMPOSE_FOUND=true
        SOURCE_COMPOSE_FILE="$compose_file"

        break
    fi

done


if [ "$COMPOSE_FOUND" = false ]; then

    error "Docker Compose configuration not found."

    echo
    echo "Source directory:"
    echo "  $SOURCE_DIR"

    exit 1
fi


# ---------------------------------------------------------
# Nginx
# ---------------------------------------------------------

if [ ! -f "$SOURCE_DIR/nginx/conf/nginx.conf" ]; then

    error "Nginx configuration not found:"

    echo
    echo "  $SOURCE_DIR/nginx/conf/nginx.conf"

    exit 1
fi


success "Source project structure is valid."

echo
echo "Docker Compose:"
echo "  $SOURCE_COMPOSE_FILE"


# =========================================================
# Check required packages
# =========================================================

info "Checking required packages..."

REQUIRED_PACKAGES=(
    "docker.io"
    "docker-compose-v2"
    "docker-buildx"
    "megatools"
)

MISSING_PACKAGES=()


for package in "${REQUIRED_PACKAGES[@]}"; do

    if dpkg -s "$package" >/dev/null 2>&1; then

        success "$package is already installed."

    else

        warning "$package is not installed."

        MISSING_PACKAGES+=("$package")

    fi

done


# =========================================================
# Install missing packages only
# =========================================================

if [ "${#MISSING_PACKAGES[@]}" -gt 0 ]; then

    info "Installing missing packages..."

    echo "Missing packages:"

    for package in "${MISSING_PACKAGES[@]}"; do
        echo "  - $package"
    done

    echo

    apt update

    apt install -y "${MISSING_PACKAGES[@]}"

    success "Missing packages installed."

else

    success "All required packages are already installed."
    echo "Skip apt update/install."

fi


# =========================================================
# Start Docker service
# =========================================================

info "Checking Docker service..."


if docker info >/dev/null 2>&1; then

    success "Docker daemon is already running."

else

    warning "Docker daemon is not running."

    echo "Trying to start Docker..."

    if command -v systemctl >/dev/null 2>&1 &&
       [ -d /run/systemd/system ]; then

        systemctl enable docker >/dev/null 2>&1 || true
        systemctl start docker

    elif command -v service >/dev/null 2>&1; then

        service docker start

    else

        error "Unable to start Docker automatically."

        exit 1
    fi


    # -----------------------------------------------------
    # Check again
    # -----------------------------------------------------

    if docker info >/dev/null 2>&1; then

        success "Docker daemon started successfully."

    else

        error "Docker daemon failed to start."

        exit 1
    fi

fi


# =========================================================
# Docker version
# =========================================================

info "Docker environment"

docker --version
docker compose version
docker buildx version


# =========================================================
# Prepare deployment directory
# =========================================================

info "Preparing deployment directory..."

mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/mysql"
mkdir -p "$APP_DIR/mysql/data"

success "Deployment directory ready."


# =========================================================
# Stop old Compose project if possible
# =========================================================

if [ -f "$APP_DIR/docker-compose.yml" ] ||
   [ -f "$APP_DIR/docker-compose.yaml" ] ||
   [ -f "$APP_DIR/compose.yml" ] ||
   [ -f "$APP_DIR/compose.yaml" ]; then

    info "Stopping existing Docker Compose project..."

    cd "$APP_DIR"

    docker compose down || warning "docker compose down returned an error."

fi


# =========================================================
# Remove old containers
#
# Prevent:
# Conflict. The container name "/mysql" is already in use
# =========================================================

info "Checking old containers..."

OLD_CONTAINERS=(
    "mysql"
    "myweb-backend"
    "myweb-frontend"
)


for container in "${OLD_CONTAINERS[@]}"; do

    if docker container inspect "$container" >/dev/null 2>&1; then

        warning "Old container found: $container"

        echo "Removing:"
        echo "  $container"

        docker rm -f "$container"

        success "Removed old container: $container"

    else

        success "Old container not found: $container"

    fi

done


# =========================================================
# Remove old network if unused
# =========================================================

info "Checking old Docker network..."

NETWORK_NAME="myWeb"


if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then

    warning "Docker network already exists: $NETWORK_NAME"

    # Check if any containers are still using the network
    NETWORK_CONTAINERS="$(
        docker network inspect "$NETWORK_NAME" \
            --format '{{range $id, $container := .Containers}}{{$id}} {{end}}' \
            2>/dev/null || true
    )"


    if [ -z "$NETWORK_CONTAINERS" ]; then

        echo "Network is not being used."
        echo "Removing old network..."

        docker network rm "$NETWORK_NAME" >/dev/null

        success "Old network removed: $NETWORK_NAME"

    else

        warning "Network is still being used by other containers."
        echo "Skip network removal."

    fi

else

    success "Old network not found."

fi


# =========================================================
# Deploy project files
# =========================================================

info "Copying project files to $APP_DIR..."


# ---------------------------------------------------------
# Dockerfile
# ---------------------------------------------------------

cp -f \
    "$SOURCE_DIR/Dockerfile" \
    "$APP_DIR/Dockerfile"


# ---------------------------------------------------------
# Docker Compose
# ---------------------------------------------------------

cp -f \
    "$SOURCE_DIR/$SOURCE_COMPOSE_FILE" \
    "$APP_DIR/$SOURCE_COMPOSE_FILE"


# ---------------------------------------------------------
# Nginx
# ---------------------------------------------------------

rm -rf "$APP_DIR/nginx"

cp -a \
    "$SOURCE_DIR/nginx" \
    "$APP_DIR/nginx"


# ---------------------------------------------------------
# MySQL
#
# mysql/data is intentionally preserved.
# ---------------------------------------------------------

mkdir -p "$APP_DIR/mysql"


if [ -d "$SOURCE_DIR/mysql/conf" ]; then

    rm -rf "$APP_DIR/mysql/conf"

    cp -a \
        "$SOURCE_DIR/mysql/conf" \
        "$APP_DIR/mysql/conf"

fi


if [ -d "$SOURCE_DIR/mysql/init" ]; then

    rm -rf "$APP_DIR/mysql/init"

    cp -a \
        "$SOURCE_DIR/mysql/init" \
        "$APP_DIR/mysql/init"

fi


mkdir -p "$APP_DIR/mysql/data"


# ---------------------------------------------------------
# Copy other project files
#
# Excluded:
#
# .git
# nginx
# mysql
# jdk17.tar.gz
# myWeb.jar
#
# Large files are handled separately.
# ---------------------------------------------------------

for item in \
    "$SOURCE_DIR"/* \
    "$SOURCE_DIR"/.[!.]* \
    "$SOURCE_DIR"/..?*
do

    [ -e "$item" ] || continue

    name="$(basename "$item")"


    case "$name" in

        ".git" | \
        "nginx" | \
        "mysql" | \
        "$JDK_FILE" | \
        "$JAR_FILE" | \
        "Dockerfile" | \
        "docker-compose.yml" | \
        "docker-compose.yaml" | \
        "compose.yml" | \
        "compose.yaml")

            continue
            ;;

    esac


    if [ -d "$item" ]; then

        rm -rf "$APP_DIR/$name"

        cp -a \
            "$item" \
            "$APP_DIR/$name"

    elif [ -f "$item" ]; then

        cp -f \
            "$item" \
            "$APP_DIR/$name"

    fi

done


success "Project files deployed to $APP_DIR."


# =========================================================
# Check deployed files
# =========================================================

info "Checking deployed project..."


if [ ! -f "$APP_DIR/Dockerfile" ]; then

    error "Dockerfile deployment failed."

    exit 1
fi


if [ ! -f "$APP_DIR/$SOURCE_COMPOSE_FILE" ]; then

    error "Docker Compose deployment failed."

    exit 1
fi


if [ ! -f "$APP_DIR/nginx/conf/nginx.conf" ]; then

    error "Nginx configuration deployment failed."

    echo
    echo "Expected:"
    echo "  $APP_DIR/nginx/conf/nginx.conf"

    exit 1
fi


success "Deployed project structure is valid."


# =========================================================
# Prepare large files
#
# Priority:
#
# 1. Deployment directory already contains file
# 2. Source directory contains file
# 3. Download from MEGA
# =========================================================

prepare_large_file() {

    local filename="$1"
    local url="$2"

    local app_file="$APP_DIR/$filename"
    local source_file="$SOURCE_DIR/$filename"


    info "Checking large file: $filename"


    # -----------------------------------------------------
    # Deployment directory
    # -----------------------------------------------------

    if [ -s "$app_file" ]; then

        success "$filename already exists."

        echo
        echo "File:"
        echo "  $app_file"

        echo
        echo "Size:"
        du -h "$app_file"

        echo
        echo "Skip MEGA download."

        return 0

    fi


    # -----------------------------------------------------
    # Remove empty / broken zero-byte file
    # -----------------------------------------------------

    if [ -f "$app_file" ]; then

        warning "Empty file detected:"
        echo "  $app_file"

        rm -f "$app_file"

    fi


    # -----------------------------------------------------
    # Source directory
    # -----------------------------------------------------

    if [ -s "$source_file" ]; then

        success "$filename found in source directory."

        echo
        echo "Source:"
        echo "  $source_file"

        echo
        echo "Copying to:"
        echo "  $app_file"

        cp -f \
            "$source_file" \
            "$app_file"


        if [ -s "$app_file" ]; then

            success "$filename copied successfully."

            echo
            echo "Size:"
            du -h "$app_file"

            return 0

        else

            error "Failed to copy $filename."

            exit 1
        fi

    fi


    # -----------------------------------------------------
    # MEGA
    # -----------------------------------------------------

    warning "$filename was not found locally."

    echo
    echo "Downloading from MEGA..."

    cd "$APP_DIR"


    # Remove possible partial file
    rm -f "$app_file"


    megatools dl "$url"


    if [ -s "$app_file" ]; then

        success "$filename downloaded successfully."

        echo
        echo "Size:"
        du -h "$app_file"

    else

        error "Failed to download $filename."

        exit 1
    fi
}


# =========================================================
# Prepare JDK / Backend JAR
# =========================================================

prepare_large_file \
    "$JDK_FILE" \
    "$JDK_URL"


prepare_large_file \
    "$JAR_FILE" \
    "$JAR_URL"


# =========================================================
# Docker image cache
# =========================================================

check_or_pull_image() {

    local image="$1"

    info "Checking Docker image: $image"


    if docker image inspect "$image" >/dev/null 2>&1; then

        success "Docker image already exists:"
        echo "  $image"

        echo
        echo "Skip docker pull."

        return 0

    fi


    warning "Docker image not found:"
    echo "  $image"

    echo
    echo "Pulling Docker image..."


    docker pull "$image"


    if docker image inspect "$image" >/dev/null 2>&1; then

        success "Docker image downloaded successfully:"
        echo "  $image"

    else

        error "Docker image download failed:"
        echo "  $image"

        exit 1
    fi
}


# =========================================================
# Check required Docker images
# =========================================================

check_or_pull_image "$NGINX_IMAGE"

check_or_pull_image "$MYSQL_IMAGE"


# =========================================================
# Validate Docker Compose
# =========================================================

info "Validating Docker Compose configuration..."

cd "$APP_DIR"

docker compose config >/dev/null

success "Docker Compose configuration is valid."


# =========================================================
# Build and start
# =========================================================

info "Building and starting Employee Management System..."

docker compose up -d --build

success "Employee Management System started."


# =========================================================
# Container status
# =========================================================

info "Container status"

docker compose ps


# =========================================================
# Linux IP
# =========================================================

LINUX_IP="$(
    hostname -I 2>/dev/null |
    awk '{print $1}'
)"


if [ -z "$LINUX_IP" ]; then
    LINUX_IP="<Linux-IP>"
fi


# =========================================================
# Deployment completed
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
