#!/bin/bash
#
# fix-wifi.sh
# Script de diagnostic et réparation du Wi-Fi sur macOS (Apple Silicon).
#
# Objectif : tenter plusieurs niveaux d'escalade pour débloquer le Wi-Fi
# sans avoir à rebooter la machine :
#   1. Vérifier si le Wi-Fi est réellement en panne
#   2. Toggle logiciel de l'interface (ifconfig down/up)
#   3. Redémarrage des daemons Wi-Fi (airportd / wifid)
#   4. Journalisation de chaque tentative avec horodatage
#
# Usage :
#   sudo ./fix-wifi.sh
#
# Nécessite les droits root (sudo) car il manipule l'interface réseau
# et tue des processus système.

set -euo pipefail

# --- Configuration ---------------------------------------------------
INTERFACE="en0"                              # Interface Wi-Fi (vérifier avec `networksetup -listallhardwareports`)
LOG_FILE="$HOME/Library/Logs/fix-wifi.log"   # Fichier de log
PING_TARGET="1.1.1.1"                        # Cible de test de connectivité
PING_COUNT=2
PING_TIMEOUT=3                               # secondes

# --- Fonctions ---------------------------------------------------------

log() {
    # Ajoute une ligne horodatée au fichier de log ET l'affiche à l'écran
    local message="$1"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

check_connectivity() {
    # Retourne 0 (succès) si le ping passe, 1 sinon
    ping -c "$PING_COUNT" -t "$PING_TIMEOUT" "$PING_TARGET" >/dev/null 2>&1
}

toggle_interface() {
    # Niveau 1 : reset logiciel de l'interface réseau
    log "Étape 1/2 : reset de l'interface $INTERFACE (ifconfig down/up)"
    ifconfig "$INTERFACE" down
    sleep 2
    ifconfig "$INTERFACE" up
    sleep 5
}

restart_wifi_daemons() {
    # Niveau 2 : tue et relance les daemons responsables du Wi-Fi.
    # macOS les relance automatiquement une fois tués (ce sont des
    # daemons supervisés par launchd).
    log "Étape 2/2 : redémarrage des daemons airportd / wifid"
    pkill -9 -f airportd 2>/dev/null || true
    pkill -9 -f wifid 2>/dev/null || true
    sleep 5
}

# --- Script principal ----------------------------------------------------

# Vérifie qu'on est bien lancé en root, sinon ifconfig/pkill échoueront
if [[ "$EUID" -ne 0 ]]; then
    echo "Ce script doit être lancé avec sudo (droits root nécessaires)."
    exit 1
fi

log "=== Lancement de fix-wifi.sh ==="

# 1. Vérification initiale : le Wi-Fi est-il vraiment cassé ?
if check_connectivity; then
    log "Connectivité OK, aucune action nécessaire."
    exit 0
fi

log "Pas de connectivité détectée. Début des tentatives de réparation."

# 2. Premier niveau : toggle de l'interface
toggle_interface
if check_connectivity; then
    log "Connectivité rétablie après reset de l'interface."
    exit 0
fi

log "Toujours pas de connectivité après reset de l'interface."

# 3. Deuxième niveau : redémarrage des daemons Wi-Fi
restart_wifi_daemons
if check_connectivity; then
    log "Connectivité rétablie après redémarrage des daemons Wi-Fi."
    exit 0
fi

# 4. Échec de toutes les tentatives logicielles
log "Échec : le Wi-Fi reste indisponible malgré toutes les tentatives."
log "Cause probable : blocage matériel/firmware ou surchauffe."
log "Un redémarrage complet ou un reset SMC est probablement nécessaire."
exit 1
