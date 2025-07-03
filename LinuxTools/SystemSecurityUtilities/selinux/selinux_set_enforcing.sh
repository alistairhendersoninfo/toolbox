#!/usr/bin/env bash
#MN SELinux Enforcing Mode
#MD Set SELinux to enforcing mode
#MDD Changes SELinux to enforcing mode immediately and updates configuration to persist after reboot. In enforcing mode, SELinux policy is actively enforced.
#INFO https://wiki.centos.org/HowTos/SELinux

echo "Setting SELinux to enforcing mode..."
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
