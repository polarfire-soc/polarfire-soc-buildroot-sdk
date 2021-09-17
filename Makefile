ISA ?= rv64imafdc
ABI ?= lp64d

LIBERO_PATH ?= /usr/local/microsemi/Libero_v2021.1/
SC_PATH ?= /usr/local/microsemi/SoftConsole-v2021.1/
fpgenprog := $(LIBERO_PATH)/bin64/fpgenprog
num_threads = $(shell nproc --ignore=1)

srcdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
srcdir := $(srcdir:/=)
patchdir := $(CURDIR)/patches
confdir := $(srcdir)/conf
wrkdir := $(CURDIR)/work

# target icicle w/ emmc by default
DEVKIT ?= icicle-kit-es
ifeq "$(DEVKIT)" "icicle-kit-es-sd"
override DEVKIT = icicle-kit-es
endif

RISCV ?= $(CURDIR)/toolchain
PATH := $(RISCV)/bin:$(PATH)
GITID := $(shell git describe --dirty --always)

toolchain_srcdir := $(srcdir)/riscv-gnu-toolchain
toolchain_wrkdir := $(wrkdir)/riscv-gnu-toolchain
toolchain_dest := $(CURDIR)/toolchain
target := riscv64-unknown-linux-gnu
CROSS_COMPILE := $(RISCV)/bin/$(target)-
target_gdb := $(CROSS_COMPILE)gdb

buildroot_srcdir := $(srcdir)/buildroot
buildroot_initramfs_wrkdir := $(wrkdir)/buildroot_initramfs
buildroot_initramfs_tar := $(buildroot_initramfs_wrkdir)/images/rootfs.tar
buildroot_initramfs_config := $(confdir)/$(DEVKIT)/buildroot_initramfs_config
buildroot_initramfs_sysroot_stamp := $(wrkdir)/.buildroot_initramfs_sysroot
buildroot_initramfs_sysroot := $(wrkdir)/buildroot_initramfs_sysroot
buildroot_rootfs_wrkdir := $(wrkdir)/buildroot_rootfs
buildroot_rootfs_ext := $(buildroot_rootfs_wrkdir)/images/rootfs.ext4
buildroot_rootfs_config := $(confdir)/buildroot_rootfs_config

buildroot_patchdir := $(patchdir)/buildroot/
buildroot_patches := $(shell ls $(buildroot_patchdir)/*.patch)
buildroot_builddir := $(wrkdir)/buildroot_build
buildroot_builddir_stamp := $(wrkdir)/.buildroot_builddir

linux_srcdir := $(srcdir)/linux
linux_wrkdir := $(wrkdir)/linux
riscv_dtbdir := $(linux_wrkdir)/arch/riscv/boot/dts/

vmlinux := $(linux_wrkdir)/vmlinux
vmlinux_stripped := $(linux_wrkdir)/vmlinux-stripped
vmlinux_bin := $(wrkdir)/vmlinux.bin

kernel-modules-stamp := $(wrkdir)/.modules_stamp
kernel-modules-install-stamp := $(wrkdir)/.modules_install_stamp

flash_image := $(wrkdir)/$(DEVKIT)-$(GITID).gpt
vfat_image := $(wrkdir)/$(DEVKIT)-vfat.part
initramfs := $(wrkdir)/initramfs.cpio.gz
rootfs := $(wrkdir)/rootfs.bin
fit := $(wrkdir)/fitImage.fit

device_tree_blob := $(wrkdir)/riscvpc.dtb

fsbl_srcdir := $(srcdir)/fsbl
fsbl_wrkdir := $(wrkdir)/fsbl
fsbl_wrkdir_stamp := $(wrkdir)/.fsbl_wrkdir
fsbl_patchdir := $(patchdir)/fsbl/
libversion := $(fsbl_wrkdir)/lib/version.c
fsbl := $(wrkdir)/fsbl.bin

uboot_s := $(buildroot_initramfs_wrkdir)/images/u-boot.bin
uboot_s_cfg := $(confdir)/$(DEVKIT)/smode_defconfig
uboot_s_txt := $(confdir)/$(DEVKIT)/uEnv_s-mode.txt
uboot_s_scr := $(buildroot_initramfs_wrkdir)/images/boot.scr

opensbi_srcdir := $(srcdir)/opensbi
opensbi_wrkdir := $(wrkdir)/opensbi
opensbi := $(wrkdir)/fw_payload.bin

openocd_srcdir := $(srcdir)/riscv-openocd
openocd_wrkdir := $(wrkdir)/riscv-openocd
openocd := $(openocd_wrkdir)/src/openocd

payload_generator_url := https://github.com/polarfire-soc/hart-software-services/releases/download/2021.04/hss-payload-generator-0.99.16-linux-x86_64.tar.gz
payload_generator_tarball := $(srcdir)/br-dl-dir/payload_generator.tar.gz
# payload_generator_srcdir := $(srcdir)/hart-software-services/tools/hss-payload-generator
# payloadgen_wrkdir := $(wrkdir)/payload_generator
hss_payload_generator := $(wrkdir)/hss-payload-generator
hss_srcdir := $(srcdir)/hart-software-services
hss_uboot_payload_bin := $(wrkdir)/payload.bin
payload_config := $(confdir)/$(DEVKIT)/config.yaml

amp_example := $(buildroot_initramfs_wrkdir)/images/mpfs-rpmsg-remote.elf
amp_example_srcdir := $(srcdir)/polarfire-soc-examples/polarfire-soc-amp-examples/mpfs-rpmsg-freertos
amp_example_wrkdir := $(wrkdir)/amp/mpfs-rpmsg-freertos

ifeq "$(DEVKIT)" "mpfs"
FSBL_SUPPORT ?= y
OSBI_SUPPORT ?= y
UBOOT_VERSION = 2020.10
linux_defconfig := mpfs_devkit_defconfig
linux_dtb := $(riscv_dtbdir)/sifive/hifive-unleashed-a00.dtb
else ifeq "$(DEVKIT)" "icicle-kit-es-amp"
HSS_SUPPORT ?= y
HSS_TARGET ?= mpfs-icicle-kit-es
AMP_SUPPORT ?= y
UBOOT_VERSION = 2021.10
linux_defconfig := icicle_kit_amp_defconfig
linux_dtb := $(riscv_dtbdir)/microchip/microchip-mpfs-icicle-kit-context-a.dtb
else
HSS_SUPPORT ?= y
HSS_TARGET ?= mpfs-icicle-kit-es
UBOOT_VERSION = 2021.10
linux_defconfig := icicle_kit_defconfig
linux_dtb := $(riscv_dtbdir)/microchip/microchip-mpfs-icicle-kit.dtb
endif

bootloaders-$(FSBL_SUPPORT) += $(fsbl)
bootloaders-$(OSBI_SUPPORT) += $(opensbi)
bootloaders-$(HSS_SUPPORT) += $(hss_uboot_payload_bin)
bootloaders-$(AMP_SUPPORT) += $(amp_example)

all: $(fit) $(vfat_image) $(bootloaders-y)
	@echo
	@echo "GPT (for SPI flash or SDcard) and U-boot Image files have"
	@echo "been generated for an ISA of $(ISA) and an ABI of $(ABI)"
	@echo
	@echo $(fit)
	@echo $(flash_image)
	@echo
	@echo "Refer to the readme for instructions on how to format"
	@echo "an SD/eMMC with the image & boot Linux."

ifneq ($(RISCV),$(toolchain_dest))
$(CROSS_COMPILE)gcc:
	ifeq (,$(CROSS_COMPILE)gcc --version 2>/dev/null)
		$(error The RISCV environment variable was set, but is not pointing at a toolchain install tree)
else
$(CROSS_COMPILE)gcc: $(toolchain_srcdir)
	mkdir -p $(toolchain_wrkdir)
	mkdir -p $(toolchain_wrkdir)/header_workdir
	$(MAKE) -C $(linux_srcdir) O=$(toolchain_wrkdir)/header_workdir ARCH=riscv INSTALL_HDR_PATH=$(abspath $(toolchain_srcdir)/linux-headers) headers_install
	cd $(toolchain_wrkdir); $(toolchain_srcdir)/configure \
		--prefix=$(toolchain_dest) \
		--with-arch=$(ISA) \
		--with-abi=$(ABI) \
		--enable-linux
	$(MAKE) -C $(toolchain_wrkdir) -j$(num_threads)
	sed 's/^#define LINUX_VERSION_CODE.*/#define LINUX_VERSION_CODE 330752/' -i $(toolchain_dest)/sysroot/usr/include/linux/version.h
endif

$(buildroot_builddir_stamp): $(buildroot_srcdir) $(buildroot_patches)
	- rm -rf $(buildroot_builddir)
	mkdir -p $(buildroot_builddir) && cd $(buildroot_builddir) && cp $(buildroot_srcdir)/* . -r
	for file in $(buildroot_patches) ; do \
			cd $(buildroot_builddir) && patch -p1 < $${file} ; \
	done
	touch $@
	rm -rf $(buildroot_initramfs_wrkdir)
	mkdir -p $(buildroot_initramfs_wrkdir)
	rm -rf $(buildroot_rootfs_wrkdir)
	mkdir -p $(buildroot_rootfs_wrkdir)

$(buildroot_initramfs_wrkdir)/.config: $(buildroot_builddir_stamp) $(confdir)/initramfs.txt $(buildroot_rootfs_config) $(buildroot_initramfs_config) $(uboot_s_cfg) $(uboot_s_txt)
	cp $(buildroot_initramfs_config) $(buildroot_initramfs_wrkdir)/.config
	$(MAKE) -C $(buildroot_builddir) RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_initramfs_wrkdir) olddefconfig CROSS_COMPILE=$(CROSS_COMPILE) -j$(num_threads)

$(buildroot_initramfs_tar): $(buildroot_builddir_stamp) $(buildroot_initramfs_wrkdir)/.config $(CROSS_COMPILE)gcc $(buildroot_initramfs_config)
	$(MAKE) -C $(buildroot_builddir) RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_initramfs_wrkdir) -j$(num_threads) DEVKIT=$(DEVKIT)

$(buildroot_initramfs_sysroot_stamp): $(buildroot_initramfs_tar)
	mkdir -p $(buildroot_initramfs_sysroot)
	tar -xpf $< -C $(buildroot_initramfs_sysroot) --exclude ./dev --exclude ./usr/share/locale
	touch $@

.PHONY: buildroot_initramfs_menuconfig
buildroot_initramfs_menuconfig: $(buildroot_initramfs_wrkdir)/.config $(buildroot_builddir_stamp)
	$(MAKE) -C $(buildroot_builddir) O=$(buildroot_initramfs_wrkdir) menuconfig
	$(MAKE) -C $(buildroot_builddir) O=$(buildroot_initramfs_wrkdir) savedefconfig
	cp $(buildroot_initramfs_wrkdir)/defconfig conf/buildroot_initramfs_config

$(buildroot_rootfs_wrkdir)/.config: $(buildroot_builddir_stamp)
	cp $(buildroot_rootfs_config) $@
	$(MAKE) -C $(buildroot_builddir) RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_rootfs_wrkdir) olddefconfig

$(buildroot_rootfs_ext): $(buildroot_builddir_stamp) $(buildroot_rootfs_wrkdir)/.config $(CROSS_COMPILE)gcc $(buildroot_rootfs_config)
	$(MAKE) -C $(buildroot_builddir) RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_rootfs_wrkdir) -j$(num_threads)

.PHONY: buildroot_rootfs_menuconfig
buildroot_rootfs_menuconfig: $(buildroot_rootfs_wrkdir)/.config $(buildroot_builddir_stamp)
	$(MAKE) -C $(buildroot_builddir) O=$(buildroot_rootfs_wrkdir) menuconfig
	$(MAKE) -C $(buildroot_builddir) O=$(buildroot_rootfs_wrkdir) savedefconfig
	cp $(buildroot_rootfs_wrkdir)/defconfig conf/buildroot_rootfs_config

.PHONY: linux_cfg
cfg: $(linux_wrkdir)/.config
$(linux_wrkdir)/.config: $(linux_srcdir) $(CROSS_COMPILE)gcc
	mkdir -p $(dir $@)
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=riscv $(linux_defconfig)
ifeq (,$(filter rv%c,$(ISA)))
	sed 's/^.*CONFIG_RISCV_ISA_C.*$$/CONFIG_RISCV_ISA_C=n/' -i $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=riscv $(linux_defconfig)
endif
ifeq ($(ISA),$(filter rv32%,$(ISA)))
	sed 's/^.*CONFIG_ARCH_RV32I.*$$/CONFIG_ARCH_RV32I=y/' -i $@
	sed 's/^.*CONFIG_ARCH_RV64I.*$$/CONFIG_ARCH_RV64I=n/' -i $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=riscv rv32_defconfig
endif

$(initramfs).d: $(buildroot_initramfs_sysroot) $(kernel-modules-install-stamp)
	cd $(wrkdir) && $(linux_srcdir)/usr/gen_initramfs.sh -l $(confdir)/initramfs.txt $(buildroot_initramfs_sysroot) > $@

$(initramfs): $(buildroot_initramfs_sysroot) $(vmlinux) $(kernel-modules-install-stamp)
	cd $(linux_wrkdir) && \
		$(linux_srcdir)/usr/gen_initramfs.sh \
		-o $@ -u $(shell id -u) -g $(shell id -g) \
		$(confdir)/initramfs.txt \
		$(buildroot_initramfs_sysroot)

$(vmlinux): $(linux_wrkdir)/.config $(CROSS_COMPILE)gcc
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) \
		ARCH=riscv \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		PATH=$(PATH) \
		vmlinux -j$(num_threads)

$(vmlinux_stripped): $(vmlinux)
	PATH=$(PATH) $(target)-strip -o $@ $<

$(vmlinux_bin): $(vmlinux)
	PATH=$(PATH) $(CROSS_COMPILE)objcopy -O binary $< $@
	
.PHONY: kernel-modules kernel-modules-install
$(kernel-modules-stamp): $(linux_srcdir) $(vmlinux)
	$(MAKE) -C $< O=$(linux_wrkdir) \
		ARCH=riscv \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		PATH=$(PATH) \
		modules -j$(num_threads)
	touch $@

$(kernel-modules-install-stamp): $(linux_srcdir) $(buildroot_initramfs_sysroot) $(kernel-modules-stamp)
	rm -rf $(buildroot_initramfs_sysroot)/lib/modules/
	$(MAKE) -C $< O=$(linux_wrkdir) \
		ARCH=riscv \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		PATH=$(PATH) \
		modules_install \
		INSTALL_MOD_PATH=$(buildroot_initramfs_sysroot)
	touch $@
	
.PHONY: linux-menuconfig
linux-menuconfig: $(linux_wrkdir)/.config
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv menuconfig CROSS_COMPILE=$(CROSS_COMPILE)
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv savedefconfig CROSS_COMPILE=$(CROSS_COMPILE)
	cp $(dir $<)/defconfig $(linux_defconfig)

$(device_tree_blob): $(vmlinux)
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=riscv dtbs
	cp $(linux_dtb) $(device_tree_blob)

$(fit): $(uboot_s) $(vmlinux_bin) $(initramfs) $(device_tree_blob) $(confdir)/osbi-fit-image.its $(kernel-modules-install-stamp)
	PATH=$(PATH) $(buildroot_initramfs_wrkdir)/build/uboot-$(UBOOT_VERSION)/tools/mkimage -f $(confdir)/osbi-fit-image.its -A riscv -O linux -T flat_dt $@

$(libversion): $(fsbl_wrkdir_stamp)
	- rm -rf $(libversion)
	echo "const char *gitid = \"$(shell git describe --always --dirty)\";" > $(libversion)
	echo "const char *gitdate = \"$(shell git log -n 1 --date=short --format=format:"%ad.%h" HEAD)\";" >> $(libversion)
	echo "const char *gitversion = \"$(shell git rev-parse HEAD)\";" >> $(libversion)

$(fsbl_wrkdir_stamp): $(fsbl_srcdir) $(fsbl_patchdir)
	- rm -rf $(fsbl_wrkdir)
	mkdir $(fsbl_wrkdir) -p && cd $(fsbl_wrkdir) && cp $(fsbl_srcdir)/* . -r
	for file in $(fsbl_patchdir)/* ; do \
			cd $(fsbl_wrkdir) && patch -p1 < $${file} ; \
	done
	touch $@

$(fsbl): $(libversion) $(fsbl_wrkdir_stamp) $(device_tree_blob)
	rm -f $(fsbl_wrkdir)/fsbl/ux00_fsbl.dts
	cp -f $(wrkdir)/riscvpc.dtb $(fsbl_wrkdir)/fsbl/ux00_fsbl.dtb
	$(MAKE) -C $(fsbl_wrkdir) O=$(fsbl_wrkdir) CROSSCOMPILE=$(CROSS_COMPILE) all -j$(num_threads)
	cp $(fsbl_wrkdir)/fsbl.bin $(fsbl)
	
$(uboot_s): $(buildroot_initramfs_sysroot_stamp)

$(opensbi): $(uboot_s) $(CROSS_COMPILE)gcc 
	rm -rf $(opensbi_wrkdir)
	mkdir -p $(opensbi_wrkdir)
	mkdir -p $(dir $@)
	$(MAKE) -C $(opensbi_srcdir) O=$(opensbi_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) \
		PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=$(uboot_s)
	cp $(opensbi_wrkdir)/platform/sifive/fu540/firmware/fw_payload.bin $@

$(rootfs): $(buildroot_rootfs_ext)
	cp $< $@

$(buildroot_initramfs_sysroot): $(buildroot_initramfs_sysroot_stamp)

$(payload_generator_tarball): 
	mkdir -p  $(srcdir)/br-dl-dir/
	wget $(payload_generator_url) -O $(payload_generator_tarball) --show-progress

$(hss_payload_generator): $(payload_generator_tarball)
	tar -xzf $(payload_generator_tarball) -C $(wrkdir)

$(hss_uboot_payload_bin): $(uboot_s) $(hss_payload_generator) $(bootloaders-y)
	cd $(buildroot_initramfs_wrkdir)/images && $(hss_payload_generator) -c $(payload_config) -v $(hss_uboot_payload_bin)

.PHONY: buildroot_initramfs_sysroot vmlinux bbl fit flash_image initrd opensbi u-boot bootloaders dtbs
buildroot_initramfs_sysroot: $(buildroot_initramfs_sysroot)
vmlinux: $(vmlinux)
fit: $(fit)
initrd: $(initramfs)
u-boot: $(uboot_s)
flash_image: $(flash_image)
opensbi: $(opensbi)
fsbl: $(fsbl)
bootloaders: $(bootloaders-y)
root-fs: $(rootfs)
dtbs: ${device_tree_blob}

.PHONY: clean distclean
clean:
	rm -rf -- $(wrkdir)

distclean:
	rm -rf -- $(wrkdir) $(toolchain_dest) br-dl-dir/ arch/ include/ scripts/ .cache.mk

.PHONY: gdb
gdb: $(target_gdb)

.PHONY: openocd
openocd: $(openocd)
	$(openocd) -f $(confdir)/u540-openocd.cfg

$(openocd): $(openocd_srcdir)
	rm -rf $(openocd_wrkdir)
	mkdir -p $(openocd_wrkdir)
	mkdir -p $(dir $@)
	cd $(openocd_srcdir) && ./bootstrap
	cd $(openocd_wrkdir) && $</configure --enable-maintainer-mode --disable-werror --enable-ft2232_libftdi
	$(MAKE) -C $(openocd_wrkdir)

EXT_CFLAGS := -DMPFS_HAL_FIRST_HART=4 -DMPFS_HAL_LAST_HART=4
export EXT_CFLAGS
.PHONY: amp
amp: $(amp_example)
$(amp_example): $(amp_example_srcdir) $(buildroot_initramfs_sysroot_stamp) $(CROSS_COMPILE)gcc
	rm -rf $(amp_example_srcdir)/Default
	$(MAKE) -C $(amp_example_srcdir) O=$(amp_example_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) REMOTE=1
	cp $(amp_example_srcdir)/Remote-Default/mpfs-rpmsg-remote.elf $(amp_example)

$(vfat_image): $(fit) $(uboot_s_scr) $(bootloaders-y)
	@if [ `du --apparent-size --block-size=512 $(fsbl) | cut -f 1` -ge $(FSBL_SIZE) ]; then \
		echo "FSBL is too large for partition!!\nReduce fsbl or increase partition size"; \
		rm $(flash_image); exit 1; fi
	dd if=/dev/zero of=$(vfat_image) bs=512 count=$(VFAT_SIZE)
	/sbin/mkfs.vfat $(vfat_image)
	PATH=$(PATH) MTOOLS_SKIP_CHECK=1 mcopy -i $(vfat_image) $(fit) ::fitImage.fit
	PATH=$(PATH) MTOOLS_SKIP_CHECK=1 mcopy -i $(vfat_image) $(uboot_s_scr) ::boot.scr

## sd/emmc/envm formatting

# partition addreses for mpfs
BBL		= 2E54B353-1271-4842-806F-E436D6AF6985
VFAT		= EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
LINUX		= 0FC63DAF-8483-4772-8E79-3D69D8477DE4
FSBL		= 5B193300-FC78-40CD-8002-E86C45580B47
UBOOT		= 5B193300-FC78-40CD-8002-E86C45580B47
UBOOTENV	= a09354ac-cd63-11e8-9aff-70b3d592f0fa
UBOOTDTB	= 070dd1a8-cd64-11e8-aa3d-70b3d592f0fa
UBOOTFIT	= 04ffcafa-cd65-11e8-b974-70b3d592f0fa
HSS_PAYLOAD 	= 21686148-6449-6E6F-744E-656564454649

# partition addreses
UENV_START=100
UENV_END=1023
FSBL_START=1024
FSBL_END=2047
FSBL_SIZE=1023
VFAT_START=2048
VFAT_END=151976
VFAT_SIZE=149928
RESERVED_SIZE=2000
OSBI_START=1549024
OSBI_END=189024


FSBL_START=2048
FSBL_END=4095
FSBL_SIZE=2048
VFAT_START=4096
VFAT_END=154023
VFAT_SIZE=149928
RESERVED_SIZE=2000
OSBI_START=155648
OSBI_END=189024

# partition addreses for icicle kit
UBOOT_START=2048
UBOOT_END=23248
LINUX_START=24096
LINUX_END=193120
ROOT_START=195168

.PHONY: format-icicle-image
format-icicle-image: $(fit) $(uboot_s_scr)
	@test -b $(DISK) || (echo "$(DISK): is not a block device"; exit 1)
	$(eval DEVICE_NAME := $(shell basename $(DISK)))
	$(eval SD_SIZE := $(shell cat /sys/block/$(DEVICE_NAME)/size))
	$(eval ROOT_SIZE := $(shell expr $(SD_SIZE) \- $(RESERVED_SIZE)))
	/sbin/sgdisk -Zo  \
    --new=1:$(UBOOT_START):$(UBOOT_END) --change-name=1:uboot --typecode=1:$(HSS_PAYLOAD) \
    --new=2:$(LINUX_START):$(LINUX_END) --change-name=2:kernel --typecode=2:$(LINUX) \
    --new=3:$(ROOT_START):${ROOT_SIZE} --change-name=3:root	--typecode=2:$(LINUX) \
    ${DISK}	
	-/sbin/partprobe
	@sleep 1
	
ifeq ($(DISK)1,$(wildcard $(DISK)1))
	@$(eval partition_prefix := )
else ifeq ($(DISK)s1,$(wildcard $(DISK)s1))
	@$(eval partition_prefix := s)
else ifeq ($(DISK)p1,$(wildcard $(DISK)p1))
	@$(eval partition_prefix := p)
else
	@echo Error: Could not find bootloader partition for $(DISK)
	@exit 1
endif

	dd if=$(hss_uboot_payload_bin) of=$(DISK)$(partition_prefix)1
	dd if=$(vfat_image) of=$(DISK)$(partition_prefix)2

# mpfs
.PHONY: format-boot-loader
format-boot-loader: $(fit) $(vfat_image) $(bootloaders-y)
	@test -b $(DISK) || (echo "$(DISK): is not a block device"; exit 1)
	$(eval DEVICE_NAME := $(shell basename $(DISK)))
	$(eval SD_SIZE := $(shell cat /sys/block/$(DEVICE_NAME)/size))
	$(eval ROOT_SIZE := $(shell expr $(SD_SIZE) \- $(RESERVED_SIZE)))
	/sbin/sgdisk -Zo  \
		--new=1:$(FSBL_START):$(FSBL_END)   --change-name=1:fsbl	--typecode=1:$(FSBL) \
		--new=2:$(VFAT_START):$(VFAT_END)  --change-name=2:"Vfat Boot"	--typecode=2:$(VFAT)   \
		--new=3:$(OSBI_START):$(OSBI_END)  --change-name=3:osbi	--typecode=3:$(BBL) \
		--new=4:264192:$(ROOT_SIZE) --change-name=4:root	--typecode=4:$(LINUX) \
		$(DISK)
	-/sbin/partprobe
	@sleep 1
ifeq ($(DISK)p1,$(wildcard $(DISK)p1))
	@$(eval PART1 := $(DISK)p1)
	@$(eval PART2 := $(DISK)p2)
	@$(eval PART3 := $(DISK)p3)
	@$(eval PART4 := $(DISK)p4)
else ifeq ($(DISK)s1,$(wildcard $(DISK)s1))
	@$(eval PART1 := $(DISK)s1)
	@$(eval PART2 := $(DISK)s2)
	@$(eval PART3 := $(DISK)s3)
	@$(eval PART4 := $(DISK)s4)
else ifeq ($(DISK)1,$(wildcard $(DISK)1))
	@$(eval PART1 := $(DISK)1)
	@$(eval PART2 := $(DISK)2)
	@$(eval PART3 := $(DISK)3)
	@$(eval PART4 := $(DISK)4)
else
	@echo Error: Could not find bootloader partition for $(DISK)
	@exit 1
endif

	dd if=$(fsbl) of=$(PART1) bs=4096
	dd if=$(vfat_image) of=$(PART2) bs=4096
	dd if=$(opensbi) of=$(PART3) bs=4096

# DEB_IMAGE	:= rootfs.tar.gz
# DEB_URL := 

# $(DEB_IMAGE):
# 	wget $(DEB_URL)$(DEB_IMAGE)

# format-deb-image: $(DEB_IMAGE) format-boot-loader
# 	/sbin/mke2fs -L ROOTFS -t ext4 $(PART4)
# 	-mkdir tmp-mnt
# 	-sudo mount $(PART2) tmp-mnt && cd tmp-mnt && \
# 		sudo tar -zxf ../$(DEB_IMAGE) -C .
# 	sudo umount tmp-mnt

format-rootfs-image: $(rootfs)
ifeq ($(DISK)p1,$(wildcard $(DISK)p1))
	@$(eval PART1 := $(DISK)p1)
	@$(eval PART2 := $(DISK)p2)
	@$(eval PART3 := $(DISK)p3)
	@$(eval PART4 := $(DISK)p4)
else ifeq ($(DISK)s1,$(wildcard $(DISK)s1))
	@$(eval PART1 := $(DISK)s1)
	@$(eval PART2 := $(DISK)s2)
	@$(eval PART3 := $(DISK)s3)
	@$(eval PART4 := $(DISK)s4)
else ifeq ($(DISK)1,$(wildcard $(DISK)1))
	@$(eval PART1 := $(DISK)1)
	@$(eval PART2 := $(DISK)2)
	@$(eval PART3 := $(DISK)3)
	@$(eval PART4 := $(DISK)4)
else
	@echo Error: Could not find bootloader partition for $(DISK)
	@exit 1
endif
ifeq ($(DEVKIT),mpfs)
	dd if=$(rootfs) of=$(PART4) bs=4096
else 
	dd if=$(rootfs) of=$(PART3) bs=4096
endif
