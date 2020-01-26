#
# PERSONAL install script for Arch linux
# url: tiny.cc/archinstall
#
# What it does?
# 
# Perform the partition
# Install the packages base and optionals
# Setup the base system
# Create the user
# Clone the configuration
# 

# VARIABLES

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)

TGTDEV=/dev/sda
RAM_SIZE=$(free --giga | awk '/^Mem:/{print $2}')
HARD_DRIVE_SIZE=$(fdisk -l | head -n 1 | grep Disk | awk '{print int($3)}')
FORMAT_SPACE=$((HARD_DRIVE_SIZE-RAM_SIZE))
MOUNTPOINT=/mnt
COUNTRY_NAME="Australia"
COUNTRY_CODE="AU"
REGION="Australia"
CITY="Melbourne"
LOCALE_UTF8="en_US.UTF-8 UTF-8"
HOSTNAME="bradbury"

adduserandpass() { \
	arch_chroot "useradd -m -g wheel -s /bin/bash \"$USERNAME\" >/dev/null 2>&1" ||
	arch_chroot "usermod -a -G wheel \"$USERNAME\" && mkdir -p /home/\"$USERNAME\" && chown \"$USERNAME\":wheel /home/\"$USERNAME\""
	arch_chroot "echo \"$USERNAME:$PASSWORD\" | chpasswd"
}

configure_mirrorlist(){
  echo "Configure mirror list..."
  url="https://www.archlinux.org/mirrorlist/?country=${COUNTRY_CODE}&use_mirror_status=on"
  tmpfile=$(mktemp --suffix=-mirrorlist)

  # Get latest mirror list and save to tmpfile
  curl -so ${tmpfile} ${url}
  sed -i 's/^#Server/Server/g' ${tmpfile}

  # Backup and replace current mirrorlist file (if new file is non-zero)
  if [[ -s ${tmpfile} ]]; then
   { echo " Backing up the original mirrorlist..."
     mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig; } &&
   { echo " Rotating the new list into place..."
     mv -i ${tmpfile} /etc/pacman.d/mirrorlist; }
  else
    echo " Unable to update, could not download list."
  fi
  # better repo should go first
  pacman -Sy --noconfirm pacman-contrib
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
  rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
  rm /etc/pacman.d/mirrorlist.tmp
  # allow global read access (required for non-root yaourt execution)
  chmod +r /etc/pacman.d/mirrorlist
  #$EDITOR /etc/pacman.d/mirrorlist
}

configure_hostname(){
  echo "$HOSTNAME" > ${MOUNTPOINT}/etc/hostname
  if [[ ! -f ${MOUNTPOINT}/etc/hosts.aui ]]; then
    cp ${MOUNTPOINT}/etc/hosts ${MOUNTPOINT}/etc/hosts.aui
  else
    cp ${MOUNTPOINT}/etc/hosts.aui ${MOUNTPOINT}/etc/hosts
  fi
  arch_chroot "sed -i '/127.0.0.1/s/$/ '${HOSTNAME}'/' /etc/hosts"
  arch_chroot "sed -i '/::1/s/$/ '${HOSTNAME}'/' /etc/hosts"
}

function  arch_chroot() {
    arch-chroot $MOUNTPOINT /bin/bash -c "${1}"
  }

function printOk {
    echo "${GREEN}OK${RESET}"
}

# Public: test the passed argument $1 and exit if is false
# $1 - the condition to test as boolean
# $2 - the message to print when exiting
# Returns: 0 if not exited
function exitOnFalse {
    if ! [ $1 ] ; then
        printf $RED$2$RESET
        exit 1
    fi
    return 0
}

# Public: Test the presence of the internet connection
# Returns: 0 if there is an internet connection, 1 otherwise
function testInternetConnection {
    wget -q --spider http://google.com.au
    return $?
}

echo "###########################################"
echo "# Karim Gorjux's arch personall installer #"
echo "###########################################"
echo ""
echo "Ram size detected...${GREEN}${RAM_SIZE}Gb${RESET}"
echo "Hard Drive size detected...${GREEN}${HARD_DRIVE_SIZE}Gb${RESET}"

printf "Testing internet connection..."
testInternetConnection
exitOnFalse $? "FAIL"
echo "${GREEN}OK${RESET}"

cat << EOF
Preparing the hard drive...
Let's prepare the hard drive of your computer.
At the moment only the old style bios

This script will create and format the partitions as follows:
    /dev/sda1 - 256MB as /boot
    /dev/sda2 - ${RAM_SIZE}GB for swap space (as the mounted RAM)
    /dev/sda3 - rest of space ${FORMAT_SPACE}GB will be mounted as /
EOF

# clean everything on the hard drive
wipefs -a /dev/sda

# PARTITION THE HARD DRIVE
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}

  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +256M # 100 MB boot parttion
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +${RAM_SIZE}G # Swap partition
  n # new partition
  p # primary partition
  3 # partion number 3
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF


printf "Formatting the partition..."
# Format the partitions
yes | mkfs.ext4 /dev/sda1
yes | mkfs.ext4 /dev/sda3
printOk

printf "Format and activate swap partition..."
mkswap /dev/sda2
swapon /dev/sda2
printOk

printf "Set up time using ntp..."
timedatectl set-ntp true
printOk

# Initate pacman keyring
#pacman-key --init
#pacman-key --populate archlinux
#pacman-key --refresh-keys

# Mount the partitions
printf "Mount partitions..."
mount /dev/sda3 /mnt
mkdir -pv /mnt/boot/
mount /dev/sda1 /mnt/boot/
printOk

configure_mirrorlist

# Install Arch Linux
echo "Starting install base arch..."
pacstrap ${MOUNTPOINT} base linux linux-firmware grub os-prober


# Generate fstab
echo "Generate fstab...${printOk}"
genfstab -U /mnt >> /mnt/etc/fstab
printOk

arch_chroot "ln -sf /usr/share/zoneinfo/${REGION}/${CITY} /etc/localtime"
arch_chroot "hwclock --systohc --utc"
arch_chroot "locale-gen"

echo "Configure locale... "
echo 'LANG="'$LOCALE_UTF8'"' > ${MOUNTPOINT}/etc/locale.conf
arch_chroot "sed -i 's/#\('${LOCALE_UTF8}'\)/\1/' /etc/locale.gen"
arch_chroot "locale-gen"

configure_hostname

echo "set root password"
passwd

echo "Unmounting..."
umount /mnt/boot
umount /mnt
swapoff /dev/sda2

echo "done. you cam reboot and start the second step"
# adduserandpass


