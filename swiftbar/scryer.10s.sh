#!/usr/bin/env bash

# SwiftBar plugin for monitoring a Scryer/Loom harness.
# Set SwiftBar's plugin folder to:
#   /Users/amanrai/Code/common-volume/scryer/swiftbar
#
# This plugin is intentionally health/link-only. It may point at a local
# harness or a remote Tailnet harness, so it does not run local start/stop/log
# commands and it does not treat local reserved-port listeners as failures.

SCRYER_ROOT="/Users/amanrai/Code/common-volume/scryer"
CONFIG_FILE="$SCRYER_ROOT/config/harness.env"

# SwiftBar/macOS GUI apps often have a minimal PATH.
export PATH="/Users/amanrai/.local/bin:/Users/amanrai/.nvm/versions/node/v22.22.0/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

: "${SCRYER_PM_URL:=http://127.0.0.1:43210}"
: "${SCRYER_LOOM_URL:=http://127.0.0.1:43211}"

url_reachable() {
  curl -sS --max-time 2 "$1" >/dev/null 2>&1
}

endpoint_ok() {
  curl -fsS --max-time 2 "$1" >/dev/null 2>&1
}

pm_status="not reachable"
pm_api_status="not reachable"
loom_status="not reachable"
loom_proxy_status="not reachable"
icon="○"
color="gray"
label="Scryer off"

if url_reachable "$SCRYER_PM_URL"; then
  pm_status="reachable"
fi
if endpoint_ok "$SCRYER_PM_URL/api/projects"; then
  pm_api_status="reachable"
fi
if url_reachable "$SCRYER_LOOM_URL"; then
  loom_status="reachable"
fi
if endpoint_ok "$SCRYER_LOOM_URL/api/projects"; then
  loom_proxy_status="reachable"
fi

if [[ "$pm_status" == "reachable" && "$pm_api_status" == "reachable" && "$loom_status" == "reachable" && "$loom_proxy_status" == "reachable" ]]; then
  icon="●"
  color="#00d084"
  label="Scryer"
elif [[ "$pm_status" == "reachable" || "$pm_api_status" == "reachable" || "$loom_status" == "reachable" || "$loom_proxy_status" == "reachable" ]]; then
  icon="◐"
  color="orange"
  label="Scryer partial"
else
  icon="○"
  color="gray"
  label="Scryer off"
fi

echo "$icon $label | color=$color"
echo "---"
echo "Open Loom | href=$SCRYER_LOOM_URL"
echo "Open PM Projects API | href=$SCRYER_PM_URL/api/projects"
echo "---"
echo "PM reachability: $pm_status"
echo "PM API reachability: $pm_api_status"
echo "Loom reachability: $loom_status"
echo "Loom API proxy reachability: $loom_proxy_status"
echo "---"
echo "PM URL: $SCRYER_PM_URL | href=$SCRYER_PM_URL"
echo "Loom URL: $SCRYER_LOOM_URL | href=$SCRYER_LOOM_URL"
echo "Refresh | refresh=true"
