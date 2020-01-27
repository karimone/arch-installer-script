#! /bin/bash

progsfile="https://raw.githubusercontent.com/karimone/arch-installer-script/master/progs.csv"

# TODO: get from config file
name="karim"
hostname="bradbury"

PACKAGES_FILE="/root/packages.txt"
YAY_PACKAGES_FILE="/root/yay_packages.txt"
PACMAN_PACKAGES=$(tr '\n' ' ' < $PACKAGES_FILE)
YAY_PACKAGES=$(tr '\n' ' ' < $YAY_PACKAGES_FILE)

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}


yayinstall() { # Installs $1 manually if not installed. Used only for AUR helper here.
    echo "Install YAY"
	[ -f "/usr/bin/yay" ] || (
	cd /tmp || exit
	rm -rf /tmp/yay*
	curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz &&
	sudo -u "$name" tar -xvf yay.tar.gz >/dev/null 2>&1 &&
	cd yay &&
	sudo -u "$name" makepkg --noconfirm -si >/dev/null 2>&1
	cd /tmp || return) ;
}

install() {
    echo "Install $1 $2"
	sudo -u "$name" yay -S --answerclean All --nocleanmenu --noeditmenu --nodiffmenu --noprovides "$1" >> install.log
}

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

echo "Install pacman packages"
sudo pacman -S --noconfirm  ${PACMAN_PACKAGES} # >> install.log

yayinstall || error "Failed to install AUR helper."

echo "Install YAY packages"
sudo -u "$name" yay -S --answerclean All --nocleanmenu --noeditmenu --nodiffmenu --noprovides ${YAY_PACKAGES} # >> install.log

