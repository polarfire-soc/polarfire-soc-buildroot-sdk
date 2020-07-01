# Microchip PolarFire SoC Linux Software Development Kit
This repository builds a command line only RISC-V Linux image for the Microchip PolarFire SoC Linux Software Development Kits.
It first will build the GNU cross-compilation toolchain for RISC-V, which will be installed in the `toolchain/` subdirectory. This toolchain is then used to build a Linux image consisting of the kernel, a Busybox based root file system and the necessary bootloaders for each development platform.

Currently the following development platforms are supported:
- [MPFS-DEV-KIT](https://github.com/polarfire-soc/polarfire-soc-documentation/blob/master/boards/mpfs-dev-kit/MPFS-DEV-KIT_user_guide.md) (HiFive Unleashed Expansion Board)
- [LC-MPFS-DEV-KIT](https://github.com/polarfire-soc/polarfire-soc-documentation/blob/master/boards/lc-mpfs-dev-kit/LC-MPFS-DEV-KIT_user_guide.md)
- Icicle Kit (Engineering Sample)

The complete User Guides for each development platform, containing board and boot instructions, are available in the `doc/` subdirectory. 

## Building Linux Using Buildroot
This section describes the procedure to build the Linux boot image and loading it into an SD card using Buildroot.

### Supported Build Hosts
This document assumes you are running on a modern Linux system. The process documented here was tested using Ubuntu 18.04 LTS.    
It should also work with other Linux distributions if the equivalent prerequisite packages are installed.

#### Tested Build Hosts:

Ubuntu 20.04 x86_64 host - Working.

Ubuntu 18.04 x86_64 host - Working.

Ubuntu 16.04 x86_64 host - Working.

### Install Prerequisite Packages
Before starting, use the `apt` command to install prerequisite packages:
```
sudo apt install autoconf automake autotools-dev bc bison \
build-essential curl flex gawk gdisk git gperf libgmp-dev \
libmpc-dev libmpfr-dev libncurses-dev libssl-dev libtool \
patchutils python screen texinfo unzip zlib1g-dev libblkid-dev \
device-tree-compiler mtools libexpat1-dev
```
The Hart Software Services (HSS) require kconfiglib:
```
pip install kconfiglib
```

### Checkout Code & Build

#### Supported Build Targets
The `DEVKIT` option can be used to set the target board for which linux is built, and if left blank it will default to `DEVKIT=mpfs`.           
The following table details the available targets:

| `DEVKIT` | Board Name |
| --- | --- |
| `DEVKIT=mpfs` | MPFS-DEV-KIT, HiFive Unleashed Expansion Board |
| `DEVKIT=lc-mpfs` | LC-MPFS-DEV-KIT |
| `DEVKIT=icicle-kit-es` | Icicle Development Kit with engineering sample silicon |

#### Build instructions
The following commands checkout SDK in a new directory:
```
git clone https://github.com/polarfire-soc/polarfire-soc-buildroot-sdk.git
cd polarfire-soc-buildroot-sdk
git checkout master
```
Before building for the first time, it is required to acquire the contents of the sub-components:
```
git submodule sync
git submodule update --init --recursive
```
Then the Linux image can be built in the `work` sub-directory:
```
unset RISCV
make all DEVKIT=lc-mpfs
```
Note: The first time the build is run it can take a long time, as it also builds the RISC-V cross compiler toolchain. 

The output file contains the first stage bootloader, the root file system and a VFAT image containing the linux kernel, device tree blob & second stage bootloader. 
This can then be copied to an SD card. The option `DEVKIT=<devkit>` selects the correct device tree for the board.   

### Preparing an SD Card (for MPFS & LC-MPFS)
Add an SD card to boot your system (16 GB or 32 GB). If the SD card is auto-mounted, first unmount it manually.               
The following steps will allow you to check and unmount the card if required:

After inserting your SD card, use `dmesg` to check what your card's identifier is.
```
$ dmesg | egrep "sd|mmcblk"
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
        DO NOT pass this identifier to any of the commands listed here without being absolutely sure that your OS is not located here.       
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

### Programming an Image for the First Time
To automatically partition and format your SD card, in the top level of mpfs-linux-sdk, type:
```
$ sudo make DISK=/dev/sdX format-boot-loader
```
At this point, your system should be bootable using your new SD card. You can remove it from your PC
and insert it into the SD card slot on the HiFive Unleashed board, and then power-on the DEV-KIT.

### Preparing the eMMC (for Icicle kit)
If the HSS is not present in eNVM, using the y-modem loader, transfer the HSS to eNVM on the Icicle kit.      
Power on the board, and connect to UART0. Press a key to stop automatic boot. In the hss console, type `usbdmsc` to expose the emmc as a block device.          
Connect the board to your dev machine using J16, located beside the SD card slot.

Once this is complete, use `dmesg` to check what the drive identifier for the onboard eMMC is.
```
$ dmesg | egrep "sd|mmcblk"
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
        DO NOT pass this identifier to any of the commands listed here without being absolutely sure that your OS is not located here.       
        Check that the size of the card matches the dmesg output before continuing.     

Once sure of the drive identifier, use the following command to copy your Linux image to the board, replacing the X as appropriate:
```
$ sudo make DISK=/dev/sdX DEVKIT=icicle-kit-es format-icicle-image 
```

When the transfer has completed, press `CTRL+C` in the hss serial console to return to the hss console.                 
To load into Linux, type `boot` in the hss console. U-Boot and Linux will use MMUART1.

### Rebuilding the Linux Kernel
To rebuild your kernel or to change the machine being targeted, type the following from the top level directory of the polarfire-soc-buildroot-sdk:
```
$ make clean
$ make DEVKIT=<devkit>
```
Copy this newly built image to the SD card using the same method as before:
```
$ sudo make DISK=/dev/sdX format-boot-loader
```

The source for the device tree for boards are in `conf/dts/<devkit>.dts`.            
The configuration options used for the Linux kernel are in `conf/<devkit>_linux_<kernel-version>_defconfig`.

## Additional Reading
[Buildroot User Manual](https://buildroot.org/docs.html)    
[PolarFire SoC Yocto BSP](https://github.com/polarfire-soc/meta-polarfire-soc-yocto-bsp)    
[MPFS-DEV-KIT User Guide](doc/MPFS-DEV-KIT_user_guide.md)    
[LC-MPFS-DEV-KIT User Guide](doc/LC-MPFS-DEV-KIT_user_guide.md) 
[Kernel Documentation for Linux](https://www.kernel.org/doc/html/v5.4/)
