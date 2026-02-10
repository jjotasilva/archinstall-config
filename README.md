# Arch Linux Post-Install Guide  

📺 Video Reference: [YouTube](https://www.youtube.com/watch?v=YG2oQgGhdIQ)  

This guide will help you configure your Arch Linux system after installation:  
- System optimization  
- Package mirrors & updates  
- Essential services (power, Bluetooth, firewall, etc.)  
- Development & virtualization tools  
- Snapshots with Btrfs  
- Gaming stack (Steam, Lutris, Heroic)  
- Shell customization (Bash, Zsh, Powerlevel10k)  
- Visual tweaks (Plymouth, Fastfetch, icons)  

---

## Table of Contents
1. [System File Configuration](#1-system-file-configuration)  
2. [Services & Applications](#2-services--applications)  
3. [Software Sources & Runtimes](#3-software-sources--runtimes)  
4. [Virtualization & Containers](#4-virtualization--containers)  
5. [Boot Splash (Plymouth)](#5-boot-splash-plymouth)  
6. [AppArmor](#6-apparmor)  
7. [Snapshots (Btrfs + Snapper)](#7-snapshots-btrfs-with-snapper)  
8. [Gaming Stack](#8-gaming-stack-lutris--heroic--steam)  
9. [Shells](#9-shells)  
10. [Icons](#10-icons)  
11. [Fastfetch](#11-fastfetch-enhanced)  
12. [Extra Tips](#12-extra-quality-of-life)  

---

## 1. System File Configuration  

### Hosts File  
```bash
sudo nano /etc/hosts
```
Replace `{hostname}` with your machine name:  
```txt
127.0.0.1  localhost {hostname}
::1        localhost {hostname}
```

---

### Pacman Configuration  
```bash
sudo nano /etc/pacman.conf
```
```txt
# Misc options
Color
ParallelDownloads = 10
ILoveCandy
```

---

### Reflector | Faster Mirrorlist  
Install dependencies:  
```bash
sudo pacman -S reflector
```

Backup:  
```bash
sudo cp -p /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bkp
```

Rank the **10 fastest mirrors "South America"**:  
```bash
sudo reflector --verbose \
  --continent "South America" \
  --latest 50 \
  --protocol https \
  --sort rate \
  --number 10 \
  --save /etc/pacman.d/mirrorlist
```

Refresh Package Database:  
```bash
sudo pacman -Syyu
```

---
### Firmware Updates:  
Install dependencies:  
```bash
sudo pacman -S --needed fwupd fwupd-efi fwupd-docs

fwupdmgr refresh --force
fwupdmgr get-updates
sudo fwupdmgr update
```
---
### Nano config:  
Install dependencies:  
```bash
sudo pacman -S --needed nano-syntax-highlighting
---
sudo nano /etc/nanorc
fwupdmgr get-updates
include "/usr/share/nano/*.nanorc"
CTRL + O (salvar)
Enter (confirmar)
CTRL + X (sair)
```
---

## 2. Services & Applications  

### Sensors (temperature & fans)  
```bash
sudo pacman -S lm_sensors i2c-tools rrdtool
sudo modprobe i2c_dev
sudo systemctl enable --now sensord.service #opcional
```
- Intel: `sudo modprobe i2c-i801`  
- AMD: `sudo modprobe i2c-piix4`  

Make permanent:  
```bash
echo "i2c_dev" | sudo tee /etc/modules-load.d/i2c.conf
```
### Sensors Detection  
```bash
sudo sensors-detect
sudo systemctl restart sensord.service #opcional
```
---

### Power Management (KDE)  
```bash
sudo pacman -S powerdevil power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon.service
```

---

### Bluetooth  
```bash
sudo systemctl enable --now bluetooth
```

---

### AUR Helpers  
**Yay:**  
```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
```

---

### KDE Applications  
```bash
sudo pacman -S kde-system spectacle gwenview ark filelight isoimagewriter kate kcalc kdialog kfind kwalletmanager sweeper yakuake dolphin-plugins inotify-tools okular kgpg
```

**KDE Connect:**  
```bash
sudo pacman -S kdeconnect
```

---

### Development Tools  
```bash
sudo pacman -S linux-headers base-devel bash-completion
```

### Fuse (filesystem mounts)  
```bash
sudo pacman -S fuse fuse2fs fuseiso lvm2 dosfstools
```

---

### Browsers  
**Firefox (PT-BR locale):**  
```bash
sudo pacman -S firefox firefox-i18n-pt-br
```

**Brave:**  
```bash
paru -S brave-bin
```

---

### Firewall  
```bash
sudo pacman -S firewalld python-pyqt6
sudo systemctl enable --now firewalld
```
Add services:  
```bash
sudo firewall-cmd --set-default-zone=home
sudo firewall-cmd --permanent --add-service=mdns
sudo firewall-cmd --permanent --add-service=kdeconnect
```

---

## 3. Software Sources & Runtimes  

### Flatpak  
```bash
sudo pacman -S flatpak flatpak-kcm xdg-desktop-portal-gtk xdg-desktop-portal-kde
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

### Snap  
```bash
yay -S snapd
sudo systemctl enable --now snapd.socket
sudo systemctl enable --now snapd.apparmor.service   # if using AppArmor
```

---

## 4. Virtualization & Containers  

### KVM/QEMU + libvirt  
```bash
sudo pacman -S qemu-full virt-manager virt-viewer dnsmasq bridge-utils libguestfs ebtables vde2 openbsd-netcat
sudo usermod -aG libvirt $USER
sudo systemctl enable --now libvirtd
sudo virsh net-start default
sudo virsh net-autostart default
```

---

## 6. AppArmor  

Check support:  
```bash
zgrep CONFIG_LSM= /proc/config.gz
```

**GRUB:**  
```bash
sudo nano /etc/default/grub
```
```txt
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash lsm=landlock,lockdown,yama,integrity,apparmor,bpf audit=1"
```
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

**systemd-boot:**  
```bash
sudo nano /boot/loader/entries/*.conf
```
Append to `options`:  
```txt
lsm=landlock,lockdown,yama,integrity,apparmor,bpf audit=1
```

Install tools:  
```bash
sudo pacman -S tk apparmor python-audit python-notify2
sudo systemctl enable --now apparmor.service
sudo systemctl enable --now auditd.service
```

Reboot:  
```bash
reboot
```

Create group & enable notifications:  
```bash
sudo groupadd -r audit
sudo gpasswd -a "$(whoami)" audit
```

Edit `/etc/audit/auditd.conf`:  
```txt
log_group = audit
```

Autostart notifications:  
```bash
mkdir -p ~/.config/autostart
nano ~/.config/autostart/apparmor-notify.desktop
```
```ini
[Desktop Entry]
Type=Application
Name=AppArmor Notify
Exec=aa-notify -p -s 1 -w 60 -f /var/log/audit/audit.log
NoDisplay=true
```

---

## 7. Snapshots (Btrfs with Snapper)  

```bash
sudo pacman -S snapper snap-pac grub-btrfs
yay -S btrfs-assistant
```

Check subvolumes:  
```bash
sudo btrfs subvolume list /
```

Remove old:  
```bash
cd /
sudo umount /.snapshots
sudo rm -rf /.snapshots
```

Create config:  
```bash
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
```

Recreate dir:  
```bash
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots
sudo chown :wheel /.snapshots
```

Snapshot:  
```bash
sudo snapper -c root create -d "Base System"
```

Enable timers:  
```bash
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
```

Exclude from locate:  
```bash
sudo nano /etc/updatedb.conf
```
Add `.snapshots`:  
```txt
PRUNENAMES = ".git .hg .svn .snapshots"
```
```bash
sudo updatedb
```

Enable grub integration:  
```bash
sudo systemctl enable --now grub-btrfsd.service
```

Add overlayfs hook:  
```bash
sudo nano /etc/mkinitcpio.conf
```
```txt
HOOKS=(base ... filesystems fsck grub-btrfs-overlayfs)
```
```bash
sudo mkinitcpio -P
```

---

## 8. Gaming Stack (Lutris / Heroic / Steam)  

**Heroic Games Launcher:**  
```bash
yay -S heroic-games-launcher
```

**Steam:**  
```bash
sudo pacman -S steam
```

**ProtonPlus:**  
```bash
paru -S protonplus
```

**Xbox Controller Drivers:**  
```bash
yay -S xpadneo-dkms-git xone-dkms-git xone-dongle-firmware
```

**GameMode:**  
```bash
sudo pacman -S gamemode
systemctl --user enable --now gamemoded
```
Use with Steam launch options:  
```txt
gamemoderun %command%
```

---

## 9. Shells  

### Bash + Oh-My-Bash  
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
```
Edit `~/.bashrc`:  
```txt
OSH_THEME="standard"
```

---

### Zsh + Oh-My-Zsh + Powerlevel10k  
```bash
sudo pacman -S zsh wget lsd bat git
chsh -s /bin/zsh
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
```

Install fonts + theme:  
```bash
sudo pacman -S ttf-hack-nerd ttf-meslo-nerd
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git   ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```
Edit `~/.zshrc`:  
```txt
ZSH_THEME="powerlevel10k/powerlevel10k"
```

Aliases:  
```bash
echo "alias ls='lsd'" >> ~/.zshrc
echo "alias cat='bat'" >> ~/.zshrc
```

Plugins:  
```bash
sudo pacman -S zsh-autocomplete zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting
```
Append to `~/.zshrc`:  
```txt
source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
```

---

## 10. Icons  
Download Arch icons from [GitHub repo](https://github.com/KernelsAndDragons/ArchPostInstall/tree/main/icons).  

---

## 11. Fastfetch (Enhanced)  
```bash
sudo pacman -S fastfetch
mkdir -p ~/.config/fastfetch
cd ~/.config/fastfetch
fastfetch --gen-config
rm config.jsonc
wget https://raw.githubusercontent.com/KernelsAndDragons/ArchPostInstall/refs/heads/main/config.jsonc
```
Restart terminal and run:  
```bash
fastfetch
```
