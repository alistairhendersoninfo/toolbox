#!/usr/bin/env bash
#MN SELinux Disable
#MD Disable SELinux completely
#MDD Disables SELinux by updating the configuration file. Requires reboot to take full effect. Disabling SELinux removes mandatory access control enforcement.
#INFO https://wiki.centos.org/HowTos/SELinux

echo "Disabling SELinux..."
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
echo "SELinux disabled. Reboot required to take full effect."
