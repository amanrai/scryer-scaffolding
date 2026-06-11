#!/usr/bin/env bash

# SwiftBar plugin for the local Scryer harness.
# Set SwiftBar's plugin folder to:
#   /Users/amanrai/Code/common-volume/scryer/swiftbar

SCRYER_ROOT="/Users/amanrai/Code/common-volume/scryer"
SCRYER_BIN="$SCRYER_ROOT/bin/scryer"
CONFIG_FILE="$SCRYER_ROOT/config/harness.env"

# SwiftBar/macOS GUI apps often have a minimal PATH.
export PATH="/Users/amanrai/.local/bin:/Users/amanrai/.nvm/versions/node/v22.22.0/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

if [[ -n "${SCRYER_NODE_BIN_DIR:-}" && -d "$SCRYER_NODE_BIN_DIR" ]]; then
  export PATH="$SCRYER_NODE_BIN_DIR:$PATH"
fi

: "${SCRYER_PM_URL:=http://127.0.0.1:43210}"
: "${SCRYER_LOOM_URL:=http://127.0.0.1:43211}"
: "${SCRYER_PM_PORT:=43210}"
: "${SCRYER_LOOM_PORT:=43211}"
: "${SCRYER_RESERVED_PORT_START:=43200}"
: "${SCRYER_RESERVED_PORT_END:=43299}"
: "${SCRYER_SWIFTBAR_AUTOSTART:=0}"
: "${SCRYER_NODE_BIN_DIR:=/Users/amanrai/.nvm/versions/node/v22.22.0/bin}"

RUN_DIR="$SCRYER_ROOT/run"
AUTOSTART_LOCK="$RUN_DIR/swiftbar-autostart.lock"
AUTOSTART_STAMP="$RUN_DIR/swiftbar-autostart.stamp"
mkdir -p "$RUN_DIR"

http_ok() {
  curl -fsS --max-time 1 "$1" >/dev/null 2>&1
}

unknown_reserved_port_count() {
  local lines count=0 port
  lines=$(lsof -nP -iTCP:"${SCRYER_RESERVED_PORT_START}-${SCRYER_RESERVED_PORT_END}" -sTCP:LISTEN 2>/dev/null || true)
  [[ -z "$lines" ]] && { echo 0; return; }
  while read -r line; do
    [[ "$line" == COMMAND* || -z "$line" ]] && continue
    port=$(awk '{print $9}' <<<"$line" | sed -E 's/.*:([0-9]+)$/\1/')
    if [[ "$port" != "$SCRYER_PM_PORT" && "$port" != "$SCRYER_LOOM_PORT" ]]; then
      count=$((count + 1))
    fi
  done <<< "$lines"
  echo "$count"
}

boot_key() {
  sysctl -n kern.boottime 2>/dev/null | shasum 2>/dev/null | awk '{print $1}' || date +%Y%m%d
}

autostart_if_needed() {
  [[ "$SCRYER_SWIFTBAR_AUTOSTART" == "1" ]] || return 0
  [[ "$unknown_ports" == "0" ]] || return 0
  [[ "$pm_status" == "healthy" && "$loom_status" == "healthy" ]] && return 0

  local key running_pid
  key="$(boot_key)"
  if [[ -f "$AUTOSTART_STAMP" && "$(cat "$AUTOSTART_STAMP" 2>/dev/null)" == "$key" ]]; then
    return 0
  fi

  if [[ -f "$AUTOSTART_LOCK" ]]; then
    running_pid="$(cat "$AUTOSTART_LOCK" 2>/dev/null)"
    if [[ -n "$running_pid" ]] && kill -0 "$running_pid" 2>/dev/null; then
      return 0
    fi
    rm -f "$AUTOSTART_LOCK"
  fi

  (
    echo "$BASHPID" > "$AUTOSTART_LOCK"
    "$SCRYER_BIN" up --no-open >> "$SCRYER_ROOT/logs/swiftbar-autostart.log" 2>&1 && echo "$key" > "$AUTOSTART_STAMP"
    rm -f "$AUTOSTART_LOCK"
  ) &
}

pm_status="stopped"
pm_api_status="stopped"
loom_status="stopped"
loom_proxy_status="stopped"
icon="○"
color="gray"
label="Scryer"

if http_ok "$SCRYER_PM_URL/healthz"; then
  pm_status="healthy"
fi
if http_ok "$SCRYER_PM_URL/api/projects"; then
  pm_api_status="healthy"
fi
if http_ok "$SCRYER_LOOM_URL"; then
  loom_status="healthy"
fi
if http_ok "$SCRYER_LOOM_URL/api/projects"; then
  loom_proxy_status="healthy"
fi

unknown_ports=$(unknown_reserved_port_count)
autostart_if_needed

if [[ "$unknown_ports" != "0" ]]; then
  icon="!"
  color="red"
  label="Scryer ports"
elif [[ "$pm_status" == "healthy" && "$pm_api_status" == "healthy" && "$loom_status" == "healthy" && "$loom_proxy_status" == "healthy" ]]; then
  icon="●"
  color="#00d084"
  label="Scryer"
elif [[ "$pm_status" == "healthy" || "$pm_api_status" == "healthy" || "$loom_status" == "healthy" || "$loom_proxy_status" == "healthy" ]]; then
  icon="◐"
  color="orange"
  label="Scryer partial"
else
  icon="○"
  color="gray"
  label="Scryer off"
fi

if [[ ! -x "$SCRYER_BIN" ]]; then
  echo "! Scryer missing | color=red"
  echo "---"
  echo "CLI not executable: $SCRYER_BIN"
  exit 0
fi

echo "$icon $label | color=$color"
echo "---"
echo "Open Loom | bash=$SCRYER_BIN param1=open terminal=false refresh=true"
echo "Start Quietly | bash=$SCRYER_BIN param1=up param2=--no-open terminal=false refresh=true"
echo "Restart Quietly | bash=$SCRYER_BIN param1=restart param2=--no-open terminal=false refresh=true"
echo "Stop | bash=$SCRYER_BIN param1=down terminal=false refresh=true"
echo "---"
echo "Status | bash=$SCRYER_BIN param1=status terminal=true refresh=true"
echo "Doctor | bash=$SCRYER_BIN param1=doctor terminal=true refresh=true"
echo "Logs: PM | bash=$SCRYER_BIN param1=logs param2=pm terminal=true"
echo "Logs: Loom | bash=$SCRYER_BIN param1=logs param2=loom terminal=true"
echo "---"
echo "PM health: $pm_status"
echo "PM API: $pm_api_status"
echo "Loom: $loom_status"
echo "Loom API proxy: $loom_proxy_status"
echo "Reserved port violations: $unknown_ports"
echo "SwiftBar autostart: $([[ "$SCRYER_SWIFTBAR_AUTOSTART" == "1" ]] && echo enabled || echo disabled)"
echo "---"
echo "PM URL: $SCRYER_PM_URL | href=$SCRYER_PM_URL"
echo "Loom URL: $SCRYER_LOOM_URL | href=$SCRYER_LOOM_URL"
echo "Refresh | refresh=true"
