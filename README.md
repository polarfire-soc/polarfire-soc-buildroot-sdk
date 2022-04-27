# Microchip PolarFire SoC Linux Software Development Kit

This repository builds a command line only RISC-V Linux image for the Microchip PolarFire SoC Development Boards.
It first will build the GNU cross-compilation toolchain for RISC-V, which will be installed in the `toolchain/` subdirectory. This toolchain is then used to build a Linux image consisting of the kernel, a Busybox based root file system and the necessary bootloaders for each development platform.

Currently the following development platforms are supported:

- [MPFS-DEV-KIT](https://github.com/polarfire-soc/polarfire-soc-documentation/blob/master/boards/mpfs-dev-kit/MPFS-DEV-KIT_user_guide.md) (HiFive Unleashed Expansion Board)
- Icicle Kit (Engineering Sample) (Requires minimum FPGA design: [v2021.08](https://github.com/polarfire-soc/icicle-kit-reference-design/releases/tag/2021.08). Designs prior to this release use a different memory map and will fail to boot.)

The complete User Guides for each development platform, containing board and boot instructions, are available in the [polarfire-soc documentation repository](https://github.com/polarfire-soc/polarfire-soc-documentation).

## Building Linux Using Buildroot

This section describes the procedure to build the Linux boot image and load it onto an SD card, eMMC or external QSPI flash memory using Buildroot. Please check the [Supported Build Hosts](#supported-build-hosts) and the [Prerequisite Packages](#prerequisite-packages) before continuing.

### Build instructions

The following commands checkout the Software Development Kit (SDK) in a new directory:

```bash
git clone https://github.com/polarfire-soc/polarfire-soc-buildroot-sdk.git
cd polarfire-soc-buildroot-sdk
git checkout master
```

Before building for the first time (or if updating to the latest version), the contents of the sub-modules must be acquired:

```bash
git submodule sync
git submodule update --init --recursive
```

Then the Linux image can be built in the `work` sub-directory:

```bash
unset RISCV
make all DEVKIT=icicle-kit-es
```

The `DEVKIT` option can be used to set the target board for which linux is built, and if left blank it will default to `DEVKIT=icicle-kit-es`.

The following table details the available targets:

| `DEVKIT` | Board Name |
| --- | --- |
| `DEVKIT=mpfs` | MPFS-DEV-KIT (HiFive Unleashed Expansion Board) |
| `DEVKIT=icicle-kit-es` | Icicle Development Kit with engineering sample silicon |
| `DEVKIT=icicle-kit-es-amp` | Icicle Development Kit with engineering sample silicon running in AMP mode |

The `icicle-kit-es-amp` target can be used to build the Icicle Development using a Linux + FreeRTOS AMP configuration demo. Please see the [Asymmetric Multiprocessing (AMP)](https://github.com/polarfire-soc/polarfire-soc-documentation/blob/master/asymmetric-multiprocessing/amp.md) documentation for further information.

To boot Linux on your board using this image, see: [Loading the Image onto the Target](#Loading-the-Image-onto-the-Target).

Note: The first time the build is run it can take a long time, as it also builds the RISC-V cross compiler toolchain.

The output file contains the first stage bootloader, the root file system and an image containing the linux kernel, device tree blob & second stage bootloader.  
The source for the device tree for the MPFS DEV-KIT (HiFive Unleashed Expansion Board) board is available in `conf/mpfs/mpfs.dts`.  
For other boards, the source is located in `linux/arch/riscv/boot/dts/microchip`.  
The configuration options used for the Linux kernel are in `linux/arch/riscv/configs/<devkit>_defconfig`.  
`conf/<devkit>` contains the U-Boot and buildroot initramfs config files.  

### Rebuilding the Linux Image

If you need to rebuild your image or change the board being targeted, type the following from the top level directory of the polarfire-soc-buildroot-sdk:

```bash
$ make clean
$ make all DEVKIT=<devkit>
```

## Loading the Image onto the Target

The instructions for the [eMMC on the Icicle Kit can be found here](#Preparing-the-eMMC-for-the-Icicle-Kit),for the [QSPI on the Icicle Kit here](#Preparing-an-external-QSPI-flash-memory-for-the-Icicle-Kit),for the [SD card on the Icicle Kit here](#Preparing-an-SD-Card-for-the-Icicle-Kit), and for the [the MPFS here](#Preparing-an-SD-Card-for-MPFS).

### Preparing the eMMC for the Icicle Kit

If the HSS is not present in eNVM, using the y-modem loader, transfer the HSS to eNVM on the Icicle kit.  
Connect to UART0 (J11), and power on the board. Settings are 115200 baud, 8 data bits, 1 stop bit, no parity, and no flow control.  
Press a key to stop automatic boot. In the HSS console, type `mmc` to select the interface and type `usbdmsc` to expose the eMMC as a block device.  
Connect the board to your host PC using J16, located beside the SD card slot.

Once this is complete, on the host PC, use `dmesg` to check what the drive identifier for the onboard eMMC is.

```bash
$ dmesg | egrep "sd|mmcblk"
```

The output should contain a line similar to one of the following lines:

```bash
[85089.431896] sd 6:0:0:2: [sdX] 31116288 512-byte logical blocks: (15.9 GB/14.8 GiB)
[51273.539768] mmcblkX: mmc0:0001 EB1QT 29.8 GiB
```

`sdX` or `mmcblkX` is the drive identifier that should be used in the following commands, where `X` should be replaced with the specific character from the output of the previous command.  
For these examples the identifier `sdX` is used.

**WARNING:**
        The drive with the identifier `sda` is the default location for your operating system.  
        DO NOT pass this identifier to any of the commands listed here without being absolutely sure that your OS is not located here.  
        Check that the size of the card matches the dmesg output before continuing.  

Once sure of the drive identifier, use the following command to copy your Linux image to the board, replacing the X and `<devkit>` as appropriate:

```bash
$ sudo make DISK=/dev/sdX DEVKIT=<devkit> format-icicle-image
```

When the transfer has completed, press `CTRL+C` in the HSS serial console to return to the HSS console.  
To boot into Linux, type `boot` in the HSS console. U-Boot and Linux will use UART1. When Linux boots, log in with the username `root`. There is no password required.  

If you are using the `icicle-kit-es-amp` machine, attach to UART3 to observe its output.

Similarly, a root file system can be written to the eMMC using

```bash
$ sudo make DISK=/dev/sdX DEVKIT=<DEVKIT> format-rootfs-image
```

### Preparing an SD Card for the Icicle Kit

Insert an SD Card (16 GB or 32 GB) into the card reader of your host PC. If the SD card is auto-mounted, first unmount it manually.  
The following steps will allow you to check and unmount the card if required:

After inserting your SD card, on the host PC, use `dmesg` to check what your card's identifier is.

```bash
$ dmesg | egrep "sd|mmcblk"
```

The output should contain a line similar to one of the following lines:

```bash
[85089.431896] sd 6:0:0:2: [sdX] 31116288 512-byte logical blocks: (15.9 GB/14.8 GiB)
[51273.539768] mmcblkX: mmc0:0001 EB1QT 29.8 GiB
```

`sdX` or `mmcblkX` is the drive identifier that should be used in the following commands, where `X` should be replaced with the specific character from the output of the previous command.  
For these examples the identifier `sdX` is used.

**WARNING:**
        The drive with the identifier `sda` is the default location for your operating system.  
        DO NOT pass this identifier to any of the commands listed here without being absolutely sure that your OS is not located here.  
        Check that the size of the card matches the dmesg output before continuing.  

Next check if this card is mounted:

```bash
$ mount | grep sdX
```

If any entries are present, then run the following. If not then skip this command:

```bash
$ sudo umount /dev/sdX
```

The SD card should have a GUID Partition Table (GPT) rather than a Master Boot Record (MBR) without any partitions defined.

#### Programming an Image for the First Time

To automatically partition and format your SD card, in the top level of polarfire-soc-buildroot-sdk, type:

```bash
$ sudo make DISK=/dev/sdX DEVKIT=icicle-kit-es format-icicle-image
```

At this point, your SD card should be ready to boot Linux.  
You can remove it from your PC and insert it into the SD card slot on the Icicle kit, and then power-on the board.  
Connect to UART0 (J11) for the HSS and UART1 (also J11) for U-Boot and Linux. Settings are 115200 baud, 8 data bits, 1 stop bit, no parity, and no flow control.  
When Linux boots, log in with the username `root`. There is no password required.  

If you are using the `icicle-kit-es-amp` machine, attach to UART3 to observe its output.

Similarly, a root file system can be written to the SD card using

```bash
$ sudo make DISK=/dev/sdX DEVKIT=<DEVKIT> format-rootfs-image
```

### Preparing an external QSPI flash memory for the Icicle Kit

This section explains how to prepare the Icicle Kit to boot from an external flash memory device using QSPI.

The Icicle Kit supports booting Linux from an external QSPI flash memory connected to the Raspberry Pi 4 Interface (J26) on an Icicle Kit.

For more information on QSPI support on the Icicle Kit, please refer to the [booting from QSPI](https://github.com/polarfire-soc/polarfire-soc-documentation/tree/master/boards/mpfs-icicle-kit-es/booting-from-qspi/booting-from-qspi.md) documentation.

Connect to UART0 (J11), and power on the board. Settings are 115200 baud, 8 data bits, 1 stop bit, no parity, and no flow control.

Press a key to stop automatic boot. In the HSS console, type `qspi` to select the QSPI interface and then type `usbdmsc` to expose the QSPI flash memory device as a block device.

Connect the board to your host PC using J16, located beside the SD card slot.

Once this is complete, on the host PC, use `dmesg` to check what the drive identifier for the QSPI flash memory device is.

```bash
$ dmesg | egrep "sd"
```

The output should contain a line similar to one of the following lines:

```bash
[114353.477108] sd 11:0:0:0: [sdX] 65536 2048-byte logical blocks: (134 MB/128 MiB)
[114353.477111] sd 11:0:0:0: [sdX] Write Protect is off
[114353.477471] sd 11:0:0:0: [sdX] Mode Sense: 00 00 00 00
```

`sdX` is the drive identifier that should be used in the following commands, where `X` should be replaced with the specific character from the output of the previous command.

**WARNING:**
        The drive with the identifier `sda` is the default location for your operating system.  
        DO NOT pass this identifier to any of the commands listed here without being absolutely sure that your OS is not located here.    

Once sure of the drive identifier, use the following command to copy your Linux image to the external QSPI flash memory device, replacing the X and <devkit> as appropriate:

```bash
$ sudo make DISK=/dev/sdX DEVKIT=<devkit> format-icicle-image-flash
```

When the transfer has completed, press CTRL+C in the HSS serial console to return to the HSS console.

Wait for the image transfer to complete. A progress bar will be shown in the HSS serial console.

To boot into Linux, type boot in the HSS console. U-Boot and Linux will use UART1. When Linux boots, log in with the username root. There is no password required.

If you are using the icicle-kit-es-amp machine, attach to UART3 to observe its output.

### Preparing an SD Card for MPFS

Insert an SD Card (16 GB or 32 GB) into the card reader of your host PC. If the SD card is auto-mounted, first unmount it manually.  
The following steps will allow you to check and unmount the card if required:

After inserting your SD card, on the host PC, use `dmesg` to check what your card's identifier is.

```bash
$ dmesg | egrep "sd|mmcblk"
```

The output should contain a line similar to one of the following lines:

```bash
[85089.431896] sd 6:0:0:2: [sdX] 31116288 512-byte logical blocks: (15.9 GB/14.8 GiB)
[51273.539768] mmcblkX: mmc0:0001 EB1QT 29.8 GiB
```

`sdX` or `mmcblkX` is the drive identifier that should be used in the following commands, where `X` should be replaced with the specific character from the previous command.  
For these examples the identifier `sdX` is used.

**WARNING:**
        The drive with the identifier `sda` is the default location for your operating system.  
        DO NOT pass this identifier to any of the commands listed here without being absolutely sure that your OS is not located here.  
        Check that the size of the card matches the dmesg output before continuing.  

Next check if this card is mounted:

```bash
$ mount | grep sdX
```

If any entries are present, then run the following. If not then skip this command:

```bash
$ sudo umount /dev/sdX
```

The SD card should have a GUID Partition Table (GPT) rather than a Master Boot Record (MBR) without any partitions defined.

#### Programming an Image for the First Time (MPFS)

To automatically partition and format your SD card, in the top level of polarfire-soc-buildroot-sdk, type:

```bash
$ sudo make DISK=/dev/sdX DEVKIT=<DEVKIT> format-boot-loader
```

At this point, your SD card should be ready to boot Linux.  
You can remove it from your PC and insert it into the SD card slot on the HiFive Unleashed board, and then power-on the DEV-KIT.  
Connect to UART1 (J7) for the fsbl, U-Boot and Linux. Settings are 115200 baud, 8 data bits, 1 stop bit, no parity, and no flow control.  
When Linux boots, log in with the username `root`. There is no password required.  
Similarly, a root file system can be written to the SD card using:

```bash
$ sudo make DISK=/dev/sdX DEVKIT=<DEVKIT> format-rootfs-image
```

## Supported Build Hosts

This document assumes you are running on a modern Linux system. The process documented here was tested using Ubuntu 20.04/18.04 LTS.  
It should also work with other Linux distributions if the equivalent prerequisite packages are installed.  

### Prerequisite Packages

#### Ubuntu

Before starting, use the `apt` command to install prerequisite packages:

```bash
sudo apt install autoconf automake autotools-dev bc bison build-essential curl \
flex gawk gdisk git gperf libgmp-dev libmpc-dev libmpfr-dev libncurses-dev \
libssl-dev libtool patchutils python screen texinfo unzip zlib1g-dev \
libblkid-dev device-tree-compiler libglib2.0-dev libpixman-1-dev mtools \
linux-firmware rsync python3 libexpat1-dev wget cpio xxd dosfstools \
python3-pip libyaml-dev libelf-dev zlib1g-dev xutils-dev libc6-dev
```

For Ubuntu 22.04, replace `python` with `python2` in the above command.

Install the python library `kconfiglib`. Without this the Hart Software Services (HSS) will fail to build with a genconfig error.

```bash
sudo pip3 install kconfiglib
```

## Known Issues

### U-Boot Error: "Can't set block device" or Linux "Error: Partition(s) 1, 2, 3 on /dev/sdX have been written, but we have been unable to inform the kernel of the change"

This error is caused by auto mounting of the SD/onboard eMMC, preventing the image being written correctly to the disk. To fix this, install dconf-editor and disable automounting of the SD card.

Install dconf-editor:

```bash
sudo apt install dconf-editor
```

Run the program:

```bash
dconf-editor
```

Navigate to `org/gnome/desktop/media-handling` and turn off auto mount.  
Now you should be able to run the `format-icicle-image` command without any issues.

### "Error: Could not find bootloader partition for /dev/sdX"

This problem may occur when writing to a new SD card, or after deleting all partitions using GParted or similar.  
If you encounter this problem, simply rerun the `format-icicle-image` make command and the image should be written correctly to the disk.

## Additional Reading

[Buildroot User Manual](https://buildroot.org/docs.html)  
[PolarFire SoC Yocto BSP](https://github.com/polarfire-soc/meta-polarfire-soc-yocto-bsp)  
[MPFS-DEV-KIT User Guide](doc/MPFS-DEV-KIT_user_guide.md)  
[Kernel Documentation for Linux](https://www.kernel.org/doc/html/v5.12/)  
[Asymmetric Multiprocessing Documentation](https://github.com/polarfire-soc/polarfire-soc-documentation/blob/master/asymmetric-multiprocessing/amp.md)  
