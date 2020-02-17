# Microchip MPFS-DEV-KIT Linux Software Development Kit

This builds a complete RISC-V cross-compile toolchain for the Microchip 
MPFS-DEV-KIT and LC-MPFS-DEV-KIT Linux Software Development Kit. It also builds a `bbl` image for 
booting the development board.

The complete User Guides are available in the `doc/` subdirectory, for the [MPFS-DEV-KIT](doc/MPFS-DEV-KIT_user_guide.md) and [LC-MPFS-DEV-KIT](doc/LC-MPFS-DEV-KIT_user_guide.md).

## Tested Configurations

### Ubuntu 18.04 x86_64 host

- Status: Working.
- Build dependencies: `autoconf automake autotools-dev bc bison build-essential curl flex gawk gdisk git gperf libgmp-dev libmpc-dev libmpfr-dev libncurses-dev libssl-dev libtool patchutils python screen texinfo unzip zlib1g-dev libblkid-dev device-tree-compiler mtools`
- Additional build deps for QEMU: `libglib2.0-dev libpixman-1-dev`

### Ubuntu 16.04 x86_64 host

- Status: Working.
- Build dependencies: `autoconf automake autotools-dev bc bison build-essential curl flex gawk gdisk git gperf libgmp-dev libmpc-dev libmpfr-dev libncurses-dev libssl-dev libtool patchutils python screen texinfo unzip zlib1g-dev libblkid-dev device-tree-compiler mtools`
- Additional build deps for QEMU: `libglib2.0-dev libpixman-1-dev`

## Build Instructions

Checkout this repository. Then you will need to checkout all of the linked submodules using:

`git submodule update --recursive --init`

This will take some time and require around 7GB of disk space. Some modules may fail because certain dependencies don't have the best git hosting. The only solution is to wait and try again later (or ask someone for a copy of that source repository).

Once the submodules are initialized, run `make` and the complete toolchain and bbl image will be built.   
The completed build tree will consume about 14G of disk space.      
You can choose between LC-MPFS-DEV-KIT and MPFS-DEV-KIT by setting the `DEVKIT` variable.
```bash
make DEVKIT=mpfs
# or
make DEVKIT=lc-mpfs
```
By default `mpfs` will be used.

## Upgrading the SD card image for booting linux

To completely erase, reformat, and program a disk, with the label `sdX`, run:
`sudo make DISK=/dev/sdX format-boot-loader`. This depends on gdisk and e2fsprogs.

The mode selection switches should be set as follows, which will boot the board into linux automatically:

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

*** spike and qemu are currently not working ***

You can boot linux on qemu by running `make qemu`.

You can boot linux on spike by running `make sim`.  This requires a patch to
enable the old serial driver, because the new one which works best on the
Freedom Unleashed hardware unfortunately does not work on spike.

```
-# CONFIG_HVC_RISCV_SBI is not set
+CONFIG_HVC_RISCV_SBI=y
```