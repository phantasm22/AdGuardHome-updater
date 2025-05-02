# AdGuardHome-updater Changelog

All notable changes to this project will be documented in this file.

This changelog follows the principles of  
[*Keep a Changelog*](https://keepachangelog.com/en/1.0.0/),  
and adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

---

## [v1.1.0] - 2025-05-02

### Added
- Visual progress indicators with percentage and status during updates.
- Improved user interface for upgrade steps and dynamic feedback.

### Fixed
- Bug where the updater could fail to detect the correct startup script on Asus routers.

---

## [v1.0.0] - 2025-04-30

### Added
- Major rewrite: Introduced an interactive menu-driven interface with support for:
  - Release train switching (Stable ↔ Beta)
  - Dynamic version detection from the current binary
  - Backup and restore options (config, binary, or both)
  - Update status with contextual line management
- Built-in service manager to start, stop, or restart AdGuardHome cleanly.

### Changed
- Refactored update logic for cleaner separation of functions and reduced redundancy.

---

## [v0.6.0] - 2024-06-12

### Changed
- Script now ignores `/overlay` directories to avoid corrupting file systems.  
  See [this thread](https://forum.gl-inet.com/t/gl-mt1300-beryl-bugs/42543/28?u=phantasm22) for background.

---

## [v0.5.0] - 2024-05-26

### Added
- Support for GL.iNet routers (e.g., Beryl AX) that enable AdGuardHome via Web UI.

### Changed
- Startup script execution now silences output during AdGuardHome service control.

---

## [v0.4.0] - 2024-05-24

### Added
- Interactive Y/N prompts for backing up AdGuardHome binary and config.
- Disk space checks before proceeding with backups, with warnings if space is low.

---

## [v0.3.0] - 2023-08-07

### Added
- Support for MIPS and ARM64 (64-bit ARM) architectures.

### Changed
- Cleaner method to check for `wget`.

### Deprecated
- Removed legacy `kill` script detection in favor of using the startup script.

### Fixed
- Removed hardcoded paths for better portability.

---

## [v0.2.0] - 2023-07-31

### Added
- Detection of `wget-ssl` if present.

### Fixed
- Missing `fi` statement.

---

## [v0.1.0] - 2023-07-05

### Added
- Initial release. Basic support for MT1300 ("Beryl") routers.
- Functionality untested outside of the author's own device.
