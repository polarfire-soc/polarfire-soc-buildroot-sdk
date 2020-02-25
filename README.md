# Microchip MPFS-DEV-KIT Linux Software Development Kit

This builds a complete RISC-V cross-compile toolchain for the Microchip 
MPFS-DEV-KIT and LC-MPFS-DEV-KIT Linux Software Development Kit. It also builds a `bbl` image for 
booting the development board.

The complete User Guides, containg build and boot instructions, are available in the `doc/` subdirectory, for the [MPFS-DEV-KIT](doc/MPFS-DEV-KIT_user_guide.md) and [LC-MPFS-DEV-KIT](doc/LC-MPFS-DEV-KIT_user_guide.md).

## Tested Build Hosts:

##### Ubuntu 18.04 x86_64 host - Working.

##### Ubuntu 16.04 x86_64 host - Working.

## Linux Build Instructions

For instructions on how the build a Linux image, please see [Building Linux using Buildroot](doc/Building_Linux_using_Buildroot.md).

## Booting Linux on a simulator

*** spike and qemu are currently not working due to how the device tree is loaded in bbl ***
