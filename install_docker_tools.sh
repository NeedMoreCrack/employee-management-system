
#!/usr/bin/env bash
set -Eeuo pipefail

# Employee Management System - Ubuntu/Debian/Alpine/Fedora/Arch
# Run: sudo bash install_docker_tools.sh (or bash ... when already root)

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
APP_DIR="/usr/local/app"
JAR_FILE="myWeb.jar"
JAR_IMAGE="codeishard/myweb-file:latest"
JAR_IMAGE_PATH="/files/myWeb.jar"
JAR_IMAGE_PLATFORM="linux/amd64"  # Scratch file-carrier image; never executed.
TEMP_CONTAINER=""
TEMP_JAR=""

info() { printf '\n[INFO] %s\n' "$*"; }
ok() { printf '[OK] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

cleanup() {
  if [[ -n "$TEMP_CONTAINER" ]]; then
    docker rm -f "$TEMP_CONTAINER" >/dev/null 2>&1 || true
  fi
  if [[ -n "$TEMP_JAR" ]]; then
    rm -f -- "$TEMP_JAR"
  fi
}
trap cleanup EXIT
trap 'printf "[ERROR] Failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

[[ $EUID -eq 0 ]] || die "Run as root: sudo bash install_docker_tools.sh"
[[ -f "$SOURCE_DIR/Dockerfile" ]] || die "Missing $SOURCE_DIR/Dockerfile"
[[ -f "$SOURCE_DIR/nginx/conf/nginx.conf" ]] || die "Missing nginx/conf/nginx.conf"

SOURCE_COMPOSE=""
for name in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
  if [[ -f "$SOURCE_DIR/$name" ]]; then
    SOURCE_COMPOSE="$name"
    break
  fi
done
[[ -n "$SOURCE_COMPOSE" ]] || die "Missing Docker Compose configuration"

if grep -Eq '(^|[[:space:]])(COPY|ADD)[[:space:]]+.*jdk17\.tar\.gz' "$SOURCE_DIR/Dockerfile"; then
  die "Dockerfile still requires jdk17.tar.gz. Update it to FROM eclipse-temurin:17-jre first."
fi

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
fi
DISTRO="${PRETTY_NAME:-${ID:-unknown}}"
ARCH="$(uname -m)"

info "Source: $SOURCE_DIR | Destination: $APP_DIR"
info "System: $DISTRO | Architecture: $ARCH"

# =========================================================
# Install Docker / Docker Compose V2 / Docker Buildx
# Ubuntu / Debian / Alpine / Fedora / Arch
# =========================================================

install_docker() {

  if command -v apt-get >/dev/null 2>&1; then

    info "APT-based Linux detected: ${ID:-unknown}"

    apt-get update

    # Check if an APT package has an installable candidate.
    apt_package_available() {
      local candidate

      candidate="$(
        apt-cache policy "$1" 2>/dev/null |
          awk '/Candidate:/ {print $2; exit}'
      )"

      [[ -n "$candidate" && "$candidate" != "(none)" ]]
    }

    # Ubuntu packages are normally provided through Universe.
    if [[ "${ID:-}" == "ubuntu" ]]; then

      if ! apt_package_available docker-compose-v2 \
        || ! apt_package_available docker-buildx; then

        info "Checking Ubuntu Universe repository"

        apt-get install -y software-properties-common
        add-apt-repository -y universe
        apt-get update
      fi
    fi

    # Install the distribution's Docker Engine.
    if ! command -v docker >/dev/null 2>&1; then
      apt_package_available docker.io \
        || die "docker.io is unavailable in the configured APT repositories"

      apt-get install -y docker.io
    fi

    # Compose V2
    if ! docker compose version >/dev/null 2>&1; then

      if apt_package_available docker-compose-v2; then
        apt-get install -y docker-compose-v2

      elif apt_package_available docker-compose-plugin; then
        apt-get install -y docker-compose-plugin

      else
        die "Docker Compose V2 package not found"
      fi
    fi

    # Buildx
    if ! docker buildx version >/dev/null 2>&1; then

      if apt_package_available docker-buildx; then
        apt-get install -y docker-buildx

      elif apt_package_available docker-buildx-plugin; then
        apt-get install -y docker-buildx-plugin

      else
        die "Docker Buildx package not found"
      fi
    fi

  elif command -v apk >/dev/null 2>&1; then

    info "Alpine Linux detected"

    apk update
    apk add docker docker-cli-compose docker-cli-buildx

  elif command -v dnf >/dev/null 2>&1; then

    info "DNF-based Linux detected"

    dnf install -y \
      docker \
      docker-compose-plugin \
      docker-buildx-plugin

  elif command -v pacman >/dev/null 2>&1; then

    info "Arch-based Linux detected"

    pacman -Sy --needed --noconfirm \
      docker \
      docker-compose \
      docker-buildx

  else

    die "Unsupported package manager. Please install Docker manually."

  fi

  # Final verification
  command -v docker >/dev/null 2>&1 \
    || die "Docker CLI installation failed"

  docker compose version >/dev/null 2>&1 \
    || die "Docker Compose V2 installation failed"

  docker buildx version >/dev/null 2>&1 \
    || die "Docker Buildx installation failed"

  ok "Docker / Compose V2 / Buildx installation completed"
}

if ! command -v docker >/dev/null 2>&1 \
   || ! docker compose version >/dev/null 2>&1 \
   || ! docker buildx version >/dev/null 2>&1; then

  info "Installing missing Docker components"
  install_docker
else
  ok "Docker CLI / Compose / Buildx already available; skip package installation"
fi

command -v docker >/dev/null 2>&1 || die "Docker CLI not found"
docker compose version || die "Docker Compose v2 unavailable"
docker buildx version || die "Docker Buildx unavailable"

# Check Docker daemon.
if ! docker info >/dev/null 2>&1; then
  info "Starting Docker daemon"

  if command -v systemctl >/dev/null 2>&1 \
     && [[ -d /run/systemd/system ]]; then
    systemctl enable --now docker

  elif command -v rc-service >/dev/null 2>&1; then
    rc-update add docker default >/dev/null 2>&1 || true
    rc-service docker start

  elif command -v service >/dev/null 2>&1; then
    service docker start

  else
    die "Docker daemon unavailable; start it manually and rerun"
  fi
fi

docker info >/dev/null 2>&1 \
  || die "Cannot communicate with Docker daemon"

docker --version

# Prepare deployment directory.
# Never wipe mysql/data or nginx/html on redeployment.
mkdir -p \
  "$APP_DIR/mysql/data" \
  "$APP_DIR/mysql/conf" \
  "$APP_DIR/mysql/init" \
  "$APP_DIR/nginx/conf" \
  "$APP_DIR/nginx/html"

# Prepare JAR BEFORE touching running services.
prepare_jar() {
  local destination="$APP_DIR/$JAR_FILE"

  if [[ -s "$SOURCE_DIR/$JAR_FILE" \
        && "$SOURCE_DIR/$JAR_FILE" != "$destination" ]]; then

    info "Copying JAR from source directory"
    cp -f "$SOURCE_DIR/$JAR_FILE" "$destination"

  elif [[ -s "$destination" ]]; then
    ok "Existing JAR found: $destination (skip Docker Hub download)"

  else
    info "Downloading $JAR_FILE from $JAR_IMAGE ($JAR_IMAGE_PLATFORM)"

    # The carrier image can be AMD64 even when the target device is ARM64:
    # docker create/cp never starts or executes its content.
    docker pull --platform "$JAR_IMAGE_PLATFORM" "$JAR_IMAGE"

    TEMP_CONTAINER="ems-jar-extract-$$"
    TEMP_JAR="$destination.tmp.$$"

    docker create \
      --platform "$JAR_IMAGE_PLATFORM" \
      --name "$TEMP_CONTAINER" \
      "$JAR_IMAGE" \
      /bin/true >/dev/null

    docker cp \
      "$TEMP_CONTAINER:$JAR_IMAGE_PATH" \
      "$TEMP_JAR"

    [[ -s "$TEMP_JAR" ]] || die "Extracted JAR is empty"

    mv -f "$TEMP_JAR" "$destination"
    TEMP_JAR=""

    docker rm "$TEMP_CONTAINER" >/dev/null
    TEMP_CONTAINER=""
  fi

  [[ -s "$destination" ]] || die "Missing/empty $destination"
  du -h "$destination"
}

prepare_jar

# Copy files only when source and deployment directories differ.
if [[ "$SOURCE_DIR" != "$APP_DIR" ]]; then
  info "Copying project files (preserving persistent data)"

  cp -f "$SOURCE_DIR/Dockerfile" "$APP_DIR/Dockerfile"
  cp -f "$SOURCE_DIR/$SOURCE_COMPOSE" "$APP_DIR/docker-compose.yml"

  [[ ! -f "$SOURCE_DIR/manage.sh" ]] \
    || cp -f "$SOURCE_DIR/manage.sh" "$APP_DIR/manage.sh"

  [[ ! -f "$SOURCE_DIR/README.md" ]] \
    || cp -f "$SOURCE_DIR/README.md" "$APP_DIR/README.md"

  [[ ! -f "$SOURCE_DIR/.dockerignore" ]] \
    || cp -f "$SOURCE_DIR/.dockerignore" "$APP_DIR/.dockerignore"

  # Copy configs/assets without deleting existing deployment data.
  [[ ! -d "$SOURCE_DIR/mysql/conf" ]] \
    || cp -a "$SOURCE_DIR/mysql/conf/." "$APP_DIR/mysql/conf/"

  [[ ! -d "$SOURCE_DIR/mysql/init" ]] \
    || cp -a "$SOURCE_DIR/mysql/init/." "$APP_DIR/mysql/init/"

  [[ ! -d "$SOURCE_DIR/nginx/conf" ]] \
    || cp -a "$SOURCE_DIR/nginx/conf/." "$APP_DIR/nginx/conf/"

  [[ ! -d "$SOURCE_DIR/nginx/html" ]] \
    || cp -a "$SOURCE_DIR/nginx/html/." "$APP_DIR/nginx/html/"
else
  ok "Running from deployment directory; skipping self-copy"
fi

COMPOSE_PATH="$APP_DIR/docker-compose.yml"

if [[ "$SOURCE_DIR" == "$APP_DIR" ]]; then
  COMPOSE_PATH="$APP_DIR/$SOURCE_COMPOSE"
fi

[[ -f "$COMPOSE_PATH" ]] || die "Missing deployed Compose file"

info "Validating Compose"
docker compose \
  -f "$COMPOSE_PATH" \
  --project-directory "$APP_DIR" \
  config -q

info "Building and starting services"

# 'up' recreates changed containers; no unconditional down / volume deletion.
docker compose \
  -f "$COMPOSE_PATH" \
  --project-directory "$APP_DIR" \
  up -d --build

info "Container status"

docker compose \
  -f "$COMPOSE_PATH" \
  --project-directory "$APP_DIR" \
  ps

# =========================================================
# Network information (Ubuntu / Alpine / BusyBox / Podroid)
# Linux guest IP is NOT necessarily the Android Wi-Fi IP.
# =========================================================
get_linux_ip() {
  local detected_ip=""

  # 1. Prefer the source IP selected by the Linux routing table.
  if command -v ip >/dev/null 2>&1; then
    detected_ip="$(
      ip -4 route get 1.1.1.1 2>/dev/null \
        | awk '{ for (i=1; i<=NF; i++) if ($i=="src") { print $(i+1); exit } }' \
        || true
    )"
  fi

  # 2. GNU hostname may provide -I; BusyBox hostname may not.
  if [[ -z "$detected_ip" ]]; then
    detected_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  fi

  # 3. Use an IPv4 global address on a Linux interface as a fallback.
  if [[ -z "$detected_ip" ]] && command -v ip >/dev/null 2>&1; then
    detected_ip="$(
      ip -4 -o addr show scope global 2>/dev/null \
        | awk 'NR==1 {split($4, parts, "/"); print parts[1]}' \
        || true
    )"
  fi

  printf '%s\n' "${detected_ip:-Unavailable}"
}

LINUX_IP="$(get_linux_ip)"

printf '\n[OK] Deployment command finished.\n'
printf 'Source: %s\nDeployment: %s\nArchitecture: %s\n' \
  "$SOURCE_DIR" "$APP_DIR" "$ARCH"

printf '\n[NETWORK]\n'
printf 'Linux internal IP: %s\n' "$LINUX_IP"
printf 'This address may not be reachable from other devices (e.g. Podroid NAT).\n'

printf '\n[LOCAL ACCESS INSIDE LINUX]\n'
printf 'Frontend: http://127.0.0.1:80/\n'
printf 'Backend : http://127.0.0.1:9090/\n'
printf 'MySQL host port: 3307\n'

case "$LINUX_IP" in
  10.0.2.*)
    printf '\n[NOTICE] A 10.0.2.x guest/virtual network address was detected.\n'
    printf 'Do not assume it is your Android Wi-Fi IP.\n'
    ;;
esac

printf '\n[REMOTE ACCESS - IF SSH FORWARDING IS CONFIGURED]\n'
printf 'On Windows: run connect-podroid.bat\n'
printf 'On macOS/Linux: run connect-podroid.sh\n'
printf 'Enter the Android Wi-Fi IP and use the actual SSH port when prompted/configured.\n'
printf 'After the SSH tunnel connects, open these URLs ON THE COMPUTER RUNNING IT:\n'
printf 'Frontend: http://localhost:18080/\n'
printf 'Backend : http://localhost:19090/\n'
printf 'An SSH tunnel is not created by this installer.\n'

printf '\nLogs: cd %s && docker compose logs -f\n' "$APP_DIR"
printf 'Note: Container startup does not guarantee application/database readiness.\n'
