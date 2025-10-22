# Frida-Server Installer

Frida-Server Installer which downloads binary online and pushes it to system/bin and fixes segmentation fault error in termux (google play) and adds one line cmd to install necessary cli tools for running frida

## Features 

- Downloads and pushes Florida-server to system/bin (bypasses anti-Frida detections)
- Fixes Termux (Google Play) segmentation faults
- Adds `frida-i` command for quick CLI tools installation

## Installation

1. Flash the module using Magisk/KSU
2. Reboot your device
3. Run `frida-i` in Termux to install CLI tools

## Usage

### Install Frida CLI tools

```
frida-i
```

### Start Frida-server

```
cd /system/bin/
tsu
```

```
./Vasuki
```

### Connect to Frida (in a new Termux session)

```
frida -H localhost:27042 -f pkg.name -l pathto/script.js
```

Replace `pkg.name` with your target package and `script.js` with your Frida script.

## Notes

Florida-server bypasses common anti-Frida detection mechanisms found in many apps. If using Termux from the Play Store, follow the module's instructions to fix segmentation faults.

## Credits

- apmods – for the curl binary
