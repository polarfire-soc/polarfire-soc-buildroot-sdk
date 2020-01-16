# RISCV should either be unset, or set to point to a directory that contains
# a toolchain install tree that was built via other means.
RISCV ?= $(CURDIR)/toolchain
PATH := $(RISCV)/bin:$(PATH)
ISA ?= rv64imafdc
ABI ?= lp64d

srcdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
srcdir := $(srcdir:/=)
confdir := $(srcdir)/conf
wrkdir := $(CURDIR)/work

uboot_srcdir := $(srcdir)/HiFive_U-Boot
uboot_wrkdir := $(wrkdir)/HiFive_U-Boot
uboot := $(uboot_wrkdir)/u-boot.bin

flash_image := $(wrkdir)/hifive-unleashed-a00-YYYY-MM-DD.gpt
bblbin := $(wrkdir)/bbl.bin

toolchain_srcdir := $(srcdir)/riscv-gnu-toolchain
toolchain_wrkdir := $(wrkdir)/riscv-gnu-toolchain
toolchain_dest := $(CURDIR)/toolchain

target := riscv64-unknown-linux-gnu

CROSS_COMPILE := $(RISCV)/bin/$(target)-

buildroot_srcdir := $(srcdir)/buildroot
buildroot_initramfs_wrkdir := $(wrkdir)/buildroot_initramfs
buildroot_initramfs_tar := $(buildroot_initramfs_wrkdir)/images/rootfs.tar
buildroot_initramfs_config := $(confdir)/buildroot_initramfs_config
buildroot_initramfs_sysroot_stamp := $(wrkdir)/.buildroot_initramfs_sysroot
buildroot_initramfs_sysroot := $(wrkdir)/buildroot_initramfs_sysroot
buildroot_rootfs_wrkdir := $(wrkdir)/buildroot_rootfs
buildroot_rootfs_ext := $(buildroot_rootfs_wrkdir)/images/rootfs.ext4
buildroot_rootfs_config := $(confdir)/buildroot_rootfs_config

linux_srcdir := $(srcdir)/linux
linux_wrkdir := $(wrkdir)/linux
linux_defconfig := $(confdir)/linux_defconfig

vmlinux := $(linux_wrkdir)/vmlinux
vmlinux_stripped := $(linux_wrkdir)/vmlinux-stripped

pk_srcdir := $(srcdir)/riscv-pk
pk_wrkdir := $(wrkdir)/riscv-pk
bbl := $(pk_wrkdir)/bbl
bin := $(wrkdir)/bbl.bin
hex := $(wrkdir)/bbl.hex

fesvr_srcdir := $(srcdir)/riscv-fesvr
fesvr_wrkdir := $(wrkdir)/riscv-fesvr
libfesvr := $(fesvr_wrkdir)/prefix/lib/libfesvr.so

spike_srcdir := $(srcdir)/riscv-isa-sim
spike_wrkdir := $(wrkdir)/riscv-isa-sim
spike := $(spike_wrkdir)/prefix/bin/spike

qemu_srcdir := $(srcdir)/riscv-qemu
qemu_wrkdir := $(wrkdir)/riscv-qemu
qemu := $(qemu_wrkdir)/prefix/bin/qemu-system-riscv64

rootfs := $(wrkdir)/rootfs.bin

MACHINE ?= mpfs
device_tree := $(confdir)/$(MACHINE).dts
device_tree_blob := $(wrkdir)/riscvpc.dtb

BBL		= 2E54B353-1271-4842-806F-E436D6AF6985
VFAT	= EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
LINUX	= 0FC63DAF-8483-4772-8E79-3D69D8477DE4
FSBL	= 5B193300-FC78-40CD-8002-E86C45580B47
UBOOT	= 5B193300-FC78-40CD-8002-E86C45580B47
UBOOTENV	= a09354ac-cd63-11e8-9aff-70b3d592f0fa
UBOOTDTB	= 070dd1a8-cd64-11e8-aa3d-70b3d592f0fa
UBOOTFIT	= 04ffcafa-cd65-11e8-b974-70b3d592f0fa



.PHONY: all
all: $(hex) $(flash_image)
	@echo
	@echo "Device tree: $(device_tree)"
	@echo
	@echo "GPT (for SPI flash or SDcard) and U-boot Image files have"
	@echo "been generated for an ISA of $(ISA) and an ABI of $(ABI)"
	@echo
	@echo $(flash_image)
	@echo
	@echo
	@echo "To completely erase, reformat, and program a disk sdX, run:"
	@echo "  make DISK=/dev/sdX format-boot-loader"
	@echo "  ... you will need gdisk and e2fsprogs installed"
	@echo

ifneq ($(RISCV),$(toolchain_dest))
$(RISCV)/bin/$(target)-gcc:
	$(error The RISCV environment variable was set, but is not pointing at a toolchain install tree)
endif

$(toolchain_dest)/bin/$(target)-gcc: $(toolchain_srcdir)
	mkdir -p $(toolchain_wrkdir)
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv INSTALL_HDR_PATH=$(abspath $(toolchain_srcdir)/linux-headers) headers_install
	cd $(toolchain_wrkdir); $(toolchain_srcdir)/configure \
		--prefix=$(toolchain_dest) \
		--with-arch=$(ISA) \
		--with-abi=$(ABI) \
		--enable-linux
	$(MAKE) -C $(toolchain_wrkdir)
	sed 's/^#define LINUX_VERSION_CODE.*/#define LINUX_VERSION_CODE 263682/' -i $(toolchain_dest)/sysroot/usr/include/linux/version.h


$(buildroot_initramfs_wrkdir)/.config: $(buildroot_initramfs_config)
$(buildroot_initramfs_wrkdir)/.config: $(buildroot_rootfs_config)
$(buildroot_initramfs_wrkdir)/.config: $(confdir)/initramfs.txt
$(buildroot_initramfs_wrkdir)/.config: $(buildroot_srcdir)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp $(buildroot_initramfs_config) $@
	$(MAKE) -C $< RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_initramfs_wrkdir) olddefconfig CROSS_COMPILE=$(CROSS_COMPILE)

$(buildroot_initramfs_tar): $(buildroot_srcdir) $(buildroot_initramfs_wrkdir)/.config $(CROSS_COMPILE)gcc $(buildroot_initramfs_config)
	$(MAKE) -C $< RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_initramfs_wrkdir)

.PHONY: buildroot_initramfs-menuconfig
buildroot_initramfs-menuconfig: $(buildroot_initramfs_wrkdir)/.config $(buildroot_srcdir)
	$(MAKE) -C $(dir $<) O=$(buildroot_initramfs_wrkdir) menuconfig
	$(MAKE) -C $(dir $<) O=$(buildroot_initramfs_wrkdir) savedefconfig
	cp $(dir $<)/defconfig conf/buildroot_initramfs_config

$(buildroot_rootfs_wrkdir)/.config: $(buildroot_srcdir)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp $(buildroot_rootfs_config) $@
	$(MAKE) -C $< RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_rootfs_wrkdir) olddefconfig

$(buildroot_rootfs_ext): $(buildroot_srcdir) $(buildroot_rootfs_wrkdir)/.config $(CROSS_COMPILE)gcc $(buildroot_rootfs_config)
	$(MAKE) -C $< RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_rootfs_wrkdir)

.PHONY: buildroot_rootfs-menuconfig
buildroot_rootfs-menuconfig: $(buildroot_rootfs_wrkdir)/.config $(buildroot_srcdir)
	$(MAKE) -C $(dir $<) O=$(buildroot_rootfs_wrkdir) menuconfig
	$(MAKE) -C $(dir $<) O=$(buildroot_rootfs_wrkdir) savedefconfig
	cp $(dir $<)/defconfig conf/buildroot_rootfs_config

$(buildroot_initramfs_sysroot_stamp): $(buildroot_initramfs_tar)
	mkdir -p $(buildroot_initramfs_sysroot)
	tar -xpf $< -C $(buildroot_initramfs_sysroot) --exclude ./dev --exclude ./usr/share/locale
	touch $@

$(linux_wrkdir)/.config: $(linux_defconfig) $(linux_srcdir)
	mkdir -p $(dir $@)
	cp -p $< $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
	echo $(ISA)
	echo $(filter rv32%,$(ISA))
ifeq (,$(filter rv%c,$(ISA)))
	sed 's/^.*CONFIG_RISCV_ISA_C.*$$/CONFIG_RISCV_ISA_C=n/' -i $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
endif
ifeq ($(ISA),$(filter rv32%,$(ISA)))
	sed 's/^.*CONFIG_ARCH_RV32I.*$$/CONFIG_ARCH_RV32I=y/' -i $@
	sed 's/^.*CONFIG_ARCH_RV64I.*$$/CONFIG_ARCH_RV64I=n/' -i $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
endif

$(vmlinux): $(linux_srcdir) $(linux_wrkdir)/.config $(buildroot_initramfs_sysroot_stamp)
	$(MAKE) -C $< O=$(linux_wrkdir) \
		CONFIG_INITRAMFS_SOURCE="$(confdir)/initramfs.txt $(buildroot_initramfs_sysroot)" \
		CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
		CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		ARCH=riscv \
		vmlinux

$(vmlinux_stripped): $(vmlinux)
	$(target)-strip -o $@ $<

.PHONY: linux-menuconfig
linux-menuconfig: $(linux_wrkdir)/.config
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv menuconfig
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv savedefconfig
	cp $(dir $<)/defconfig conf/linux_defconfig

$(device_tree_blob): $(device_tree)
	dtc -I dts $(device_tree) -O dtb -o $(device_tree_blob)

$(bbl): $(pk_srcdir) $(vmlinux_stripped) $(wrkdir)/riscvpc.dtb
	rm -rf $(pk_wrkdir)
	mkdir -p $(pk_wrkdir)
	cd $(pk_wrkdir) && $</configure \
		--host=$(target) \
		--with-payload=$(vmlinux_stripped) \
		--enable-logo 
	CFLAGS="-mabi=$(ABI) -march=$(ISA)" $(MAKE) -C $(pk_wrkdir)

$(bin): $(bbl)
	$(target)-objcopy -S -O binary --change-addresses -0x80000000 $< $@

$(hex):	$(bin)
	xxd -c1 -p $< > $@
	
$(uboot): $(uboot_srcdir) $(target_gcc) $(hex)
	rm -rf $(uboot_wrkdir)
	mkdir -p $(uboot_wrkdir)
	mkdir -p $(dir $@)
	$(MAKE) -C $(uboot_srcdir) O=$(uboot_wrkdir) HiFive-U540_defconfig
	$(MAKE) -C $(uboot_srcdir) O=$(uboot_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE)

VFAT_START=2048
VFAT_END=65502
VFAT_SIZE=63454
UBOOT_START=1100
UBOOT_END=2020
UBOOT_SIZE=950
UENV_START=1024
UENV_END=1099

#pactron
$(flash_image): $(uboot) $(bblbin)
	dd if=/dev/zero of=$(flash_image) bs=1M count=32
	/sbin/sgdisk --clear  \
		--new=1:$(VFAT_START):$(VFAT_END)  --change-name=1:"bbl"	--typecode=1:$(BBL)   \
		--new=3:$(UBOOT_START):$(UBOOT_END)   --change-name=3:uboot	--typecode=3:$(FSBL) \
		--new=4:$(UENV_START):$(UENV_END) --change-name=4:uboot-env --typecode=4:$(UBOOTENV) \
		$(flash_image)
	@sleep 1
	dd conv=notrunc if=$(bblbin) of=$(flash_image) bs=512 seek=$(VFAT_START)
	dd conv=notrunc if=$(uboot) of=$(flash_image) bs=512 seek=$(UBOOT_START) count=$(UBOOT_SIZE)


$(libfesvr): $(fesvr_srcdir)
	rm -rf $(fesvr_wrkdir)
	mkdir -p $(fesvr_wrkdir)
	mkdir -p $(dir $@)
	cd $(fesvr_wrkdir) && $</configure \
		--prefix=$(dir $(abspath $(dir $@)))
	$(MAKE) -C $(fesvr_wrkdir)
	$(MAKE) -C $(fesvr_wrkdir) install
	touch -c $@

$(spike): $(spike_srcdir) $(libfesvr)
	rm -rf $(spike_wrkdir)
	mkdir -p $(spike_wrkdir)
	mkdir -p $(dir $@)
	cd $(spike_wrkdir) && $</configure \
		--prefix=$(dir $(abspath $(dir $@))) \
		--with-fesvr=$(dir $(abspath $(dir $(libfesvr))))
	$(MAKE) -C $(spike_wrkdir)
	$(MAKE) -C $(spike_wrkdir) install
	touch -c $@

$(qemu): $(qemu_srcdir)
	rm -rf $(qemu_wrkdir)
	mkdir -p $(qemu_wrkdir)
	mkdir -p $(dir $@)
	cd $(qemu_wrkdir) && $</configure \
		--prefix=$(dir $(abspath $(dir $@))) \
		--target-list=riscv64-softmmu
	$(MAKE) -C $(qemu_wrkdir)
	$(MAKE) -C $(qemu_wrkdir) install
	touch -c $@

$(rootfs): $(buildroot_rootfs_ext)
	cp $< $@

.PHONY: buildroot_initramfs_sysroot vmlinux bbl uboot
buildroot_initramfs_sysroot: $(buildroot_initramfs_sysroot)
vmlinux: $(vmlinux)
bbl: $(bbl)
uboot: $(uboot)

.PHONY: flash_image
flash_image: $(flash_image)

.PHONY: clean
clean:
	rm -rf -- $(wrkdir) $(toolchain_dest)

.PHONY: sim
sim: $(spike) $(bbl)
	$(spike) --isa=$(ISA) -p4 $(bbl)

.PHONY: qemu
qemu: $(qemu) $(bbl) $(rootfs)
	$(qemu) -nographic -machine virt -kernel $(bbl) \
		-drive file=$(rootfs),format=raw,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev user,id=net0 -device virtio-net-device,netdev=net0

# Relevant partition type codes
# BBL   = 2E54B353-1271-4842-806F-E436D6AF6985
# LINUX = 0FC63DAF-8483-4772-8E79-3D69D8477DE4
# FSBL  = 5B193300-FC78-40CD-8002-E86C45580B47

.PHONY: format-boot-loader
format-boot-loader: $(bin)
	@test -b $(DISK) || (echo "$(DISK): is not a block device"; exit 1)
	sgdisk --clear                                                               \
		--new=1:2048:4095   --change-name=1:uboot      --typecode=1:$(FSBL)   \
		--new=2:4096:69631  --change-name=2:bootloader --typecode=2:$(BBL)   \
		--new=3:264192:     --change-name=3:root       --typecode=3:$(LINUX) \
		$(DISK)
	@sleep 1
ifeq ($(DISK)p1,$(wildcard $(DISK)p1))
	@$(eval PART1 := $(DISK)p1)
	@$(eval PART2 := $(DISK)p2)
	@$(eval PART3 := $(DISK)p3)
else ifeq ($(DISK)s1,$(wildcard $(DISK)s1))
	@$(eval PART1 := $(DISK)s1)
	@$(eval PART2 := $(DISK)s2)
	@$(eval PART3 := $(DISK)s3)
else ifeq ($(DISK)1,$(wildcard $(DISK)1))
	@$(eval PART1 := $(DISK)1)
	@$(eval PART2 := $(DISK)2)
	@$(eval PART3 := $(DISK)3)
else
	@echo Error: Could not find bootloader partition for $(DISK)
	@exit 1
endif
	dd if=$(uboot) of=$(PART1) bs=4096

	dd if=$(shell pwd)/work/bbl.bin of=$(PART2) bs=4096

	mke2fs -t ext3 $(PART3)
