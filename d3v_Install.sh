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

#==============================================================================================================
clear
echo -e  "\e[32m                                                  _____    ____   __      __    _______   ______              __  __ ";
echo -e  "\e[32m                                                 |  __ \  |___ \  \ \    / /   |__   __| |  ____|     /\     |  \/  |";
echo -e  "\e[32m                                                 | |  | |   __) |  \ \  / /       | |    | |__       /  \    | \  / |";
echo -e  "\e[32m                                                 | |  | |  |__ <    \ \/ /        | |    |  __|     / /\ \   | |\/| |";
echo -e  "\e[32m                                                 | |__| |  ___) |    \  /         | |    | |____   / ____ \  | |  | |";
echo -e  "\e[32m                                                 |_____/  |____/      \/          |_|    |______| /_/    \_\ |_|  |_|";

echo ""

#================= Test connection
ping -c 4 google.com 
test=$?

if [ "$test" -eq 0 ]; then
    echo -e "\e[33m[-- Network connecter, suite du programme...]";
else
	echo -e "\e[31m[-- S'il vous plait connecter Network...]";
	sleep 3s && exit 0
fi

#================= Mirroir Listes selection

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
curl -sSL "https://www.archlinux.org/mirrorlist/?country=FR&protocol=http&ip_version=4&use_mirror_status=on" | sed 's/^#Server/Server/' | head -20 > /etc/pacman.d/mirrorlist.raw
rankmirrors /etc/pacman.d/mirrorlist.raw > /etc/pacman.d/mirrorlist
pacman --noconfirm -Syy

#================= Main
cat Bienvenue.txt

echo -e  "\e[33m======================================================================================================[Press [y] pour poursuivre l'installation...]=====";
echo -e  "\e[32m========================================================================================================================================================";
read -r install

if [ "$install" == "y" ] || [ "$install" == "Y" ]; then
    timedatectl set-ntp true

    while [ -z $architecture ]
    do
        PS3="> " # definie l'invite du menu
        echo -e  "\e[33m==========================================================================================================[Bios : [LEGACY=1]-[UEFI=2]...]=======";
        echo -e  "\e[32m================================================================================================================================================";
        select choix in LEGACY UEFI; do
            case $REPLY in
                1) architecture="$choix"; break ;;
                2) architecture="$choix"; break ;;

                *) echo -e  "\e[33m==============================================================================[Mauvais Choix...Bios : [LEGACY=1] ou [UEFI=2]...]=====";;
            esac
        done
    done


    echo -e  "\e[33m================================================================================================================[Hostname [Ex : Arch-Linux]...]=====";
    echo -e  "\e[32m====================================================================================================================================================";
    read -r hostname

    echo -e  "\e[33m======================================================================================================================[Username [Ex : toto]...]=====";
    echo -e  "\e[32m====================================================================================================================================================";
    read -r user

    echo -e  "\e[33m===============================================================================================================================[Password $user]=====";
    echo -e  "\e[32m====================================================================================================================================================";
    read -r password_user

    echo -e  "\e[33m================================================================================================================================[Password Root]=====";
    echo -e  "\e[32m====================================================================================================================================================";
    read -r password_root


    if [ "$architecture" == "LEGACY" ]; then
        wipefs --force --all /dev/sda
        echo -e "o\nn\np\n1\n\n+100M\na\nn\np\n2\n\n+16G\nn\np\n3\n\n\nw" | fdisk /dev/sda
        mkfs.ext2 /dev/sda1
        mkfs.ext4 /dev/sda3

        mkswap /dev/sda2
        swapon /dev/sda2

        mount /dev/sda3 /mnt
        mkdir /mnt/boot
        mount /dev/sda1 /mnt/boot

        pacstrap /mnt base base-devel grub os-prober sudo networkmanager network-manager-applet gnome-keyring

    elif [ "$architecture" == "UEFI" ]; then
        wipefs --force --all /dev/sda
        sgdisk -Z /dev/sda
        sgdisk -a 2048 -o /dev/sda

        sgdisk -n 0:0:+512M -t 0:EF00 -c 0:"boot" /dev/sda
        sgdisk -n 0:0:+16G -t 0:8200 -c 0:"swap" /dev/sda
        sgdisk -n 0:0:0 -t 0:8300 -c 0:"home" /dev/sda
        sgdisk -p /dev/sda

        mkfs.fat -F32 /dev/sda1
        mkfs.ext4 /dev/sda3

        mkswap /dev/sda2
        swapon /dev/sda2

        mount /dev/sda3 /mnt
        mkdir /mnt/boot && mount /dev/sda1 /mnt/boot


        pacstrap /mnt base base-devel efibootmgr grub os-prober sudo networkmanager network-manager-applet gnome-keyring
    fi

        #============== Drivers video
        driver_nvidia=$(lspci | grep -e VGA -e 3D | grep -ie nvidia 2> /dev/null || echo '')
        driver_amd_ati=$(lspci | grep -e VGA -e 3D | grep -e ATI -e AMD 2> /dev/null || echo '')
        driver_intel=$(lspci | grep -e VGA -e 3D | grep -i intel 2> /dev/null || echo '')
        driver_Bumblebee=$(lspci | grep -e VGA -e 3D | grep -ie nvidia | grep -i intel 2> /dev/null || echo '') 

        if [[ -n "$driver_nvidia" ]]; then
            pacstrap /mnt xf86-video-nouveau mesa

        elif [[ -n "$driver_amd_ati" ]]; then
            pacstrap /mnt mesa xf86-video-amd mesa

        elif [[ -n "$driver_intel" ]]; then
            pacstrap /mnt xf86-video-intel mesa

        elif [[ -n "$driver_Bumblebee" ]]; then
            pacstrap /mnt xf86-video-bumblebee_nouveau mesa

        else
            echo -e "GPU found !! Installation de vesa."
            pacstrap /mnt xf86-video-vesa mesa
        fi

        #===================== Xorg ==============================
        pacstrap /mnt xf86-input-libinput xorg-server xorg-xinit xf86-input-keyboard xorg-xkbcomp xorg-xset xf86-input-synaptics xorg-xrandr xorg-twm xorg-xclock

        #===================== Polices ===========================
        pacstrap /mnt xorg-fonts-type1 ttf-dejavu artwiz-fonts font-bh-ttf
        pacstrap /mnt font-bitstream-speedo gsfonts sdl_ttf ttf-bitstream-vera
        pacstrap /mnt ttf-cheapskate ttf-liberation ttf-freefont ttf-arphic-uming ttf-baekmuk

        #===================== Audio =============================
        pacstrap /mnt alsa-utils alsa-plugins alsa-lib alsa-firmware alsa-utils pavucontrol pulseaudio pulseaudio-alsa volwheel

        #===================== Environnement Openbox =============

        pacstrap /mnt openbox obconf obmenu tint2
        pacstrap /mnt feh lxappearance terminology zsh zsh-completions unzip unrar p7zip xarchiver ruby compton bspwm ranger pcmanfm viewnior lm_sensors hddtemp tmux gmrun blueman
        pacstrap /mnt syslog-ng mtools pyxdg lsb-release ntfs-3g exfat-utils usbutils usb_modeswitch git curl ntp avahi nss-mdns cronie firefox tmux rhythmbox totem
        pacstrap /mnt gvfs numlockx gtk3 wireless_tools arandr cups cups-pdf ghostscript gsfonts libcups system-config-printer conky atom

        genfstab -U -p /mnt >> /mnt/etc/fstab

        mkdir -p /mnt/usr/bin/$user/
        cp -r * /mnt/usr/bin/$user/
        arch-chroot /mnt /bin/bash /usr/bin/$user/arch-chroot.sh $architecture $hostname $user $password_user $password_root
        rm -rf /mnt/usr/bin/$user/

        echo -e  "\e[33m==============================================================================================================[Installation terminé, reboot...]=====";
        echo -e  "\e[32m====================================================================================================================================================";

        umount -R /mnt
        sleep 2s && reboot

else
    echo -e  "\e[33m==================================================================================================================[Installation Echoué, Bay...]=====";
    echo -e  "\e[32m====================================================================================================================================================";
    exit 1
fi
