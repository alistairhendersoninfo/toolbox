#!/usr/bin/env bash
#MN SELinux Permissive Mode
#MD Set SELinux to permissive mode
#MDD Changes SELinux to permissive mode immediately and updates configuration to persist after reboot. In permissive mode, SELinux only logs denials but does not enforce them.
#INFO https://wiki.centos.org/HowTos/SELinux

echo "Setting SELinux to permissive mode (log only)..."
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
