# AdGuardHome-updater Changelog

All notable changes to this project will be documented in this file.

The format is based on
[*Keep a Changelog*](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [v0.5] - 2024-05-26

### Added
-  Added support for GLiNet routers that enable AdGuardHome from the WebUI e.g. Beryl AX
  
### Changed
- Starting and stopping of AdGuardHome service will silence output from the startup script

### Deprecated

### Fixed


## [v0.4] - 2024-05-24

### Added
-  Added Y/N questions for backing up config file and AGH binary and checking for backup space. If your /usr/bin is tight on space, then you should skip backup of your adguardhome binary
  
### Changed

### Deprecated

### Fixed



## [v0.3] - 2023-08-07

### Added
-  Added support for mips and 64bit ARM processors
  
### Changed
- Cleaner check for wget

### Deprecated
-  No longer checks for a kill script. Will use the startup script to kill processes.

### Fixed
-  Removed all explicit paths



## [v0.2] - 2023-07-31

### Added
-  Now checks for wget-ssl to be installed
  
### Changed

### Deprecated

### Fixed
-   Missing fi statement


## [v0.1] - 2023-07-05

### Added

-  Initial release: Currently only works on MT1300 "Beryl" routers. Not tested outside of my own router.
  
### Changed

### Deprecated

### Fixed
