HSS_SUPPORT ?= y
HSS_TARGET ?= mpfs-icicle-kit-es
UBOOT_VERSION = 4b28e3e93ae339d7d29e6b0efc26777bfef714eb
linux_defconfig := mpfs_defconfig
linux_dtb := $(riscv_dtbdir)/microchip/mpfs-icicle-kit.dtb
