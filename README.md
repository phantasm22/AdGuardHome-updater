# AdGuardHome-Updater
Shell script to update AdGuardHome on GL.iNet and Asus based routers. Others may work but unsupported.

## Features
1. Checks for dependencies:
   - Free disk space to upgrade
   - Properly installed and running version of AGH
   - Checks for the correct model and fails if you aren’t running the correct version
1. Downloads and parses the available beta and release versions of AGH comparing to your current version and presents an output of the same
1. Allows you to switch from beta to release and vice versa or just upgrade to the latest version of your chosen branch (if available)
1. Will fetch the correct go binary based on your arch type
1. Extracts the tarball (with a check that it can find the new binary file)
1. Creates a backup of your existing binary and config files
1. Disables your AGH service (temporarily)
1. Copies new AGH binary into place
1. Reloads AGH service
1. Cleans up temp files created
1. Status along the way with error handling and graceful exiting if something fails (e.g. cleanup of temp files)

## Tested Routers
1. GL.iNet - MIPS
2. Asus - 64Bit ARM

## Installation
1. SSH to your router
1. Change to the directory you'd like to download AGH updater
1. `wget https://raw.githubusercontent.com/phantasm22/AdGuardHome-updater/main/update-agh.sh`
1. `chmod +x ./update-agh.sh`
1. `./update-agh.sh`
