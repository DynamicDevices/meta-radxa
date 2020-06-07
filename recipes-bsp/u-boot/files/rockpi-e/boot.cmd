# DO NOT EDIT THIS FILE
#
# Please edit /boot/uEnv.txt to set supported parameters
#

setenv load_addr "0x05000000"
#setenv load_addr "0x39000000"
setenv overlay_error "false"
# default values
setenv overlay_prefix "rockchip"
setenv rootdev "/dev/mmcblk0p5"
setenv verbosity "1"
setenv console " "
setenv rootfstype "ext4"
setenv docker_optimizations "on"

echo "Boot script loaded from ${devtype} ${devnum}"

if test -e ${devtype} ${devnum} ${prefix}uEnv.txt; then
	load ${devtype} ${devnum} ${load_addr} ${prefix}uEnv.txt
	env import -t ${load_addr} ${filesize}
fi

# get PARTUUID of first partition on SD/eMMC the boot script was loaded from
if test "${devtype}" = "mmc"; then part uuid mmc ${devnum}:1 partuuid; fi

setenv bootargs "root=UUID=${rootuuid} rootwait rw rootfstype=${rootfstype} console=tty1 console=${console} panic=10 consoleblank=0 loglevel=${verbosity} ${extraargs} ${extraboardargs}"

if test "${docker_optimizations}" = "on"; then setenv bootargs "${bootargs} cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1"; fi

load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${kernelimg}

load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}${fdtfile}
fdt addr ${fdt_addr_r}
fdt resize 65536
for overlay_file in ${overlays}; do
	if load ${devtype} ${devnum} ${load_addr} ${prefix}overlays/${overlay_file}.dtbo; then
		echo "Applying kernel provided DT overlay ${overlay_file}.dtbo"
		fdt apply ${load_addr} || setenv overlay_error "true"
	fi
done
for overlay_file in ${user_overlays}; do
	if load ${devtype} ${devnum} ${load_addr} ${prefix}overlay-user/${overlay_file}.dtbo; then
		echo "Applying user provided DT overlay ${overlay_file}.dtbo"
		fdt apply ${load_addr} || setenv overlay_error "true"
	fi
done
if test "${overlay_error}" = "true"; then
	echo "Error applying DT overlays, restoring original DT"
	load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}${fdtfile}
else
	if load ${devtype} ${devnum} ${load_addr} ${prefix}overlays/${overlay_prefix}-fixup.scr; then
		echo "Applying kernel provided DT fixup script (${overlay_prefix}-fixup.scr)"
		source ${load_addr}
	fi
	if test -e ${devtype} ${devnum} ${prefix}overlay-user/fixup.scr; then
		load ${devtype} ${devnum} ${load_addr} ${prefix}overlay-user/fixup.scr
		echo "Applying user provided fixup script (overlay-user/fixup.scr)"
		source ${load_addr}
	fi
fi
bootm ${kernel_addr_r} - ${fdt_addr_r}
# Recompile with:
# mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
