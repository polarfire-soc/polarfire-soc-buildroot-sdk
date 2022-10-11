HSS_SUPPORT ?= y
HSS_TARGET ?= polarberry
UBOOT_VERSION = 2021.04
linux_defconfig := mpfs_defconfig
linux_dtb := $(riscv_dtbdir)/microchip/mpfs-polarberry.dtb
