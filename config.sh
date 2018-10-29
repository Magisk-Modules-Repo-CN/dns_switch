##########################################################################################
#
# Magisk Module Template Config Script
# by topjohnwu
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure the settings in this file (config.sh)
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Defines
##########################################################################################

# NOTE: This part has to be adjusted to fit your own needs

# Set to true if you need to enable Magic Mount
# Most mods would like it to be enabled
AUTOMOUNT=true

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=false

# Unity Variables
# Uncomment and change 'MINAPI' and 'MAXAPI' to the minimum and maxium android version for your mod (note that magisk has it's own minimum api: 21 (lollipop))
# Uncomment DYNAMICOREO if you want libs installed to vendor for oreo and newer and system for anything older
# Uncomment DYNAMICAPP if you want anything in $INSTALLER/system/app to be installed to the optimal app directory (/system/priv-app if it exists, /system/app otherwise)
# Uncomment SYSOVERRIDE if you want the mod to always be installed to system (even on magisk)
# Uncomment RAMDISK if you have ramdisk modifications. If you only want ramdisk patching as part of a conditional, just keep this commented out and set RAMDISK=true in that conditional.
# Uncomment DEBUG if you want full debug logs (saved to SDCARD if in twrp, part of regular log if in magisk manager (user will need to save log after flashing)
#MINAPI=21
#MAXAPI=25
#SYSOVERRIDE=true
#DYNAMICOREO=true
#DYNAMICAPP=true
#RAMDISK=true
DEBUG=true

# Custom Variables for Install AND Uninstall - Keep everything within this function
unity_custom() {
  BIN=$SYS/bin
  XBIN=$SYS/xbin
  if [ -d $XBIN ]; then BINPATH=$XBIN; else BINPATH=$BIN; fi
  if [ -d /cache ]; then CACHELOC=/cache; else CACHELOC=/data/cache; fi
  MODTITLE=$(grep_prop name $INSTALLER/module.prop)
  VER=$(grep_prop version $INSTALLER/module.prop)
	AUTHOR=$(grep_prop author $INSTALLER/module.prop)
	INSTLOG=$CACHELOC/dns_switch_install.log
} 

# Custom Functions for Install AND Uninstall - You can put them here
# Log functions

log_handler() {
  echo "" >> $INSTLOG 2>&1
  echo -e "$(date +"%m-%d-%Y %H:%M:%S") - $1" >> $INSTLOG 2>&1
}

log_start() {
	if [ -f "$INSTLOG" ]; then
    rm -f $INSTLOG
  fi
  touch $INSTLOG
  echo " " >> $INSTLOG 2>&1
  echo "    *******************************************" >> $INSTLOG 2>&1
  echo "    *<name2>*" >> $INSTLOG 2>&1
  echo "    *******************************************" >> $INSTLOG 2>&1
  echo "    *<version2>*" >> $INSTLOG 2>&1
  echo "    *******************************************" >> $INSTLOG 2>&1
  echo "    *<author2>*" >> $INSTLOG 2>&1
  echo "    *******************************************" >> $INSTLOG 2>&1
  echo " " >> $INSTLOG 2>&1
  log_handler "Starting module installation script"
}

log_print() {
  ui_print "$1"
  log_handler "$1"
}

# INSERT MODULE INFO INTO CONFIG.SH
(
for TMP in version2 name2 author2; do
  NEW=$(grep_prop $TMP $INSTALLER/module.prop)
  [ "$TMP" == "author" ] && NEW="by ${NEW}"
  CHARS=$((${#NEW}-$(echo "$NEW" | tr -cd "©®™" | wc -m)))
  SPACES=""
  if [ $CHARS -le 41 ]; then
    for i in $(seq $(((41-$CHARS) / 2))); do
      SPACES="${SPACES} "
    done
  fi
  if [ $(((41-$CHARS) % 2)) == 1 ]; then sed -i "s/<$TMP>/$SPACES$NEW${SPACES} /" $INSTALLER/config.sh; else sed -i "s/<$TMP>/$SPACES$NEW$SPACES/" $INSTALLER/config.sh; fi
done
)

# PRINT MOD NAME
log_start


##########################################################################################
# Installation Message
##########################################################################################

# Set what you want to show when installing your mod

print_modname() {
  ui_print " "
  ui_print "    *******************************************"
  ui_print "    *<name>*"
  ui_print "    *******************************************"
  ui_print "    *<version>*"
  ui_print "    *<author>*"
  ui_print "    *******************************************"
  ui_print " "
}

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# By default Magisk will merge your files with the original system
# Directories listed here however, will be directly mounted to the correspond directory in the system

# You don't need to remove the example below, these values will be overwritten by your own list
# This is an example
REPLACE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here, it will overwrite the example
# !DO NOT! remove this if you don't need to replace anything, leave it empty as it is now
REPLACE="
"

##########################################################################################
# Permissions
##########################################################################################

# NOTE: This part has to be adjusted to fit your own needs

set_permissions() {
  # DEFAULT PERMISSIONS, DON'T REMOVE THEM
  $MAGISK && set_perm_recursive $MODPATH 0 0 0755 0644

  # CUSTOM PERMISSIONS

set_perm $UNITY$BINPATH/dns_switch 0 2000 0777

  # Some templates if you have no idea what to do:
  # Note that all files/folders have the $UNITY prefix - keep this prefix on all of your files/folders
  # Also note the lack of '/' between variables - preceding slashes are already included in the variables
  # Use $SYS for system and $VEN for vendor (Do not use $SYS$VEN, the $VEN is set to proper vendor path already - could be /vendor, /system/vendor, etc.)

  # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  # set_perm_recursive $UNITY$SYS/lib 0 0 0755 0644
  # set_perm_recursive $UNITY$VEN/lib/soundfx 0 0 0755 0644

  # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  # set_perm $UNITY$SYS/lib/libart.so 0 0 0644
}
