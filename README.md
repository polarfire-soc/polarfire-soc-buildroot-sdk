# Microchip MPFS-DEV-KIT Linux Software Development Kit

This builds a complete RISC-V cross-compile toolchain for the Microchip 
MPFS-DEV-KIT and LC-MPFS-DEV-KIT Linux Software Development Kit. It also builds a `bbl` image for 
booting the development board.

The complete User Guides are available in the `doc/` subdirectory, for the [MPFS-DEV-KIT](doc/MPFS-DEV-KIT_user_guide.md) and [LC-MPFS-DEV-KIT](doc/LC-MPFS-DEV-KIT_user_guide.md).

## Tested Configurations

### Ubuntu 18.04 x86_64 host

- Status: Working.
- Build dependencies: `autoconf automake autotools-dev bc bison build-essential curl flex gawk gdisk git gperf libgmp-dev libmpc-dev libmpfr-dev libncurses-dev libssl-dev libtool patchutils python screen texinfo unzip zlib1g-dev libblkid-dev device-tree-compiler`
- Additional build deps for QEMU: `libglib2.0-dev libpixman-1-dev`
- tools required for 'format-boot-loader' target: mtools

### Ubuntu 16.04 x86_64 host

- Status: Building.
- Build dependencies: `autoconf automake autotools-dev bc bison build-essential curl flex gawk gdisk git gperf libgmp-dev libmpc-dev libmpfr-dev libncurses-dev libssl-dev libtool patchutils python screen texinfo unzip zlib1g-dev libblkid-dev device-tree-compiler`
- Additional build deps for QEMU: `libglib2.0-dev libpixman-1-dev`
- tools required for 'format-boot-loader' target: mtools

## Build Instructions

Checkout this repository. Then you will need to checkout all of the linked submodules using:

`git submodule update --recursive --init`

This will take some time and require around 7GB of disk space. Some modules may fail because certain dependencies don't have the best git hosting. The only solution is to wait and try again later (or ask someone for a copy of that source repository).

Once the submodules are initialized, run `make` and the complete toolchain and bbl image will be built.   
The completed build tree will consume about 14G of disk space.      
You can choose between LC-MPFS-DEV-KIT and MPFS-DEV-KIT by setting the `MACHINE` variable.
```bash
make MACHINE=mpfs
# or
make MACHINE=lc-mpfs
```
By default `mpfs` will be used.

## Upgrading the BBL for booting the Freedom Unleashed dev board

Once the build of the SDK is complete, there will be a new bbl image under `work/bbl.bin`. This can be copied to the first partition of the MicroSD card using the `dd` tool.

To completely erase, reformat, and program a disk, with the label `sdX`, run:
`sudo make DISK=/dev/sdX format-boot-loader`. This depends on gdisk and e2fsprogs.

The mode selection switches should be set as follows for the MPFS, which will boot into linux automatically:

```
      USB   LED    Mode Select                  Ethernet
 +===|___|==****==+-+-+-+-+-+-+=================|******|===+
 |                | | | | | | |                 |      |   |
 |                | | | | | | |                 |      |   |
 |        HFXSEL->|X|X|X|X|X|X|                 |______|   |
 |                +-+-+-+-+-+-+                            |
 |        RTCSEL-----/ 0 1 2 3 <--MSEL                     |
 |                                                         |
```

And as follows for the LC-MPFS. Instructions for booting linux can be found in the user guide for the [LC-MPFS-DEV-KIT](doc/LC-MPFS-DEV-KIT_user_guide.md), in the section *Board Setup*.
```
      USB   LED    Mode Select                  Ethernet
 +===|___|==****==+-+-+-+-+-+-+=================|******|====
 |                | | | | |X| |                 |      |   
 |                | | | | | | |                 |      |   
 |        HFXSEL->|X|X|X|X| |X|                 |______|   
 |                +-+-+-+-+-+-+                            
 |        RTCSEL-----/ 0 1 2 3 <--MSEL                     
 |                                                         
``` 

## Booting Linux on a simulator

*** spike and qemu are currently not working due to how we load the device tree in bbl ***

You can boot linux on qemu by running `make qemu`.

You can boot linux on spike by running `make sim`.  This requires a patch to
enable the old serial driver, because the new one which works best on the
Freedom Unleashed hardware unfortunately does not work on spike.

```
diff --git a/conf/linux_defconfig b/conf/linux_defconfig
index cd87340..87b480f 100644
--- a/conf/linux_defconfig
+++ b/conf/linux_defconfig
@@ -53,7 +53,7 @@ CONFIG_SERIAL_8250_CONSOLE=y
 CONFIG_SERIAL_OF_PLATFORM=y
 CONFIG_SERIAL_SIFIVE=y
 CONFIG_SERIAL_SIFIVE_CONSOLE=y
-# CONFIG_HVC_RISCV_SBI is not set
+CONFIG_HVC_RISCV_SBI=y
 CONFIG_VIRTIO_CONSOLE=y
 # CONFIG_HW_RANDOM is not set
 CONFIG_I2C=y
