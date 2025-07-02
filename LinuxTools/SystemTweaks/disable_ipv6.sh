#!/bin/bash

# MN: DisableIPv6
# MD: Temporarily disable IPv6 on all interfaces

echo "Disabling IPv6 temporarily..."

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1

echo "To make this persistent, add to /etc/sysctl.conf:"
echo "net.ipv6.conf.all.disable_ipv6=1"
echo "net.ipv6.conf.default.disable_ipv6=1"
echo "net.ipv6.conf.lo.disable_ipv6=1"
