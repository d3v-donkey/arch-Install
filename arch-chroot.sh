#!/bin/bash

#==============================================================================================================
#
# Auteur  : Alexandre Maury
# License : Distributed under the terms of GNU GPL version 2 or later
#
# GitHub : https://github.com/d3v-donkey
#==============================================================================================================

# Couleurs Bash

#    30m : noir
#    31m : rouge
#    32m : vert
#    33m : jaune
#    34m : bleu
#    35m : rose
#    36m : cyan
#    37m : gris

architecture="$1"
hostname="$2"
user="$3"
password_user="$4"
password_root="$5"
DOMAIN="local.dev"

echo $hostname > /etc/hostname
echo "127.0.1.1 $hostname.$DOMAIN $hostname" >> /etc/hosts
rm -f /etc/localtime && ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc --utc
echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
export LANG="fr_FR.UTF-8"
echo 'KEYMAP=fr-latin9' > /etc/vconsole.conf

mkinitcpio -p linux

if [ "$architecture" == "UEFI" ]; then
  mkdir -p /boot/efi
  mount -t vfat /dev/sda1  /boot/efi
  mkdir -p /boot/efi/EFI
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck
  grub-mkconfig -o /boot/grub/grub.cfg

elif [ "$architecture" == "LEGACY" ]; then
  grub-install --target=i386-pc --no-floppy --recheck /dev/sda
  grub-mkconfig -o /boot/grub/grub.cfg
fi

sed -i 's/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/' /etc/sudoers
useradd -m -g users -G wheel -s /bin/bash $user

echo "${user}:${password_user}" | chpasswd
echo "root:${password_root}" | chpasswd
# echo $3:$4 | chpasswd

# Pour l'installation de yaourt dans dossier bin
echo '[archlinuxfr]' >> /etc/pacman.conf
echo 'SigLevel = Never' >> /etc/pacman.conf
echo 'Server = http://repo.archlinux.fr/$arch' >> /etc/pacman.conf

#=============== Configuration openbox ===================

git clone https://github.com/d3v-donkey/arch-dotfiles.git && cd arch-dotfiles && cp -R dotfiles-openbox.tar.gz /home/$user
cd /home/$user && tar -zxvf dotfiles-openbox.tar.gz && rm -R dotfiles-openbox.tar.gz
#cd /home/$user && git clone https://github.com/d3v-donkey/neofetch.git && cd neofetch && make install
mkdir /home/$user/.icons && cd /home/$user/.icons && git clone https://github.com/d3v-donkey/la-capitaine-icon-theme.git && cd la-capitaine-icon-theme && ./configure
cd ~/.icons && git clone https://github.com/d3v-donkey/arc-icon-theme.git && cd arc-icon-theme && ./autogen.sh --prefix=/usr && make install

chown -R $user /home/$user
#===================== Services activation ====================================
localectl set-x11-keymap fr
systemctl enable dhcpcd.service
systemctl enable syslog-ng@default.service
systemctl enable cronie.service
systemctl enable avahi-daemon.service
systemctl enable avahi-dnsconfd.service
systemctl enable org.cups.cupsd.service
systemctl enable bluetooth.service
systemctl enable ntpd.service
systemctl enable NetworkManager.service
