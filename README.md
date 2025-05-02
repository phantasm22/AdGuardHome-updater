# update_adguardhome.sh

An interactive shell script for managing [AdGuardHome](https://github.com/AdguardTeam/AdGuardHome) on embedded Linux systems like OpenWRT, GL.iNet routers, and other minimal environments.

---

## ✨ Features

- 🚀 One-click update to the latest stable or beta AdGuardHome version
- 🔁 Seamless switching between **Stable** and **Beta** release trains
- 📦 Backup and restore:
  - Binary only
  - Config only
  - Both
- ⚙️ Manage AdGuardHome service (start/stop/restart)
- 💬 Interactive, menu-driven interface with progress bar and messages
- ✅ Verifies installation success before applying changes
- 📊 Auto-detects architecture (e.g., `linux_arm64`, `linux_amd64`, etc.)
- 🧼 Cleans up temporary files

---

## 🛠 Requirements

- Minimal POSIX-compatible shell (`/bin/sh`)
- Tools: `curl`, `tar`, `ps`, `kill`, `grep`, `awk`, `df`
- Internet access to fetch updates from GitHub

---

## 📦 Installation

1. Copy the script to your router or embedded system.
2. Make it executable:
   ```sh
   chmod +x update_adguardhome.sh
