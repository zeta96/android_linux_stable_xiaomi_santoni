# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Luuvy kernel from Zamrud Khatulistiwa
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=santoni
device.name2=Xiaomi
device.name3=Redmi 4X
supported.versions=9, 9.0, 8.1, 8
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;


## AnyKernel install
dump_boot;

# begin ramdisk changes

# fstab.qcom
if [ -f /fstab.qcom ]; then
insert_line fstab.qcom "data        f2fs" before "data        ext4" "/dev/block/bootdevice/by-name/userdata     /data        f2fs    nosuid,nodev,noatime,inline_xattr,data_flush      wait,check,encryptable=footer,formattable,length=-16384";
insert_line fstab.qcom "cache        f2fs" after "data        ext4" "/dev/block/bootdevice/by-name/cache     /cache        f2fs    nosuid,nodev,noatime,inline_xattr,flush_merge,data_flush wait,formattable,check";
fi;

#Spectrum
if [ -e init.qcom.rc ]; then
backup_file init.qcom.rc;
insert_line init.qcom.rc "init.spectrum.rc" before "import init.qcom.usb.rc" "import /init.spectrum.rc";
else
backup_file init.rc;
insert_line init.rc "init.spectrum.rc" before "import /init.usb.rc" "import /init.spectrum.rc";
fi;

# If the kernel image and dtbs are separated in the zip
decompressed_image=/tmp/anykernel/kernel/Image
compressed_image=$decompressed_image.gz
if [ -f $compressed_image ]; then
  # Hexpatch the kernel if Magisk is installed ('skip_initramfs' -> 'want_initramfs')
  if [ -d $ramdisk/.backup ]; then
    ui_print " "; ui_print "Magisk detected! Patching kernel so reflashing Magisk is not necessary...";
    $bin/magiskboot --decompress $compressed_image $decompressed_image;
    $bin/magiskboot --hexpatch $decompressed_image 736B69705F696E697472616D667300 77616E745F696E697472616D667300;
    $bin/magiskboot --compress=gzip $decompressed_image $compressed_image;
  fi;

  # Concatenate all of the dtbs to the kernel
  cat $compressed_image /tmp/anykernel/dtbs/*.dtb > /tmp/anykernel/Image.gz-dtb;
fi;

# fix selinux denials for /init.*.sh
$bin/magiskpolicy --load sepolicy --save $ramdisk/sepolicy \
  "allow init rootfs file execute_no_trans" \
  "allow init sysfs_devices_system_cpu file write" \
  "allow init sysfs_msms_perf file write" \
  "allow init proc file { open write }" \
  "allow init sysfs file" \
  "allow init sysfs_graphics file { open write }" \
  "allow toolbox toolbox capability sys_admin" \
  "allow toolbox property_socket sock_file write" \
  "allow toolbox default_prop property_service set" \
  "allow toolbox init unix_stream_socket connectto" \
  "allow toolbox init fifo_file { getattr write }" && \
  { cat "$ramdisk/sepolicy" > sepolicy; }
  
# end ramdisk changes

write_boot;

## end install
