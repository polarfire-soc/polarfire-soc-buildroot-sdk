HSS_SUPPORT ?= y
HSS_TARGET ?= aries-m100pfsevp
UBOOT_VERSION = 2020.10
linux_defconfig := mpfs_defconfig
linux_dtb := $(riscv_dtbdir)/microchip/mpfs-m100pfsevp-sdcard.dtb