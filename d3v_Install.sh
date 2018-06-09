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

########################################################################
EUID_0() {
########################################################################
    if [[ $EUID = 0 ]]; then
        echo -e "==>"  "\e[33m===================================[Droits sudo accorder ...]=====";

    else
	    echo -e "==>"  "\e[31m==============[Veuillez lancer le scripts en root (sudo) ...]=====";
        exit 1
    fi
}

########################################################################
base_Install() {
########################################################################
#================= Test connection
ping -c 4 google.com
test=$?

if [ "$test" -eq 0 ]; then
    echo -e "==>"  "\e[33m==============================================[Network Actif...]=====";
else
	echo -e "==>"  "\e[33m===============================================[Network Fail...]=====";
	sleep 3s && exit 0
fi
    echo -e "==>"  "\e[33m=================================[Installation drivers video...]=====";

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
curl -sSL "https://www.archlinux.org/mirrorlist/?country=FR&protocol=http&ip_version=4&use_mirror_status=on" | sed 's/^#Server/Server/' | head -20 > /etc/pacman.d/mirrorlist.raw
rankmirrors /etc/pacman.d/mirrorlist.raw > /etc/pacman.d/mirrorlist
pacman -Syyu --noconfirm

echo -e "==>"  "\e[33m======================================================================================================[Press [y] pour poursuivre l'installation...]=====";
read -r install
    
timedatectl set-ntp true

while [ -z $architecture ]
do
    PS3="> " # definie l'invite du menu
    echo -e "==>"  "\e[33m=========[Bios : [LEGACY=1]-[UEFI=2]...]=======";
    select choix in LEGACY UEFI; do
        case $REPLY in
            1) architecture="$choix"; break ;;
            2) architecture="$choix"; break ;;

            *) echo -e "==>"  "\e[33m===[Mauvais Choix...Bios : [LEGACY=1] ou [UEFI=2]...]=====";;
        esac
    done
done

echo -e "==>"  "\e[33m======[Nom de la machine [Ex : Arch-Linux]...]=====";
read -r hostname

echo -e "==>"  "\e[33m========================[Login [Ex : toto]...]=====";
read -r user

echo -e "==>"  "\e[33m==============================[Password $user]=====";
read -r password_user

echo -e "==>"  "\e[33m=====================[Password Administrateur]=====";
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

    pacstrap /mnt base base-devel grub sudo networkmanager network-manager-applet git wget zip unzip p7zip

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

    pacstrap /mnt base base-devel efibootmgr grub sudo networkmanager network-manager-applet git wget zip unzip p7zip
fi

genfstab -U -p /mnt >> /mnt/etc/fstab

mkdir -p /mnt/usr/bin/$user/
cp -r * /mnt/usr/bin/$user/
arch-chroot /mnt /bin/bash /usr/bin/$user/arch-chroot.sh $architecture $hostname $user $password_user $password_root
rm -rf /mnt/usr/bin/$user/

umount -R /mnt

echo -e "==>"  "\e[33m==[ Vous avez fini l'installation de la base, au redemarrage lancé : ./d3v_Install.sh --post ]=====";
sleep 10s && reboot
}

########################################################################
post_Install() {
########################################################################
echo -e "==>"  "\e[33m===================================================[Votre Login ...]=====";
read -r user
#================= Test connection
ping -c 4 google.com
test=$?

if [ "$test" -eq 0 ]; then
    echo -e "==>"  "\e[33m==============================================[Network Actif...]=====";
else
	echo -e "==>"  "\e[33m===============================================[Network Fail...]=====";
	sleep 3s && exit 0
fi

echo -e "==>"  "\e[33mBienvenue $user vous allez installer l'environnement Openbox prés configurer... Patience l'installation risque d'etre un peu longue";
echo -e "==>"  "\e[33mDépart de l'installation dans 5s !!!";
sleep 5s
clear

echo -e "==>"  "\e[33m=================================[Installation drivers video...]=========";
        ### DRIVER VIDEO                     ###
        ########################################
driver_nvidia=$(lspci | grep -e VGA -e 3D | grep -ie nvidia 2> /dev/null || echo '')
driver_amd_ati=$(lspci | grep -e VGA -e 3D | grep -e ATI -e AMD 2> /dev/null || echo '')
driver_intel=$(lspci | grep -e VGA -e 3D | grep -i intel 2> /dev/null || echo '')
driver_Bumblebee=$(lspci | grep -e VGA -e 3D | grep -ie nvidia | grep -i intel 2> /dev/null || echo '') 

if [[ -n "$driver_nvidia" ]]; then
    sudo pacman -S --noconfirm xf86-video-nouveau mesa

elif [[ -n "$driver_amd_ati" ]]; then
    sudo pacman -S --noconfirm mesa xf86-video-amd mesa

elif [[ -n "$driver_intel" ]]; then
    sudo pacman -S --noconfirm xf86-video-intel mesa

elif [[ -n "$driver_Bumblebee" ]]; then
    sudo pacman -S --noconfirm xf86-video-bumblebee_nouveau mesa

else
    echo -e "==>"  "\e[33m==============================[Installation de Vesa...]=========";
    sudo pacman -S --noconfirm xf86-video-vesa mesa
fi

        ### XORG                             ###
        ########################################
echo -e "==>"  "\e[33m=========================================[Installation Xorg...]=====";
sudo pacman -S --noconfirm xorg-server xorg-xinit xorg-apps xf86-input-mouse xf86-input-keyboard xf86-input-libinput xf86-input-synaptics

        ### SYSTEME                          ###
        ########################################
echo -e "==>"  "\e[33m==========================[Installation Utilitaires systeme...]=====";
sudo pacman -S --noconfirm gtk3 syslog-ng mtools dosfstools lsb-release ntfs-3g exfat-utils gparted arandr linux-headers gvfs lm_sensors hddtemp htop dos2unix
    # firejail (senbox)

        ### POLICES                          ###
        ########################################
echo -e "==>"  "\e[33m==================================[Installation des polices...]=====";
sudo pacman -S --noconfirm ttf-dejavu ttf-liberation

        ### CODECS MULTIMEDIA                ###
        ########################################
echo -e "==>"  "\e[33m========================[Installation des codecs multimedia...]=====";
sudo pacman -S --noconfirm transcode libtheora jasper flac libdvdcss libdvdread xvidcore musepack-tools

        ### AUDIO                            ###
        ########################################
echo -e "==>"  "\e[33m============================[Installation Utilitaires audio...]=====";
sudo pacman -S --noconfirm pulseaudio pulseaudio-alsa pavucontrol volumeicon
sudo pacman -S --noconfirm alsa-utils alsa-plugins alsa-lib alsa-firmware
sudo pacman -S --noconfirm gst-plugins-good gst-plugins-bad gst-plugins-base gst-plugins-ugly gstreamer

        ### PRINTER                          ###
        ########################################
echo -e "==>"  "\e[33m=======================[Installation Utilitaires imprimante...]=====";
sudo pacman -S --noconfirm cups gtk3-print-backends hplip python2-gnomekeyring system-config-printer

        ### VIDEO                            ###
        ########################################
echo -e "==>"  "\e[33m============================[Installation Utilitaires video...]=====";
sudo pacman -S --noconfirm mpv totem vlc
       
        ### MUSICS                           ###
        ########################################
echo -e "==>"  "\e[33m===========================[Installation Utilitaires musics...]=====";
sudo pacman -S --noconfirm deadbeef

        ### GRAPHICS                         ###
        ########################################
echo -e "==>"  "\e[33m========================[Installation Utilitaires graphique...]=====";
sudo pacman -S --noconfirm blender gimp imagemagick viewnior feh

        ### OFFICES                          ###
        ########################################
echo -e "==>"  "\e[33m==========================[Installation Utilitaires offices...]=====";
sudo pacman -S --noconfirm evince libreoffice-still 

        ### NETWORK                          ###
        ########################################
echo -e "==>"  "\e[33m==============================[Installation Utilitaires web...]=====";
sudo pacman -S --noconfirm wpa_supplicant wpa_actiond wireless_tools iw gnome-keyring firefox-i18n-fr flashplugin tor torsocks 

        ### BLUETOOTH                        ###
        ########################################
echo -e "==>"  "\e[33m========================[Installation Utilitaires bluetooth...]=====";
# sudo pacman -S --noconfirm pulseaudio-bluetooth bluez bluez-utils blueman blueman-applet blueman-manager

        ### EDITEUR                          ###
        ########################################
echo -e "==>"  "\e[33m====================[Installation Utilitaires developpement...]=====";
sudo pacman -S --noconfirm gvim atom vim neovim

        ### BASH + TERMINAL                  ###
        ########################################
echo -e "==>"  "\e[33m=========================[Installation Utilitaires terminal...]=====";
sudo pacman -S --noconfirm rxvt-unicode tmux bspwm zsh zsh-completions bash-completion cpio 

        ### FILE MANAGER + ARCHIVE MANAGER   ###
        ########################################
echo -e "==>"  "\e[33m=====================[Installation Utilitaires file manager...]=====";
sudo pacman -S --noconfirm file-roller nautilus ranger 

        ### OPENBOX + UTILS                  ###
        ########################################
echo -e "==>"  "\e[33m==========================[Installation Utilitaires openbox...]=====";
sudo pacman -S --noconfirm openbox obconf obmenu tint2 numlockx conky lxappearance compton gmrun


#=============== Configuration openbox ===================
echo -e "==>"  "\e[33m=====================================[Configuration Openbox...]=====";
mkdir /home/$user/openbox
cd /home/$user/openbox && git clone https://github.com/d3v-donkey/arch-dotfiles.git
cd /home/$user/openbox/arch-dotfiles && cp -r dotfiles-openbox.tar.xz /home/$user
cd /home/$user && tar xf dotfiles-openbox.tar.xz && sudo rm -r /home/$user/openbox

mkdir /home/$user/.icons 
cd /home/$user/.icons && git clone https://github.com/d3v-donkey/la-capitaine-icon-theme.git && cd la-capitaine-icon-theme && ./configure
cd /home/$user/.icons && git clone https://github.com/d3v-donkey/arc-icon-theme.git && cd arc-icon-theme && ./autogen.sh --prefix=/usr && make install
    
sudo chown -R $user /home/$user

echo -e "==>"  "\e[33m======================[Installation de yaourt + package Aur...]=====";

mkdir /home/$user/yaourt_install
cd /home/$user/yaourt_install && git clone https://aur.archlinux.org/package-query.git
cd /home/$user/yaourt_install && git clone https://aur.archlinux.org/yaourt.git
cd /home/$user/yaourt_install/package-query && makepkg -si
cd /home/$user/yaourt_install/yaourt && makepkg -si
sudo rm -rf /home/$user/yaourt_install

# Installation de quelques packages.
yaourt -S gksu vivaldi --noconfirm

#===================== Sublime text ==============
curl -O https://download.sublimetext.com/sublimehq-pub.gpg
sudo pacman-key --add sublimehq-pub.gpg
sudo pacman-key --lsign-key 8A8F901A
sudo rm sublimehq-pub.gpg

echo -e "\n[sublime-text]\nServer = https://download.sublimetext.com/arch/stable/x86_64" | sudo tee -a /etc/pacman.conf
sudo pacman -Syu sublime-text --noconfirm

    ### repo dans pacman.conf            ###
    ########################################

echo -e  "\e[33m========[rajout des repositories archstrike dans pacman.conf]=====";
sudo pacman-key --init
sudo dirmngr < /dev/null
sudo wget https://archstrike.org/keyfile.asc
sudo pacman-key --add keyfile.asc
sudo pacman-key --lsign-key 9D5F1C051D146843CDA4858BDE64825E7CBC0D51

sudo tee -a /etc/pacman.conf >/dev/null << 'EOF'
[archstrike]
Server = https://mirror.archstrike.org/$arch/$repo
EOF

sudo pacman -Syy --noconfirm 

    ### Information_Gaterring            ###
    ########################################
echo -e  "\e[33m==================================[ Information Gaterring...]=====";
sudo pacman -S nmap zmap nikto wireshark-cli wireshark-qt ettercap sslscan dmitry 0trace wafw00f golismero theharvester --noconfirm 

    ### Exploitation_Tools               ###
    ########################################
echo -e  "\e[33m=====================================[ Exploitation Tools...]=====";
sudo pacman -S postgresql metasploit sqlmap maltego yersinia armitage exploitdb beef --noconfirm
sudo systemctl start postgresql

    ### Web_Applications                 ###
    ########################################
echo -e  "\e[33m====================================[ Web Applications...]=====";
sudo pacman -S whatweb burpsuite --noconfirm 

    ### Password_Attacks                 ###
    ########################################
echo -e  "\e[33m====================================[ Password Attacks...]=====";
sudo pacman -S pdfcrack fcrackzip ophcrack medusa hydra john --noconfirm 

    ### Wireless_tools                   ###
    ########################################
echo -e  "\e[33m======================================[ Wireless tools...]=====";
    # airgeddon-git
sudo pacman -S aircrack-ng kismet --noconfirm 

    ### Forensic                         ###
    ########################################
echo -e  "\e[33m============================================[ Forensic...]=====";
sudo pacman -S volatility --noconfirm 

    ### Security_Tools                   ###
    ########################################
echo -e  "\e[33m======================================[ Security Tools...]=====";
    # [HTTP Anti Virus Proxy]
sudo pacman -S clamav clamtk iptables snort --noconfirm 

    ### Osptl                            ###
    ########################################
echo -e  "\e[33m===============================================[ Osptl...]=====";
sudo pacman -S virtualbox --noconfirm 

    
#===================== Services activation ==============
echo -e "==>"  "\e[33m========================[Activation des services...]=====";
sudo localectl set-x11-keymap fr
sudo systemctl enable dhcpcd.service
sudo systemctl enable syslog-ng@default.service
sudo systemctl enable cronie.service
sudo systemctl enable avahi-daemon.service
sudo systemctl enable avahi-dnsconfd.service
sudo systemctl enable org.cups.cupsd.service
sudo systemctl enable bluetooth.service
sudo systemctl enable ntpd.service
sudo systemctl enable wpa_supplicant.service
sudo systemctl enable postgresql.service

#===================== Paramétrage de postgresql metasploit ===========
sudo -u postgres initdb --locale fr_FR.UTF-8 -E UTF8 -D '/var/lib/postgres/data'
echo "Dans createuser renseigné 'toor' pour le password"
sudo -u postgres createuser msfuser -P -S -R -D 
sudo -u postgres createdb -O msfuser msfdb

echo "Creation Database configuration YAML file."
mkdir ~/.msf4 && touch ~/.msf4/database.yml
echo "production:
        adapter: postgresql
        database: msfdb
        username: msfuser
        password: toor
        host: 127.0.0.1
        port: 5432
        pool: 5
        timeout: 5" > ~/.msf4/database.yml

sudo cp -rf ~/.msf4/database.yml /opt/metasploit/config/

echo -e "==>"  "\e[33m===================[Installation terminé, reboot...]=====";
sleep 2 && reboot

}

help_() {
echo -e "==>"  "\e[33m==================================[Installation de la base...]=====";
echo ""
echo -e "==>"  "\e[33m========================================[./d3v_Install --base]=====";
echo ""
echo ""
echo -e "==>"  "\e[33m=======================[Post Installation...Aprés redemarrage]=====";
echo ""
echo -e "==>"  "\e[33m========================================[./d3v_Install --post]=====";
}

########################################################################
case "$1" in
    --base)
        base_Install
        ;;
    --post)
        post_Install
        ;;
    --help)
        help_
        ;;

    *) echo -e "==>" "\e[33m=====Options invalid" "[./d3v_Install --help]=============="; 
esac
########################################################################
