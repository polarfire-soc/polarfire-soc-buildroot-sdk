# LC-MPFS-DEV-KIT User Guide

## Overview
The LC-MPFS-DEV-KIT consists of SiFive's U540 processor and Microchip’s PolarFire FPGA on a single board. The LC-MPFS-DEV-KIT is a reduced version of the HiFive Unleashed platform. The LC-MPFS-DEV-KIT enables users to create a Linux system running on the RISC-V core complex, with a large FPGA fabric accessible through the memory map. The PolarFire FPGA is shipped with a pre-configured bitstream which enables peripherals such as GPIO, UART, SPI, and I2C on the PolarFire FPGA fabric.

## Reference
Visit the following links for further reference reading materials.
### Recommended Reading
[RISC-V User-level ISA Specification](https://riscv.org/specifications/)     
[RISC-V Draft Privileged ISA Specification](https://riscv.org/specifications/privileged-isa/)     
[SiFive FU540-C000 User Manual](https://www.sifive.com/documentation/chips/freedom-u540-c000-manual/)     
[TU0844 Libero SoC PolarFire v2.2 Design Flow Tutorial](https://www.microsemi.com/document-portal/doc_download/1243632-tu0844-libero-soc-polarfire-v2-2-design-flow-tutorial)     
[HiFive Unleashed Getting Started Guide](https://www.microsemi.com/document-portal/doc_download/1243284-hifive-unleashed-getting-started-guide)   

### Reference
[PolarFire FPGA Documentation](https://www.microsemi.com/product-directory/fpgas/3854-polarfire-fpgas#documentation)     
[Libero SoC PolarFire Documentation](https://www.microsemi.com/product-directory/design-resources/3863-libero-soc-polarfire#documents)     
[FlashPro User Guide for PolarFire](https://www.microsemi.com/document-portal/doc_download/137626-flashpro-user-guide-for-polarfire)     
[FlashPro Express User Guide for PolarFire](https://www.microsemi.com/document-portal/doc_download/137627-flashpro-express-user-guide-for-polarfire)     
[PolarFire SoC Information](https://www.microsemi.com/product-directory/soc-fpgas/5498-polarfire-soc-fpga)         
[Schematics of LC-MPFS-DEV-KIT](https://www.microsemi.com/document-portal/doc_download/1244485-lc-mpfs-dev-kit-schematics) 

## Hardware Features
This section describes the features of the LC-MPFS-DEV-KIT hardware with the block diagram. 

The LC-MPFS-DEV-KIT consists of the following:
- SiFive Freedom U540 SoC
- 8 GB DDR4 with ECC
- Gigabit Ethernet port
- 32 MB Quad SPI flash connected to U540 SoC
- 1 GB SPI flash MT25QL01GBBB8ESF-0SIT connected to the PolarFire FPGA System controller
- MicroSD card for removable storage
- 300 kLE PolarFire FPGA in an FCG1152 package (MPF300T-1FCG1152)

![LC-MPFS-DEV-KIT Board](images/LC-MPFS-DEV-KIT.jpg)

## System Setup and Prerequisites
### Libero SoC Design Suite
Libero SoC design suite version 12.3 or later is needed to use the Libero project provided with the LC-MPFS-DEV-KIT.

Download the Libero SoC design suite v12.3 for Windows [here](https://www.microsemi.com/document-portal/doc_download/1244618-download-libero-soc-v12-3-for-windows).             
Download the Libero SoC design suite v12.3 for Linux [here](https://www.microsemi.com/document-portal/doc_download/1244619-download-libero-soc-v12-3-for-linux).

Along with the purchase of the LC-MPFS-DEV-KIT, customers are eligible for one platinum floating license for the Libero SoC Design Suite. Write to [mi-v-embeddedpartner@microchip.com](mi-v-embeddedpartner@microchip.com) with the subject “License Request <your organization name>” and include the 12-digit MAC ID of the two linux machines/PCs in your email.

### Solution Versions
The latest revisions of the Libero project and bitstream files are available on the [Microsemi](http://soc.microsemi.com/download/rsc/?f=Libero_Project_LC-MPFS-DEV-KIT) Website.

## Board Setup
The following instructions guide you to set up the LC-MPFS-DEV-KIT.

1. Switch off the power button on the LC-MPFS-DEV-KIT.

![Power Button](images/Power_On.PNG)

2. Set the pins in the DIP switch to select MSEL of 1011 (MSEL2 = 0).

![DIP Switch Setting](images/DIP_Switch.PNG)

3. To prepare the SD-card programmed with the bootloader and Linux images, see Building and Loading the Linux Image.

4. Insert the SD card into the SD card slot J10.
5. Connect the micro USB cable from J7 to the Host PC. The USB connector has two serial interfaces: the higher index serial port is used for the Linux serial console and the lower index serial port is used for JTAG debug.

![USB Connector](images/USB_Connector.PNG)

6. Update the PolarFire FPGA with the FPGA bitstream provided in Software Versions. See Programming the FPGA Using FlashPro for steps to program the FPGA.
7. The LC-MPFS-DEV-KIT is now configured as seen in Libero Block Diagram.
8. Ensure the push-button is switched on, connect the power supply to the board, and slide the power switch SW3 as shown in the following figure.

![Power on the Device](images/Power_On.PNG)

9. Configure the serial terminal in the Host PC for 115200 baud, 8 data bits, no stop bits, no parity, and no flow control. Push reset button (near the power button) on the LC-MPFS-DEV-KIT.
10. The Linux boot process can be observed on a serial terminal as shown in the following image.

![Linux Booting Messages on the Terminal](images/Linux_Booting.PNG)

Enter the following commands on the serial terminal.
```
mmc_spi 1 20000000 0
mmc read 0x80000000 0x1000 0x10000
```

![Serial Terminal](images/Serial_Command.PNG)

12. Now, boot linux with the the following command:
```
go 0x80000000
```
13. You should see linux boot. Enter the following login credentials.
```
Buildroot login: root

Password: microchip
```
The console should now look as shown in the following figure.

![Linux Booting Credentials](images/Booting_Credentials.PNG)

14. You should now see an LED flashing alongside PWM0_0 on the evaluation board.

![LED Flash On](images/LED.PNG)

## Programming Guide
The following sections explain the step-by-step procedure to download the FPGA bitstream onto the PolarFire FPGA. 
### Programming the FPGA using FlashPro
#### Windows Environment 
To program the PolarFire SoC device with the .job programming file (using FlashPro in Windows environment), perform the following steps. The link to the .job file is given in Software Versions.

1. Ensure that the jumpers J13, J21, J28, and J31 are plugged in.
Note: The power supply switch must be switched off while making the jumper connections.
2. Connect the power supply cable to the J3 connector on the board.
3. Connect the FlashPro4 to a PC USB port and to the connector J24 (FP4 header) of the LC-MPFS-DEV-KIT hardware.
4. Power on the board using the SW3 slide switch.
5. On the host PC, launch the FlashPro Express software.
6. Click New or select New Job Project from FlashPro Express Job from Project menu to create a new job project, as shown in the following figure.
7. Enter the following in the New Job Project from FlashPro Express Job dialog box:
   - Programming job file: Click Browse, and navigate to the location where the .job file is located and select the file. The default location is `<download_folder>\mpf_ac466_eval\splash_df\Programming_Job`.
   - FlashPro Express job project location: Click Browse and navigate to the location where you want to save the project.

8. Click OK. The required programming file is selected and ready to be programmed in the
9. The FlashPro Express window appears as shown in the following Confirm that a programmer number appears in the Programmer field. If it does not, confirm the board connections and click Refresh/Rescan Programmers.
10. Click RUN. When the device is programmed successfully, a RUN PASSED status is displayed as shown in the following figure. See Running the Demo, page 31 to run the demo.

#### Linux Environment 

To program the PolarFire SoC device with the .job programming file (using FlashPro5 programmer in Linux environment), perform the following steps. The link to the .job file can be found in Software Versions.

1. Ensure that the jumpers J13, J21, J28, and J31 are plugged in.
Note: The power supply switch must be switched off while making the jumper connections.
2. Connect the power supply cable to the J3 connector on the board.
3. Connect the FlashPro5 to a PC USB port and to the connector J24 (FP4 header) of the board.
4. Power on the board using the SW3 slide switch.
5. On the host PC, launch the FlashPro Express (FP Express) software.
6. From the Project menu, choose Create Job Project from Programming Job.
7. Click Browse to load the Programming Job File and specify your FlashPro Express job project location. Click OK to continue.
8. Save the FlashPro Express job project.
9. Set the Programming Action in the dropdown menu to PROGRAM.
10. Click RUN. Detailed individual programmer and device status information appears in the Programmer List. Your programmer status (PASSED or FAILED) appears in the Programmer Status Bar.
See the [FlashPro Express User Guide](https://www.microsemi.com/document-portal/doc_download/137627-flashpro-express-user-guide-for-polarfire) for more information.

### Building and Loading the Linux Image
[folder](.)
see Building a Yocto Image] or [Building an image using Buildroot]()
This section describes the procedure to build the Linux boot image and loading it into an SD card using
Buildroot.

#### Buildroot

##### Supported Platforms
This document assumes you are running on a modern Linux system. The process documented here was tested using Ubuntu 18.04.3 LTS. It should also work with other Linux distributions if the equivalent prerequisite packages are installed.

##### Install Prerequisite Packages
Before starting, use the `apt` command to install prerequisite packages:
```
sudo apt install autoconf automake autotools-dev bc bison \
build-essential curl flex gawk gdisk git gperf libgmp-dev \
libmpc-dev libmpfr-dev libncurses-dev libssl-dev libtool \
patchutils python screen texinfo unzip zlib1g-dev libblkid-dev \
device-tree-compiler mtools
```
##### Build and Checkout Code
The following commands build the system to a work/sub-directory.
```
$ git clone https://github.com/Microsemi-SoC-IP/mpfs-linux-sdk.git
$ cd mpfs-linux-sdk
$ git checkout master
$ git submodule update --init --recursive
$ unset RISCV
$ make all DEVKIT=lc-mpfs
```
Note: The first time the build is run it can take a long time, as it also builds the RISC-V cross compiler toolchain. 

The output file `work/bbl.bin` contains the bootloader (RISC-V pk/bbl), the Linux kernel, and the device tree blob. A GPT image is also created, with U-Boot as the first stage boot loader that can be copied to an SD card. 
The option `DEVKIT=lc-mpfs` selects the correct device tree for the board.   

#### Yocto
This section describes the installation procedures to build the Linux boot image using Yocto.
Yocto is an open source project for creating custom embedded Linux distributions. 'Poky' refers to Yocto’s
implementation of a customized Linux distribution. It is the starting point to create a custom distribution
for your hardware target by leveraging Yocto.
BitBake is the Python-based build tool available in Poky. The tool parsesrecipe files and performsthe various
build tasks. To speed up repeated builds, BitBake caches downloads and build results. While the first full
build of a system image can take several hours, the following build times easily collapse down to minutes.
Microchip LC-MPFS-DEV-KIT source is a minimal Yocto (Poky) on top of [meta RISC-V](https://github.com/riscv/meta-riscv) layer which provides
new disk image targets for the kit. Using this source, you will be able to:
- Build predefined disk images for Microchip LC-MPFS-DEV-KIT development board
- Build bootloader binaries (u-boot.bin)
- Build Device Tree Binary (DTB)
- Build Linux kernel (bbl.bin which includes dtb and kernel image)
- Build Rootfs (aloelite-image-aloelite.tar.gz)
- Easily modify disk partition layout
  
For more information on Yocto and BitBake, see Recommended Reading.

##### Install Prerequisite Packages
Before starting, use the `apt` command to install prerequisite packages on Ubuntu 18.04:
```
sudo apt install gawk wget git-core diffstat unzip texinfo gcc-multilib \
build-essential chrpath socat cpio python python3 python3-pip \
python3-pexpect xz-utils debianutils iputils-ping libsdl1.2-dev \
xterm python3-distutils
```
Or use `yum` to install packages in CentOS. Extra packages for Enterprise Linux (that is, epel-release) 
is a collection of packages from Fedora built on RHEL/CentOS for easy installation of packages not 
included in enterprise Linux by default. These packages must be installed separately. 
The makecache command consumes additional metadata from epel-release.
```
sudo yum install -y epel-release
sudo yum makecache
sudo yum install gawk make wget tar bzip2 gzip python unzip perl \
patch diffutils diffstat git cpp gcc gcc-c++ glibc-devel texinfo \
chrpath socat perl-Data-Dumper perl-Text-ParseWords perl-Thread-Queue \
python34-pip xz which SDL-devel xterm
sudo pip3 install GitPython jinja2
```
#### Build Code
The following commands clone the Yocto source for the LC-MPFS-DEV-KIT from Github and sets the working
directory to the project source as shown in the following figure.
```
git clone https://github.com/Microsemi-SoC-IP/mpfs-linux-apps.git
cd mpfs-linux-apps/
```
![Cloning Yocto Source]()
To set up the build environment, enter the following command.
```
source setupenv.sh
```
This command redirects to `$BUILDDIR (<path>/ mpfs-linux-apps/build)` as shown in the following figure.
![BUILDDIR]()
To build disk images, use the following command.
```
./build_all.sh
```
If the build generation is successful, all the available build fragments(including disk images) will be available
in `$BUILDDIR/aloelite_images/(<path>/ mpfs-linux-apps/build/aloelite_images)`. The
disk images generated (and to be written to the USB card) are `u-boot.bin`, `bbl.bin` and
`aloelite-image-aloelite.tar.gz`

### Preparing an SD Card with Buildroot or Yocto
Add an SD card to boot your system (16 GB or 32 GB). If the SD card is auto-mounted, first unmount it manually.               
The following steps will allow you to check and unmount the card if required:

After inserting your SD card, use dmesg to check what your card's identifier is.
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
and insert it into the SD card slot on the HiFive Unleashed board, and then power-on the LC-MPFS-DEV-KIT.

### Rebuilding the Linux Kernel with Buildroot
To rebuild your kernel, type the following from the top level of mpfs-linux-sdk:
```
$ rm -rf work/linux/
$ make
```
Copy this newly built image to the SD card using the same method as before:
```
sudo make DISK=/dev/sdX format-boot-loader
```
### Switching machines with Buildroot
To change the machine being targeted, type the following from the top level of mpfs-linux-sdk:
```
$ rm -rf work/linux/ work/riscvpc.dtb
$ make DEVKIT=lc-mpfs
```
Copy this newly built image to the SD card using the same method as before:
```
sudo make DISK=/dev/sdX format-boot-loader
```

The source for the device tree for HiFive Unleashed Expansion board is in `conf/lc-mpfs.dts`.           
The configuration options used for the Linux kernel are in `conf/linux_defconfig`.
Currently, the Microsemi PolarFire Linux SDK for the HiFive Unleashed platform uses a modification to
the RISC-V Bootloader startup code to pass in the device tree blob (see `riscv-pk/machine/mentry.S` for
the modification.)

### Partitioning and Formatting SD Card for Yocto
To automatically partition and format your SD card, from the `$BUILDDIR/aloelite_images/(<path>/mpfs-linux-apps/build/aloelite_images)`, enter the following commands.
```
cd $BUILDDIR/aloelite_images:
sudo make DISK=/dev/path-to-sdcard-device format-boot-loader
```
Now, the LC-MPFS-DEV-KIT should be bootable using your new SD card. You can remove it from your PC
and insert it into the SD card slot on the `LC-MPFS-DEV-KIT`.


### Booting Linux and Accessing LSRAM with Yocto
This section describes details on booting the Linux image using the SD card and prebuilt images in Yocto.
On successful linux boot using the bootable SD card, the Linux prompt is displayed asshown in the following figure.                
![Successful Linux Boot]()               
Type 'root' and login. No password is required.

##### Booting the Linux Image Using Prebuilt Images
On successful cloning of the Github Yocto source, the prebuilt images are downloaded at:
`<path>/mpfs-linux-apps/lc_mpfs_dev_kit_prebuilt_images`
Navigate to the prebuilt images location as shown in the following figure using the command:
```
cd <path>/mpfs-linux-apps/lc_mpfs_dev_kit_prebuilt_images
```
![Linux Prebuilt Images]()                
To copy the images to SD card, use the following command.
```
sudo make DISK=/dev/path-to-sdcard-device format-boot-loader
```
#### Running Applications in Linux with Yocto
##### Executing gpio_led_blink
Run the following command to turn on LED4 and LED5 on the LC-MPFS-DEV-KIT. These two LEDs are
interfaced to `gpio0` and `gpio1` in the FPGA design. The application `gpio_led_blink` and the source file
`gpio_led_blink.c` are available in the apps folder.
```
cd apps
./gpio_led_blink #
```
Choose any number between 1 to 3 to access one or both the LEDs.
• Enter 1 to toggle both LEDs at a time
• Enter 2 to toggle one LED at a time
• Enter 3 to exit

##### Executing uio_lsram_check
This application writes/reads to/from LSRAM and uses Linux UIO framework. The FPGA design has AXI_MS0
and AXI_MS1 slave devices. AXI_MS0 is interfaced to one LSRAM block and AXI_MS1 is interfaced to 8
LSRAM blocks through the AXI4 Interconnect.
The application `uio_lsram_check` and the source file `uio_lsram_check.c` are available in the
apps folder.
Run the following command to access any of the LSRAM blocks:
```
./uio_lsram_check #
```
Choose from the following options to access a particular LSRAM.
- 0 for lsram1_0
- 1 for lsram1_1
- 2 for lsram1_2
- 3 for lsram1_3
- 4 for lsram1_4
- 5 for lsram1_5
- 6 for lsram1_6
- 7 for lsram1_7
- 8 for lsram0
- 9 to exit application
-or example, the following sequence of commands are available once you enter option 1 to access lsram1_1.
```
#1
lsram1 block 1 (lsram1_1) is interfaced to AXI_MS1 through AXI4 Interconnect that is mapped to userspace.
#Enter a digit between 0 to 4 to write a pattern into lsram or
# Enter 5 to initial 4k memory read or
# Enter 6 to 64k full memory read or
# Enter 7 to goto main menu
```















### FPGA Design in Libero
The Libero project interfaces the PolarFire FPGA with the U540 SoC through the ChipLink interface. The FPGA fabric is instantiated with the ChipLink to AXI bridge, while peripherals — GPIO, MMUART, SPI, and I2C — are connected to it. The ChipLink interface uses 125 MHz clock and the AXI interface uses 75 MHz clock.
The high-level block diagram of the Libero project implemented on the PolarFire FPGA is as shown in the following figure.

![LC-MPFS-DEV-KIT Board Block Diagram](images/LC_Block_Diagram.png)

#### Memory Map and GPIO Pinout

The IP cores on the LC-MPFS-DEV-KIT are accessible from the RISC-V U540 memory map as listed in the following table. 

| Peripheral | Start Address | End Address | Interrupt |
| --- | --- | --- | --- |
| GPIO | 0x2000103000 | 0x2000104000 | 7 |
| SPI_0 | 0x2000107000 | 0x2000108000 | 34 |
| I2C_0 | 0x2000100000 | 0x2000101000 | 35 |
| MMUART_0 | 0x2000104000 | 0x2000105000 | |
| SRAM | 0x2030000000 | 0x203FFFFFFF | |
| AXI_MS0 | 0x2030000000 | | |
| AXI_MS1 | 0x2600000000 | 0x263FFFFFFF | |

#### Memory Map
The GPIO implemented in the design is pinned out as a starting point for your custom design implementation. The details of the GPIO is listed in GPIO Pinout.

| GPIO | Function |
| --- | --- |
| 0 | LED4 |
| 1 | LED5  |
| 2 | Not connected |
| 3 | Not connected |
| 4 | SWITCH 9 |
| 5 | SWITCH 10 |
| 6 | Not connected |
| 7 | USB1 reset |

## Technical Support

For technical queries, email [mi-v-embeddedpartner@microchip.com](mi-v-embeddedpartner@microchip.com). Microsemi’s technical support team will create a ticket, address the query, and track it to completion.
  
