# AlmaLinux OS 10 kickstart file for Cloud-init included and OpenStack compatible Generic Cloud images with unified (BIOS+UEFI) boot on x86_64

url --url https://repo.almalinux.org/almalinux/10/BaseOS/x86_64/os
text
lang en_US.UTF-8
keyboard us
timezone UTC --utc
selinux --enforcing
firewall --disabled
services --enabled=sshd

bootloader --timeout=0 --location=mbr --append="console=tty0 console=ttyS0,115200n8 no_timer_check net.ifnames=0"

%pre --erroronfail
parted -s -a optimal /dev/sda -- mklabel gpt
parted -s -a optimal /dev/sda -- mkpart root ext4 51MiB 100%
parted -s -a optimal /dev/sda -- mkpart '"EFI System Partition"' fat32 1MiB 51MiB set 2 esp on
%end

part / --fstype=ext4 --onpart=sda1
part /boot/efi --fstype=efi --onpart=sda2

rootpw --plaintext almalinux
reboot --eject

%packages --exclude-weakdeps --inst-langs=en
dracut-config-generic
grub2-pc
tar
-*firmware
-dracut-config-rescue
-firewalld
-c-ares
-ethtool
-gssproxy
-hdparm
-jansson
-kexec-tools
-lsscsi
-NetworkManager-tui
-ncurses
-polkit
-sg3_utils
-sg3_utils-libs
-sssd-common
-sssd-kcm
%end
# We tried to -xfsprogs here but cloud-init pulls it in as a dependency anyway.

# disable kdump service
%addon com_redhat_kdump --disable
%end

%post --erroronfail

EX_NOINPUT=66

root_disk=$(grub2-probe --target=disk /boot/grub2)

if [[ "$root_disk" =~ ^"/dev/" ]]; then
    grub2-install --target=i386-pc "$root_disk"
else
    exit "$EX_NOINPUT"
fi

# permit root login via SSH with password authetication
echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/01-permitrootlogin.conf

%end
