#! /bin/bash

progsfile="https://raw.githubusercontent.com/karimone/arch-installer-script/master/progs.csv"

installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}
grepseq="\"^[PGA]*,\""

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

gitmakeinstall() {
    echo "git make install $1 $2"
	dir=$(mktemp -d)
	git clone --depth 1 "$1" "$dir" >/dev/null 2>&1
	cd "$dir" || exit
	make >/dev/null 2>&1
	make install >/dev/null 2>&1
	cd /tmp || return ;}

manualinstall() { # Installs $1 manually if not installed. Used only for AUR helper here.
    echo "manual install $1 $2"
	[ -f "/usr/bin/$1" ] || (
	cd /tmp || exit
	rm -rf /tmp/"$1"*
	curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/"$1".tar.gz &&
	sudo -u "$name" tar -xvf "$1".tar.gz # >/dev/null 2>&1 &&
	cd "$1" &&
	sudo -u "$name" makepkg --noconfirm -si # >/dev/null 2>&1
	cd /tmp || return) ;}

aurinstall() { \
    echo "aur install $1 $2"
	echo "$aurinstalled" | grep "^$1$" # >/dev/null 2>&1 && return
	sudo -u "$name" $aurhelper -S --noconfirm "$1" # >/dev/null 2>&1
	}

pipinstall() { \
    echo "pip install $1 $2"
	command -v pip || installpkg python-pip # >/dev/null 2>&1
	yes | pip install "$1"
	}

maininstall() { # Installs all needed programs from main repo.
    echo "manual install $1 $2"
	installpkg "$1"
	}


manualinstall "yay" || error "Failed to install AUR helper."

installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' | eval grep "$grepseq" > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	aurinstalled=$(pacman -Qqm)
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep "^\".*\"$" >/dev/null 2>&1 && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"A") aurinstall "$program" "$comment" ;;
			"G") gitmakeinstall "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
			*) maininstall "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;}


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
echo "Set root password"
passwd

# Install bootloader
# grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch

# MBR Instructions
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Create new user
useradd -m -G wheel,power,input,storage,uucp,network -s /usr/bin/zsh karim
sed --in-place 's/^#\s*\(%wheel\s\+ALL=(ALL)\s\+NOPASSWD:\s\+ALL\)/\1/' /etc/sudoers
echo "Set password for new user karim"
passwd karim

# Setup display manager
# systemctl enable sddm.service

# Enable services
systemctl enable NetworkManager.service > /dev/null 2&1

# disable the beep
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

echo "Start the installation from prog file"
installationloop

echo "Configuration done. You can now exit chroot."
