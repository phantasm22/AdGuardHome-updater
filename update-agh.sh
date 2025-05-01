#!/bin/sh

#AdGuardHome Updater for GL.INET and Asus routers created by phantasm22
#Last updated 1-May-2025
#v1.0

#==================== COLORS ====================
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
#================================================

ARCH="linux_arm64"
SCRIPT_VERSION="1.0.0"
AGH_BIN=""
VERSION=""
LATEST_VERSION=""
TRAIN=""
TMP_DIR="/tmp/agh-update"

#==================== FUNCTIONS ====================

find_running_binary() {
    pid=$(pidof AdGuardHome 2>/dev/null)
    if [ -n "$pid" ]; then
        exe=$(readlink -f "/proc/$pid/exe")
        if [ -x "$exe" ]; then
            AGH_BIN="$exe"
            return
        fi
    fi

    # Try startup script fallback
    for candidate in /etc/init.d/AdGuardHome /etc/rc.local /etc/rc.d/* /etc/config/*; do
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
    echo -e "\n${BLUE}                               AdGuardHome Updater v$SCRIPT_VERSION${NOCOLOR}"
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
    for file in /etc/init.d/* /etc/rc.local /jffs/scripts/* /opt/etc/init.d/*; do
        [ -f "$file" ] || continue
        grep -q 'AdGuardHome' "$file" && STARTUP_SCRIPT="$file" && return
    done
}

stop_adguardhome() {
    if [ -n "$STARTUP_SCRIPT" ]; then                                                                                                                                                                                         
        "$STARTUP_SCRIPT" stop 2>/dev/null                                                                                                                                                                                
    else                                                                                                                                                                                                                      
    	pid=$(pidof AdGuardHome)
    	[ -n "$pid" ] && kill "$pid" && sleep 2
    fi                                                                                                                                                                                                                        
}

start_adguardhome() {
    if [ -n "$STARTUP_SCRIPT" ]; then
        "$STARTUP_SCRIPT" start 2>/dev/null
    else
        "$AGH_BIN" -s start 2>/dev/null
    fi
}

restart_adguardhome() {                                                                                                                                                                                                                          
    if [ -n "$STARTUP_SCRIPT" ]; then                                                                                                                                                                                                          
        "$STARTUP_SCRIPT" restart 2>/dev/null                                                                                                                                                                                                    
    else                                                                                                                                                                                                                                       
        "$AGH_BIN" -s restart 2>/dev/null                                                                                                                                                                                                      
    fi                                                                                                                                                                                                                                         
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

    MESSAGES=""  # Accumulator for stacked status messages

    draw_screen() {
        percent="$1"
        bar_width=50
        filled=$((percent * bar_width / 100))
        empty=$((bar_width - filled))
        bar="$(printf "%0.s=" $(seq 1 "$filled"))"
        bar="$bar$(printf "%0.s." $(seq 1 "$empty"))"

        clear
        printf "🔄 [%3d%%] [%-${bar_width}s]\n\n" "$percent" "$bar"
        [ -n "$MESSAGES" ] && printf "%b\n" "$MESSAGES"
    }

    add_msg() {
        MESSAGES="${MESSAGES}\n$1"
    }

    draw_screen 0

    add_msg "⬇️ Downloading AdGuardHome_${ARCH}.tar.gz..."
    draw_screen 10
    URL=$(build_download_url)
    if ! curl -sSL -o "AdGuardHome_${ARCH}.tar.gz" "$URL"; then
        add_msg "${RED}❌ Failed to download from $URL${NOCOLOR}"
        draw_screen 10
        cd /tmp && rm -rf "$TMP_DIR"
        return 1
    fi

    add_msg "🔧 Extracting files..."
    draw_screen 25
    if ! tar -xzf "AdGuardHome_${ARCH}.tar.gz"; then
        add_msg "${RED}❌ Extraction failed.${NOCOLOR}"
        draw_screen 25
        cd /tmp && rm -rf "$TMP_DIR"
        return 1
    fi

    add_msg "🛑 Stopping AdGuardHome service..."
    draw_screen 50
    find_startup_script
    stop_adguardhome

    add_msg "📁 Replacing binary..."
    draw_screen 75
    if [ -f "./AdGuardHome/AdGuardHome" ]; then
        cp -f ./AdGuardHome/AdGuardHome "$AGH_BIN"
        chmod +x "$AGH_BIN"
    else
        add_msg "${RED}❌ Extracted binary not found.${NOCOLOR}"
        draw_screen 75
        cd /tmp && rm -rf "$TMP_DIR"
        return 1
    fi

    add_msg "✅ Restarting service..."
    draw_screen 100
    start_adguardhome

    NEW_VER="$($AGH_BIN --version | awk '{print $4}')"
    if [ "$NEW_VER" = "$LATEST_VERSION" ]; then
        add_msg "✅ Update complete!"
    else
        add_msg "${RED}❌ Update failed: still running $NEW_VER${NOCOLOR}"
    fi
    draw_screen 100

    cd /tmp && rm -rf "$TMP_DIR"
    return 0
}

manage_service() {
    find_startup_script
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

#==================== MAIN ====================
find_running_binary
get_current_version
get_release_train
get_latest_version
show_info

while true; do
    echo -e "\n🧭 Please choose an option:"
    echo -e "  1) 🚀 Update AdGuardHome"
    echo -e "  2) 🔁 Change Release Train"
    echo -e "  3) 🕰️  Restore Previous Version"
    echo -e "  4) 🔧 Manage AdGuardHome (Start/Stop/Restart)"
    echo -e "  5) ❌ Exit"
    echo -n -e "\n📍 Enter choice: "
    read choice

    case "$choice" in
        1)
            echo -ne "\n💾 Backup option? (both/binary/config/none): "
            read backup_choice
            echo "(Backup code here – currently not implemented)"
            download_update
            ;;
        2)
            change_release_train
            show_info
            ;;
        3)
            echo "Restore functionality not yet implemented."
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
