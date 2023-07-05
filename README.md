# Gl.iNet-AdGuardHome-Updater
Shell script to update AdGuardHome on GL.iNet based routers.

## Features
1. Checks for dependencies:
   a. Free disk space to upgrade
   b. Properly installed and running version of AGH
   c. Checks for the correct model and fails if you aren’t running the correct version
2. Downloads and parses the available beta and release versions of AGH comparing to your current version and presents an output of the same
3. Allows you to switch from beta to release and vice versa or just upgrade to the latest version of your chosen branch (if available)
4. Will fetch the correct go binary based on your model number
5. Extracts the tarball (with a check that it can find the new binary file)
6. Creates a backup of your existing binary and config files
7. Disables your AGH service (temporarily)
8. Copies new AGH binary into place
9. Reloads AGH service
10. Cleans up temp files created
11. Status along the way with error handling and graceful exiting if something fails (e.g. cleanup of temp files)

## Supported Routers
1. GL.iNet - "Beryl" MT1300


## Versions
--------
v0.1 - alpha version, only works on MT1300 "Beryl" routers. Not tested outside of my own router.
