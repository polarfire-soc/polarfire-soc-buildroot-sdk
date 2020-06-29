# Booting Linux on the icicle kit using TFTP
Trivial File Transfer Protocol (TFTP) enables booting Linux over the network on an icicle kit. The server is installed on the development machine & the U-Boot TFTP client can then be used to transfer kernel/ramdisk/device tree to the icicle kit.

## Installing the tftp server

On Ubuntu 18.04 LTS the following steps apply. First install the prerequisite packages:
```
sudo apt update; sudo apt install tftp-hpa tftpd-hpa xinetd
```
Then create a config file for xinetd in `/etc/xinetd.d/tftp`:
```
service tftp
{
protocol        = udp
port            = 69
socket_type     = dgram
wait            = yes
user            = nobody
server          = /usr/sbin/in.tftpd
server_args     = /tftpboot
disable         = no
}
```
Create the tftp server directory & restart the xinetd daemon:
```
sudo mkdir /tftpboot/
sudo chmod -R 777 /tftpboot/
sudo chown -R nobody /tftpboot/
sudo service xinetd restart
```

## Booting via TFTP

1. Build the linux image using the PolarFire SoC Buildroot SDK.

2. Create a symbolic link from the tftp directory, inserting the full path to the PolarFire SoC Buildroot SDK:
```
ln -s <path to polarfire-soc-buildroot-sdk>/work/fitImage.fit /tftpboot/tftpImage.fit
```

3. Connect to the icicle kit over UART and connect to the network using the ethernet port J2. 

4. Wait for the U-Boot prompt. When prompted, press a key to cancel automatic boot.

5. Set configure the board for the TFTP transfer:
```
setenv serverip <development_machine_ip_address>
setenv ipaddr <icicle_board_ip_address>
setenv fileaddr 0x90000000
```

6. Transfer the fit image to the board:
```
tftp ${fileaddr} fitImage.fit
```

7. Boot using the fit image that has been transferred to the board:
```
bootm ${fileaddr}
```
