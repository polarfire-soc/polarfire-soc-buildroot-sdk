HSS_SUPPORT ?= y
HSS_TARGET ?= mpfs-icicle-kit-es
AMP_SUPPORT ?= y
UBOOT_VERSION = 2022.01
linux_defconfig := mpfs_amp_defconfig
linux_dtb := $(riscv_dtbdir)/microchip/mpfs-icicle-kit-context-a.dtb
