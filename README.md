# Arch Linux Post-Install (KDE + BTRFS + Tweaks)

Guia de pós-instalação do Arch Linux com foco em KDE Plasma, BTRFS/Snapper, otimizações do sistema, apps essenciais, gaming, firewall, Flatpak e AppArmor.

------------------------------------------------------------

## Sumário

- [Pré-requisitos](#pré-requisitos)
- [Passo a passo](#passo-a-passo)
  - [1) Configurar hosts](#1-configurar-hosts)
  - [2) Instalar Paru (AUR Helper)](#2-instalar-paru-aur-helper)
  - [3) Criar alias ll](#3-criar-alias-ll)
  - [4) Libvirt/KVM - Ajuste no subvolume @images](#4-libvirtkvm---ajuste-no-subvolume-images)
  - [5) Habilitar fstrim](#5-habilitar-fstrim)
  - [6) Power Profiles / Bateria](#6-power-profiles--bateria)
  - [7) Configurar pacman.conf](#7-configurar-pacmanconf)
  - [8) Reflector - Configurar mirrors](#8-reflector---configurar-mirrors)
  - [9) Firmware (fwupd)](#9-firmware-fwupd)
  - [10) Nano - syntax highlighting](#10-nano---syntax-highlighting)
  - [11) Sensores de temperatura](#11-sensores-de-temperatura)
  - [12) NTP.br (systemd-timesyncd)](#12-ntpbr-systemd-timesyncd)
  - [13) Bluetooth](#13-bluetooth)
  - [14) Desabilitar SplitLock](#14-desabilitar-splitlock)
  - [15) Dualboot - detectar outros SOs](#15-dualboot---detectar-outros-sos)
  - [16) Gaming](#16-gaming)
  - [17) Resize disco BTRFS](#17-resize-disco-btrfs)
  - [18) Subvolumes Brave / Mozilla](#18-subvolumes-brave--mozilla)
  - [19) Desativar IPv6](#19-desativar-ipv6)
  - [20) KDE Apps](#20-kde-apps)
  - [21) KDE Connect](#21-kde-connect)
  - [22) Dev tools](#22-dev-tools)
  - [23) Apps via pacman](#23-apps-via-pacman)
  - [24) Apps via AUR](#24-apps-via-aur)
  - [25) Firewall (firewalld)](#25-firewall-firewalld)
  - [26) Flatpak](#26-flatpak)
  - [27) AppArmor + Audit](#27-apparmor--audit)
  - [28) Fastfetch (Enhanced)](#28-fastfetch-enhanced)
- [Extras: Snapper BTRFS Assistante](#extras-snapper-btrfs-assistante)
- [Notas importantes](#notas-importantes)
- [Roadmap](#roadmap)

------------------------------------------------------------

## Pré-requisitos

- Instalação do Arch finalizada e funcionando
- Conexão com internet
- Usuário com sudo configurado
- (Opcional) BTRFS + Snapper já configurados

------------------------------------------------------------

## Passo a passo

### 1) Configurar hosts

Edite o arquivo:

sudo nano /etc/hosts

Substitua {hostname} pelo hostname da máquina:

127.0.0.1  localhost {hostname}
::1        localhost {hostname}

------------------------------------------------------------

### 2) Instalar Paru (AUR Helper)

Dependências:

sudo pacman -S --needed base-devel git

Instalar Paru:

cd ~
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

------------------------------------------------------------

### 3) Criar alias ll

Edite:

sudo nano /etc/bash.bashrc

Adicione no final:

alias ll="ls -lh --color=auto"

Atualize:

source ~/.bashrc

------------------------------------------------------------

### 4) Libvirt/KVM - Ajuste no subvolume @images

Validar atributo:

lsattr -d /var/lib/libvirt/images

Se precisar ajustar:

sudo chattr -VR +C /var/lib/libvirt/images

------------------------------------------------------------

### 5) Habilitar fstrim

sudo systemctl enable --now fstrim.timer
sudo systemctl status fstrim.timer --no-pager

------------------------------------------------------------

### 6) Power Profiles / Bateria

Instalar:

sudo pacman -S --needed powerdevil power-profiles-daemon

Habilitar serviço:

sudo systemctl enable --now power-profiles-daemon.service

------------------------------------------------------------

### 7) Configurar pacman.conf

Edite:

sudo nano /etc/pacman.conf

Habilite:

Color
ParallelDownloads = 10

Adicione:

ILoveCandy

------------------------------------------------------------

### 8) Reflector - Configurar mirrors

Instalar:

sudo pacman -S --needed reflector

Backup do mirrorlist:

sudo cp -p /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bkp

Gerar mirrors:

sudo reflector --verbose \
  --continent "South America" \
  --latest 50 \
  --protocol https \
  --sort rate \
  --number 10 \
  --save /etc/pacman.d/mirrorlist

Atualizar sistema:

sudo pacman -Syyu

------------------------------------------------------------

### 9) Firmware (fwupd)

Instalar:

sudo pacman -S --needed fwupd fwupd-efi fwupd-docs

Executar update:

fwupdmgr refresh --force
fwupdmgr get-updates
sudo fwupdmgr update

------------------------------------------------------------

### 10) Nano - syntax highlighting

Instalar:

sudo pacman -S --needed nano-syntax-highlighting

Editar:

sudo nano /etc/nanorc

Adicionar no fim:

include "/usr/share/nano/*.nanorc"

------------------------------------------------------------

### 11) Sensores de temperatura

Instalar:

sudo pacman -S --needed lm_sensors i2c-tools rrdtool

Ativar módulo:

sudo modprobe i2c_dev

Opcional (serviço):

sudo systemctl enable --now sensord.service

Módulos extras:

Intel:
sudo modprobe i2c-i801

AMD:
sudo modprobe i2c-piix4

Carregar no boot:

echo "i2c_dev" | sudo tee /etc/modules-load.d/i2c.conf

Detectar sensores:

sudo sensors-detect

Opcional:

sudo systemctl restart sensord.service

------------------------------------------------------------

### 12) NTP.br (systemd-timesyncd)

Verificar:

timedatectl timesync-status

Editar se necessário:

sudo nano /etc/systemd/timesyncd.conf

Conteúdo:

[Time]
NTP=a.st1.ntp.br b.st1.ntp.br c.st1.ntp.br d.st1.ntp.br
FallbackNTP=a.ntp.br b.ntp.br c.ntp.br

Reiniciar e validar:

sudo systemctl restart systemd-timesyncd
timedatectl timesync-status

------------------------------------------------------------

### 13) Bluetooth

Instalar:

sudo pacman -S --needed bluez bluez-utils

Habilitar:

sudo systemctl enable --now bluetooth

------------------------------------------------------------

### 14) Desabilitar SplitLock

Criar sysctl:

echo 'kernel.split_lock_mitigate=0' | sudo tee /etc/sysctl.d/99-splitlock.conf >/dev/null

Aplicar:

sudo sysctl --system

------------------------------------------------------------

### 15) Dualboot - detectar outros SOs

Instalar:

sudo pacman -S --needed os-prober

Editar:

sudo nano /etc/default/grub

Adicionar/descomentar:

GRUB_DISABLE_OS_PROBER=false

Atualizar grub:

sudo grub-mkconfig -o /boot/grub/grub.cfg

------------------------------------------------------------

### 16) Gaming

Instalar pacotes oficiais:

sudo pacman -S --needed gamemode steam

Instalar AUR:

paru -S --needed heroic-games-launcher-bin protonplus termius mangojuice

Reiniciar serviço:

systemctl --user restart gamemoded

Steam launch options:

gamemoderun mangohud %command%

Heroic Launcher:
Ativar nas configurações internas.

Xbox Controller Drivers:

paru -S --needed xpadneo-dkms-git xone-dkms-git xone-dongle-firmware

------------------------------------------------------------

### 17) Resize disco BTRFS

Método manual (cfdisk):

sudo cfdisk /dev/sda

Resize do filesystem:

sudo btrfs filesystem resize max /

Método recomendado (growpart):

sudo pacman -S --needed cloud-guest-utils
sudo parted -s /dev/sda unit GiB print free
sudo growpart /dev/sda 2
sudo btrfs filesystem resize max /

Validar:

sudo parted -s /dev/sda unit GiB print free
sudo btrfs filesystem usage /

------------------------------------------------------------

### 18) Subvolumes Brave / Mozilla

Brave:

mv -v ~/.config/BraveSoftware ~/.config/BraveSoftware-old
sudo btrfs subvolume create ~/.config/BraveSoftware
sudo chown -Rv $USER: ~/.config/BraveSoftware
sudo cp -arv ~/.config/BraveSoftware-old/. ~/.config/BraveSoftware
sudo rm -rf ~/.config/BraveSoftware-old/
sudo btrfs subvolume list /

Firefox em ~/.mozilla:

mv -v ~/.mozilla/ ~/.mozilla-old
sudo btrfs subvolume create ~/.mozilla
sudo chown -Rv $USER: ~/.mozilla
cp -arv ~/.mozilla-old/. ~/.mozilla
rm -rf ~/.mozilla-old/
sudo btrfs subvolume list /

Firefox em ~/.config/mozilla (se estiver assim):

pgrep -a firefox

cd ~/.config
mv -v mozilla mozilla-old
sudo btrfs subvolume create mozilla
sudo chown -R $USER:$USER mozilla
mv -v mozilla-old/* mozilla/
rm -rf mozilla-old

Validar:

sudo btrfs subvolume show ~/.config/mozilla
sudo btrfs subvolume list ~ | grep -i mozilla

------------------------------------------------------------

### 19) Desativar IPv6

Método sysctl:

sudo tee /etc/sysctl.d/99-disable-ipv6.conf >/dev/null <<'EOF'
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

sudo sysctl --system
sudo reboot

Validar:

cat /proc/sys/net/ipv6/conf/all/disable_ipv6
ip -6 addr

Método recomendado (GRUB):

sudo nano /etc/default/grub

Adicionar ipv6.disable=1 em GRUB_CMDLINE_LINUX_DEFAULT:

GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet ipv6.disable=1"

Atualizar grub:

sudo grub-mkconfig -o /boot/grub/grub.cfg

Validar:

ip a | grep -i inet6

------------------------------------------------------------

### 20) KDE Apps

sudo pacman -S --needed \
  kde-system spectacle gwenview ark filelight isoimagewriter kate \
  kcalc kdialog kfind kwalletmanager sweeper yakuake dolphin-plugins \
  inotify-tools okular kgpg

------------------------------------------------------------

### 21) KDE Connect

sudo pacman -S --needed kdeconnect

------------------------------------------------------------

### 22) Dev tools

sudo pacman -S --needed linux-headers base-devel bash-completion

------------------------------------------------------------

### 23) Apps via pacman

sudo pacman -S --needed \
  rsync unzip bash-completion alsa-utils sof-firmware dmidecode \
  nvme-cli smartmontools fwupd cloud-guest-utils wireless-regdb \
  ksystemlog mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon \
  inetutils curl firefox firefox-i18n-pt-br

------------------------------------------------------------

### 24) Apps via AUR

paru -S --needed brave-bin vscodium-bin ttf-ms-fonts

------------------------------------------------------------

### 25) Firewall (firewalld)

Instalar:

sudo pacman -S --needed firewalld python-pyqt6 firewall-applet

Habilitar:

sudo systemctl enable --now firewalld

Configuração recomendada:

sudo firewall-cmd --set-default-zone=home
sudo firewall-cmd --permanent --add-service=mdns
sudo firewall-cmd --permanent --add-service=kdeconnect

------------------------------------------------------------

### 26) Flatpak

Instalar:

sudo pacman -S --needed flatpak flatpak-kcm xdg-desktop-portal-gtk xdg-desktop-portal-kde

Adicionar Flathub:

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

------------------------------------------------------------

### 27) AppArmor + Audit

Checar suporte:

zgrep CONFIG_LSM= /proc/config.gz

Editar GRUB:

sudo nano /etc/default/grub

Adicionar ao GRUB_CMDLINE_LINUX_DEFAULT:

GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet lsm=landlock,lockdown,yama,integrity,apparmor,bpf audit=1"

Atualizar grub:

sudo grub-mkconfig -o /boot/grub/grub.cfg

Reboot.

Instalar dependências:

sudo pacman -S --needed tk apparmor python-audit python-notify2

Habilitar serviços:

sudo systemctl enable --now apparmor.service
sudo systemctl enable --now auditd.service

Criar grupo audit e adicionar usuário:

sudo groupadd -r audit
sudo gpasswd -a "$(whoami)" audit

Editar auditd.conf:

sudo nano /etc/audit/auditd.conf

Adicionar:

log_group = audit

Notificação automática:

mkdir -p ~/.config/autostart
nano ~/.config/autostart/apparmor-notify.desktop

Conteúdo:

[Desktop Entry]
Type=Application
Name=AppArmor Notify
Exec=aa-notify -p -s 1 -w 60 -f /var/log/audit/audit.log
NoDisplay=true

------------------------------------------------------------

### 28) Fastfetch (Enhanced)

sudo pacman -S --needed fastfetch
mkdir -p ~/.config/fastfetch
cd ~/.config/fastfetch
fastfetch --gen-config
rm config.jsonc
wget https://raw.githubusercontent.com/KernelsAndDragons/ArchPostInstall/refs/heads/main/config.jsonc

------------------------------------------------------------

## Extras: Snapper BTRFS Assistante

Script recomendado:

https://github.com/jjotasilva/archinstall-config/blob/main/configs/01_btrfs-config.sh

------------------------------------------------------------

## Notas importantes

- Vários ajustes exigem reboot (GRUB, AppArmor, IPv6, firmware).
- Em BTRFS, criar subvolumes requer cuidado com permissões e processos em execução.
- AUR pode quebrar após updates: valide e mantenha rotina de revisão.

------------------------------------------------------------

## Roadmap

- Automatizar o processo em um script (postinstall.sh)
- Adicionar checks automáticos de serviços essenciais
- Criar seção de troubleshooting com erros comuns e logs
