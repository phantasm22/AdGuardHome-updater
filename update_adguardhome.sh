#!/bin/sh
###############################################################################
# update_adguardhome.sh
#
# Description:
#   Interactive shell script for managing AdGuardHome on embedded Linux systems
#   (e.g., OpenWRT, GL.iNet). Provides functionality to:
#     - Check for and apply AdGuardHome updates
#     - Switch between stable and beta release trains
#     - Backup and restore previous versions
#     - Manage the AdGuardHome service (start/stop/restart)
#
# Features:
#   - Menu-based interface with progress display
#   - Intelligent architecture detection (no hardcoded arch)
#   - Optional backup of config and binary before updates
#   - Minimal external dependencies (compatible with /bin/sh)
#
# Requirements:
#   - curl, tar, kill, ps, and standard POSIX tools
#
# Author: Phantasm22
#
# License: GNU General Public License v3.0
#          This program is free software: you can redistribute it and/or modify
#          it under the terms of the GNU General Public License as published by
#          the Free Software Foundation, either version 3 of the License, or
#          (at your option) any later version.
#
#          This program is distributed in the hope that it will be useful,
#          but WITHOUT ANY WARRANTY; without even the implied warranty of
#          MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#          GNU General Public License for more details.
#
#          You should have received a copy of the GNU General Public License
#          along with this program. If not, see <https://www.gnu.org/licenses/>.
###############################################################################

#==================== COLORS ====================
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LTBLUE='\033[96m'
#================================================

ARCH=""
SCRIPT_VERSION="1.1.0"
AGH_BIN=""
VERSION=""
LATEST_VERSION=""
TRAIN=""
TMP_DIR="/tmp/agh-update"

#==================== FUNCTIONS ====================

show_splash_screen() {                              
    clear
    echo -e                                               
    echo -e "${LTBLUE}+------------------------------------------------------------------------------+"
    echo -e "|    _       _  ____                     _ _   _                               |"       
    echo -e "|   / \   __| |/ ___|_   _  __ _ _ __ __| | | | | ___  _ __ ___   ___          |"       
    echo -e "|  / _ \ / _\` | |  _| | | |/ _\` | '__/ _\` | |_| |/ _ \| '_ \` _ \ / _ \         |"       
    echo -e "| / ___ \ (_| | |_| | |_| | (_| | | | (_| |  _  | (_) | | | | | |  __/         |"       
    echo -e "|/_/  _\_\__,_|\____|\__,_|\__,_|_|  \__,_|_| |_|\___/|_| |_| |_|\___|         |"       
    echo -e "| | | | |_ __   __| | __ _| |_ ___ _ __                                        |"        
    echo -e "| | | | | '_ \ / _\` |/ _\` | __/ _ \ '__|                                       |"        
    echo -e "| | |_| | |_) | (_| | (_| | ||  __/ |                                          |"        
    echo -e "|  \___/| .__/ \__,_|\__,_|\__\___|_|                                          |"        
    echo -e "|       |_|                                   by Phantasm22                    |"          
    echo -e "|                                             v.${SCRIPT_VERSION}                          |"           
    echo -e "+------------------------------------------------------------------------------+${NOCOLOR}"
}  

detect_arch() {
    uname_s=$(uname -s | sed 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/')
    uname_m=$(uname -m)

    case "$uname_s" in
        linux)
            case "$uname_m" in
                x86_64) ARCH="linux_amd64" ;;
                i*86)   ARCH="linux_386" ;;
                armv7l | armv6l) ARCH="linux_armv7" ;;
                aarch64 | arm64) ARCH="linux_arm64" ;;
                mips*)  ARCH="linux_mips" ;;  # Adjust as needed for mipsel vs mips
                *)      echo "❌ Unsupported architecture: $uname_m"; exit 1 ;;
            esac
            ;;
        darwin)
            case "$uname_m" in
                x86_64) ARCH="darwin_amd64" ;;
                arm64)  ARCH="darwin_arm64" ;;
                *)      echo "❌ Unsupported architecture: $uname_m"; exit 1 ;;
            esac
            ;;
        *)
            echo "❌ Unsupported OS: $uname_s"
            exit 1
            ;;
    esac
}

find_running_binary() {
    pid=$(pidof AdGuardHome 2>/dev/null)
    if [ -n "$pid" ]; then
        exe=$(readlink -f "/proc/$pid/exe" | awk '{print $1}')
        if [ -x "$exe" ]; then
            AGH_BIN="$exe"
            return
        fi
    fi

    # Try startup script fallback
    for candidate in /etc/init.d/* /etc/rc.local /etc/rc.d/* /etc/config/* /opt/etc/init.d/*; do
        [ -f "$candidate" ] || continue
        bin=$(grep -Eo '/[^ ]*/AdGuardHome' "$candidate" | head -n1)
        if [ -n "$bin" ] && [ -x "$bin" ]; then
            AGH_BIN="$bin"
            return
        fi
    done

    echo -e "${RED}❌ AdGuardHome binary not found.${NOCOLOR}"
}

get_current_version() {
    if [ -x "$AGH_BIN" ]; then
        VERSION="$($AGH_BIN --version | awk '{print $4}')"
    else
        VERSION="v0.000.00"
    fi
}

get_release_train() {
    case "$VERSION" in
        v0.107.*) TRAIN="stable" ;;
        v0.108.*) TRAIN="beta" ;;
        *) TRAIN="unknown" ;;
    esac
}

get_latest_version() {
    LATEST_VERSION=$(curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases \
    	| grep '"tag_name":' \
    	| grep -o 'v0\.10[78]\.[0-9]*\(-b\.[0-9]*\)\?' \
    	| { [ "$TRAIN" = "beta" ] && grep '^v0\.108' || grep -E '^v0\.107(\.[0-9]+)?$'; } \
    	| head -n 1)
    if [ -z "$LATEST_VERSION" ]; then
        echo -e "${RED}❌ Failed to fetch latest version from GitHub.${NOCOLOR}"
    fi
}

build_download_url() {
    echo -e "https://github.com/AdguardTeam/AdGuardHome/releases/download/${LATEST_VERSION}/AdGuardHome_${ARCH}.tar.gz"
}

show_info() {
    show_splash_screen
    echo -e "Current Version: ${GREEN}${VERSION}${NOCOLOR}"
    echo -e "Release Train:  ${YELLOW}${TRAIN}${NOCOLOR}"
    echo -e "Latest Version: ${BLUE}${LATEST_VERSION}${NOCOLOR}"
    if [ "$VERSION" = "$LATEST_VERSION" ]; then
        echo -e "Update Available: ${GREEN}No${NOCOLOR}"
    else
        echo -e "Update Available: ${YELLOW}Yes${NOCOLOR}"
    fi
}

find_startup_script() {
    STARTUP_SCRIPT=""
    for file in /etc/init.d/[Aa]d[Gg]uard[Hh]ome /etc/rc.local /etc/rc.d/S[0-9][0-9]* /jffs/addons/AdGuardHome.d/AdGuardHome.sh  /opt/etc/init.d/*; do
        [ -f "$file" ] || continue
        grep -q 'AdGuardHome' "$file" && STARTUP_SCRIPT="$file" && return 0
    done
    echo -e ""
    echo -e "❌ No valid AdGuardHome startup script found." >&2
    return 1
}

stop_adguardhome() {
    find_startup_script
    local before_pid after_pid i

    before_pid=$(pidof AdGuardHome)
    echo -e ""
    if [ -z "$before_pid" ]; then
        echo -e "${YELLOW}⚠️  AdGuardHome is not running.${NOCOLOR}"
        return 0
    fi

    echo -e "${BLUE}🛑 Attempting to stop AdGuardHome (PID $before_pid)...${NOCOLOR}"

    if [ -n "$STARTUP_SCRIPT" ]; then
        "$STARTUP_SCRIPT" stop 2>/dev/null
    else
        kill "$before_pid" 2>/dev/null
    fi

    # Countdown and check
    for i in 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1; do
        printf "\r⏳ Waiting... %s " "$i"
        sleep 1
        after_pid=$(pidof AdGuardHome)
        [ -z "$after_pid" ] && break
    done
    echo ""

    if [ -n "$after_pid" ]; then
        echo -e "${RED}❌ Failed to stop AdGuardHome (PID $after_pid still running).${NOCOLOR}" >&2
        return 1
    fi

    echo -e "${GREEN}✅ AdGuardHome stopped successfully.${NOCOLOR}"
    return 0
}

start_adguardhome() {
    find_startup_script
    echo -e ""

    pid=$(pidof AdGuardHome)
    if [ -n "$pid" ]; then
        echo -e "${GREEN}⚠️  AdGuardHome already started (PID $pid).${NOCOLOR}"
        return 1
    fi
    
    echo -e "${BLUE}🚀 Attempting to start AdGuardHome...${NOCOLOR}"

    if [ -n "$STARTUP_SCRIPT" ]; then
        "$STARTUP_SCRIPT" start 2>/dev/null
    else
        "$AGH_BIN" -s start 2>/dev/null
    fi

    # Wait and check for startup
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
        sleep 1
        pid=$(pidof AdGuardHome)
        if [ -n "$pid" ]; then
            echo -e "${GREEN}✅ AdGuardHome started successfully (PID $pid).${NOCOLOR}"
            return 0
        fi
        printf "\r⏳ Waiting for AdGuardHome to start... %s " "$((31 - i))"
    done
    echo ""
    echo -e "${RED}❌ Failed to start AdGuardHome.${NOCOLOR}" >&2
    return 1
}

restart_adguardhome() {
    find_startup_script
    echo -e ""
    echo -e "${BLUE}🚀 Attempting to restart AdGuardHome...${NOCOLOR}"

    if [ -n "$STARTUP_SCRIPT" ]; then
        "$STARTUP_SCRIPT" restart 2>/dev/null
    else
        "$AGH_BIN" -s restart 2>/dev/null
    fi

    # Wait and check for startup
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
        sleep 1
        pid=$(pidof AdGuardHome)
        if [ -n "$pid" ]; then
            echo -e "${GREEN}✅ AdGuardHome restarted successfully (PID $pid).${NOCOLOR}"
            return 0
        fi
        printf "\r⏳ Waiting for AdGuardHome to restart... %s " "$((31 - i))"
    done
    echo ""
    echo -e "${RED}❌ Failed to restart AdGuardHome.${NOCOLOR}" >&2
    return 1
}

download_update() {
    echo ""

    CURRENT_VER="$($AGH_BIN --version 2>/dev/null | awk '{print $4}')"
    if [ "$CURRENT_VER" = "$LATEST_VERSION" ]; then
        echo -e "✅ AdGuardHome is already at the latest version ($CURRENT_VER)."
        echo -n "🔁 Do you want to redownload and overwrite it anyway? [y/N]: "
        read -r confirm
        [ "$confirm" != "y" ] && echo "ℹ️  Skipping update." && return 0
    fi

    TMP_DIR="/tmp/agh-update"
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR" || return 1

echo ""

draw_screen() {
    percent="$1"
    bar_width=25
    filled=$((percent * bar_width / 100))
    empty=$((bar_width - filled))

    bar=""
    [ "$filled" -gt 0 ] && bar="$(printf "%${filled}s" | sed 's/ /🟩/g')"
    [ "$empty" -gt 0 ] && bar="$bar$(printf "%${empty}s" | sed 's/ /⬜/g')"

    # Clear the line and redraw the progress bar
    printf "\r🔄 [%3d%%] %-${bar_width}s\n" "$percent" "$bar"
}

    draw_screen 0
    echo -e "⬇️  Downloading AdGuardHome_${ARCH}.tar.gz..."
    draw_screen 10
    URL=$(build_download_url)
    if ! curl -sSL -o "AdGuardHome_${ARCH}.tar.gz" "$URL"; then
        add_msg "${RED}❌ Failed to download from $URL${NOCOLOR}"
        draw_screen 10
        cd /tmp && rm -rf "$TMP_DIR"
        return 1
    fi

    echo -e "🔧 Extracting files..."
    draw_screen 25
    if ! tar -xzf "AdGuardHome_${ARCH}.tar.gz"; then
        echo -e "${RED}❌ Extraction failed.${NOCOLOR}"
        draw_screen 25
        cd /tmp && rm -rf "$TMP_DIR"
        return 1
    fi

    echo -e "🛑 Stopping AdGuardHome service..."
    draw_screen 50
    stop_adguardhome

    echo -e "📁 Replacing binary..."
    draw_screen 60
    if [ -f "./AdGuardHome/AdGuardHome" ]; then
        cp -f ./AdGuardHome/AdGuardHome "$AGH_BIN"
        chmod +x "$AGH_BIN"
    else
        echo -e "${RED}❌ Extracted binary not found.${NOCOLOR}"
        draw_screen 75
        cd /tmp && rm -rf "$TMP_DIR"
        return 1
    fi

    echo -e "✅ Restarting service..."
    draw_screen 85
    start_adguardhome

    NEW_VER="$($AGH_BIN --version | awk '{print $4}')"
    if [ "$NEW_VER" = "$LATEST_VERSION" ]; then
        draw_screen 100
 	echo -e "✅ Update complete!"
    else
        echo -e "${RED}❌ Update failed: still running $NEW_VER${NOCOLOR}"
    fi

    cd /tmp && rm -rf "$TMP_DIR"
    return 0
}

manage_service() {
    echo -e "\n🔧 Manage AdGuardHome:"
    echo "  1) Start"
    echo "  2) Stop"
    echo "  3) Restart"
    echo "  4) Cancel"
    echo -n "Select an option: "
    read opt
    case "$opt" in
        1) start_adguardhome ;;
        2) stop_adguardhome ;;
        3) restart_adguardhome ;;
        *) echo "Cancelled." ;;
    esac
}

change_release_train() {
    echo -e "\n🔁 Switch to release train:"
    echo -e "  1) stable"
    echo -e "  2) beta"
    echo -e "  3) cancel"
    echo -e -n "Select an option: "
    read opt
    case "$opt" in
        1) TRAIN="stable" ;;
        2) TRAIN="beta" ;;
        *) echo -e "Cancelled."; return ;;
    esac
    get_latest_version
}

backup_adguardhome() {
    AGH_DIR=$(dirname "$AGH_BIN")
    AGH_BAK="$AGH_BIN.bak"

    CONFIG_FILE=$(ps | grep '[A]dGuardHome' | grep -oE '\-c [^ ]+\.yaml' | awk '{print $2}')
    if [ -z "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ Unable to determine AdGuardHome config file location. AdGuardHome running?${NOCOLOR}"
        return 1
    fi

    CONFIG_BAK="${CONFIG_FILE}.bak"

    case "$backup_choice" in
        both)
            cp -f "$AGH_BIN" "$AGH_BAK"
            cp -f "$CONFIG_FILE" "$CONFIG_BAK"
            echo -e "${GREEN}✅ Binary and config backed up.${NOCOLOR}"
	    sleep 2
            ;;
        binary)
            cp -f "$AGH_BIN" "$AGH_BAK"
            echo -e "${GREEN}✅ Binary backed up.${NOCOLOR}"
	    sleep 2
            ;;
        config)
            cp -f "$CONFIG_FILE" "$CONFIG_BAK"
            echo -e "${GREEN}✅ Config backed up.${NOCOLOR}"
	    sleep 2
            ;;
        none)
            echo "🛈 No backup selected."
	    sleep 2
            ;;
        *)
            echo -e "${YELLOW}⚠️  Unknown backup option: $backup_choice${NOCOLOR}"
            ;;
    esac
}

restore_adguardhome() {
    AGH_DIR=$(dirname "$AGH_BIN")
    AGH_BAK="$AGH_BIN.bak"

    CONFIG_FILE=$(ps | grep '[A]dGuardHome' | grep -oE '\-c [^ ]+\.yaml' | awk '{print $2}')
    if [ -z "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ Unable to determine AdGuardHome config file location.${NOCOLOR}"
        return 1
    fi

    CONFIG_BAK="${CONFIG_FILE}.bak"

    echo -e "\n🕰️  Restore options:"
    echo "  1) Restore both binary and config"
    echo "  2) Restore binary only"
    echo "  3) Restore config only"
    echo "  4) Cancel"
    echo -n "Choose an option: "
    read restore_choice

    case "$restore_choice" in
        1)                                                                                             
	    stop_adguardhome 
            [ -f "$AGH_BAK" ] && cp -f "$AGH_BAK" "$AGH_BIN" && chmod +x "$AGH_BIN" \
                && echo -e "${GREEN}✅ Binary restored.${NOCOLOR}" \
                || echo -e "${RED}❌ Binary backup not found.${NOCOLOR}"
            [ -f "$CONFIG_BAK" ] && cp -f "$CONFIG_BAK" "$CONFIG_FILE" \
                && echo -e "${GREEN}✅ Config restored.${NOCOLOR}" \
                || echo -e "${RED}❌ Config backup not found.${NOCOLOR}"
            start_adguardhome
	    ;;
        2)                                                                                        
            stop_adguardhome 
            [ -f "$AGH_BAK" ] && cp -f "$AGH_BAK" "$AGH_BIN" && chmod +x "$AGH_BIN" \
                && echo -e "${GREEN}✅ Binary restored.${NOCOLOR}" \
                || echo -e "${RED}❌ Binary backup not found.${NOCOLOR}"
	    start_adguardhome
            ;;
        3)                                                                                        
            stop_adguardhome 
            [ -f "$CONFIG_BAK" ] && cp -f "$CONFIG_BAK" "$CONFIG_FILE" \
                && echo -e "${GREEN}✅ Config restored.${NOCOLOR}" \
                || echo -e "${RED}❌ Config backup not found.${NOCOLOR}"
            start_adguardhome
	    ;;
        *)
            echo "Cancelled."
            ;;
    esac
}



#==================== MAIN ====================
find_running_binary
detect_arch
get_current_version
get_release_train
get_latest_version
show_info

while true; do
    echo -e "\n📦  Choose an option: "
    echo -e "  1) 🚀  Update AdGuardHome"
    echo -e "  2) 🔁  Change Release Train"
    echo -e "  3) 🕰️   Restore Previous Version"
    echo -e "  4) 🔧  Manage AdGuardHome (Start/Stop/Restart)"
    echo -e "  5) ❌  Exit"
    echo -n -e "\n📍  Enter choice: "
    read choice

    case "$choice" in
        1)
            echo -ne "\n💾 Backup option? (both/binary/config/none): "
            read backup_choice
	    case "$backup_choice" in
                both)   backup_adguardhome both ;;
                binary) backup_adguardhome binary ;;
                config) backup_adguardhome config ;;
                none)   echo "Skipping backup." ;;
                *)      echo "Invalid option, skipping backup." ;;
            esac
            download_update
            ;;
        2)
            change_release_train
            show_info
            ;;
        3)
            restore_adguardhome
            ;;
        4)
            manage_service
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
done
