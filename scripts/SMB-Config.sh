#!/usr/bin/env bash
#
# SMB Config for PSBBN Slim + GL-Mango
# Configura OPL/NHDDL para usar Samba del Mango amarillo
#

[[ -t 0 && -t 1 ]] || exit 1

if [[ "$LAUNCHED_BY_MAIN" != "1" ]]; then
    echo "This script should not be run directly. Please run: PSBBN-Definitive-Patch.sh"
    exit 1
fi

TOOLKIT_PATH="$(pwd)"
SCRIPTS_DIR="${TOOLKIT_PATH}/scripts"
ASSETS_DIR="${SCRIPTS_DIR}/assets"
LANG_DIR="${ASSETS_DIR}/lang"
STORAGE_DIR="${SCRIPTS_DIR}/storage"
OPL="${SCRIPTS_DIR}/OPL"
LOG_FILE="${TOOLKIT_PATH}/logs/smb-config.log"
LANG_FILE="$1"
path_arg="$2"

mkdir -p "${TOOLKIT_PATH}/logs" 2>/dev/null
mkdir -p "${TOOLKIT_PATH}/config" 2>/dev/null

declare -A UI_TEXT
if [[ -f "${LANG_DIR}/$LANG_FILE.txt" ]]; then
    while IFS='=' read -r key value; do [[ -z "$key" ]] && continue; UI_TEXT["$key"]="$value"; done < "${LANG_DIR}/$LANG_FILE.txt"
else
    echo "[X] Error: Language file not found."; sleep 3; exit 1
fi

# Fallback texts if not translated
: ${UI_TEXT[SMB_TITLE]:="Samba (Mango) Configuration"}
: ${UI_TEXT[SMB_IP_PROMPT]:="IP del Mango (ej: 192.168.8.1)"}
: ${UI_TEXT[SMB_SHARE_PROMPT]:="Nombre del share (ej: PS2SMB)"}
: ${UI_TEXT[SMB_USER_PROMPT]:="Usuario Samba (guest para sin pass)"}
: ${UI_TEXT[SMB_PASS_PROMPT]:="Password Samba (vacio para guest)"}
: ${UI_TEXT[SMB_SUCCESS]:="Configuracion SMB guardada"}
: ${UI_TEXT[SMB_HINT]:="Conecta Mango via LAN a PS2 Slim, USB con HDD en Mango"}

SMB_CFG="${TOOLKIT_PATH}/config/smb.cfg"

clear
cat << "EOF"
   _____ __  __ ____    __  __
  / ___//  |/  // __ )  / |/ /___ _____  ____ _____ ____
  \__ \/ /|_/ // __  | / /|_/ / __ `/ __ \/ __ `/ _ \/ __ \
 ___/ / /  / // /_/ |/ /  / / /_/ / / / / /_/ /  __/ /_/ /
/____/_/  /_//_____//_/  /_/\__,_/_/ /_/\__, /\___/\____/
                                       /____/
  PSBBN Slim + GL-iNet Mango (Amarillo) - Samba Share
EOF
echo
echo "${UI_TEXT[SMB_HINT]}"
echo "Mango: OpenWrt > Samba4 > Share /mnt/sda1 con carpetas DVD/CD/POPS"
echo

# Load existing
if [[ -f "$SMB_CFG" ]]; then
    source "$SMB_CFG"
    echo "Config actual: $SMB_IP / $SMB_SHARE / $SMB_USER"
    echo
fi

read -rp "${UI_TEXT[SMB_IP_PROMPT]} [${SMB_IP:-192.168.8.1}]: " inp
SMB_IP=${inp:-${SMB_IP:-192.168.8.1}}
read -rp "${UI_TEXT[SMB_SHARE_PROMPT]} [${SMB_SHARE:-PS2SMB}]: " inp
SMB_SHARE=${inp:-${SMB_SHARE:-PS2SMB}}
read -rp "${UI_TEXT[SMB_USER_PROMPT]} [${SMB_USER:-guest}]: " inp
SMB_USER=${inp:-${SMB_USER:-guest}}
read -rsp "${UI_TEXT[SMB_PASS_PROMPT]}: " inp; echo
SMB_PASS=${inp:-$SMB_PASS}

cat > "$SMB_CFG" <<EOL
SMB_IP="$SMB_IP"
SMB_SHARE="$SMB_SHARE"
SMB_USER="$SMB_USER"
SMB_PASS="$SMB_PASS"
EOL
echo
echo "[✓] ${UI_TEXT[SMB_SUCCESS]} -> $SMB_CFG" | tee -a "$LOG_FILE"
cat "$SMB_CFG" | tee -a "$LOG_FILE"

# Try to write OPL config if OPL partition mounted
DEVICE_RAW=$(sudo blkid -t TYPE=exfat | grep OPL | awk -F: '{print $1}' | head -n1)
if [[ -n "$DEVICE_RAW" ]]; then
    if [[ "$DEVICE_RAW" == *mmcblk* || "$DEVICE_RAW" == *loop*p3 ]]; then DEVICE=$(echo "$DEVICE_RAW" | sed -E 's/p[0-9]+$//'); OPL_PART="${DEVICE}p3"; else DEVICE=$(echo "$DEVICE_RAW" | sed -E 's/[0-9]+$//'); OPL_PART="${DEVICE}3"; fi
    mkdir -p "${OPL}" 2>/dev/null
    if sudo mount -o uid=$UID,gid=$(id -g) "$OPL_PART" "${OPL}" 2>/dev/null || sudo mount.exfat-fuse -o uid=$UID,gid=$(id -g) "$OPL_PART" "${OPL}" 2>/dev/null; then
        echo "Actualizando OPL config en $OPL..." | tee -a "$LOG_FILE"
        mkdir -p "${OPL}/CFG" 2>/dev/null
        # OPL config file is conf_opl.cfg or opl.cfg depending on version
        OPL_CFG_FILE="${OPL}/conf_opl.cfg"
        [[ -f "${OPL}/opl.cfg" ]] && OPL_CFG_FILE="${OPL}/opl.cfg"
        touch "$OPL_CFG_FILE" 2>/dev/null
        sudo bash -c "cat > '${OPL_CFG_FILE}' <<EOL2
# Auto-generated por SMB-Config.sh Mango
eth_op_mode=1
smb_server_ip=$SMB_IP
smb_share=$SMB_SHARE
smb_user=$SMB_USER
smb_pass=$SMB_PASS
enable_bdm_hdd=1
bdl_start_mode=auto
EOL2
"
        echo "[✓] OPL SMB config escrito en $OPL_CFG_FILE" | tee -a "$LOG_FILE"
        cat "$OPL_CFG_FILE" | tee -a "$LOG_FILE"
        sync
        sudo umount -l "${OPL}" 2>/dev/null
    else
        echo "[!] No se pudo montar OPL para escribir config. Se aplicara en proximo Game-Installer." | tee -a "$LOG_FILE"
    fi
else
    echo "[!] PS2 drive no detectado. Config guardada solo local. Conecta SD/MX4SIO y re-ejecuta." | tee -a "$LOG_FILE"
fi

echo
echo "Siguiente paso:"
echo "1) En Mango: Samba share con carpetas DVD/ CD/ POPS (ISO/VCD)"
echo "2) En PC: pon ISOs en games/SMB/DVD o directo en Mango USB"
echo "3) Ejecuta 'Install Games and Apps' > detectara SMB2"
echo
read -n 1 -s -r -p "Press any key..." </dev/tty; echo
