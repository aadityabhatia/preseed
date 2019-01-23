# Preseed Generator

Ubuntu/Debian preconfiguration file generator for automated OS installation

## Installation
```
npm install --global preseed
```

## Usage
```
preseed [-p 18000] [-t template.cfg] [-c config.json] [-H hostnames.json] [-n]
```

## Options
```
  -p, --port <number>              HTTP server port
  -t, --template <filename>        preseed template
  -c, --config <filename.json>     configuration file
  -H, --hostnames <filename.json>  list of hostnames
  -n, --no-apt-proxy-detect        do NOT automatically detect apt-proxy on local network
  -V, --version                    output the version number
  -h, --help                       output usage information
```

## Configuration File

- `TIMEZONE`: See `/usr/share/zoneinfo/` for valid values.
- `PACKAGE_DESKTOP_ENV`: Package containing the desktop environment
- `PACKAGES_ADDITIONAL`: List of additional packages to be installed; can be an array, a space-separated string, or an array of space-separated strings
- `URL_RESOURCES`: Location of `SCRIPT_BOOTSTRAP` and `RESOURCES`; can be HTTP, HTTPS, or FTP
- `SCRIPT_BOOTSTRAP`: Script executed during installation using `preseed/late_command` directive
- `RESOURCES`: Files downloaded to the default user's home directory (e.g. `/home/user`); these are not executed during or after the installation.

## Note

 This module relies on certain Linux binaries. Windows is currently not supported. Other platforms were not tested. Pull requests are welcome.
