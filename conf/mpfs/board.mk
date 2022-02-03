FSBL_SUPPORT ?= y
OSBI_SUPPORT ?= y
UBOOT_VERSION = 2020.10
linux_defconfig := mpfs_devkit_defconfig
linux_dtb := $(riscv_dtbdir)/sifive/hifive-unleashed-a00.dtb
