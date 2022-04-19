DESCRIPTION = "Linux kernel for Radxa Zero"

LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

inherit kernel
require recipes-kernel/linux/linux-yocto.inc

SRC_URI = " \
	git://github.com/radxa/kernel.git;branch=linux-5.10.y-radxa-zero; \
"

SRCREV = "617a45dd0fce8a4e63693d62578ef720941f9784"
LINUX_VERSION = "5.10.69"

# Override local version in order to use the one generated by linux build system
# And not "yocto-standard"
LINUX_VERSION_EXTENSION = ""
PR = "r1"
PV = "${LINUX_VERSION}"

COMPATIBLE_MACHINE = "(s905y2)"

# We need mkimage for the overlays
DEPENDS += "u-boot-mkimage-radxa-native"

do_compile_append() {
	oe_runmake dtbs
}

do_deploy_append() {
	install -d ${DEPLOYDIR}/overlays
	install -m 644 ${B}/arch/arm64/boot/dts/amlogic/overlay/* ${DEPLOYDIR}/overlays
}
