#!/usr/bin/env bash
#MN SELinux Install
#MD Install SELinux packages for your OS
#MDD Installs the necessary SELinux policy packages for either RedHat-based or Debian-based systems, enabling you to configure and enforce mandatory access control policies.
#INFO https://wiki.centos.org/HowTos/SELinux

echo "Installing SELinux and dependencies..."
if [ -f /etc/redhat-release ]; then
  sudo yum install -y selinux-policy selinux-policy-targeted
elif [ -f /etc/debian_version ]; then
  sudo apt update
  sudo apt install -y selinux-basics selinux-policy-default
else
  echo "Unsupported OS."
  exit 1
fi
