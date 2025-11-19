#!/system/bin/sh

TIMEOUT=30

ui_print() {
  echo "$1"
}

choose_option() {
  ui_print ""
  ui_print "[*] Fix wget segmentation error?"
  echo ""
  ui_print "⬆️ = Yes | ⬇️ = No"
  echo ""
  ui_print "[*] Press Volume Button to select options"
  echo ""
  while :; do
    event=$(getevent -qlc 1 2>/dev/null)
    echo "$event" | grep -q "KEY_VOLUMEUP.*DOWN"   && return 0
    echo "$event" | grep -q "KEY_VOLUMEDOWN.*DOWN" && return 1
  done
}

banner() {
ui_print "
⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠀⠀
⢸⣍⡙⢿⣏⠉⠉⠉⠋⠉⠉⣩⣾⢋⣩⡇
⢸⡈⢿⣦⡙⢳⣄⠀⠀⣠⡶⢋⣵⡿⢃⡇
⢸⣙⠿⣮⢋⢷⡝⣣⠸⣫⡴⢛⣵⡾⢋⡇
⢸⣝⢿⣮⣜⢷⢸⢋⡄⣫⡶⣃⣵⡾⣫⡇
⢸⠙⢶⣭⢚⠷⢰⣯⢆⣩⡾⣃⣭⡶⠋⡇
⢸⠀⠳⣾⣘⡃⠰⡣⢋⣵⠞⡃⣽⡶⠀⡇
⢸⠀⠐⠾⡍⡃⡺⢞⣁⠶⣛⢭⡷⠂⠀⡇
⠘⠤⣀⠙⠶⠆⣚⠽⢐⣫⠍⠶⠊⣀⠤⠃
⠀⠀⠈⠙⢫⣬⣖⠃⠙⢊⣚⡋⠊⠁⠀⠀
⠀⠀⠀⠀⠀⠀⠈⠙⠋⠁⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 Frida Installer
 by Vasuki⠀⠀⠀⠀                                          
"
echo ""
sleep 1
}

get_frida() {
ARCH=$(getprop ro.product.cpu.abi)
case "$ARCH" in
  arm64-v8a)
    CURL="$MODPATH/bin/arm64/curl"
    ;;
  armeabi-v7a)
    CURL="$MODPATH/bin/arm/curl"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

chmod +x "$CURL"
LATEST_TAG=$("$CURL" -s -L https://api.github.com/repos/vasuki-re/Florida/releases/latest | grep '"tag_name":' | cut -d'"' -f4)

if [ -z "$LATEST_TAG" ]; then
    echo "Failed to fetch latest release tag"
    exit 1
fi

case "$ARCH" in
  arm64-v8a)
    URL="https://github.com/vasuki-re/Florida/releases/download/${LATEST_TAG}/florida-server-${LATEST_TAG}-android-arm64.gz"
    ;;
  armeabi-v7a)
    URL="https://github.com/vasuki-re/Florida/releases/download/${LATEST_TAG}/florida-server-${LATEST_TAG}-android-arm.gz"
    ;;
esac

cd /data/local/tmp
echo "[*] Downloading Florida Server $LATEST_TAG..."
echo ""
"$CURL" -L -o frida.gz "$URL"

if [ ! -f frida.gz ]; then
    echo "Download failed"
    exit 1
fi

echo "[*] Extracting Binary..."
echo ""
gunzip -f frida.gz

mkdir -p "$MODPATH/system/bin"
mv frida "$MODPATH/system/bin/Vasuki"

cd /
rm -rf /data/local/tmp/frida*
rm -rf "$MODPATH/bin"
}

perm() {
echo "[*] Setting Permissions"
echo ""
find "$MODPATH/system" -type d -exec chmod 755 {} + 2>/dev/null
find "$MODPATH/system" -type f -exec chmod 777 {} + 2>/dev/null
chmod 777 "$MODPATH/system/bin/Vasuki"
}

fix_wget() {
    # Extract module ID from module.prop
    MODID=$(grep "^id=" "$MODPATH/module.prop" | cut -d= -f2)
    
    # Check if the marker file exists in the currently installed module directory
    if [ -f "/data/adb/modules/$MODID/wget" ]; then
        # Persist the marker to the new installation
        touch "$MODPATH/wget"
        return 0
    fi

    VERSION=$(dumpsys package com.termux | grep versionName | head -n 1 | sed 's/.*versionName=//')

    if echo "$VERSION" | grep -qi "googleplay"; then
        ui_print ""
        ui_print "[*] Google Play Termux detected..."
        
        choose_option
        
        if [ $? -eq 0 ]; then
            [ ! -d "/data/data/com.termux/files/usr/etc/apt" ] && {
                am start -n com.termux/.app.TermuxActivity >/dev/null 2>&1
                sleep 3
                am force-stop com.termux
            }
            
            umask 0000
            
            TERMUX_APT_PATH="/data/data/com.termux/files/usr/etc/apt"
            SOURCE_PATH="$MODPATH/apt"
            TERMUX_UID=$(stat -c "%u:%g" /data/data/com.termux/files/usr 2>/dev/null)
            
            rm -rf "$TERMUX_APT_PATH"
            cp -r "$SOURCE_PATH" "$TERMUX_APT_PATH"
            chown "$TERMUX_UID" "$TERMUX_APT_PATH"
            chmod 700 "$TERMUX_APT_PATH"
            chown -R "$TERMUX_UID" "$TERMUX_APT_PATH"
            
            for dir in "$TERMUX_APT_PATH"/*; do
                [ -d "$dir" ] && chmod 700 "$dir"
            done
            
            for dir in "$TERMUX_APT_PATH"/*; do
                [ -d "$dir" ] && for file in "$dir"/*; do
                    [ -f "$file" ] && chmod 660 "$file"
                done
            done
            
            for dir in "$TERMUX_APT_PATH"/*; do
                [ -d "$dir" ] && for subdir in "$dir"/*; do
                    [ -d "$subdir" ] && chmod 700 "$subdir"
                done
            done
            
            for dir in "$TERMUX_APT_PATH"/*; do
                [ -d "$dir" ] && for subdir in "$dir"/*; do
                    [ -d "$subdir" ] && for file in "$subdir"/*; do
                        [ -f "$file" ] && chmod 600 "$file"
                    done
                done
            done
            
            ui_print "[*] Fixed wget ₍^. .^₎⟆"
        fi
        touch "$MODPATH/wget"
    fi
}
install_frida() {
    TERMUX_BIN="/data/data/com.termux/files/usr/bin"
    
    if [ -f "$TERMUX_BIN/frida-i" ]; then
        return 0
    fi

    ui_print ""
    ui_print "[*] Configuring Termux to install frida easier..."
    echo ""
    
    cat > "$TERMUX_BIN/frida-i" << 'EOF'
pkg update
pkg upgrade -y
pkg install tsu
pkg install -y build-essential python python-pip git wget binutils openssl
wget https://maglit.me/frida-python -O frida-python && yes | bash frida-python
EOF
    
    chmod 777 "$TERMUX_BIN/frida-i"
    ui_print "[*] Frida installer script created ₍^. .^₎⟆"
    ui_print ""
    ui_print "═══════════════════════════════════════"
    ui_print "  Go to Termux and run: frida-i"
    ui_print "  to install cli pkgs required to use Frida"
    ui_print "═══════════════════════════════════════"
    ui_print ""
}

banner
get_frida
perm
fix_wget
install_frida