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

echo $hostname > /etc/hostname
echo "127.0.1.1 $hostname.local.dev $hostname" >> /etc/hosts
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

### YAOURT                           ###
########################################
mkdir /home/$user/yaourt_install
cd /home/$user/yaourt_install && git clone https://aur.archlinux.org/package-query.git 
cd /home/$user/yaourt_install && git clone https://aur.archlinux.org/yaourt.git
cd /home/$user/yaourt_install/package-query && makepkg -si
cd /home/$user/yaourt_install/yaourt && makepkg -si
rm -rf /home/$user/yaourt_install

#=============== Configuration openbox ===================

    git clone https://github.com/d3v-donkey/arch-dotfiles.git && cd arch-dotfiles && cp -r dotfiles-openbox.tar.xz /home/$user
    cd /home/$user && tar -xf dotfiles-openbox.tar.xz && rm -r dotfiles-openbox.tar.xz

    #git clone https://github.com/d3v-donkey/bestbash.git ~/.bash/
    #mv .bashrc .bashrc.bak
    #ln -s ~/.bash/init ~/.bashrc

    mkdir /home/$user/.icons && cd /home/$user/.icons && git clone https://github.com/d3v-donkey/la-capitaine-icon-theme.git && cd la-capitaine-icon-theme && ./configure
    cd ~/.icons && git clone https://github.com/d3v-donkey/arc-icon-theme.git && cd arc-icon-theme && ./autogen.sh --prefix=/usr && make install
    chown -R $user /home/$user
    
#===================== Services activation ==============
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
    systemctl enable wpa_supplicant.service




