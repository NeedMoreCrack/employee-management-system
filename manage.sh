
#!/usr/bin/env bash
set -Eeuo pipefail

# Employee Management System - Docker Compose management (WSL / Alpine / Podroid)
# Usage: sudo bash manage.sh (or bash manage.sh when already root)
APP_DIR="/usr/local/app"
MYSQL_PORT="3307"
MYSQL_USER="root"
MYSQL_DATABASE="restful"

info() { printf '\n============================================================\n[INFO] %s\n============================================================\n' "$*"; }
success() { printf '\n[OK] %s\n' "$*"; }
warning() { printf '\n[WARNING] %s\n' "$*" >&2; }
die() { printf '\n[ERROR] %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root: sudo bash manage.sh"
[[ -d "$APP_DIR" ]] || die "Deployment directory not found: $APP_DIR. Run install_docker_tools.sh first."
COMPOSE_FILE=""
for file in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
  if [[ -f "$APP_DIR/$file" ]]; then COMPOSE_FILE="$APP_DIR/$file"; break; fi
done
[[ -n "$COMPOSE_FILE" ]] || die "Docker Compose configuration not found in $APP_DIR"
command -v docker >/dev/null 2>&1 || die "Docker is not installed"
docker info >/dev/null 2>&1 || die "Docker daemon is not running"
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is unavailable"
cd "$APP_DIR"

# Explicit -f and --project-directory keep all actions on the deployed project.
compose() { docker compose -f "$COMPOSE_FILE" --project-directory "$APP_DIR" "$@"; }

get_linux_ip() {
  local found=""
  if command -v ip >/dev/null 2>&1; then
    found="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}' || true)"
  fi
  if [[ -z "$found" ]]; then found="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"; fi
  if [[ -z "$found" ]] && command -v ip >/dev/null 2>&1; then
    found="$(ip -4 -o addr show scope global 2>/dev/null | awk 'NR==1 {split($4,a,"/"); print a[1]}' || true)"
  fi
  printf '%s\n' "${found:-unavailable}"
}

pause() { printf '\n'; read -r -p '按 Enter 返回主選單...' _ || true; }
show_header() {
  clear 2>/dev/null || true
  printf '============================================================\n Employee Management System\n Docker Management\n============================================================\n'
  printf 'Deployment: %s\n\n' "$APP_DIR"
}
show_menu() {
  cat <<'MENU'
------------------------------------------------------------
請選擇操作：
------------------------------------------------------------
1) 啟動專案
2) 關閉專案
3) 重啟專案
4) 查看 Container 狀態

5) 查看全部 Log
6) 查看 Backend Log
7) 查看 Frontend Log
8) 查看 MySQL Log

9) Rebuild 專案
10) 修復 Frontend（重建容器／重新掛載靜態檔案）
0) 離開
MENU
  printf '\n'
}
show_container_status() { info 'Container status'; compose ps; }
show_connection_info() {
  local linux_ip
  linux_ip="$(get_linux_ip)"
  printf '\n============================================================\n Employee Management System - Connection Information\n============================================================\n'
  printf 'Linux internal IP: %s\n' "$linux_ip"
  printf '\n[LOCAL ACCESS IN LINUX]\nFrontend: http://127.0.0.1:80/\nBackend:  http://127.0.0.1:9090/\n'
  printf '\n[MYSQL]\nHost (in Linux): 127.0.0.1\nPort: %s\nUser: %s\nDatabase: %s\n' "$MYSQL_PORT" "$MYSQL_USER" "$MYSQL_DATABASE"
  printf 'Password: (not displayed; see your local Compose/.env configuration)\n'
  printf 'CLI (if mysql client installed): mysql -h 127.0.0.1 -P%s -u %s -p\n' "$MYSQL_PORT" "$MYSQL_USER"
  if [[ "$linux_ip" == 10.0.2.* ]]; then
    printf '\n[PODROID / VIRTUAL NETWORK]\n'
    printf 'The Linux internal IP is NOT automatically the Android Wi-Fi IP.\n'
    printf 'For Windows access, forward Android ports or create an SSH tunnel:\n'
    printf '  ssh -N -p SSH_PORT -L 18080:127.0.0.1:80 -L 19090:127.0.0.1:9090 root@PHONE_IP\n'
    printf 'Then access http://localhost:18080/ from Windows.\n'
  elif [[ "$linux_ip" != unavailable ]]; then
    printf '\n[POSSIBLE NETWORK URL - host network must be reachable]\nhttp://%s/\n' "$linux_ip"
  fi
  printf '============================================================\n'
}
show_project_info() { show_container_status; show_connection_info; }
start_project() { info 'Starting Employee Management System...'; compose up -d; success 'Project started'; show_project_info; }
stop_project() {
  info 'Stopping Employee Management System...'
  compose down # Does not remove named volumes; never use -v here.
  success 'Project stopped (persistent data preserved)'
}
restart_project() {
  info 'Restarting Employee Management System...'
  compose up -d --force-recreate
  success 'Project restarted'
  show_project_info
}
show_logs() {
  local service="${1:-}"
  info "${service:-All} logs"
  printf '按 Ctrl+C 停止 Log 並返回主選單。\n\n'
  if [[ -n "$service" ]]; then compose logs -f "$service" || true; else compose logs -f || true; fi
}
rebuild_project() { info 'Building and starting Employee Management System...'; compose up -d --build; success 'Project rebuilt and started'; show_project_info; }

repair_frontend() {
  info 'Repairing Frontend: recreate container and refresh bind mounts...'
  # Recreate only the frontend; do not rebuild or restart the backend and MySQL.
  if ! compose up -d --force-recreate --no-deps frontend; then
    warning 'Frontend recreate failed. Check: docker compose logs --tail=100 frontend'
    return 1
  fi

  local container_id
  container_id="$(compose ps -q frontend)"
  if [[ -z "$container_id" ]]; then
    warning 'Frontend container was not found after recreation.'
    return 1
  fi

  printf '\n[CHECK] Frontend files inside container:\n'
  if ! docker exec "$container_id" ls -lah /usr/share/nginx/html/; then
    warning 'Unable to read frontend directory inside container.'
    return 1
  fi

  if ! docker exec "$container_id" test -f /usr/share/nginx/html/index.html; then
    warning 'index.html is missing inside the container.'
    warning 'Check /usr/local/app/nginx/html and the frontend bind mount in docker-compose.yml.'
    return 1
  fi
  success 'index.html exists in frontend container.'

  printf '\n[CHECK] HTTP response from Linux localhost:\n'
  if command -v curl >/dev/null 2>&1; then
    local http_code="" attempt
    for attempt in 1 2 3 4 5; do
      http_code="$(curl --noproxy '*' -sS -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:80/ 2>/dev/null)" || http_code=""
      [[ "$http_code" == 200 ]] && break
      [[ "$attempt" -eq 5 ]] || sleep 1
    done
    printf 'HTTP status: %s\n' "${http_code:-unavailable}"
    if [[ "$http_code" != 200 ]]; then
      warning 'Frontend did not return HTTP 200. Check Nginx configuration and logs.'
      return 1
    fi
    success 'Frontend HTTP 200 OK.'
  else
    warning 'curl is not installed. Skipping HTTP test; run curl -I http://127.0.0.1:80/ manually.'
  fi
  printf '\n[INFO] If using an SSH tunnel on Windows, visit http://localhost:18080/\n'
}

confirm_action() {
  local answer=""
  printf '\n'
  read -r -p "$1 [y/N]: " answer || return 1
  case "$answer" in y|Y|yes|YES|Yes) return 0;; *) return 1;; esac
}

while true; do
  show_header
  show_menu
  choice=""
  read -r -p '請輸入選項 [0-10]: ' choice || { printf '\nBye.\n'; exit 0; }
  case "$choice" in
    1) start_project; pause ;;
    2) if confirm_action '確定要關閉 Employee Management System？'; then stop_project; else warning '已取消關閉操作。'; fi; pause ;;
    3) if confirm_action '確定要重新啟動 Employee Management System？'; then restart_project; else warning '已取消重新啟動操作。'; fi; pause ;;
    4) show_container_status; pause ;;
    5) show_logs ;;
    6) show_logs backend ;;
    7) show_logs frontend ;;
    8) show_logs mysql ;;
    9) if confirm_action '確定要重新 Build Employee Management System？'; then rebuild_project; else warning '已取消 Rebuild。'; fi; pause ;;
    10) if confirm_action '確定要重新建立 Frontend Container（不動 Backend / MySQL）？'; then repair_frontend || warning 'Frontend 修復或驗證失敗，請查看上方訊息。'; else warning '已取消 Frontend 修復。'; fi; pause ;;
    0) printf '\nBye.\n'; exit 0 ;;
    *) warning "無效選項：$choice"; sleep 1 ;;
  esac
done
