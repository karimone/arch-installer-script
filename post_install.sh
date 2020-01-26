#! /bin/bash

echo "Karim's Gorjux Arch configuration"

# Set date time
ln -sf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
hwclock --systohc

# Set locale to en_US.UTF-8 UTF-8
sed -i '/en_US.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# Set hostname
echo "bradbury" >> /etc/hostname
echo "127.0.1.1 bradbury.localdomain  bradbury" >> /etc/hosts

# Set root password
passwd

# Install bootloader
# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch

# MBR Instructions
grub-install --target=i386-pc /dev/sdX
grub-mkconfig -o /boot/grub/grub.cfg

# Create new user
useradd -m -G wheel,power,iput,storage,uucp,network -s /usr/bin/zsh karim
sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
echo "Set password for new user karim"
passwd karim

# Setup display manager
# systemctl enable sddm.service

# Enable services
systemctl enable NetworkManager.service

echo "Configuration done. You can now exit chroot."
