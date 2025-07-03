#!/usr/bin/env bash
#MN Install Let's Encrypt SSL
#MD Install certbot and display SSL creation guide with email registration
#MDD This script installs Let's Encrypt certbot for your system, prompts for your email address for registration, and provides clear instructions to generate SSL certificates for Apache, Nginx, standalone, and DNS challenges.
#MI LinuxTools
#INFO https://certbot.eff.org/

set -e

echo "🔧 Installing Certbot (Let's Encrypt SSL tool)..."

# Detect OS and install certbot
if [ -f /etc/debian_version ]; then
    echo "Detected Debian/Ubuntu system."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx python3-certbot-apache
elif [ -f /etc/redhat-release ]; then
    echo "Detected RHEL/CentOS system."
    sudo yum install -y epel-release
    sudo yum install -y certbot python3-certbot-nginx python3-certbot-apache
else
    echo "❌ Unsupported OS. Please install certbot manually."
    exit 1
fi

echo "✅ Certbot installation complete."

# Prompt for email
read -rp "📧 Enter your email address for Let's Encrypt registration: " email

echo "🔒 =============================="
echo " Let's Encrypt SSL Certificate Guide"
echo "=============================="
echo
echo "Table of Contents:"
echo " 1. Generate SSL for Nginx"
echo " 2. Generate SSL for Apache"
echo " 3. Generate SSL using standalone mode"
echo " 4. Generate wildcard SSL using DNS challenge"
echo " 5. Test certificate renewal"
echo
echo "Instructions:"
echo
echo "1️⃣ For Nginx:"
echo "   sudo certbot --nginx -m \"$email\" --agree-tos"
echo
echo "2️⃣ For Apache:"
echo "   sudo certbot --apache -m \"$email\" --agree-tos"
echo
echo "3️⃣ For standalone mode (no web server running, port 80 must be free):"
echo "   sudo certbot certonly --standalone -d yourdomain.com -m \"$email\" --agree-tos"
echo
echo "4️⃣ For DNS challenge (wildcard certificates):"
echo "   sudo certbot -d \"*.yourdomain.com\" --manual --preferred-challenges dns certonly -m \"$email\" --agree-tos"
echo
echo "5️⃣ To test renewal process:"
echo "   sudo certbot renew --dry-run"
echo
echo "📄 Certificates are saved in /etc/letsencrypt/live/yourdomain.com/"
echo
echo "🚀 You can now secure your websites with Let's Encrypt free SSL certificates."

exit 0
