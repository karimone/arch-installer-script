#! /bin/bash

# TODO: get from config file
name="karim"
hostname="bradbury"

echo "Karim's Gorjux Arch configuration"

# Set date time
ln -sf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
hwclock --systohc

# Set locale to en_US.UTF-8 UTF-8
sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Set hostname
echo "${hostname}" >> /etc/hostname
echo "127.0.1.1 ${hostname}.localdomain  ${hostname}" >> /etc/hosts

# Set root password
passwd

# Install bootloader
# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch

# MBR Instructions
grub-install --target=i386-pc /dev/sda 
grub-mkconfig -o /boot/grub/grub.cfg

# Create new user
useradd -m -G wheel,power,input,storage,uucp,network -s /usr/bin/zsh $name
sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
echo "Set password for new user ${name}"
passwd $name

# Setup display manager
# systemctl enable sddm.service

# Enable services
systemctl enable NetworkManager.service

# disable the beep
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;

