mkdir -p $UNITY$BINPATH
cp_ch -n $INSTALLER/custom/dns_switch.sh $UNITY$BINPATH/dns_switch
log_print "Using $BINPATH."
sed -i -e "s|<MAGISK>|$MAGISK|" -e "s|<BINPATH>|$BINPATH|" -e "s|<MODVERSION>|$(grep_prop versionCode $INSTALLER/module.prop)|" -e "s|<MODID>|$MODID|" -e "s|<CACHELOC>|$CACHELOC|" $UNITY$BINPATH/dns_switch >> $INSTLOG 2>&1
if $MAGISK; then
sed -i -e "s|<PROP>|/sbin/.core/img/dns_switch/system.prop|" -e "s|<MODPATH>|/sbin/.core/img/dns_switch|" -e "s|<MODPROP>|$(echo $MOD_VER)|" $UNITY$BINPATH/dns_switch >> $INSTLOG 2>&1
else
  sed -i -e "s|<PROP>|$PROP|" -e "s|<MODPROP>|$MOD_VER|" -e "s|<MODPATH>|\"\"|" $UNITY$BINPATH/dns_switch >> $INSTLOG 2>&1
fi
patch_script $UNITY$BINPATH/dns_switch >> $INSTLOG 2>&1
