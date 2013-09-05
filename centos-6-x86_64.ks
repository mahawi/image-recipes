# This is a basic CentOS 6 spin designed to work in OpenStack and other
# virtualized environments. It's configured with cloud-init so it will
# take advantage of ec2-compatible metadata services for provisioning
# ssh keys and user data.

# Basic kickstart bits
text
skipx
cmdline
install

# Installation path
url --url=http://mirrors.kernel.org/centos/6/os/x86_64

# Repositories
repo --name=base --baseurl=http://mirrors.kernel.org/centos/6/os/x86_64
repo --name=updates --baseurl=http://mirrors.kernel.org/centos/6/updates/x86_64
repo --name=epel --baseurl=http://mirrors.kernel.org/fedora-epel/6/x86_64
repo --name=cloud-init --baseurl=http://repos.fedorapeople.org/repos/openstack/cloud-init/epel-6/

# Common configuration
rootpw --iscrypted $1$fakehash-bruteforcetocrackitnow
lang en_US.UTF-8
keyboard us
timezone --utc UTC
network --onboot=on --bootproto=dhcp
firewall --enabled
auth --useshadow --enablemd5
firstboot --disable
poweroff

# TODO(dtroyer): selinux isn't totally happy yet
#selinux --enforcing
selinux --permissive

# Simple disk layout
zerombr
clearpart --all --initlabel
bootloader --location=mbr --append="console=tty console=ttyS0 notsc"
part / --size 100 --fstype ext4 --grow

# Start a few things
services --enabled=acpid,ntpd,sshd,cloud-init

# Bare-minimum packages
%packages --nobase
@server-policy
acpid
logrotate
ntp
ntpdate
openssh-clients
rng-tools
rsync
screen
tmpwatch
wget

epel-release
cloud-init
cloud-utils

# Some things from @core we can do without in a minimal install
-NetworkManager
-sendmail

%end

# Fix up the installation
%post

# Cleanup after yum
yum clean all

#disable zeroconf for getting access for vm to openstack metadata service, otherwise the vm gets route: 169.254.0.0 netmask 255.255.0.0 by booting and cant get metadata
echo NOZEROCONF=yes >> /etc/sysconfig/network

# Rename the default cloud-init user to 'centos'

# cloud-init 0.6 config format
#sed -i 's/^user: ec2-user/user: centos/g' /etc/cloud/cloud.cfg

# cloud-init 0.7 config format
#sed -i 's/ name: cloud-user/ name: centos/g' /etc/cloud/cloud.cfg
sed -i 's/name: cloud-user/name: centos\
    lock_passwd: True\
    gecos: CentOS\
    groups: \[adm, audio, cdrom, dialout, floppy, video, dip\]\
    sudo: \[\"ALL=(ALL) NOPASSWD:ALL\"\]\
    shell: \/bin\/bash/' /etc/cloud/cloud.cfg

# Turn off additional services
chkconfig postfix off

# Set up to grow root in initramfs
cat << EOF > 05-grow-root.sh
#!/bin/sh

/bin/echo
/bin/echo Resizing root filesystem

growpart --fudge 20480 -v /dev/vda 1
e2fsck -f /dev/vda1
resize2fs /dev/vda1
EOF

chmod +x 05-grow-root.sh

dracut --force --include 05-grow-root.sh /mount --install 'echo awk grep fdisk sfdisk growpart partx e2fsck resize2fs' "$(ls /boot/initramfs-*)" $(ls /boot/|grep vmlinuz|sed s/vmlinuz-//g)
rm -f 05-grow-root.sh

#tail -4 /boot/grub/grub.conf | sed s/initramfs/initramfs-grow_root/g| sed s/CentOS/ResizePartition/g | sed s/crashkernel=auto/crashkernel=0@0/g >> /boot/grub/grub.conf

# let's run the kernel & initramfs that expands the partition only once
#echo "savedefault --default=1 --once" | grub --batch


# Leave behind a build stamp
echo "build=$(date +%F.%T)" >/etc/.build

# Remove udev net entries
sed -i '/ENV{MATCHADDR}="$attr{address}"$/a\ENV{MATCHADDR}=="fa:16:3e:*", GOTO="persistent_net_generator_end"' /lib/udev/rules.d/75-persistent-net-generator.rules
sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth0

%end
