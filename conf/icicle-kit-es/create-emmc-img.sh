#!/bin/bash

emmc_file_name=$1
fit_image_name=$2
boot_script_name=$3
payload_name=$4
mount_point=$5

dd if=/dev/zero of=${emmc_file_name} bs=512 count=52240

/sbin/sgdisk -Zo  \
    --new=1:2048:3248 --change-name=1:uboot --typecode=1:21686148-6449-6E6F-744E-656564454649 \
    --new=2:4096:52206 --change-name=2:root --typecode=2:0FC63DAF-8483-4772-8E79-3D69D8477DE4 \
    ${emmc_file_name}

loop_device=$(losetup --find --show ${emmc_file_name} --partscan)

dd if=${payload_name} of=${loop_device}p1

mkfs.ext4 ${loop_device}p2

mount ${loop_device}p2 ${mount_point}
cp ${fit_image_name} ${mount_point}
cp ${boot_script_name} ${mount_point}
umount ${mount_point}

losetup --detach ${loop_device}