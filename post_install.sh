#! /bin/bash

progsfile="https://raw.githubusercontent.com/karimone/arch-installer-script/master/progs.csv"

# TODO: get from config file
name="karim"
hostname="bradbury"

PACKAGES_URL="https://raw.githubusercontent.com/karimone/arch-installer-script/master/packages.txt"
YAY_PACKAGES_URL="https://raw.githubusercontent.com/karimone/arch-installer-script/master/yay_packages.txt"

curl -LO ${PACKAGES_URL}
curl -LO ${YAY_PACKAGES_URL}

PACKAGES_FILE="./packages.txt"
YAY_PACKAGES_FILE="./yay_packages.txt"
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

echo "Karim's Gorjux Arch post install"
echo "Install pacman packages"
sudo pacman -S --noconfirm  ${PACMAN_PACKAGES} # >> install.log

yayinstall || error "Failed to install AUR helper."

echo "Install YAY packages"
sudo -u "$name" yay -S --answerclean All --nocleanmenu --noeditmenu --nodiffmenu --noprovides ${YAY_PACKAGES} # >> install.log

