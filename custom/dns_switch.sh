#!/system/bin/sh
# Terminal Magisk Mod Template
# by veez21 @ xda-developers
# Modified by @JohnFawkes - Telegram
# Supersu/all-root compatibility with Unity and @Zackptg5

# Magisk Module ID **
# > ENTER MAGISK MODULE ID HERE
MODID=<MODID>

# Detect root
_name=$(basename $0)
[[ $(id -u) -ne 0 ]] && { echo "$MODID needs to run as root!"; echo "type 'su' then '$_name'"; exit 1; }

# Variables

OLDPATH=$PATH
MODPATH=<MODPATH>
MAGISK=<MAGISK>
ROOT=<ROOT>
SYS=<SYS>
VEN=<VEN>
CACHELOC=<CACHELOC>
DNSLOG=$MODPATH/dns.txt
DNSSERV=$MODPATH/service.sh

# Set Prop Directory

PROP=<PROP>
MODPROP=<MODPROP>
[ -f $MODPROP ] || { echo "Module not detected!"; quit 1; }

# Set Log Files
mount -o remount,rw /cache 2>/dev/null
mount -o rw,remount /cache 2>/dev/null
# > Logs should go in this file
LOG=$CACHELOC/${MODID}.log
oldLOG=$CACHELOC/${MODID}-old.log
# > Verbose output goes here
VERLOG=$CACHELOC/${MODID}-verbose.log
oldVERLOG=$CACHELOC/${MODID}-verbose-old.log

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

if $BBox; then
  BBV=$(busybox | grep "BusyBox v" | sed 's|.*BusyBox ||' | sed 's| (.*||')
  echo "Using busybox: ${PATH} (${BBV})." >> $LOG 2>&1
else
 echo "Using installed applets (not busybox)" >> $LOG 2>&1
fi

# Functions
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
		echo "$MAGISK_VERSION $MAGISK_VERSIONCODE" >> $LOG 2>&1
	else
		echo "Magisk not installed" >> $LOG 2>&1
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
MAGISK_VERSION=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VER=") | sed 's|-.*||')
MAGISK_VERSIONCODE=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VER_CODE=") | sed 's|-.*||')

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
    echo "$MODEL ($DEVICE) API $API\n$ROM\n$MODID\n
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
  echo "${R}$BRAND${N},${R}$MODEL${N},${R}$ROM${N}"
  echo "$div"
	echo "${W}BUSYBOX VERSION = ${N}${R}$BBV${N}"
	echo "$div"
if $MAGISK; then 
	echo "${W}MAGISK VERSION = ${N}${R} $MAGISK_VERSION${N}" 
	echo "$div"
  echo ""
fi
}

#=========================== Main
# > You can start your MOD here.
# > You can add functions, variables & etc.
# > Rather than editing the default vars above.

# Find prop type
get_prop_type() {
	echo $1 | sed 's|.*\.||'
}

# Get left side of =
get_eq_left() {
	echo $1 | sed 's|=.*||'
}

# Get right side of =
get_eq_right() {
	echo $1 | sed 's|.*=||'
}

# Get first word in string
get_first() {
	case $1 in
		*\ *) echo $1 | sed 's|\ .*||'
		;;
		*=*) get_eq_left "$1"
		;;
	esac
}

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  [ -z $5 ] && chcon 'u:object_r:system_file:s0' $1 || chcon $5 $1 || return 1
}

help_me() {
  cat << EOF
$MODTITLE $VER($REL)
by $AUTHOR

Usage: $_name
   or: $_name [options]...
   
Options:
    -nc                    removes ANSI escape codes
    -r                     remove DNS
    -c [DNS ADRESS]        add custom DNS
    -l                     list custom DNS server(s) in use
    -h                     show this message
EOF
exit
}

log_menu () {

logresponse=""
choice=""

  echo "$div"
  echo "" 
  echo "${G}***LOGGING MAIN MENU***${N}"
  echo ""
  echo "$div"
  echo ""
  echo "${G}Do You Want To Take Logs?${N}"
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"
  read -r logresponse
if [ "$logresponse" = "y" ] || [ "$logresponse" = "Y" ] || [ "$logresponse" = "yes" ] || [ "$logresponse" = "Yes" ] || [ "$logresponse" = "YES" ]; then
upload_logs
else
echo -n "${R}Return to menu? < y | n > : ${N}"
read -r mchoice
 if [ "$mchoice" = "y" ]; then
menu
else
echo "${R} Thanks For Using Custom DNS Module By @JohnFawkes - @Telegram/@XDA ${N}"
sleep 1.5
clear && quit
 fi
fi
}

dns_remove () {

custom=$(echo $(get_file_value $DNSLOG "custom=") | sed 's|-.*||')
custom2=$(echo $(get_file_value $DNSLOG "custom2=") | sed 's|-.*||')

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
  sed -i "/nameserver\ "$custom"/d" $MODPATH/system/etc/resolv.conf
  if [ "$custom2" ]; then
    sed -i "/nameserver\ "$custom2"/d" $MODPATH/system/etc/resolv.conf
  fi
fi
echo -n "${R}Return to menu? < y | n > : ${N}"
read -r mchoice
if [ "$mchoice" = "y" ]; then
menu
else
echo "${R} Thanks For Using Custom DNS Module By @JohnFawkes - @Telegram/@XDA ${N}"
sleep 1.5
clear && quit
fi
}

re_dns_menu () {

response=""
choice=""

  echo "$div"
  echo ""
  echo "${G}***REMOVE CUSTOM DNS MENU***${N}"
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
  echo ""
  echo -e "${W}R)${N} ${B}Return to Main Menu${N}"
  echo ""
  echo -e "${W}Q)${N} ${B}Quit${N}"
  echo "$div"
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"

  read -r choice
 
  case $choice in
  r|R) echo "${B}Return to Main Menu Selected... ${N}"
  sleep 1
  clear
  menu
  ;;
  q|Q) echo " ${R}Quiting... ${N}"
  sleep 1
  clear
  quit
  ;;
  *) echo "${Y}item not available! Try Again${N}"
  sleep 1.5
  clear
  ;;
  esac
fi
}

dns_menu () {

custom=""
custom2=""
choice=""

  echo "$div"
  echo ""
  echo "${G}***CUSTOM DNS MENU***${N}"
  echo ""
  echo "$div"
  echo ""
  echo -n "${G}Please Enter Your Custom DNS${N}" 
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"
  echo ""
  read -r custom
 if [ -n $custom ]; then
touch $DNSLOG
set_perm $DNSLOG 0 0 0777
truncate -s 0 $DNSLOG
echo "custom=$custom" >> $DNSLOG 2>&1
setprop net.eth0.dns1 $custom
setprop net.dns1 $custom
setprop net.ppp0.dns1 $custom
setprop net.rmnet0.dns1 $custom
setprop net.rmnet1.dns1 $custom
setprop net.pdpbr1.dns1 $custom
echo "iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination $custom:53" >> $DNSSERV 2>&1
echo "iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to-destination $custom:53" >> $DNSSERV 2>&1
 fi
  echo ""
  echo -n "${G} Would You Like to Enter a Second DNS?${N}"
  echo ""
  echo -n "${R} [CHOOSE] :   ${N}"
  echo ""
  read -r choice
  echo ""
if [ "$choice" = "y" ] || [ "$choice" = "Y" ] || [ "$choice" = "yes" ] || [ "$choice" = "Yes" ] || [ "$choice" = "YES" ]; then
  echo -n "${G} Please Enter Your Custom DNS2${N}"
  echo ""
  echo -n "${R} [CHOOSE]  :  ${N}"
  echo ""
  read -r custom2
  if [ -n $custom2 ]; then
echo "custom2=$custom2" >> $DNSLOG 2>&1
setprop net.eth0.dns2 $custom2
setprop net.dns2 $custom2
setprop net.ppp0.dns2 $custom2
setprop net.rmnet0.dns2 $custom2
setprop net.rmnet1.dns2 $custom2
setprop net.pdpbr1.dns2 $custom2
echo "iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination $custom2:53" >> $DNSSERV 2>&1 
echo "iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to-destination $custom2:53" >> $DNSSERV 2>&1
  fi
   if [ -f /system/etc/resolv.conf ]; then
mkdir -p $MODPATH/system/etc
cp -f /system/etc/resolv.conf $MODPATH/system/etc
printf "nameserver $custom\nnameserver $custom2" >> $MODPATH/system/etc/resolv.conf
chmod 644 $MODPATH/system/etc/resolv.conf
   fi
else
echo -n "${R}Return to menu? < y | n > : ${N}"
read -r mchoice
 if [ "$mchoice" = "y" ]; then
menu
 else
echo "${R} Thanks For Using Custom DNS Module By @JohnFawkes - @Telegram/@XDA ${N}"
sleep 1.5
clear && quit
 fi
fi
} 

menu () {
  
choice=""
custom=$(echo $(get_file_value $DNSLOG "custom=") | sed 's|-.*||')
custom2=$(echo $(get_file_value $DNSLOG "custom2=") | sed 's|-.*||')

while [ "$choice" != "q" ]
  do  	
  mod_head
  echo "$div"
  echo "${G}***DNS MAIN MENU***${N}"
  echo "$div"
  echo ""
  echo "$div"
  if [ "$custom" ]; then
  echo -e "${W}Your Custom DNS is :${N} ${R}$custom${N}"
  fi
  if [ "$custom2" ]; then
  echo -e "${W}Your Second Custom DNS is :${N} ${R}$custom2${N}"
  fi
  echo "$div"
  echo "${G}Please make a Selection${N}"
  echo ""
  echo -e "${W}D)${N} ${B}Enter Custom DNS${N}"
  echo ""
  echo -e "${W}R)${N} ${B}Remove Custom DNS${N}"
  echo ""
  echo -e "${W}Q)${N} ${B}Quit${N}"
  echo ""
  echo -e "${W}L)${N} ${B}Logs${N}"
  echo "$div"
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"

  read -r choice
 
  case $choice in
  d|D) echo "${G} Custom DNS Menu Selected... ${N}"
  sleep 1
  clear
  dns_menu
  ;;
  r|R) echo "${B} Remove Custom DNS Selected... ${N}"
  sleep 1
  clear
  re_dns_menu
  ;;
  q|Q) echo " ${R}Quiting... ${N}"
  sleep 1
  clear
  quit
  ;;
  l|L) echo "${R}Logs Selected...${N}"
  sleep 1
  clear
  log_menu
  ;;
  *) echo "${Y}item not available! Try Again${N}"
  sleep 1.5
  clear
  ;;
  esac
done
}

case $1 in
-r|-R) shift
  for i in "$@"; do
  dns_remove
  done
  exit;;
-l|-L) shift
  for i in "$@"; do
custom=$(echo $(get_file_value $DNSLOG "custom=") | sed 's|-.*||')
custom2=$(echo $(get_file_value $DNSLOG "custom2=") | sed 's|-.*||')
  if [ "$custom" ]; then
  echo -e "${W}Your Custom DNS is :${N} ${R}$custom${N}"
  elif [ "$custom2" ]; then
  echo -e "${W}Your Second Custom DNS is :${N} ${R}$custom2${N}"
  else
  echo -e "${R}NO CUSTOM DNS IN USE${N}"
  echo -e "${R}Please run 'su' then 'dns_switch' to use a custom DNS${N}"
  fi
  done
  exit;;
-h|--help) help_me;;
esac  

menu

quit $?


Options:
    -nc                    removes ANSI escape codes
    -r                     remove DNS
#    -c [DNS ADRESS]        add custom DNS
    -l                     list custom DNS server(s) in use
    -h                     show this message
EOF
exit
}