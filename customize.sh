ui_print " "

# info
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`
ui_print " ID=$MODID"
ui_print " Version=$MODVER"
ui_print " VersionCode=$MODVERCODE"
ui_print " MagiskVersion=$MAGISK_VER"
ui_print " MagiskVersionCode=$MAGISK_VER_CODE"
ui_print " "

# sdk
NUM=29
if [ "$API" -lt $NUM ]; then
  ui_print "! Unsupported SDK $API. You have to upgrade your"
  ui_print "  Android version at least SDK API $NUM to use this module."
  abort
else
  ui_print "- SDK $API"
  ui_print " "
fi

# bit
if [ "$IS64BIT" == true ]; then
  ui_print "- 64 bit"
  ui_print " "
  if getprop | grep -Eq "se.dolby\]: \[1"; then
    ui_print "- Activating Dolby Atmos..."
    DOLBY=true
    MODNAME2='Sound Enhancement Xperia 10 and Dolby Atmos Xperia 1 II'
    sed -i "s/$MODNAME/$MODNAME2/g" $MODPATH/module.prop
    MODNAME=$MODNAME2
    ui_print " "
  fi
else
  ui_print "- 32 bit"
  rm -rf `find $MODPATH/system -type d -name *64`
  DOLBY=false
  if getprop | grep -Eq "se.dolby\]: \[1"; then
    ui_print "  ! Unsupported Dolby Atmos."
  fi
  ui_print " "
fi

# sepolicy.rule
if [ "$BOOTMODE" != true ]; then
  mount -o rw -t auto /dev/block/bootdevice/by-name/persist /persist
  mount -o rw -t auto /dev/block/bootdevice/by-name/metadata /metadata
fi
FILE=$MODPATH/sepolicy.sh
DES=$MODPATH/sepolicy.rule
if [ -f $FILE ] && ! getprop | grep -Eq "sepolicy.sh\]: \[1"; then
  mv -f $FILE $DES
  sed -i 's/magiskpolicy --live "//g' $DES
  sed -i 's/"//g' $DES
fi

# .aml.sh
mv -f $MODPATH/aml.sh $MODPATH/.aml.sh

# function
conflict() {
for NAMES in $NAME; do
  DIR=/data/adb/modules_update/$NAMES
  if [ -f $DIR/uninstall.sh ]; then
    sh $DIR/uninstall.sh
  fi
  rm -rf $DIR
  DIR=/data/adb/modules/$NAMES
  rm -f $DIR/update
  touch $DIR/remove
  FILE=/data/adb/modules/$NAMES/uninstall.sh
  if [ -f $FILE ]; then
    sh $FILE
    rm -f $FILE
  fi
  rm -rf /metadata/magisk/$NAMES
  rm -rf /mnt/vendor/persist/magisk/$NAMES
  rm -rf /persist/magisk/$NAMES
  rm -rf /data/unencrypted/magisk/$NAMES
  rm -rf /cache/magisk/$NAMES
done
}

# mod ui
if getprop | grep -Eq "mod.ui\]: \[1"; then
  APP=SoundEnhancement
  FILE=/sdcard/$APP.apk
  DIR=`find $MODPATH/system -type d -name $APP`
  ui_print "- Using modified UI apk..."
  if [ -f $FILE ]; then
    cp -f $FILE $DIR
    chmod 0644 $DIR/$APP.apk
    ui_print "  Applied"
  else
    ui_print "  ! There is no $FILE file."
    ui_print "    Please place the apk to your internal storage first"
    ui_print "    and reflash!"
  fi
  ui_print " "
fi

# cleaning
ui_print "- Cleaning..."
PKG="com.sonyericsson.soundenhancement
     com.reiryuki.soundenhancement.launcher
     com.sonymobile.audioutil"
for PKGS in $PKG; do
  if [ "$BOOTMODE" == true ]; then
    UNINSTALL=`pm uninstall $PKGS`
  fi
done
rm -f $MODPATH/LICENSE
rm -rf $MODPATH/unused
rm -rf /metadata/magisk/$MODID
rm -rf /mnt/vendor/persist/magisk/$MODID
rm -rf /persist/magisk/$MODID
rm -rf /data/unencrypted/magisk/$MODID
rm -rf /cache/magisk/$MODID
if [ $DOLBY == true ]; then
  PKG2="com.dolby.daxappui com.dolby.daxservice"
  for PKG2S in $PKG2; do
    if [ "$BOOTMODE" == true ]; then
      UNINSTALL=`pm uninstall $PKG2S`
    fi
  done
  rm -f /data/vendor/dolby/dax_sqlite3.db
  NAME="dolbyatmos
          DolbyAudio
          DolbyAtmos
          MotoDolby
          dsplus
          Dolby"
  conflict
fi
ui_print " "

# function
cleanup() {
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
DIR=/data/adb/modules_update/$MODID
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
}

# cleanup
DIR=/data/adb/modules/$MODID
FILE=$DIR/module.prop
if getprop | grep -Eq "se.cleanup\]: \[1"; then
  ui_print "- Cleaning-up $MODID data..."
  cleanup
  ui_print " "
elif [ -d $DIR ] && ! grep -Eq "$MODNAME" $FILE; then
  ui_print "- Different version detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# function
permissive() {
SELINUX=`getenforce`
if [ "$SELINUX" == Enforcing ]; then
  setenforce 0
  SELINUX=`getenforce`
  if [ "$SELINUX" == Enforcing ]; then
    ui_print "  ! Unsupported Dolby Atmos."
    ui_print "  ! Your device can't be turned to Permissive state."
    DOLBY=false
  fi
  setenforce 1
fi
sed -i '1i\
SELINUX=`getenforce`\
if [ "$SELINUX" == Enforcing ]; then\
  setenforce 0\
fi\' $MODPATH/post-fs-data.sh
}
backup() {
if [ ! -f $FILE.orig ] && [ ! -f $FILE.bak ]; then
  cp -f $FILE $FILE.orig
fi
}
patch_manifest() {
if [ -f $FILE ]; then
  backup
  ui_print "- Patching"
  ui_print "  $FILE"
  ui_print "  directly..."
  sed -i '/<manifest/a\
    <hal format="hidl">\
        <name>vendor.dolby.hardware.dms</name>\
        <transport>hwbinder</transport>\
        <version>1.0</version>\
        <interface>\
            <name>IDms</name>\
            <instance>default</instance>\
        </interface>\
        <fqname>@1.0::IDms/default</fqname>\
    </hal>' $FILE
  ui_print " "
fi
}
patch_hwservice() {
if [ -f $FILE ]; then
  backup
  ui_print "- Patching"
  ui_print "  $FILE"
  ui_print "  directly..."
  sed -i '1i\
vendor.dolby.hardware.dms::IDms u:object_r:hal_dms_hwservice:s0' $FILE
  ui_print " "
fi
}
patching_failed() {
ui_print "! Patching failed. This ROM is Read-Only."
ui_print "  Will be using systemless manifest.xml patch."
ui_print "  On some ROMs, it's buggy or even makes bootloop"
ui_print "  because not allowed to restart hwservicemanager."
ui_print " "
}

# permissive
if getprop | grep -Eq "permissive.mode\]: \[1"; then
  ui_print "- Using permissive method"
  rm -f $MODPATH/sepolicy.rule
  permissive
  ui_print " "
elif getprop | grep -Eq "permissive.mode\]: \[2"; then
  ui_print "- Using both permissive and SE policy patch"
  permissive
  ui_print " "
fi

# magisk
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`find /dev -mindepth 2 -maxdepth 2 -type d -name .magisk`
fi

# remount
if [ $DOLBY == true ]; then
  mount -o rw,remount $MAGISKTMP/mirror/system
  mount -o rw,remount $MAGISKTMP/mirror/system_root
  mount -o rw,remount $MAGISKTMP/mirror/system_ext
  mount -o rw,remount $MAGISKTMP/mirror/vendor
  mount -o rw,remount /system
  mount -o rw,remount /
  mount -o rw,remount /system_root
  mount -o rw,remount /system_ext
  mount -o rw,remount /vendor
fi

# patch manifest.xml
if [ $DOLBY == true ]; then
  CHECK=@1.0::IDms/default
  DIR="$MAGISKTMP/mirror/*/etc/vintf
        /*/etc/vintf
        /system/*/etc/vintf"
  if ! grep -rEq "$CHECK" $DIR\
  && ! getprop | grep -Eq "se.skip.vendor\]: \[1"; then
    FILE=$MAGISKTMP/mirror/vendor/etc/vintf/manifest.xml
    patch_manifest
  fi
  if ! grep -rEq "$CHECK" $DIR\
  && ! getprop | grep -Eq "se.skip.system\]: \[1"; then
    FILE=$MAGISKTMP/mirror/system/etc/vintf/manifest.xml
    patch_manifest
  fi
  if ! grep -rEq "$CHECK" $DIR\
  && ! getprop | grep -Eq "se.skip.system_ext\]: \[1"; then
    FILE=$MAGISKTMP/mirror/system_ext/etc/vintf/manifest.xml
    patch_manifest
  fi
  if ! grep -rEq "$CHECK" $DIR\
  && ! getprop | grep -Eq "se.skip.vendor\]: \[1"; then
    FILE=/vendor/etc/vintf/manifest.xml
    patch_manifest
  fi
  if ! grep -rEq "$CHECK" $DIR\
  && ! getprop | grep -Eq "se.skip.system\]: \[1"; then
    FILE=/system/etc/vintf/manifest.xml
    patch_manifest
  fi
  if ! grep -rEq "$CHECK" $DIR\
  && ! getprop | grep -Eq "se.skip.system_ext\]: \[1"; then
    FILE=/system/system_ext/etc/vintf/manifest.xml
    patch_manifest
  fi
  if ! grep -rEq "$CHECK" $DIR\; then
    patching_failed
  fi
fi

# patch hwservice contexts
if [ $DOLBY == true ]; then
  CHECK=u:object_r:hal_dms_hwservice:s0
  CHECK2=u:object_r:default_android_hwservice:s0
  FILE="$MAGISKTMP/mirror/*/etc/selinux/*_hwservice_contexts
        /*/etc/selinux/*_hwservice_contexts
        /system/*/etc/selinux/*_hwservice_contexts"
  if ! grep -Eq "$CHECK" $FILE\
  && ! grep -Eq "$CHECK2" $FILE\
  && ! getprop | grep -Eq "se.skip.vendor\]: \[1"; then
    FILE=$MAGISKTMP/mirror/vendor/etc/selinux/vendor_hwservice_contexts
    patch_hwservice
  fi
  if ! grep -Eq "$CHECK" $FILE\
  && ! grep -Eq "$CHECK2" $FILE\
  && ! getprop | grep -Eq "se.skip.system\]: \[1"; then
    FILE=$MAGISKTMP/mirror/system/etc/selinux/plat_hwservice_contexts
    patch_hwservice
  fi
  if ! grep -Eq "$CHECK" $FILE\
  && ! grep -Eq "$CHECK2" $FILE\
  && ! getprop | grep -Eq "se.skip.system_ext\]: \[1"; then
    FILE=$MAGISKTMP/mirror/system_ext/etc/selinux/system_ext_hwservice_contexts
    patch_hwservice
  fi
  if ! grep -Eq "$CHECK" $FILE\
  && ! grep -Eq "$CHECK2" $FILE\
  && ! getprop | grep -Eq "se.skip.vendor\]: \[1"; then
    FILE=/vendor/etc/selinux/vendor_hwservice_contexts
    patch_hwservice
  fi
  if ! grep -Eq "$CHECK" $FILE\
  && ! grep -Eq "$CHECK2" $FILE\
  && ! getprop | grep -Eq "se.skip.system\]: \[1"; then
    FILE=/system/etc/selinux/plat_hwservice_contexts
    patch_hwservice
  fi
  if ! grep -Eq "$CHECK" $FILE\
  && ! grep -Eq "$CHECK2" $FILE\
  && ! getprop | grep -Eq "se.skip.system_ext\]: \[1"; then
    FILE=/system/system_ext/etc/selinux/system_ext_hwservice_contexts
    patch_hwservice
  fi
  #if ! grep -Eq "$CHECK" $FILE\
  #&& ! grep -Eq "$CHECK2" $FILE; then
  #  patching_failed
  #fi
fi

# remount
if [ "$BOOTMODE" == true ] && [ $DOLBY == true ]; then
  mount -o ro,remount $MAGISKTMP/mirror/system
  mount -o ro,remount $MAGISKTMP/mirror/system_root
  mount -o ro,remount $MAGISKTMP/mirror/system_ext
  mount -o ro,remount $MAGISKTMP/mirror/vendor
  mount -o ro,remount /system
  mount -o ro,remount /
  mount -o ro,remount /system_root
  mount -o ro,remount /system_ext
  mount -o ro,remount /vendor
fi

# dolby
if [ $DOLBY == true ]; then
  sed -i 's/#d//g' $MODPATH/.aml.sh
  sed -i 's/#d//g' $MODPATH/*.sh
  cp -rf $MODPATH/systemdolby/* $MODPATH/system
else
  MODNAME2='Sound Enhancement Sony Xperia 10'
  sed -i "s/$MODNAME/$MODNAME2/g" $MODPATH/module.prop
fi
rm -rf $MODPATH/systemdolby

# mod ui
if [ $DOLBY == true ] && getprop | grep -Eq "mod.ui\]: \[1"; then
  APP=DaxUI
  FILE=/sdcard/$APP.apk
  DIR=`find $MODPATH/system -type d -name $APP`
  ui_print "- Using modified Dolby UI apk..."
  if [ -f $FILE ]; then
    cp -f $FILE $DIR
    chmod 0644 $DIR/$APP.apk
    ui_print "  Applied"
  else
    ui_print "  ! There is no $FILE file."
    ui_print "    Please place the apk to your internal storage first"
    ui_print "    and reflash!"
  fi
  ui_print " "
fi

# cleaning
APP="`ls $MODPATH/system/priv-app` `ls $MODPATH/system/app`"
for APPS in $APP; do
  rm -f `find /data/dalvik-cache /data/resource-cache -type f -name *$APPS*.apk`
done

# power save
PROP=`getprop power.save`
FILE=$MODPATH/system/etc/sysconfig/*
if [ "$PROP" == 1 ]; then
  ui_print "- $MODNAME will not be allowed in power save."
  ui_print "  It may save your battery but decreasing $MODNAME performance."
  for PKGS in $PKG; do
    sed -i "s/<allow-in-power-save package=\"$PKGS\"\/>//g" $FILE
    sed -i "s/<allow-in-power-save package=\"$PKGS\" \/>//g" $FILE
  done
  if [ $DOLBY == true ]; then
    for PKGS2 in $PKG2; do
      sed -i "s/<allow-in-power-save package=\"$PKGS2\"\/>//g" $FILE
      sed -i "s/<allow-in-power-save package=\"$PKGS2\" \/>//g" $FILE
    done
  fi
  ui_print " "
fi

# function
hide_oat() {
for APPS in $APP; do
  mkdir -p `find $MODPATH/system -type d -name $APPS`/oat
  touch `find $MODPATH/system -type d -name $APPS`/oat/.replace
done
}
replace_app() {
if [ -d $DIR ]; then
  mkdir -p $MODDIR
  touch $MODDIR/.replace
fi
}
hide_app() {
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/system/app/$APPS
else
  DIR=/system/app/$APPS
fi
MODDIR=$MODPATH/system/app/$APPS
replace_app
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/system/priv-app/$APPS
else
  DIR=/system/priv-app/$APPS
fi
MODDIR=$MODPATH/system/priv-app/$APPS
replace_app
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/product/app/$APPS
else
  DIR=/product/app/$APPS
fi
MODDIR=$MODPATH/system/product/app/$APPS
replace_app
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/product/priv-app/$APPS
else
  DIR=/product/priv-app/$APPS
fi
MODDIR=$MODPATH/system/product/priv-app/$APPS
replace_app
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/product/preinstall/$APPS
else
  DIR=/product/preinstall/$APPS
fi
MODDIR=$MODPATH/system/product/preinstall/$APPS
replace_app
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/system_ext/app/$APPS
else
  DIR=/system/system_ext/app/$APPS
fi
MODDIR=$MODPATH/system/system_ext/app/$APPS
replace_app
if [ "$BOOTMODE" == true ]; then
  DIR=$MAGISKTMP/mirror/system_ext/priv-app/$APPS
else
  DIR=/system/system_ext/priv-app/$APPS
fi
MODDIR=$MODPATH/system/system_ext/priv-app/$APPS
replace_app
}
check_app() {
if [ "$BOOTMODE" == true ]; then
  for APPS in $APP; do
    FILE=`find $MAGISKTMP/mirror/system_root/system\
               $MAGISKTMP/mirror/system_root/product\
               $MAGISKTMP/mirror/system_root/system_ext\
               $MAGISKTMP/mirror/system\
               $MAGISKTMP/mirror/product\
               $MAGISKTMP/mirror/system_ext -type f -name $APPS.apk`
    if [ "$FILE" ]; then
      ui_print "  Checking $APPS.apk"
      ui_print "  Please wait..."
      if grep -Eq $UUID $FILE; then
        ui_print "  Your $APPS.apk will be hidden"
        hide_app
      fi
    fi
  done
fi
}
detect_soundfx() {
if [ "$BOOTMODE" == true ]; then
  if dumpsys media.audio_flinger | grep -Eq $UUID; then
    ui_print "- $NAME is detected"
    ui_print "  It may conflicting with this module"
    ui_print "  Read Github Troubleshootings to disable it"
    ui_print " "
  fi
fi
}

# hide
hide_oat
if [ $DOLBY == true ]; then
  APP="MotoDolbyV3 OPSoundTuner DolbyAtmos MusicFX AudioFX"
  for APPS in $APP; do
    hide_app
  done
fi
if getprop | grep -Eq "disable.dirac\]: \[1" || getprop | grep -Eq "disable.misoundfx\]: \[1"; then
  APP=MiSound
  for APPS in $APP; do
    hide_app
  done
fi

# dirac
FILE=$MODPATH/.aml.sh
APP="XiaomiParts
     ZenfoneParts
     ZenParts
     GalaxyParts
     KharaMeParts"
NAME='dirac soundfx'
UUID=e069d9e0-8329-11df-9168-0002a5d5c51b
if getprop | grep -Eq "disable.dirac\]: \[1"; then
  ui_print "- $NAME will be disabled"
  sed -i 's/#2//g' $FILE
  check_app
  ui_print " "
else
  detect_soundfx
fi

# misoundfx
FILE=$MODPATH/.aml.sh
NAME=misoundfx
UUID=5b8e36a5-144a-4c38-b1d7-0002a5d5c51b
if getprop | grep -Eq "disable.misoundfx\]: \[1"; then
  ui_print "- $NAME will be disabled"
  sed -i 's/#3//g' $FILE
  check_app
  ui_print " "
else
  detect_soundfx
fi

# stream mode
FILE=$MODPATH/.aml.sh
PROP=`getprop stream.mode`
if [ $DOLBY == true ]; then
  if echo "$PROP" | grep -Eq m; then
    ui_print "- Activating Dolby music stream..."
    sed -i 's/#m//g' $FILE
    ui_print " "
  else
    ui_print "- Sound Enhancement post process effect is disabled"
    ui_print "  for Dolby Atmos global effect"
    sed -i 's/persist.sony.effect.dolby_atmos false/persist.sony.effect.dolby_atmos true/g' $MODPATH/service.sh
    sed -i 's/persist.sony.effect.ahc true/persist.sony.effect.ahc false/g' $MODPATH/service.sh
    ui_print " "
  fi
  if echo "$PROP" | grep -Eq r; then
    ui_print "- Activating Dolby ring stream..."
    sed -i 's/#r//g' $FILE
    ui_print " "
  fi
  if echo "$PROP" | grep -Eq a; then
    ui_print "- Activating Dolby alarm stream..."
    sed -i 's/#a//g' $FILE
    ui_print " "
  fi
  if echo "$PROP" | grep -Eq v; then
    ui_print "- Activating Dolby voice_call stream..."
    sed -i 's/#v//g' $FILE
    ui_print " "
  fi
  if echo "$PROP" | grep -Eq n; then
    ui_print "- Activating Dolby notification stream..."
    sed -i 's/#n//g' $FILE
    ui_print " "
  fi
fi
#if echo "$PROP" | grep -Eq c; then
if ! getprop | grep -Eq "se.znr\]: \[0"; then
  ui_print "- Activating Sony ZNR effect for mic and camcorder stream..."
  sed -i 's/#c//g' $FILE
  ui_print " "
fi

# settings
if [ $DOLBY == true ]; then
  FILE=$MODPATH/system/vendor/etc/dolby/dax-default.xml
  PROP=`getprop se.bass`
  if [ "$PROP" -gt 0 ]; then
    ui_print "- Enable bass enhancer for all profiles..."
    sed -i 's/bass-enhancer-enable value="false"/bass-enhancer-enable value="true"/g' $FILE
    ui_print "- Changing bass enhancer boost values to $PROP for all profiles..."
    ROW=`grep bass-enhancer-boost $FILE | sed 's/<bass-enhancer-boost value="0"\/>//p'`
    echo $ROW > $TMPDIR/test
    sed -i 's/<bass-enhancer-boost value="//g' $TMPDIR/test
    sed -i 's/"\/>//g' $TMPDIR/test
    ROW=`cat $TMPDIR/test`
    ui_print "  (Default values: $ROW)"
    for ROWS in $ROW; do
      sed -i "s/bass-enhancer-boost value=\"$ROWS\"/bass-enhancer-boost value=\"$PROP\"/g" $FILE
    done
  elif [ "$PROP" == true ]; then
    ui_print "- Enable bass enhancer for all profiles..."
    sed -i 's/bass-enhancer-enable value="false"/bass-enhancer-enable value="true"/g' $FILE
  elif [ "$PROP" == default ]; then
    ui_print "- Using default settings for bass enhancer"
  else
    ui_print "- Disable bass enhancer for all profiles..."
    sed -i 's/bass-enhancer-enable value="true"/bass-enhancer-enable value="false"/g' $FILE
  fi
  if getprop | grep -Eq "se.virtualizer\]: \[1"; then
    ui_print "- Enable virtualizer for all profiles..."
    sed -i 's/virtualizer-enable value="false"/virtualizer-enable value="true"/g' $FILE
  elif getprop | grep -Eq "se.virtualizer\]: \[0"; then
    ui_print "- Disable virtualizer for all profiles..."
    sed -i 's/virtualizer-enable value="true"/virtualizer-enable value="false"/g' $FILE
  fi
  if getprop | grep -Eq "se.volumeleveler\]: \[1"; then
    ui_print "- Using default volume leveler settings"
  elif getprop | grep -Eq "se.volumeleveler\]: \[2"; then
    ui_print "- Enable volume leveler for all profiles..."
    sed -i 's/volume-leveler-enable value="false"/volume-leveler-enable value="true"/g' $FILE
  else
    ui_print "- Disable volume leveler for all profiles..."
    sed -i 's/volume-leveler-enable value="true"/volume-leveler-enable value="false"/g' $FILE
  fi
  ui_print " "
fi

# check
NAME=libaudio-resampler.so
if [ "$BOOTMODE" == true ]; then
  FILE=$MAGISKTMP/mirror/system/lib/$NAME
  FILE2=$MAGISKTMP/mirror/system/lib64/$NAME
else
  FILE=/system/lib/$NAME
  FILE2=/system/lib64/$NAME
fi
if [ -f $FILE ] || [ -f $FILE2 ]; then
  rm -f `find $MODPATH -type f -name $NAME`
else
  ui_print "- Added $NAME"
  ui_print " "
fi

# function
file_check() {
  if [ "$BOOTMODE" == true ]; then
    FILE=$MAGISKTMP/mirror/vendor/lib/$NAME
    FILE2=$MAGISKTMP/mirror/vendor/lib64/$NAME
  else
    FILE=/vendor/lib/$NAME
    FILE2=/vendor/lib64/$NAME
  fi
  if [ -f $FILE ] || [ -f $FILE2 ]; then
    rm -f `find $MODPATH -type f -name $NAME`
  else
    ui_print "- Added $NAME"
    ui_print " "
  fi
}

# check
NAME=libAlacSwDec.so
file_check
NAME=libOmxAlacDec.so
file_check
NAME=libOmxAlacDecSw.so
file_check

# check
NAME=dsee_hx_state
if [ "$BOOTMODE" == true ]; then
  FILE=$MAGISKTMP/mirror/vendor/lib*/hw/audio.primary.*.so
else
  FILE=/vendor/lib*/hw/audio.primary.*.so
fi
if grep -Eq "$NAME" $FILE ; then
  ui_print "- Detected DSEEHX support in"
  ui_print "  $FILE"
  sed -i 's/ro.somc.dseehx.supported true/ro.somc.dseehx.supported false/g' $MODPATH/service.sh
  ui_print " "
fi

# audio rotation
PROP=`getprop audio.rotation`
FILE=$MODPATH/service.sh
if [ "$PROP" == 1 ]; then
  ui_print "- Activating ro.audio.monitorRotation=true"
  sed -i '1i\
resetprop ro.audio.monitorRotation true' $FILE
  ui_print " "
fi

# raw
PROP=`getprop disable.raw`
FILE=$MODPATH/.aml.sh
if [ "$PROP" == 0 ]; then
  ui_print "- Not disabling Ultra Low Latency playback (RAW)"
  ui_print " "
else
  sed -i 's/#u//g' $FILE
fi

# function
file_check_vendor() {
for NAMES in $NAME; do
  if [ "$BOOTMODE" == true ]; then
    FILE64=$MAGISKTMP/mirror/vendor/lib64/$NAMES
    FILE=$MAGISKTMP/mirror/vendor/lib/$NAMES
  else
    FILE64=/vendor/lib64/$NAMES
    FILE=/vendor/lib/$NAMES
  fi
  if [ -f $FILE64 ]; then
    ui_print "- Detected"
    ui_print "  $FILE64"
    rm -f $MODPATH/system/vendor/lib64/$NAMES
    ui_print " "
  fi
  if [ -f $FILE ]; then
    ui_print "- Detected"
    ui_print "  $FILE"
    rm -f $MODPATH/system/vendor/lib/$NAMES
    ui_print " "
  fi
done
}

# check
NAME="libstagefrightdolby.so
      libstagefright_soft_ddpdec.so
      libstagefright_soft_ac4dec.so"
if [ $DOLBY == true ]; then
  file_check_vendor
fi

# permission
ui_print "- Setting permission..."
chmod 0751 $MODPATH/system/bin
FILE=`find $MODPATH/system/bin $MODPATH/system/vendor/bin -type f`
for FILES in $FILE; do
  chmod 0755 $FILES
done
chmod 0751 $MODPATH/system/vendor/bin
chmod 0751 $MODPATH/system/vendor/bin/hw
chown -R 0.2000 $MODPATH/system/bin
DIR=`find $MODPATH/system/vendor -type d`
for DIRS in $DIR; do
  chown 0.2000 $DIRS
done
FILE=`find $MODPATH/system/vendor/bin -type f`
for FILES in $FILE; do
  chown 0.2000 $FILES
done
magiskpolicy "dontaudit { hal_dms_default_exec system_lib_file vendor_file vendor_configs_file } labeledfs filesystem associate"
magiskpolicy "allow     { hal_dms_default_exec system_lib_file vendor_file vendor_configs_file } labeledfs filesystem associate"
magiskpolicy "dontaudit init { system_lib_file vendor_file vendor_configs_file } dir relabelfrom"
magiskpolicy "allow     init { system_lib_file vendor_file vendor_configs_file } dir relabelfrom"
magiskpolicy "dontaudit init { hal_dms_default_exec system_lib_file vendor_file vendor_configs_file } file relabelfrom"
magiskpolicy "allow     init { hal_dms_default_exec system_lib_file vendor_file vendor_configs_file } file relabelfrom"
chcon -R u:object_r:system_lib_file:s0 $MODPATH/system/lib*
chcon -R u:object_r:vendor_file:s0 $MODPATH/system/vendor
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/etc
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/odm/etc
#chcon u:object_r:hal_dms_default_exec:s0 $FILE
ui_print " "

# vendor_overlay
if [ $DOLBY == true ]; then
  DIR=/product/vendor_overlay
  if [ -d $DIR ]; then
    ui_print "- Fixing $DIR mount..."
    cp -rf $DIR/*/* $MODPATH/system/vendor
    ui_print " "
  fi
fi

# uninstaller
NAME=DolbyUninstaller.zip
if [ $DOLBY == true ]; then
  ui_print "- Flash /sdcard/$NAME"
  ui_print "  via recovery if you got bootloop"
  cp -f $MODPATH/$NAME /sdcard
  ui_print " "
fi
rm -f $MODPATH/$NAME






