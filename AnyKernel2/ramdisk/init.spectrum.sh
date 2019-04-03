#!/system/bin/sh
# SPECTRUM KERNEL MANAGER
# Profile initialization script by nathanchance

# If there is not a persist value, we need to set one
if [ ! -f /data/property/persist.spectrum.profile ]; then
    setprop persist.spectrum.profile 0
fi

#zram based of ram########################
if [ $MEM_ALL -gt 3000000000 ]; then
	ZRAM_SIZE=0;
elif [ $MEM_ALL -lt 2900000000 ]; then
	ZRAM_SIZE=1GB;
else
	ZRAM_SIZE=512MB;
fi;

if [ -e /dev/block/zram0 ]; then
	if [ $MEM_ALL -gt 3000000000 ]; then
		$BB swapoff /dev/block/zram0 >/dev/null 2>&1;
		echo "1" > /sys/block/zram0/reset;
	else
		$BB swapoff /dev/block/zram0 >/dev/null 2>&1;
		echo "1" > /sys/block/zram0/reset;
		echo "lz4" > /sys/block/zram0/comp_algorithm;
		echo $ZRAM_SIZE > /sys/block/zram0/disksize;
		$BB mkswap /dev/block/zram0 >/dev/null;
		$BB swapon /dev/block/zram0;
	fi;
fi;
#################zram#########################
