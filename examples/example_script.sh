#!/usr/bin/env bash
#MN System Information
#MD Display comprehensive system information
#MDD Shows detailed system information including hardware specs, OS details, network configuration, and resource usage. Useful for system auditing and troubleshooting.
#MI SystemUtilities
#INFO https://linux.die.net/man/1/uname
#MICON 💻
#MCOLOR Z2
#MORDER 10
#MDEFAULT false
#MSEPARATOR System Information
#MTAGS system,info,hardware,monitoring
#MAUTHOR Toolbox Team

echo "🖥️  System Information Report"
echo "=================================="
echo ""

echo "📋 Basic System Info:"
echo "  Hostname: $(hostname)"
echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "  Kernel: $(uname -r)"
echo "  Architecture: $(uname -m)"
echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
echo ""

echo "🔧 Hardware Info:"
echo "  CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
echo "  CPU Cores: $(nproc)"
echo "  Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "  Disk Usage: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
echo ""

echo "🌐 Network Info:"
echo "  IP Address: $(hostname -I | awk '{print $1}')"
echo "  Network Interfaces:"
ip addr show | grep -E '^[0-9]+:' | awk '{print "    " $2}' | sed 's/://'
echo ""

echo "📊 Resource Usage:"
echo "  Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "  Memory Usage:"
free -h | grep -E '^(Mem|Swap):' | awk '{printf "    %s: %s used / %s total (%.1f%%)\n", $1, $3, $2, ($3/$2)*100}'
echo ""

echo "🔍 Running Processes (Top 5 by CPU):"
ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "    %-10s %5s%% %s\n", $1, $3, $11}'
echo ""

echo "✅ System information collection complete!"