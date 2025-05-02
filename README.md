# update_adguardhome.sh

An interactive shell script for managing [AdGuardHome](https://github.com/AdguardTeam/AdGuardHome) on embedded Linux systems such as OpenWRT, GL.iNet routers, and other minimal environments.

---

## ✨ Features

- 🚀 One-click update to the latest **Stable** or **Beta** version of AdGuardHome
- 🔁 Seamless switching between Stable and Beta release trains
- 📦 Backup and restore:
  - Binary only
  - Config only
  - Both binary + config
- 🔧 Manage AdGuardHome service (start, stop, restart)
- 💬 Interactive, menu-driven interface with progress bar and messages
- 📊 Auto-detects system architecture (`linux_arm64`, `linux_amd64`, etc.)
- ✅ Verifies installation success before applying updates
- 🧼 Cleans up all temporary files and state after run
- 🔐 Minimal, dependency-free, POSIX-compliant shell script

---

## 🛠 Requirements

- **Shell**: POSIX-compatible shell (`/bin/sh`)
- **Tools**: `curl`, `tar`, `ps`, `kill`, `grep`, `awk`, `df`, `uname`, `sed`
- **Internet access**: To download the latest release from GitHub

---

## ⚠️ Minimum Disk Space

To perform updates and backups, the script requires **at least 45MB** of free space in `/tmp` or the working directory. This accounts for:

- The `.tar.gz` release file (~8–12MB)
- Extracted binary and support files (~28–32MB)
- Optional backup files (~1–30MB)

---

## 🚀 Installation

1. SSH into your router or device:

    ```sh
    ssh root@192.168.8.1
    ```

2. Download and make the script executable:

    ```sh
    wget -O update_adguardhome.sh https://raw.githubusercontent.com/phantasm22/AdGuardHome-updater/main/update_adguardhome.sh
    chmod +x update_adguardhome.sh
    ```

3. Run the script:

    ```sh
    ./update_adguardhome.sh
    ```

---

## 🔄 How Updates Work

- The script fetches the latest version metadata from GitHub
- It checks your system architecture and chooses the correct binary
- Downloads and extracts to a temporary directory
- Stops AdGuardHome service (if running)
- Replaces the old binary, and restarts the service
- Optionally creates or restores backups

All actions are verified and logged interactively.

---

## 🗂 Directory Structure

| File / Directory          | Purpose                           |
|---------------------------|-----------------------------------|
| `/tmp/agh-update/`        | Temporary download/extract path   |
| `AdGuardHome`             | Installed binary                  |
| `AdGuardHome.yaml` or `config.yaml`       | User configuration file           |
| `.bak`                   | Optional backup files            |

---

## 🧪 Tested Devices

This script has been tested on:

- GL.iNet GL-BE9300 (`linux_arm64`)
- GL.iNet GL-BE3600 (`linux_armv7`)
- Asus RT-AX86U (Merlin fork, USB install)
- OpenWRT 21.02+ (Generic targets)

If it works on your device, [submit a PR](https://github.com/phantasm22/AdGuardHome-updater) or open an issue to add it!

---

## ❓ Troubleshooting

- **Not enough disk space?**
  - Clear unused files in `/tmp`
  - Use an external `/opt` mount point with sufficient space

- **Script fails to detect architecture?**
  - Try running: `uname -m` and manually export `ARCH=linux_arm64`

- **Service doesn’t restart?**
  - Check your system's service manager or startup scripts
  - Use Option 4 in the menu to manually restart

---

## 📜 License

This project is licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).

---

## 🙌 Credits

- [AdGuard Team](https://github.com/AdguardTeam/AdGuardHome)
- [GL.iNet](https://www.gl-inet.com/)
- Inspired by real-world embedded shell scripting needs and router-side automation

---

## 📫 Contact

Questions or suggestions? Open an [issue](https://github.com/phantasm22/AdGuardHome-updater/issues) or message @phantasm22 on GitHub.
