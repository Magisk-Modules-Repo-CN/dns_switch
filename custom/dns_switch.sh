#!/system/bin/sh
# Terminal Magisk Mod Template
# by veez21 @ xda-developers
# Modified by @JohnFawkes - Telegram
# Supersu/all-root compatibility with Unity and @Zackptg5

# Magisk Module ID **
# > ENTER MAGISK MODULE ID HERE
MODID=<MODID>

# Varizbles
OLDPATH=$PATH
MOUNTPATH=<MOUNTPATH>
MODPATH=<MODPATH>
MAGISK=<MAGISK>
ROOT=<ROOT>
SYS=<SYS>
VEN=<VEN>

# Set Prop Directory
PROP=<PROP>
MODPROP=<MODPROP>
[ -f $MODPROP ] || { echo "Module not detected!"; quit 1; }

# Set Log Files
mount -o remount,rw /cache 2>/dev/null
mount -o rw,remount /cache 2>/dev/null
# > Logs should go in this file
LOG=/cache/${MODID}.log
oldLOG=/cache/${MODID}-old.log
# > Verbose output goes here
VERLOG=/cache/${MODID}-verbose.log
oldVERLOG=/cache/${MODID}-verbose-old.log

# Start Logging verbosely
mv -f $VERLOG $oldVERLOG 2>/dev/null; mv -f $LOG $oldLOG 2>/dev/null
set -x 2>$VERLOG

#ZACKPTG5 BUSYBOX
#=========================== Set Busybox up
if [ "$(busybox 2>/dev/null)" ]; then
  BBox=true
elif $MAGISK && [ -d /sbin/.core/busybox ]; then
  PATH=/sbin/.core/busybox:$PATH
	_bb=/sbin/.core/busybox/busybox
  BBox=true
else
  BBox=false
  echo "! Busybox not detected"
	echo "Please install one (@osm0sis' busybox recommended)"
  for applet in cat chmod cp grep md5sum mv printf sed sort tar tee tr wget; do
    [ "$($applet)" ] || quit 1
  done
  echo "All required applets present, continuing"
fi
if $BBox; then
  alias cat="busybox cat"
  alias chmod="busybox chmod"
  alias cp="busybox cp"
  alias grep="busybox grep"
  alias md5sum="busybox md5sum"
  alias mv="busybox mv"
  alias printf="busybox printf"
  alias sed="busybox sed"
  alias sort="busybox sort"
  alias tar="busybox tar"
  alias tee="busybox tee"
  alias tr="busybox tr"
  alias wget="busybox wget"
fi

if [ -z "$(echo $PATH | grep /sbin:)" ]; then
	alias resetprop="/data/adb/magisk/magisk resetprop"
fi

# Log print
#echo "Functions loaded."
if $BBox; then
  BBV=$(busybox | grep "BusyBox v" | sed 's|.*BusyBox ||' | sed 's| (.*||')
#  echo "Using busybox: ${PATH} (${BBV})."
#else
#  echo "Using installed applets (not busybox)"
fi

#=========================== Functions
quit() {
  PATH=$OLDPATH
  exit $?
}

# Finding file values
get_file_value() {
	if [ -f "$1" ]; then
		cat $1 | grep $2 | sed "s|.*${2}||" | sed 's|\"||g'
	fi
}


api_level_arch_detect() {
  API=`grep_prop ro.build.version.sdk`
  ABI=`grep_prop ro.product.cpu.abi | cut -c-3`
  ABI2=`grep_prop ro.product.cpu.abi2 | cut -c-3`
  ABILONG=`grep_prop ro.product.cpu.abi`
  ARCH=arm
  ARCH32=arm
  IS64BIT=false
  if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
}

grep_prop() {
  REGEX="s/^$1=//p"
  shift
  FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  [ -z $5 ] && chcon 'u:object_r:system_file:s0' $1 || chcon $5 $1 || return 1
}

magisk_version() {
  if grep MAGISK_VER /data/adb/magisk/util_functions.sh; then
		echo "$MAGISK_VERSION $MAGISK_VERSIONCODE" >> $ALOG 2>&1
	else
		echo "Magisk not installed" >> $ALOG 2>&1
	fi
}

# Device Info
# BRAND MODEL DEVICE API ABI ABI2 ABILONG ARCH
BRAND=$(getprop ro.product.brand)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
ROM=$(getprop ro.build.display.id)
api_level_arch_detect
# Version Number
VER=$(grep_prop version $MODPROP)
# Version Code
REL=$(grep_prop versionCode $MODPROP)
# Author
AUTHOR=$(grep_prop author $MODPROP)
# Mod Name/Title
MODTITLE=$(grep_prop name $MODPROP)
#Grab Magisk Version
MAGISK_VERSION=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VERSION=") | sed 's|-.*||')
MAGISK_VERSIONCODE=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VERSIONCODE=") | sed 's|-.*||')

# Colors
G='\e[01;32m'		# GREEN TEXT
R='\e[01;31m'		# RED TEXT
Y='\e[01;33m'		# YELLOW TEXT
B='\e[01;34m'		# BLUE TEXT
V='\e[01;35m'		# VIOLET TEXT
Bl='\e[01;30m'		# BLACK TEXT
C='\e[01;36m'		# CYAN TEXT
W='\e[01;37m'		# WHITE TEXT
BGBL='\e[1;30;47m'	# Background W Text Bl
N='\e[0m'			# How to use (example): echo "${G}example${N}"
loadBar=' '			# Load UI
# Remove color codes if -nc or in ADB Shell
[ -n "$1" -a "$1" == "-nc" ] && shift && NC=true
[ "$NC" -o -n "$LOGNAME" ] && {
	G=''; R=''; Y=''; B=''; V=''; Bl=''; C=''; W=''; N=''; BGBL=''; loadBar='=';
}

# Divider (based on $MODTITLE, $VER, and $REL characters)
character_no=$(echo "$MODTITLE $VER $REL" | tr " " '_' | wc -c)
div="${Bl}$(printf '%*s' "${character_no}" '' | tr " " "=")${N}"

# Title Div
title_div() {
  no=$(echo "$@" | wc -c)
  extdiv=$((no-character_no))
  echo "${W}$@${N} ${Bl}$(printf '%*s' "$extdiv" '' | tr " " "=")${N}"
}

# set_file_prop <property> <value> <prop.file>
set_file_prop() {
  if [ -f "$3" ]; then
    if grep "$1=" "$3"; then
      sed -i "s/${1}=.*/${1}=${2}/g" "$3"
    else
      echo "$1=$2" >> "$3"
    fi
  else
    echo "$3 doesn't exist!"
  fi
}

# https://github.com/fearside/ProgressBar
ProgressBar() {
# Process data
  _progress=$(((${1}*100/${2}*100)/100))
  _done=$(((${_progress}*4)/10))
  _left=$((40-$_done))
# Build progressbar string lengths
  _done=$(printf "%${_done}s")
  _left=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : ${BGBL}|${N}${_done// /${BGBL}$loadBar${N}}${_left// / }${BGBL}|${N} ${_progress}%%"
}

#https://github.com/fearside/SimpleProgressSpinner
Spinner() {

# Choose which character to show.
case ${_indicator} in
  "|") _indicator="/";;
  "/") _indicator="-";;
  "-") _indicator="\\";;
  "\\") _indicator="|";;
  # Initiate spinner character
  *) _indicator="\\";;
esac

# Print simple progress spinner
printf "\r${@} [${_indicator}]"
}

# "cmd & spinner [message]"
e_spinner() {
  PID=$!
  h=0; anim='-\|/';
  while [ -d /proc/$PID ]; do
    h=$(((h+1)%4))
    sleep 0.02
    printf "\r${@} [${anim:$h:1}]"
  done
}

# test_connection
test_connection() {
  echo -n "Testing internet connection "
  ping -q -c 1 -W 1 google.com >/dev/null 2>/dev/null && echo "- OK" || { echo "Error"; false; }
}

# Log files will be uploaded to termbin.com
upload_logs() {
  $BBok && {
    test_connection
    [ $? -ne 0 ] && exit
    verUp=none; oldverUp=none; logUp=none; oldlogUp=none;
    echo "Uploading logs"
    [ -s $VERLOG ] && verUp=$(cat $VERLOG | nc termbin.com 9999)
    [ -s $oldVERLOG ] && oldverUp=$(cat $oldVERLOG | nc termbin.com 9999)
    [ -s $LOG ] && logUp=$(cat $LOG | nc termbin.com 9999)
    [ -s $oldLOG ] && oldlogUp=$(cat $oldLOG | nc termbin.com 9999)
    echo -n "Link: "
    echo "$MODEL ($DEVICE) API $API\n$ROM\n$ID\n
    O_Verbose: $oldverUp
    Verbose:   $verUp

    O_Log: $oldlogUp
    Log:   $logUp" | nc termbin.com 9999
  } || echo "Busybox not found!"
  exit
}

# Heading
mod_head() {
	clear
	echo "$div"
	echo "${W}$MODTITLE $VER${N}(${Bl}$REL${N})"
	echo "by ${W}$AUTHOR${N}"
	echo "$div"
  echo "${W}$BRAND,$MODEL,$DEVICE,$ROM${N}"
  echo "$div"
#  echo "${W}$PATH${N}"
	echo "${W}$BBV${N}"
	echo "${W}$_bb${N}"
	echo "$div"
if $MAGISK; then 
	magisk_version
	echo "$div"
fi
}

#=========================== Main
# > You can start your MOD here.
# > You can add functions, variables & etc.
# > Rather than editing the default vars above.

re_dns_menu () {

response=""

  echo ""
  title_div "${G}REMOVE CUSTOM DNS MENU${N}"
  echo ""
  echo "$div"
  echo ""
  echo -n "${G}Do You Want to Remove Your Custom DNS?${N}" 
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"
  read -r response
if [ "$response" = "y" ] || [ "$response" = "Y" ] || [ "$response" = "yes" ] || [ "$response" = "Yes" ] || [ "$response" = "YES" ]; then
dns_remove
else
menu
fi
}

 dns_remove () {
resetprop --delete net.eth0.dns1
resetprop --delete net.eth0.dns2
resetprop --delete net.dns1
resetprop --delete net.dns2
resetprop --delete net.ppp0.dns1
resetprop --delete net.ppp0.dns2
resetprop --delete net.rmnet0.dns1
resetprop --delete net.rmnet0.dns2
resetprop --delete net.rmnet1.dns1
resetprop --delete net.rmnet1.dns2
resetprop --delete net.pdpbr1.dns1
resetprop --delete net.pdpbr1.dns2

if [ -f $MODPATH/system/etc/resolv.conf ]; then
sed -i -e "$custom/d" >> $MODPATH/system/etc/resolv.conf
sed -i -e "$custom2/d" >> $MODPATH/system/etc/resolv.conf
fi

echo "${B}Custom DNS Removed Successfully${N}"
sleep 1
menu
} 

dns_menu() {

custom=""
custom2=""
choice2=""

  echo ""
  title_div "${G}CUSTOM DNS MENU${N}"
  echo ""
  echo "$div"
  echo ""
  echo -n "${G}Please Enter Your Custom DNS${N}" 
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"
  echo ""
  read -r custom
  echo "${G}$custom${N}"
  echo ""
  echo "${G} Would You Like to Enter a Second DNS?${N}"
  echo ""
  echo -n "${R} [CHOOSE] :   ${N}"
  echo ""
  read -r choice2
  echo "${G}$choice2${N}"
  echo ""
if [ "$choice2" = "y" ] || [ "$choice2" = "Y" ] || [ "$choice2" = "yes" ] || [ "$choice2" = "Yes" ] || [ "$choice2" = "YES" ]; then
  echo -n "${G} Please Enter Your Custom DNS2${N}"
  echo ""
  echo -n "${R} [CHOOSE]  :  ${N}"
  echo ""
  read -r custom2
  echo "${G}$custom2${N}"
fi
if [ -n $custom ] || [ -n $custom2 ]; then
setprop net.eth0.dns1 $custom
setprop net.eth0.dns2 $custom2
setprop net.dns1 $custom
setprop net.dns2 $custom2
setprop net.ppp0.dns1 $custom
setprop net.ppp0.dns2 $custom2
setprop net.rmnet0.dns1 $custom
setprop net.rmnet0.dns2 $custom2
setprop net.rmnet1.dns1 $custom
setprop net.rmnet1.dns2 $custom2
setprop net.pdpbr1.dns1 $custom
setprop net.pdpbr1.dns2 $custom2
iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination $custom:53
iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination $custom2:53
iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to-destination $custom:53
iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to-destination $custom2:53
  if [ -f /system/etc/resolv.conf ]; then
mkdir -p $MODPATH/system/etc
cp -f /system/etc/resolv.conf $MODPATH/system/etc
printf "nameserver $custom\nnameserver $custom2" >> $MODPATH/system/etc/resolv.conf
chmod 644 $MODPATH/system/etc/resolv.conf
  fi
fi
echo "${R} Thanks For Using Custom DNS Module By @JohnFawkes - @Telegram/@XDA ${N}"
quit
} 

menu() {
  
choice=""

while [ "$choice" != "q" ]
  do  	
  mod_head
  echo ""
  title_div "${G}DNS MAIN MENU${N}"
  echo ""
  echo "$div"
  echo ""
  echo "${G}Please make a Selection${N}"
  echo ""
  echo -e "${W}D)${N} ${B}Enter Custom DNS${N}"
  echo ""
  echo -e "${W}R)${N} ${B}Remove Custom DNS${N}"
  echo ""
  echo -e "${W}Q)${N} ${B}Quit${N}"
  echo ""
  echo "$div"
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"

  read -r choice
 
  case $choice in
  d|D) echo "${G} Custom DNS Menu Selected... ${N}"
  sleep 1.5
  dns_menu
  ;;
  r|R) echo "${Y} Remove Custom DNS Selected... ${N}"
  sleep 1.5
  re_dns_menu
  ;;
  q|Q) echo " ${R}Quiting... ${N}"
  clear
  quit
  ;;
  *) echo "${Y}item not available! Try Again${N}"
  sleep 1.5
  clear
  ;;
  esac
done
}

menu

quit $?
