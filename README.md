image-recipes
=============

Kickstart files and scripts for building minimal VM images.

Instalation
-----------

Howto: http://hackstack.org/x/blog/2013/04/25/a-centos-6-image-for-openstack/

Basic commands:

virt-install     --name centos-6     --ram 1024     --cpu host     --vcpus 1     --nographics     --os-type=linux     --os-variant=rhel6     --location=http://mirrors.kernel.org/centos/6/os/x86_64     --initrd-inject=centos-6-x86_64.ks     --extra-args="ks=file:/centos-6-x86_64.ks text console=tty0 utf8 console=ttyS0,115200"     --disk path=/var/lib/libvirt/images/centos-6-x86_64.img,size=2,bus=virtio     --force     --noreboot
virt-sysprep --no-selinux-relabel -a /var/lib/libvirt/images/centos-6-x86_64.img
virt-sparsify --convert qcow2 --compress /var/lib/libvirt/images/centos-6.img centos-6-x86_64.qcow2

Features
--------

The images created will have the following features:
* minimal installs excluding the common 'base' groups
* timezone is UTC
* single root filesystem, grows to size of disk on first boot
* cloud-init is installed
* rng-tools is loaded to take advantage of host virt entropy if available
* build timestamp in /etc/.build

Fedora
------
* login name is 'fedora'

CentOS
------
* EPEL repo is enabled
* login name is 'centos'
* postfix is installed (prereq for cronie) but not enabled
