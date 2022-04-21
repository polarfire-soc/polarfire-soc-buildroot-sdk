HSS_SUPPORT ?= y
HSS_TARGET ?= aries-m100pfsevp
UBOOT_VERSION = 2020.10
linux_defconfig := aries_m100pfsevp_defconfig
linux_dtb := $(riscv_dtbdir)/aries/m100pfsevp-sdcard.dtb