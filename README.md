# Microchip MPFS-DEV-KIT Linux Software Development Kit

This builds a complete RISC-V cross-compile toolchain for the Microchip 
MPFS-DEV-KIT and LC-MPFS-DEV-KIT Linux Software Development Kit. It also builds a `bbl` image for 
booting the development board.

The complete User Guides, containing board and boot instructions, are available in the `doc/` subdirectory, for the [MPFS-DEV-KIT](doc/MPFS-DEV-KIT_user_guide.md) and [LC-MPFS-DEV-KIT](doc/LC-MPFS-DEV-KIT_user_guide.md).

## Building Linux Using Buildroot
This section describes the procedure to build the Linux boot image and loading it into an SD card using
Buildroot.

### Supported Build Hosts
This document assumes you are running on a modern Linux system. The process documented here was tested using Ubuntu 18.04 LTS. It should also work with other Linux distributions if the equivalent prerequisite packages are installed.

#### Tested Build Hosts:

Ubuntu 18.04 x86_64 host - Working.

Ubuntu 16.04 x86_64 host - Working.

### Supported Build Targets
The `DEVKIT` option can be used to set the target board for which linux is built, and if left blank it will default to `DEVKIT=mpfs`.           
The following table details the available targets:

| `DEVKIT` | Board Name |
| --- | --- |
| `DEVKIT=mpfs` | MPFS-DEV-KIT, HiFive Unleashed Expansion Board |
| `DEVKIT=lc-mpfs` | LC-MPFS-DEV-KIT |


### Install Prerequisite Packages
Before starting, use the `apt` command to install prerequisite packages:
```
sudo apt install autoconf automake autotools-dev bc bison \
build-essential curl flex gawk gdisk git gperf libgmp-dev \
libmpc-dev libmpfr-dev libncurses-dev libssl-dev libtool \
patchutils python screen texinfo unzip zlib1g-dev libblkid-dev \
device-tree-compiler mtools
```
### Build and Checkout Code
The following commands build the system to a work/sub-directory.
#### Note:                
        Set DEVKIT to whichever board you are using.
        If you have the MPFS-DEV-KIT, use `make all DEVKIT=lc-mpfs`
        And for the LC-MPFS-DEV-KIT, use `make all DEVKIT=mpfs`
        By default `mpfs` will be used.

```
git clone https://github.com/polarfire-soc/polarfire-soc-buildroot-sdk.git
cd polarfire-soc-buildroot-sdk
git checkout master
git submodule update --init --recursive
unset RISCV
make all DEVKIT=lc-mpfs
```
Note: The first time the build is run it can take a long time, as it also builds the RISC-V cross compiler toolchain. 

The output file `work/bbl.bin` contains the bootloader (RISC-V pk/bbl), the Linux kernel, and the device tree blob. A GPT image is also created, with U-Boot as the first stage boot loader that can be copied to an SD card. 
The option `DEVKIT=<target>` selects the correct device tree for the target board.   

### Preparing an SD Card 
Add an SD card to boot your system (16 GB or 32 GB). If the SD card is auto-mounted, first unmount it manually.               
The following steps will allow you to check and unmount the card if required:

After inserting your SD card, use dmesg to check what your card's identifier is.
```
dmesg | egrep "sd|mmcblk"
```
The output should contain a line similar to one of the below lines:
```
[85089.431896] sd 6:0:0:2: [sdX] 31116288 512-byte logical blocks: (15.9 GB/14.8 GiB)
[51273.539768] mmcblk0: mmc0:0001 EB1QT 29.8 GiB 
```
`sdX` or `mmcblkX` is the drive identifier that should be used going forwards, where `X` should be replaced with the specific value from the previous command.           
For these examples the identifier `sdX` is used. 

#### WARNING:              
        The drive with the identifier `sda` is the default location for your operating system.        
        DO NOT pass this identifier to any of the commands listed here.       
        Check that the size of the card matches the dmesg output before continuing.     

Next check if this card is mounted:
```
$ mount | grep sdX
```
If any entries are present, then run the following. If not then skip this command:
```
$ sudo umount /dev/sdX
```
The SD card should have a GUID Partition Table (GPT) rather than a Master Boot Record (MBR) without any partitions defined.

### Programming an Image for the First Time with Buildroot
To automatically partition and format your SD card, in the top level of mpfs-linux-sdk, type:
```
$ sudo make DISK=/dev/sdX format-boot-loader
```
At this point, your system should be bootable using your new SD card. You can remove it from your PC
and insert it into the SD card slot on the HiFive Unleashed board, and then power-on the DEV-KIT.

### Rebuilding the Linux Kernel with Buildroot
To rebuild your kernel, type the following from the top level of mpfs-linux-sdk:
```
$ rm -rf work/linux/
$ make DEVKIT=<board>
```
Copy this newly built image to the SD card using the same method as before:
```
$ sudo make DISK=/dev/sdX format-boot-loader
```
### Switching machines with Buildroot
To change the machine being targeted, type the following from the top level of mpfs-linux-sdk:
```
$ rm -rf work/linux/ work/riscvpc.dtb
$ make DEVKIT=<board>
```
Copy this newly built image to the SD card using the same method as before:
```
$ sudo make DISK=/dev/sdX format-boot-loader
```

The source for the device tree for HiFive Unleashed Expansion board is in `conf/<DEVKIT>.dts`.           
The configuration options used for the Linux kernel are in `conf/<DEVKIT>linux_defconfig`.
Currently, the Microsemi PolarFire Linux SDK for the HiFive Unleashed platform uses a modification to
the RISC-V Bootloader startup code to pass in the device tree blob (see `riscv-pk/machine/mentry.S` for
the modification.)

## Booting Linux on a simulator

*** spike and qemu are currently not working due to how the device tree is loaded in bbl ***
