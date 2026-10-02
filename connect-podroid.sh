#!/usr/bin/env bash
set -Eeuo pipefail

# macOS / Linux -> Podroid SSH tunnel
SSH_USER="${PODROID_USER:-root}"
SSH_PORT="${PODROID_SSH_PORT:-9922}"
FRONTEND_LOCAL_PORT="${FRONTEND_LOCAL_PORT:-18080}"
BACKEND_LOCAL_PORT="${BACKEND_LOCAL_PORT:-19090}"

command -v ssh >/dev/null 2>&1 || { printf '[ERROR] OpenSSH client (ssh) is required.\n' >&2; exit 1; }

valid_ipv4() {
  local ip="$1" part
  local -a octets
  [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  IFS='.' read -r -a octets <<< "$ip"
  ((${#octets[@]} == 4)) || return 1
  for part in "${octets[@]}"; do
    ((${#part} <= 3)) || return 1
    ((10#$part <= 255)) || return 1
  done
}

printf '\n========================================\n Podroid SSH Tunnel (macOS / Linux)\n========================================\n'
while :; do
  read -r -p 'Android Wi-Fi IPv4 (e.g. 192.168.0.229): ' PODROID_IP || { printf '\n[ERROR] No IP supplied.\n' >&2; exit 1; }
  PODROID_IP="${PODROID_IP//[[:space:]]/}"
  if valid_ipv4 "$PODROID_IP"; then break; fi
  printf '[ERROR] Invalid IPv4. Try again.\n' >&2
done

printf '\n[INFO] Connecting to %s@%s:%s\n' "$SSH_USER" "$PODROID_IP" "$SSH_PORT"
printf '[INFO] After authentication, keep this terminal open. Ctrl+C to stop.\n'
printf 'Frontend (this computer): http://localhost:%s/\n' "$FRONTEND_LOCAL_PORT"
printf 'Backend  (this computer): http://localhost:%s/\n\n' "$BACKEND_LOCAL_PORT"

exec ssh -N -T -o ExitOnForwardFailure=yes \
  -p "$SSH_PORT" \
  -L "127.0.0.1:${FRONTEND_LOCAL_PORT}:127.0.0.1:80" \
  -L "127.0.0.1:${BACKEND_LOCAL_PORT}:127.0.0.1:9090" \
  "${SSH_USER}@${PODROID_IP}"
