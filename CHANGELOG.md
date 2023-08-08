# AdGuardHome-updater Changelog

All notable changes to this project will be documented in this file.

The format is based on
[*Keep a Changelog*](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).


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
