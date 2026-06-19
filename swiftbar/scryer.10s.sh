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

http_ok() {
  curl -fsS --max-time 2 "$1" >/dev/null 2>&1
}

pm_status="stopped"
pm_api_status="stopped"
loom_status="stopped"
loom_proxy_status="stopped"
icon="○"
color="gray"
label="Scryer off"

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

if [[ "$pm_status" == "healthy" && "$pm_api_status" == "healthy" && "$loom_status" == "healthy" && "$loom_proxy_status" == "healthy" ]]; then
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

echo "$icon $label | color=$color"
echo "---"
echo "Open Loom | href=$SCRYER_LOOM_URL"
echo "Open PM Health | href=$SCRYER_PM_URL/healthz"
echo "Open PM Projects API | href=$SCRYER_PM_URL/api/projects"
echo "---"
echo "PM health: $pm_status"
echo "PM API: $pm_api_status"
echo "Loom: $loom_status"
echo "Loom API proxy: $loom_proxy_status"
echo "---"
echo "PM URL: $SCRYER_PM_URL | href=$SCRYER_PM_URL"
echo "Loom URL: $SCRYER_LOOM_URL | href=$SCRYER_LOOM_URL"
echo "Refresh | refresh=true"
