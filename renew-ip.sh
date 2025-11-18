#!/usr/bin/env bash
# wifi-reconnect.sh
# Script : force une reconnexion Wi-Fi + toggle Location Services
# Conçu pour macOS (M2, Tahoe), nécessite sudo/root.

set -eu
LOG_PREFIX="[wifi-reconnect]"

# --- s'assurer d'être root ---
if [ "$(id -u)" -ne 0 ]; then
  echo "${LOG_PREFIX} relaunching with sudo..."
  exec sudo "$0" "$@"
fi

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }

backup_plist() {
  local f="$1"
  local b="/var/tmp/$(basename "$f").bak.$(date +%s)"
  cp -a "$f" "$b" 2>/dev/null && echo "$(timestamp) backup $f -> $b"
}

toggle_location_services() {
  local action="$1"   # "disable" ou "enable"
  local value
  if [ "$action" = "disable" ]; then
    value="false"
  else
    value="true"
  fi

  local dir="/var/db/locationd/Library/Preferences/ByHost"
  if [ ! -d "$dir" ]; then
    echo "${LOG_PREFIX} $dir introuvable. Je ne peux pas modifier Location Services."
    return 1
  fi

  shopt -s nullglob
  local plists=("$dir"/com.apple.locationd*.plist)
  if [ ${#plists[@]} -eq 0 ]; then
    echo "${LOG_PREFIX} aucun plist com.apple.locationd*.plist trouvé dans $dir."
    return 1
  fi

  for p in "${plists[@]}"; do
    echo "${LOG_PREFIX} processing $p ..."
    backup_plist "$p" || true
    /usr/bin/defaults write "$p" LocationServicesEnabled -bool "$value" || {
      echo "${LOG_PREFIX} impossible d'écrire dans $p"
    }
  done

  # redémarrer le daemon locationd
  echo "${LOG_PREFIX} restart locationd..."
  pkill -9 locationd 2>/dev/null || true
  sleep 2
  # laisser launchd redémarrer le service automatiquement
  echo "${LOG_PREFIX} done (locationd should restart automatically)."
}

# --- début du script principal ---
echo
echo "${LOG_PREFIX} Début du script."

echo "${LOG_PREFIX} Disable Location Services"
toggle_location_services disable || echo "${LOG_PREFIX} warning: toggle disable returned non-zero"

echo "${LOG_PREFIX} Stop wifi"
networksetup -setnetworkserviceenabled "Wi-Fi" off || {
  echo "${LOG_PREFIX} échec désactivation Wi-Fi"
}

sleep 6

echo "${LOG_PREFIX} re init DHCP and ip"
ipconfig set en0 DHCP || echo "${LOG_PREFIX} ipconfig DHCP failed"

sleep 6

echo "${LOG_PREFIX} flush dns"
dscacheutil -flushcache || true
sleep 1
killall -HUP mDNSResponder 2>/dev/null || true

sleep 6

echo "${LOG_PREFIX} start wifi"
networksetup -setnetworkserviceenabled "Wi-Fi" on || {
  echo "${LOG_PREFIX} échec activation Wi-Fi"
}

sleep 6

echo "${LOG_PREFIX} renew ip"
ifconfig en0 down || true
sleep 6
ifconfig en0 up || true
sleep 6

echo "${LOG_PREFIX} Check connexion (ping)"
if ping -c 5 free.fr >/dev/null 2>&1; then
  echo "${LOG_PREFIX} ping OK"
else
  echo "${LOG_PREFIX} ping échoue"
fi

echo "${LOG_PREFIX} Enable Location Services"
toggle_location_services enable || echo "${LOG_PREFIX} warning: toggle enable returned non-zero"

echo "${LOG_PREFIX} Fin du script."
exit 0

