# Build instructions

1. Make sure that all [Prerequisite Packages](https://github.com/SDSP-github/polarfire-soc-buildroot-sdk#prerequisite-packages) are installed.

1. clone the repository. 
    ```` 
    git clone https://github.com/SDSP-github/polarfire-soc-buildroot-sdk.git
    cd polarfire-soc-buildroot-sdk
    git checkout master
    ```` 

1. Sync sub modules
    ````
    git submodule sync
    git submodule update --init --recursive
    ````
1. Build linux and UBoot images:
    ````
    unset RISCV
    make all DEVKIT=polarberry
    ````
1. check that the following files are created in the work directory
````
payload.bin             // UBoot image
polarberry.vfat.part    // Linux image
````

# Install UBoot and Linux images on PolarBerry

## Preparing system
1. Prepare your system and have these software ready for usage:
    
    1. [ExtraPutty](https://sourceforge.net/projects/extraputty/)
    1. [FTFP server](https://www.solarwinds.com/free-tools/free-tftp-server) 
1. Connect PolarBerry to PC via its 40 Pin serial connection (Please refer to PolarBerry user guide for detail)

## Inatsll UBoot into the PolarBerry board.
1. Power up PolarBerry and look at the serial output
1. When the HSS boots, press a key to cancel the boot process and use ym command to access to ymodem utility integrated into HSS.

1. Press 2 to init the eMMC board memory.
1. Press 3 to start ymodem transferring.
1. Start transferring "payload.bin" file to the board using ymodem protocol in your UART terminal software.
1. After the transfer has completed press 5 to write to the eMMC.
1. Press 6 to exit the ymodem utility once this has completed.
1. Use the "boot" command to boot the image (or do the power-cycle of the board).
1. When u-boot runs, wait while it will stop with error (It can't load linux on this step, it`s normal due to we have no linux installed yet)

## Install Linux into the PolarBerry board.
1. Connect the PolarBerry board via the Ethernet cable to the PC you are using.
1. Launch the TFTP server on your host computer, and place `payload.bin` and `polarberry-vfat.part` in the PS's TFTP directory.
1. Ensure that Uboot is started anв stopped and you have uboot's command prompt and need to write the GPT table on the eMMC (partitions has been set as an environment variable in the build process). To write GPT table in the eMMC flash, type: 
    ````
    gpt write mmc 0 ${partitions}
    ````
1. Setup u-boot for the TFTP transfer, type this commands:
    ````
    setenv autoload no
    setenv ipaddr <insert the board`s IP address> (You can choose the free IP address from the same subnetwork as PC IP address)
    setenv serverip <insert host`s computer IP address>
    ````
1. Receive u-boot into DDR at the address 0x90000000, run the following commands:
    ````
    tftp 0x90000000 payload.bin
    ````
1. Write uboot from the DDR to the eMMC (partition-1) at sector '0x2000' with size 0x957 sectors, run the followwing commands: 
    ````
    mmc write 0x90000000 0x2000 0x954
    ````
1. Receive VFAT file system image through the tftp into the DDR, run the following commands: 
    ````
    tftp 0x90000000 polarberry-vfat.part
    ````    
1. At the end of transfer you will see the received bytes count, you shall convert it into the number of 512 Byte sectors:
    * For example if the tftp says (which it should for this image): Bytes transferred = 92123136
    Then we have 92123136/512 = 179928 sectors, which we convert to 0x2BED8 as HEX
1. Write VFAT image from the DDR to the eMMC (partition-2) at sector 0x2800 with size 0x2BED8 sectors: run the following commands 
    ````
    mmc write 0x90000000 0x2800 0x2BED8
    ````
1. Power cycle your board, it should now boot straight to the linux login prompt
