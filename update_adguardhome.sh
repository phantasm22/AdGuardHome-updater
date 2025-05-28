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
    echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃${LTBLUE}        _       _  ____                     _ _   _                           ${BLUE}┃"       
    echo -e "┃${LTBLUE}       / \   __| |/ ___|_   _  __ _ _ __ __| | | | | ___  _ __ ___   ___      ${BLUE}┃"       
    echo -e "┃${LTBLUE}      / _ \ / _\` | |  _| | | |/ _\` | '__/ _\` | |_| |/ _ \| '_ \` _ \ / _ \     ${BLUE}┃"       
    echo -e "┃${LTBLUE}     / ___ \ (_| | |_| | |_| | (_| | | | (_| |  _  | (_) | | | | | |  __/     ${BLUE}┃"       
    echo -e "┃${LTBLUE}    /_/  _\_\__,_|\____|\__,_|\__,_|_|  \__,_|_| |_|\___/|_| |_| |_|\___|     ${BLUE}┃"       
    echo -e "┃${LTBLUE}     | | | |_ __   __| | __ _| |_ ___ _ __                                    ${BLUE}┃"        
    echo -e "┃${LTBLUE}     | | | | '_ \ / _\` |/ _\` | __/ _ \ '__|                                   ${BLUE}┃"        
    echo -e "┃${LTBLUE}     | |_| | |_) | (_| | (_| | ||  __/ |                                      ${BLUE}┃"        
    echo -e "┃${LTBLUE}      \___/| .__/ \__,_|\__,_|\__\___|_|                                      ${BLUE}┃"        
    echo -e "┃${LTBLUE}           |_|                                   by Phantasm22                ${BLUE}┃"          
    echo -e "┃${LTBLUE}                                                 ${GREEN}v.${SCRIPT_VERSION}                      ${BLUE}┃"           
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NOCOLOR}"
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
            return 0
        fi
    else
	exe=$(which AdGuardHome)
        if [ -x "$exe" ]; then                                                                            
            AGH_BIN="$exe"                                                                                
            return 0                                                                                        
        fi
    fi
    echo -e "${RED}❌ AdGuardHome binary not found.${NOCOLOR}"
    sleep 2
    return 1
}

get_current_version() {
    if [ -x "$AGH_BIN" ]; then
        VERSION="$($AGH_BIN --version | awk '{print $4}')"
    else
        VERSION="v0.000.00"
	return 1
    fi
}

get_release_train() {
    while :; do
        case "$VERSION" in
            v0.107.*) TRAIN="stable"; return 0 ;;
            v0.108.*) TRAIN="beta"; return 0 ;;
            *)
                if get_current_version; then
                    continue  # Retry the case block with updated $VERSION
                else
                    TRAIN="unknown"
                    return 1
                fi
                ;;
        esac
    done
}

get_latest_version() {
    LATEST_VERSION=$(curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases \
    	| grep '"tag_name":' \
    	| grep -o 'v0\.10[78]\.[0-9]*\(-b\.[0-9]*\)\?' \
    	| { [ "$TRAIN" = "beta" ] && grep '^v0\.108' || grep -E '^v0\.107(\.[0-9]+)?$'; } \
    	| head -n 1)
    if [ -z "$LATEST_VERSION" ]; then
        echo -e "${RED}❌ Failed to fetch latest version from GitHub.${NOCOLOR}"
	sleep 2
	return 1
    fi
}

build_download_url() {
    echo -e "https://github.com/AdguardTeam/AdGuardHome/releases/download/${LATEST_VERSION}/AdGuardHome_${ARCH}.tar.gz"
}

show_info() {
    show_splash_screen
    get_current_version
    echo -e "Current Version: ${GREEN}${VERSION}${NOCOLOR}"
    echo -e "Release Train:  ${YELLOW}${TRAIN}${NOCOLOR}"
    echo -e "Latest Version: ${BLUE}${LATEST_VERSION}${NOCOLOR}"
    if [ "$VERSION" = "$LATEST_VERSION" ]; then
        echo -e "Update Available: ${GREEN}No${NOCOLOR}"
    else
        echo -e "Update Available: ${YELLOW}Yes${NOCOLOR}"
    fi
    if [ -n "$(pidof AdGuardHome 2>/dev/null)" ]; then
        echo -e "AdGuardHome status: 🟢 ${GREEN}Running${NOCOLOR}"
    else
        echo -e "AdGuardHome status: 🔴 ${RED}Stopped${NOCOLOR}"
fi
    
}

find_startup_script() {
    STARTUP_SCRIPT=""
    for file in /etc/init.d/[Aa]d[Gg]uard[Hh]ome /etc/rc.local /etc/rc.d/S[0-9][0-9]* /jffs/addons/AdGuardHome.d/AdGuardHome.sh  /opt/etc/init.d/*; do
        [ -f "$file" ] || continue
        grep -q 'AdGuardHome' "$file" && STARTUP_SCRIPT="$file" && return 0
    done
    echo -e ""
    echo -e "❌ No valid AdGuardHome startup script found."
    sleep 2
    return 1
}

get_config_file() {
    # First try to get config file from running process
    CONFIG_FILE=$(ps | grep '[A]dGuardHome' | grep -oE '\-c [^ ]+\.ya?ml' | awk '{print $2}')
    if [ -n "$CONFIG_FILE" ]; then
        return 0
    fi

    # Fallback: try to locate from startup script
    find_startup_script
    if [ -n "$STARTUP_SCRIPT" ] && [ -f "$STARTUP_SCRIPT" ]; then
        CONFIG_FILE=$(grep -oE '\-c[ =][^ ]+\.ya?ml' "$STARTUP_SCRIPT" | head -n 1 | sed -E 's/-c[ =]//')
        if [ -n "$CONFIG_FILE" ]; then
            return 0
        fi
    fi

    # Tertiary: Broad file system search if startup script exists but no -c flag found
    if [ -n "$STARTUP_SCRIPT" ] && [ -f "$STARTUP_SCRIPT" ]; then
        CONFIG_FILE=$(find /etc /opt -type f -iname '*.yaml' 2>/dev/null | grep -i 'adguardhome' | head -n 1)
	if [ -z "$CONFIG_FILE" ]; then
	    CONFIG_FILE=$(find / -type f -iname '*.yaml' 2>/dev/null | grep -i 'adguardhome' | head -n 1)
	fi
        if [ -n "$CONFIG_FILE" ]; then
            return 0
        fi
    fi
    
    echo -e "${RED}❌  No valid AdGuardHome config file found.${NOCOLOR}"
    CONFIG_FILE=""
    sleep 2
    return 1
}

stop_adguardhome() {
    find_startup_script || return 1
    local before_pid after_pid i

    before_pid=$(pidof AdGuardHome)
    echo -e ""
    if [ -z "$before_pid" ]; then
        echo -e "${YELLOW}⚠️  AdGuardHome is not running.${NOCOLOR}"
        return 1
    fi

    echo -e "${BLUE}🛑 Attempting to stop AdGuardHome (PID $before_pid)...${NOCOLOR}"

    if [ -n "$STARTUP_SCRIPT" ]; then
        "$STARTUP_SCRIPT" stop 2>/dev/null
    else
        kill "$before_pid" 2>/dev/null
    fi

    i=60 #Max timer
    ii=3 #Time to wait after process ends to continue 
    while [ "$i" -gt 0 ] && [ "$ii" -gt 0 ]; do
	printf "\r⏳ Waiting... %s " "$i"
        sleep 1
        after_pid=$(pidof AdGuardHome 2>/dev/null)
	asus_pid=$(pidof S99AdGuardHome 2>/dev/null)

        if [ -z "$after_pid" ] && [ -z "$asus_pid" ]; then
	    if [ "$ii" -eq 0 ]; then
		break
	    fi
	    ii=$((ii - 1))
        fi

        i=$((i - 1))
    done
    echo ""

    if [ -n "$after_pid" ]; then
        echo -e "${RED}❌ Failed to stop AdGuardHome (PID $after_pid still running).${NOCOLOR}"
	sleep 2
        return 1
    fi

    echo -e "${GREEN}✅ AdGuardHome stopped successfully.${NOCOLOR}"
    sleep 2
    return 0
}

start_adguardhome() {
    find_startup_script || return 1
    echo -e ""

    pid=$(pidof AdGuardHome)
    if [ -n "$pid" ]; then
        echo -e "${GREEN}⚠️  AdGuardHome already started (PID $pid).${NOCOLOR}"
	sleep 2
        return 1
    fi
    
    echo -e "${BLUE}🚀 Attempting to start AdGuardHome...${NOCOLOR}"

    if [ -n "$STARTUP_SCRIPT" ]; then
        "$STARTUP_SCRIPT" start 2>/dev/null
    else
        "$AGH_BIN" -s start 2>/dev/null
    fi

    # Wait and check for startup
    i=60 #max timer
    while [ "$i" -gt 0 ]; do 
        sleep 1
        pid=$(pidof AdGuardHome)
        if [ -n "$pid" ]; then
            echo -e "${GREEN}✅ AdGuardHome started successfully (PID $pid).${NOCOLOR}"
            sleep 2
	    return 0
        fi
        printf "\r⏳ Waiting for AdGuardHome to start... %s " "$i"
        i=$((i-1))
    done
    echo ""
    echo -e "${RED}❌ Failed to start AdGuardHome.${NOCOLOR}"
    sleep 2
    return 1
}

restart_adguardhome() {
    find_startup_script || return 1
    local before_pid after_pid i

    before_pid=$(pidof AdGuardHome)
    echo -e ""
    if [ -z "$before_pid" ]; then
        echo -e "${YELLOW}⚠️  AdGuardHome is not running.${NOCOLOR}"
        return 0
    fi
    
    echo -e ""
    echo -e "${BLUE}🚀 Attempting to restart AdGuardHome...${NOCOLOR}"

    if [ -n "$STARTUP_SCRIPT" ]; then
        "$STARTUP_SCRIPT" restart 2>/dev/null
    else
        "$AGH_BIN" -s restart 2>/dev/null
    fi

    # Wait and check for restart
    i=60 #max timer
    while [ "$i" -gt 0 ]; do
	sleep 1
        after_pid=$(pidof AdGuardHome)
        if [ -n "$after_pid" ] && [ "$before_pid" -ne "$after_pid" ] ; then
            echo -e "\n${GREEN}✅ AdGuardHome restarted successfully (PID $pid).${NOCOLOR}"
            sleep 2
	    return 0
        fi
        printf "\r⏳ Waiting for AdGuardHome to restart... %s " "$i"
	i=$((i-1))
    done
    echo ""
    echo -e "${RED}❌ Failed to restart AdGuardHome.${NOCOLOR}"
    sleep 2
    return 1
}

show_process_status() {
    echo -e "\n\n[  🔍 Checking for process: AdGuardHome  ]"

    # Capture process info (excluding the grep line)
    proc_info=$(ps | grep -i adguardhome | grep -v grep | grep -v update_adguardhome.sh)

    if [ -n "$proc_info" ]; then
        echo -e "   ✅ Process \"${GREEN}AdGuardHome${NOCOLOR}\" is running:\n"
        echo -e "${GREEN}─────────── ⏹ Beginning of Output ⏹ ───────────${NOCOLOR}"
	echo -e "$proc_info"
	echo -e "${GREEN}────────────── ⏹ End of Output ⏹ ──────────────${NOCOLOR}"
    else
        echo -e "   ❌ Process \"${RED}AdGuardHome${NOCOLOR}\" not found."
    fi

    echo ""
    printf "⏎  Press ${LTBLUE}enter${NOCOLOR} to continue..."
    read dummy
}

download_update() {
    echo ""

    CURRENT_VER="$($AGH_BIN --version 2>/dev/null | awk '{print $4}')"
    if [ "$CURRENT_VER" = "$LATEST_VERSION" ]; then
        echo -e "✅ AdGuardHome is already at the latest version ($CURRENT_VER).\n"
        read -n1 -p "🔁 Do you want to redownload and overwrite it anyway? [y/N]: " confirm
	echo ""
        [ "$confirm" != "y" ] && echo "ℹ️  Skipping update." && return 0
    fi

    TMP_DIR="/tmp/agh-update"
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR" || return 1

echo ""

draw_screen() {
    percent="$1"
    bar_width=24
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
    draw_screen 16
    URL=$(build_download_url)
    if ! curl -sSL -o "AdGuardHome_${ARCH}.tar.gz" "$URL"; then
        add_msg "${RED}❌ Failed to download from $URL${NOCOLOR}"
        draw_screen 10
        cd /tmp && rm -rf "$TMP_DIR"
	sleep 2
        return 1
    fi

    echo -e "🔧 Extracting files..."
    draw_screen 33
    if ! tar -xzf "AdGuardHome_${ARCH}.tar.gz"; then
        echo -e "${RED}❌ Extraction failed.${NOCOLOR}"
        draw_screen 25
        cd /tmp && rm -rf "$TMP_DIR"
	sleep 2
        return 1
    fi

    echo -e "🛑 Stopping AdGuardHome service..."
    draw_screen 50
    stop_adguardhome

    echo -e "📁 Replacing binary..."
    draw_screen 66
    if [ -f "./AdGuardHome/AdGuardHome" ]; then
        cp -f ./AdGuardHome/AdGuardHome "$AGH_BIN"
        chmod +x "$AGH_BIN"
    else
        echo -e "${RED}❌ Extracted binary not found.${NOCOLOR}"
        draw_screen 73
        cd /tmp && rm -rf "$TMP_DIR"
	sleep 2
        return 1
    fi

    echo -e "✅ Restarting service..."
    draw_screen 83
    start_adguardhome

    NEW_VER="$($AGH_BIN --version | awk '{print $4}')"
    if [ "$NEW_VER" = "$LATEST_VERSION" ]; then
        draw_screen 100
 	echo -e "✅ Update complete!"
  	get_current_version
    else
        echo -e "${RED}❌ Update failed: still running $NEW_VER${NOCOLOR}"
	cd /tmp && rm -rf "$TMP_DIR"
	sleep 2
 	return 1
    fi

    cd /tmp && rm -rf "$TMP_DIR"
    return 0
}

manage_service() {
    echo -e "\n\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃  🔧 Manage AdGuardHome 🔧  ┃"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"    
    echo -e "  1) ▶️   Start"
    echo -e "  2) ⏹️   Stop"
    echo -e "  3) 🔄  Restart"
    echo -e "  4) 📋  Show Process Status"
    echo -e "  5) ❌  Cancel\n"
    read -n1 -p "👉  Select an option [1-5]: " opt
    echo ""
    case "$opt" in
        1) start_adguardhome ;;
        2) stop_adguardhome || sleep 2 ;;
        3) restart_adguardhome ;;
        4) show_process_status ;;
        *) return 0 ;;
    esac
}

change_release_train() {
    echo -e "\n\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃  🔁 Switch Release Train 🔁  ┃"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo -e "  1) 🟢  Stable – Reliable and tested"
    echo -e "  2) 🧪  Beta   – New features, possibly unstable"
    echo -e "  3) ❌  Cancel\n"
    read -n1 -p "👉  Select an option [1-3]: " opt
    echo ""
    case "$opt" in
        1) TRAIN="stable" && echo "✅ Switched to Stable release train." && sleep 1 ;;
        2) TRAIN="beta"   && echo "⚠️  Switched to Beta release train." && sleep 1 ;;
        *) return ;;
    esac
    get_latest_version || return 1
}

backup_adguardhome() {
    echo -e "\n\n┏━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃  🕰️  Backup Options 🕰️    ┃"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo -e "  1) 📦  Backup Both Binary and Config"
    echo -e "  2) 💾  Backup Binary Only"
    echo -e "  3) 🧾  Backup Config Only"
    echo -e "  4) ❌  No Backup"
    echo -e "  5) 🛑  Cancel\n"
    read -n1 -p "👉 Select an option [1-5]: " backup_choice
    echo ""
    
    AGH_DIR=$(dirname "$AGH_BIN")
    AGH_BAK="$AGH_BIN.bak"

    get_config_file || return 1
    CONFIG_BAK="${CONFIG_FILE}.bak"

    case "$backup_choice" in
        1)
            cp -f "$AGH_BIN" "$AGH_BAK"
            cp -f "$CONFIG_FILE" "$CONFIG_BAK"
            echo -e "${GREEN}✅ Binary and config backed up.${NOCOLOR}"
            ;;
        2)
            cp -f "$AGH_BIN" "$AGH_BAK"
            echo -e "${GREEN}✅ Binary backed up.${NOCOLOR}"
            ;;
        3)
            cp -f "$CONFIG_FILE" "$CONFIG_BAK"
            echo -e "${GREEN}✅ Config backed up.${NOCOLOR}"
            ;;
        4)
            echo "❌🛈 No backup selected."
            ;;
	*) 
 	    echo "🛑 Cancelled."
            sleep 2
            return 1
            ;;
    esac
}

restore_adguardhome() {
    AGH_DIR=$(dirname "$AGH_BIN")
    AGH_BAK="$AGH_BIN.bak"
    get_config_file || return 1
    CONFIG_BAK="${CONFIG_FILE}.bak"

    echo -e "\n\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃  🕰️  Restore Options 🕰️    ┃"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    echo -e "  1) 📦  Restore Both Binary and Config"
    echo -e "  2) 💾  Restore Binary Only"
    echo -e "  3) 🧾  Restore Config Only"
    echo -e "  4) ❌  Cancel\n"
    read -n1 -p "👉  Select an option [1-4]: " restore_choice
    echo ""

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
        *)  return ;;
    esac
}



#==================== MAIN ====================
find_running_binary
detect_arch
get_release_train
get_latest_version
show_info

while true; do
    echo -e "\n┏━━━━━━━━━━━━━━━━━━━━━┓"
    echo -e "┃  📦  Main Menu  📦  ┃"
    echo -e "┗━━━━━━━━━━━━━━━━━━━━━┛"
    echo -e "  1) 🚀  Update AdGuardHome"
    echo -e "  2) 🔁  Change Release Train"
    echo -e "  3) 🕰️   Restore Previous Version"
    echo -e "  4) 🔧  Manage AdGuardHome (Start/Stop/Restart)"
    echo -e "  5) ❌  Exit\n"
    read -n1 -p "👉  Select an option [1-5]: " choice
    echo ""
    
    case "$choice" in
        1)
            backup_adguardhome || { show_info; continue; }
            download_update
	    printf "⏎  Press ${LTBLUE}enter${NOCOLOR} to continue..."
    	    read dummy
	    show_info
            ;;
        2)
            change_release_train
            show_info
            ;;
        3)
            restore_adguardhome
	    show_info
            ;;
        4)
            manage_service
	    show_info
            ;;
        5)
            echo "🔚  Exiting..."
	    echo ""
            exit 0
            ;;
        *)
            echo "⚠️  Invalid choice."
            ;;
    esac
done
