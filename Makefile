ISA ?= rv64imafdc
ABI ?= lp64d
LIBERO_PATH ?= /usr/local/microsemi/Libero_SoC_v12.6/Libero/
fpgenprog := $(LIBERO_PATH)/bin64/fpgenprog

srcdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
srcdir := $(srcdir:/=)
patchdir := $(CURDIR)/patches
confdir := $(srcdir)/conf
wrkdir := $(CURDIR)/work

# target icicle w/ emmc by default
DEVKIT ?= icicle-kit-es
device_tree_blob := $(wrkdir)/riscvpc.dtb

ifeq "$(DEVKIT)" "icicle-kit-es"
HSS_SUPPORT ?= y
HSS_TARGET ?= mpfs-icicle-kit-es
target_die = MPFS250T_ES
target_package = FCVG484
mem_file_base_address = 20220000
else ifeq "$(DEVKIT)" "icicle-kit-es-sd"
HSS_SUPPORT ?= y
HSS_TARGET ?= mpfs-icicle-kit-es
target_die = MPFS250T_ES
target_package = FCVG484
mem_file_base_address = 20220000
else
FSBL_SUPPORT ?= y
OSBI_SUPPORT ?= y
endif

RISCV ?= $(CURDIR)/toolchain
PATH := $(RISCV)/bin:$(PATH)
GITID := $(shell git describe --dirty --always)

toolchain_srcdir := $(srcdir)/riscv-gnu-toolchain
toolchain_wrkdir := $(wrkdir)/riscv-gnu-toolchain
bm_toolchain_wrkdir := $(wrkdir)/bm_riscv-gnu-toolchain
toolchain_dest := $(CURDIR)/toolchain
target := riscv64-unknown-linux-gnu
CROSS_COMPILE := $(RISCV)/bin/$(target)-
target_gdb := $(CROSS_COMPILE)gdb

buildroot_srcdir := $(srcdir)/buildroot
buildroot_initramfs_wrkdir := $(wrkdir)/buildroot_initramfs
buildroot_initramfs_tar := $(buildroot_initramfs_wrkdir)/images/rootfs.tar
buildroot_initramfs_config := $(confdir)/buildroot_initramfs_config
buildroot_initramfs_sysroot_stamp := $(wrkdir)/.buildroot_initramfs_sysroot
buildroot_initramfs_sysroot := $(wrkdir)/buildroot_initramfs_sysroot
buildroot_rootfs_wrkdir := $(wrkdir)/buildroot_rootfs
buildroot_rootfs_ext := $(buildroot_rootfs_wrkdir)/images/rootfs.ext4
buildroot_rootfs_config := $(confdir)/buildroot_rootfs_config

buildroot_patchdir := $(patchdir)/buildroot/
buildroot_builddir := $(wrkdir)/buildroot_build
buildroot_builddir_stamp := $(wrkdir)/.buildroot_builddir

linux_srcdir := $(srcdir)/linux
linux_wrkdir := $(wrkdir)/linux
linux_patchdir := $(patchdir)/linux/
linux_builddir := $(wrkdir)/linux_build
linux_builddir_stamp := $(wrkdir)/.linux_builddir
linux_defconfig := $(confdir)/$(DEVKIT)/linux_56_defconfig

vmlinux := $(linux_wrkdir)/vmlinux
vmlinux_stripped := $(linux_wrkdir)/vmlinux-stripped
vmlinux_bin := $(wrkdir)/vmlinux.bin
uImage := $(wrkdir)/uImage
uInitramfs := $(wrkdir)/initramfs.ub

kernel-modules-stamp := $(wrkdir)/.modules_stamp
kernel-modules-install-stamp := $(wrkdir)/.modules_install_stamp

flash_image := $(wrkdir)/hifive-unleashed-$(GITID).gpt
vfat_image := $(wrkdir)/hifive-unleashed-vfat.part
initramfs := $(wrkdir)/initramfs.cpio.gz
rootfs := $(wrkdir)/rootfs.bin
fit := $(wrkdir)/fitImage.fit

fesvr_srcdir := $(srcdir)/riscv-fesvr
fesvr_wrkdir := $(wrkdir)/riscv-fesvr
libfesvr := $(fesvr_wrkdir)/prefix/lib/libfesvr.so

spike_srcdir := $(srcdir)/riscv-isa-sim
spike_wrkdir := $(wrkdir)/riscv-isa-sim
spike := $(spike_wrkdir)/prefix/bin/spike

qemu_srcdir := $(srcdir)/riscv-qemu
qemu_wrkdir := $(wrkdir)/riscv-qemu
qemu := $(qemu_wrkdir)/prefix/bin/qemu-system-riscv64

fsbl_srcdir := $(srcdir)/fsbl
fsbl_wrkdir := $(wrkdir)/fsbl
fsbl_wrkdir_stamp := $(wrkdir)/.fsbl_wrkdir
fsbl_patchdir := $(patchdir)/fsbl/
libversion := $(fsbl_wrkdir)/lib/version.c
fsbl := $(wrkdir)/fsbl.bin

uboot_s_srcdir := $(srcdir)/u-boot
uboot_s_wrkdir := $(wrkdir)/u-boot-smode

# TODO remove below when osbi supports memory reservation
uboot_s_builddir := $(wrkdir)/u-boot-smode-build 
uboot_s_builddir_stamp := $(wrkdir)/.uboot_s_builddir
uboot_s_patchdir := $(patchdir)/u-boot/
# TODO remove above when osbi supports memory reservation

uboot_s := $(wrkdir)/u-boot-s.bin
uboot_s_cfg := $(confdir)/$(DEVKIT)/smode_defconfig
uboot_s_scr := $(confdir)/$(DEVKIT)/uEnv_s-mode.txt

opensbi_srcdir := $(srcdir)/opensbi
opensbi_wrkdir := $(wrkdir)/opensbi
opensbi := $(wrkdir)/fw_payload.bin

openocd_srcdir := $(srcdir)/riscv-openocd
openocd_wrkdir := $(wrkdir)/riscv-openocd
openocd := $(openocd_wrkdir)/src/openocd

payload_generator_srcdir := $(srcdir)/hart-software-services/tools/hss-payload-generator
payloadgen_wrkdir := $(wrkdir)/payload_generator
hss_payload_generator := $(payloadgen_wrkdir)/hss-payload-generator

hss_srcdir := $(srcdir)/hart-software-services
hss_defconfig := $(confdir)/hss_defconfig
hss_wrkdir := $(wrkdir)/hart-software-services
hss := $(hss_wrkdir)/Default/hss.bin
hss_hex := $(hss_wrkdir)/Default/hss.hex
hss_config := $(hss_wrkdir)/config.h

xml_config := $(confdir)/$(DEVKIT)/config.xml 
hss_wrkdir_stamp := $(wrkdir)/.hss_wrkdir
hss_hw_config_stamp := $(wrkdir)/.hss_hw_config

hss_uboot_payload_bin := $(wrkdir)/payload.bin
emmc_image := $(wrkdir)/emmc.img
icicle_image_mnt_point=/mnt

bootloaders-$(FSBL_SUPPORT) += $(fsbl)
bootloaders-$(OSBI_SUPPORT) += $(opensbi)
bootloaders-$(HSS_SUPPORT) += $(hss_uboot_payload_bin)
bootloaders-$(HSS_SUPPORT) += $(hss)

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
endif

$(CROSS_COMPILE)gcc: $(toolchain_srcdir)
	mkdir -p $(toolchain_wrkdir)
	mkdir -p $(toolchain_wrkdir)/header_workdir
	$(MAKE) -C $(linux_srcdir) O=$(toolchain_wrkdir)/header_workdir ARCH=riscv INSTALL_HDR_PATH=$(abspath $(toolchain_srcdir)/linux-headers) headers_install
	cd $(toolchain_wrkdir); $(toolchain_srcdir)/configure \
		--prefix=$(toolchain_dest) \
		--with-arch=$(ISA) \
		--with-abi=$(ABI) \
		--enable-linux
	$(MAKE) -C $(toolchain_wrkdir)
	sed 's/^#define LINUX_VERSION_CODE.*/#define LINUX_VERSION_CODE 329232/' -i $(toolchain_dest)/sysroot/usr/include/linux/version.h

$(buildroot_builddir_stamp): $(buildroot_srcdir) $(buildroot_patchdir)
	- rm -rf $(buildroot_builddir)
	mkdir -p $(buildroot_builddir) && cd $(buildroot_builddir) && cp $(buildroot_srcdir)/* . -r
	for file in $(buildroot_patchdir)/* ; do \
			cd $(buildroot_builddir) && patch -p1 < $${file} ; \
	done
	touch $@

$(buildroot_initramfs_wrkdir)/.config: $(buildroot_builddir_stamp) $(confdir)/initramfs.txt $(buildroot_rootfs_config) $(buildroot_initramfs_config)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp $(buildroot_initramfs_config) $@
	$(MAKE) -C $(buildroot_builddir) RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_initramfs_wrkdir) olddefconfig CROSS_COMPILE=$(CROSS_COMPILE)

$(buildroot_initramfs_tar): $(buildroot_builddir_stamp) $(buildroot_initramfs_wrkdir)/.config $(CROSS_COMPILE)gcc $(buildroot_initramfs_config)
	$(MAKE) -C $(buildroot_builddir) RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_initramfs_wrkdir)

.PHONY: buildroot_initramfs_menuconfig
buildroot_initramfs_menuconfig: $(buildroot_initramfs_wrkdir)/.config $(buildroot_builddir_stamp)
	$(MAKE) -C $(buildroot_builddir) O=$(buildroot_initramfs_wrkdir) menuconfig
	$(MAKE) -C $(buildroot_builddir) O=$(buildroot_initramfs_wrkdir) savedefconfig
	cp $(buildroot_builddir)/defconfig conf/buildroot_initramfs_config

$(buildroot_rootfs_wrkdir)/.config: $(buildroot_builddir_stamp)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp $(buildroot_rootfs_config) $@
	$(MAKE) -C $(buildroot_builddir) RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_rootfs_wrkdir) olddefconfig

$(buildroot_rootfs_ext): $(buildroot_builddir_stamp) $(buildroot_rootfs_wrkdir)/.config $(CROSS_COMPILE)gcc $(buildroot_rootfs_config)
	$(MAKE) -C $(buildroot_builddir) RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_rootfs_wrkdir)

.PHONY: buildroot_rootfs-menuconfig
buildroot_rootfs-menuconfig: $(buildroot_rootfs_wrkdir)/.config $(buildroot_builddir_stamp)
	$(MAKE) -C $(dir $(buildroot_builddir)) O=$(buildroot_rootfs_wrkdir) menuconfig
	$(MAKE) -C $(dir $(buildroot_builddir)) O=$(buildroot_rootfs_wrkdir) savedefconfig
	cp $(dir $(buildroot_builddir))/defconfig conf/buildroot_rootfs_config

$(buildroot_initramfs_sysroot_stamp): $(buildroot_initramfs_tar)
	mkdir -p $(buildroot_initramfs_sysroot)
	tar -xpf $< -C $(buildroot_initramfs_sysroot) --exclude ./dev --exclude ./usr/share/locale
	touch $@

$(linux_builddir_stamp): $(linux_srcdir) $(linux_patchdir)
	- rm -rf $(linux_builddir)
	mkdir -p $(linux_builddir) && cd $(linux_builddir) && cp $(linux_srcdir)/* . -r
	for file in $(linux_patchdir)/$(DEVKIT)/* ; do \
			cd $(linux_builddir) && patch -p1 < $${file} ; \
	done
	touch $@

$(linux_wrkdir)/.config: $(linux_defconfig) $(linux_builddir_stamp)
	mkdir -p $(dir $@)
	cp -p $< $@
	$(MAKE) -C $(linux_builddir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
ifeq (,$(filter rv%c,$(ISA)))
	sed 's/^.*CONFIG_RISCV_ISA_C.*$$/CONFIG_RISCV_ISA_C=n/' -i $@
	$(MAKE) -C $(linux_builddir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
endif
ifeq ($(ISA),$(filter rv32%,$(ISA)))
	sed 's/^.*CONFIG_ARCH_RV32I.*$$/CONFIG_ARCH_RV32I=y/' -i $@
	sed 's/^.*CONFIG_ARCH_RV64I.*$$/CONFIG_ARCH_RV64I=n/' -i $@
	$(MAKE) -C $(linux_builddir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
endif

$(initramfs).d: $(buildroot_initramfs_sysroot) $(kernel-modules-install-stamp)
	cd $(wrkdir) && $(linux_builddir)/usr/gen_initramfs.sh -l $(confdir)/initramfs.txt $(buildroot_initramfs_sysroot) > $@

$(initramfs): $(buildroot_initramfs_sysroot) $(vmlinux) $(kernel-modules-install-stamp)
	cd $(linux_wrkdir) && \
		$(linux_builddir)/usr/gen_initramfs.sh \
		-o $@ -u $(shell id -u) -g $(shell id -g) \
		$(confdir)/initramfs.txt \
		$(buildroot_initramfs_sysroot)

$(vmlinux): $(linux_wrkdir)/.config $(buildroot_initramfs_sysroot_stamp) $(CROSS_COMPILE)gcc
	$(MAKE) -C $(linux_builddir) O=$(linux_wrkdir) \
		ARCH=riscv \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		PATH=$(PATH) \
		vmlinux

$(vmlinux_stripped): $(vmlinux)
	PATH=$(PATH) $(target)-strip -o $@ $<

$(vmlinux_bin): $(vmlinux)
	PATH=$(PATH) $(CROSS_COMPILE)objcopy -O binary $< $@
	
$(uImage): $(vmlinux_bin)
	$(uboot_s_wrkdir)/tools/mkimage -A riscv -O linux -T kernel -C "none" -a 80200000 -e 80200000 -d $< $@

.PHONY: kernel-modules kernel-modules-install
$(kernel-modules-stamp): $(linux_builddir) $(vmlinux)
	$(MAKE) -C $< O=$(linux_wrkdir) \
		ARCH=riscv \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		PATH=$(PATH) \
		modules
	touch $@

$(kernel-modules-install-stamp): $(linux_builddir) $(buildroot_initramfs_sysroot) $(kernel-modules-stamp)
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
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv menuconfig
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv savedefconfig
	cp $(dir $<)/defconfig $(linux_defconfig)

$(device_tree_blob): $(confdir)/$(DEVKIT)/$(DEVKIT).dts
	rm -rf $(wrkdir)/dts
	mkdir -p $(wrkdir)/dts
	cp $(confdir)/dts/* $(wrkdir)/dts
	cp $< $(wrkdir)/dts
	(cat $(wrkdir)/dts/$(DEVKIT).dts; ) > $(wrkdir)/dts/.riscvpc.dtb.pre.tmp;
	$(CROSS_COMPILE)gcc -E -Wp,-MD,$(wrkdir)/dts/.riscvpc.dtb.d.pre.tmp -nostdinc -I$(wrkdir)/dts/ -D__ASSEMBLY__ -undef -D__DTS__ -x assembler-with-cpp -o $(wrkdir)/dts/.riscvpc.dtb.dts.tmp $(wrkdir)/dts/.riscvpc.dtb.pre.tmp 
	dtc -O dtb -o $(device_tree_blob) -b 0 -i $(wrkdir)/dts/ -R 4 -p 0x1000 -d $(wrkdir)/dts/.riscvpc.dtb.d.dtc.tmp $(wrkdir)/dts/.riscvpc.dtb.dts.tmp 
	rm $(wrkdir)/dts/.*.tmp

$(fit): $(uboot_s) $(uImage) $(vmlinux_bin) $(root) $(initramfs) $(device_tree_blob) $(confdir)/osbi-fit-image.its $(kernel-modules-install-stamp)
	$(uboot_s_wrkdir)/tools/mkimage -f $(confdir)/osbi-fit-image.its -A riscv -O linux -T flat_dt $@

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
	cd $(spike_wrkdir) && PATH=$(PATH) $</configure \
		--prefix=$(dir $(abspath $(dir $@))) \
		--with-fesvr=$(dir $(abspath $(dir $(libfesvr))))
	$(MAKE) PATH=$(PATH) -C $(spike_wrkdir)
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
	$(MAKE) -C $(fsbl_wrkdir) O=$(fsbl_wrkdir) CROSSCOMPILE=$(CROSS_COMPILE) all
	cp $(fsbl_wrkdir)/fsbl.bin $(fsbl)
	
$(uboot_s_builddir_stamp): $(uboot_s_srcdir) $(uboot_s_patchdir)
	- rm -rf $(uboot_s_builddir)
	mkdir -p $(uboot_s_builddir) && cd $(uboot_s_builddir) && cp $(uboot_s_srcdir)/* . -r
ifeq ($(DEVKIT),icicle-kit-es)	
	for file in $(uboot_s_patchdir)/* ; do \
			cd $(uboot_s_builddir) && patch -p1 < $${file} ; \
	done
else ifeq ($(DEVKIT),icicle-kit-es-sd)	
	for file in $(uboot_s_patchdir)/* ; do \
			cd $(uboot_s_builddir) && patch -p1 < $${file} ; \
	done
endif
	touch $@

$(uboot_s): $(uboot_s_builddir_stamp) $(CROSS_COMPILE)gcc
	- rm -rf $(uboot_s_wrkdir)
	mkdir -p $(uboot_s_wrkdir)
	cp  $(uboot_s_cfg) $(uboot_s_wrkdir)/.config
	$(MAKE) -C $(uboot_s_builddir) O=$(uboot_s_wrkdir) ARCH=riscv olddefconfig
	$(MAKE) -C $(uboot_s_builddir) O=$(uboot_s_wrkdir) ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE)
	cp -v $(uboot_s_wrkdir)/u-boot.bin $(uboot_s)

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

$(hss_wrkdir_stamp): $(hss_srcdir)
	rm -rf $(hss_wrkdir) $(hss_wrkdir_stamp) $(hss_hw_config_stamp)
	mkdir -p $(hss_wrkdir)
	cp -r $(hss_srcdir)/* $(hss_wrkdir)
	touch $@

$(hss_hw_config_stamp): $(xml_config) $(hss_wrkdir_stamp)
ifeq ($(DEVKIT),icicle-kit-es)	
	rm -rf $(hss_wrkdir)/boards/$(HSS_TARGET)/soc_config
	cd $(hss_srcdir)/tools/polarfire-soc-configuration-generator && python3 mpfs_configuration_generator.py $(xml_config) $(hss_wrkdir)/boards/$(HSS_TARGET)
else ifeq ($(DEVKIT),icicle-kit-es-sd)	
	rm -rf $(hss_wrkdir)/boards/$(HSS_TARGET)/soc_config
	cd $(hss_srcdir)/tools/polarfire-soc-configuration-generator && python3 mpfs_configuration_generator.py $(xml_config) $(hss_wrkdir)/boards/$(HSS_TARGET)
endif
	touch $@

$(hss_config): $(hss_wrkdir_stamp)
	cp $(confdir)/$(DEVKIT)/hss_def_config $(hss_wrkdir)/.config
	PATH=$(PATH) $(MAKE) -C $(hss_wrkdir) BOARD=$(HSS_TARGET) CROSS_COMPILE=$(CROSS_COMPILE) config.h

$(hss): $(hss_hw_config_stamp) $(hss_config) $(hss_uboot_payload_o) $(CROSS_COMPILE)gcc
	PATH=$(PATH) $(MAKE) -C $(hss_wrkdir) BOARD=$(HSS_TARGET) CROSS_COMPILE=$(CROSS_COMPILE)

$(hss_payload_generator): $(payload_generator_srcdir)
	mkdir -p $(payloadgen_wrkdir)
	$(MAKE) -C $(payload_generator_srcdir) O=$(payloadgen_wrkdir)

$(hss_uboot_payload_bin): $(uboot_s) $(hss_payload_generator)
	cd $(wrkdir) && $(hss_payload_generator) -c $(confdir)/config.yaml -v $(hss_uboot_payload_bin)

.PHONY: buildroot_initramfs_sysroot vmlinux bbl fit flash_image initrd opensbi u-boot hss bootloaders
buildroot_initramfs_sysroot: $(buildroot_initramfs_sysroot)
vmlinux: $(vmlinux_bin)
fit: $(fit)
initrd: $(initramfs)
u-boot: $(uboot_s)
flash_image: $(flash_image)
initrd: $(initramfs)
opensbi: $(opensbi)
fsbl: $(fsbl)
hss: $(hss)
bootloaders: $(bootloaders-y)

.PHONY: clean distclean
clean:
	rm -rf -- $(wrkdir)

distclean:
	rm -rf -- $(wrkdir) $(toolchain_dest) arch/ include/ scripts/ .cache.mk

.PHONY: sim
sim: $(spike) $(bbl_payload)
	$(spike) --isa=$(ISA) -p4 $(bbl_payload)

.PHONY: qemu
qemu: $(qemu) $(bbl) $(vmlinux) $(initramfs)
	$(qemu) -nographic -machine virt -bios $(bbl) -kernel $(vmlinux) -initrd $(initramfs) \
		-netdev user,id=net0 -device virtio-net-device,netdev=net0

.PHONY: qemu-rootfs
qemu-rootfs: $(qemu) $(bbl) $(vmlinux) $(initramfs) $(rootfs)
	$(qemu) -nographic -machine virt -bios $(bbl) -kernel $(vmlinux) -initrd $(initramfs) \
		-drive file=$(rootfs),format=raw,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev user,id=net0 -device virtio-net-device,netdev=net0

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

.PHONY: gdb
gdb: $(target_gdb)

$(vfat_image): $(fit) $(uboot_s_scr)
	@if [ `du --apparent-size --block-size=512 $(fsbl) | cut -f 1` -ge $(FSBL_SIZE) ]; then \
		echo "FSBL is too large for partition!!\nReduce fsbl or increase partition size"; \
		rm $(flash_image); exit 1; fi
	dd if=/dev/zero of=$(vfat_image) bs=512 count=$(VFAT_SIZE)
	/sbin/mkfs.vfat $(vfat_image)
	PATH=$(PATH) MTOOLS_SKIP_CHECK=1 mcopy -i $(vfat_image) $(fit) ::fitImage.fit
	PATH=$(PATH) MTOOLS_SKIP_CHECK=1 mcopy -i $(vfat_image) $(uboot_s_scr) ::uEnv.txt

## sd/emmc/envm formatting

# partition addreses for {lc-,}mpfs
BBL			= 2E54B353-1271-4842-806F-E436D6AF6985
VFAT		= EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
LINUX		= 0FC63DAF-8483-4772-8E79-3D69D8477DE4
FSBL		= 5B193300-FC78-40CD-8002-E86C45580B47
UBOOT		= 5B193300-FC78-40CD-8002-E86C45580B47
UBOOTENV	= a09354ac-cd63-11e8-9aff-70b3d592f0fa
UBOOTDTB	= 070dd1a8-cd64-11e8-aa3d-70b3d592f0fa
UBOOTFIT	= 04ffcafa-cd65-11e8-b974-70b3d592f0fa
HSS_PAYLOAD = 21686148-6449-6E6F-744E-656564454649

# partition addreses
VFAT_START=2048
VFAT_END=126976
VFAT_SIZE=124928
FSBL_START=1024
FSBL_END=2047
FSBL_SIZE=1023
UENV_START=100
UENV_END=1023
RESERVED_SIZE=2000
OSBI_START=129024
OSBI_END=159024

# partition addreses for icicle kit
UBOOT_START=2048
UBOOT_END=3248
LINUX_START=4096
LINUX_END=133120
ROOT_START=135168

.PHONY: format-icicle-image
format-icicle-image: $(fit) $(uboot_s_scr) $(icicle_image_mnt_point)
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

# {lc-,}mpfs
.PHONY: format-boot-loader
format-boot-loader: $(fit) $(vfat_image) $(bootloaders-y)
	@test -b $(DISK) || (echo "$(DISK): is not a block device"; exit 1)
	$(eval DEVICE_NAME := $(shell basename $(DISK)))
	$(eval SD_SIZE := $(shell cat /sys/block/$(DEVICE_NAME)/size))
	$(eval ROOT_SIZE := $(shell expr $(SD_SIZE) \- $(RESERVED_SIZE)))
	/sbin/sgdisk --clear  \
		--new=1:$(VFAT_START):$(VFAT_END)  --change-name=1:"Vfat Boot"	--typecode=1:$(VFAT)   \
		--new=2:264192:$(ROOT_SIZE) --change-name=2:root	--typecode=2:$(LINUX) \
		--new=3:$(OSBI_START):$(OSBI_END)  --change-name=3:osbi	--typecode=3:$(BBL) \
		--new=4:$(FSBL_START):$(FSBL_END)   --change-name=4:fsbl	--typecode=4:$(FSBL) \
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

	dd if=$(fsbl) of=$(PART4) bs=4096
	dd if=$(opensbi) of=$(PART3) bs=4096
	dd if=$(vfat_image) of=$(PART1) bs=4096

# DEB_IMAGE	:= rootfs.tar.gz
# DEB_URL := 

# $(DEB_IMAGE):
# 	wget $(DEB_URL)$(DEB_IMAGE)

# format-deb-image: $(DEB_IMAGE) format-boot-loader
# 	/sbin/mke2fs -L ROOTFS -t ext4 $(PART2)
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
ifeq ($(DEVKIT),icicle-kit-es)
	dd if=$(rootfs) of=$(PART3) bs=4096
else ifeq ($(DEVKIT),icicle-kit-es-sd)
	dd if=$(rootfs) of=$(PART3) bs=4096
else 
	dd if=$(rootfs) of=$(PART2) bs=4096
endif

program_envm: $(hss)
ifeq (,$(shell which $(fpgenprog)))
	$(error fpgenprog not found - either libero is not installed or LIBERO_PATH does not point to the installation directory)
endif
	rm -rf $(wrkdir)/fpgen
	mkdir -p $(wrkdir)/fpgen
	$(fpgenprog) new_project --location $(wrkdir)/fpgen --target_die $(target_die) --target_package $(target_package)
	$(fpgenprog) envm_client --location $(wrkdir)/fpgen  --number_of_bytes $(shell wc -c $(hss) | cut -d ' ' -f 1) --content_file_format intel-hex --content_file $(hss_hex) --start_page 0 --client_name envm1 --mem_file_base_address $(mem_file_base_address)
	$(fpgenprog) mss_boot_info --location $(wrkdir)/fpgen  --u_mss_bootmode 1 --u_mss_bootcfg $(mem_file_base_address)$(mem_file_base_address)$(mem_file_base_address)$(mem_file_base_address)$(mem_file_base_address)
	$(fpgenprog) generate_bitstream --location $(wrkdir)/fpgen
	$(fpgenprog) run_action --location $(wrkdir)/fpgen --action PROGRAM