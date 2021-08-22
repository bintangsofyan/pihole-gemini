#!/usr/bin/env bash

# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

echo -e "${GREEN}Install additional package${NOCOLOR}"
apt install curl wget bash sudo keepalived libipset*

echo -e "${GREEN}remove existing cloudflared${NOCOLOR}"
sudo systemctl stop cloudflared
sudo systemctl disable cloudflared
sudo systemctl daemon-reload
sudo deluser cloudflared
sudo rm /etc/default/cloudflared
sudo rm /etc/systemd/system/cloudflared.service
sudo rm /usr/local/bin/cloudflared

echo -e "${GREEN}install cloudflared${NOCOLOR}"
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo apt-get install ./cloudflared-linux-amd64.deb
cloudflared -v

echo -e "${GREEN}adduser cloudflared${NOCOLOR}"
sudo useradd -s /usr/sbin/nologin -r -M cloudflared

echo -e "${GREEN}created /etc/default/cloudflared${NOCOLOR}"
printf "#Commandline args for cloudflared, using Cloudflare DNS \nCLOUDFLARED_OPTS=--port 5053 --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query" >> /etc/default/cloudflared

echo -e "${GREEN}Make chown /etc/default/cloudflared and /usr/local/bin/cloudflared${NOCOLOR}"
sudo chown cloudflared:cloudflared /etc/default/cloudflared
sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared

echo -e "${GREEN}created /etc/systemd/system/cloudflared.service${NOCOLOR}"
printf "[Unit] \nDescription=cloudflared DNS over HTTPS proxy \nAfter=syslog.target network-online.target \n \n[Service] \nType=simple \nUser=cloudflared \nEnvironmentFile=/etc/default/cloudflared \nExecStart=/usr/local/bin/cloudflared proxy-dns $CLOUDFLARED_OPTS \nRestart=on-failure \nRestartSec=10 \nKillMode=process \n \n[Install] \nWantedBy=multi-user.target" >> /etc/systemd/system/cloudflared.service

echo -e "${GREEN}Running Service Cloudflare${NOCOLOR}"
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
#sudo systemctl status cloudflared

echo -e "${GREEN}back to root directory${NOCOLOR}"
cd /root/

echo -e "${GREEN}Uninstall Pi-Hole${NOCOLOR}"
sudo pihole uninstall
sudo rm -rf /etc/.pihole /etc/pihole /opt/pihole /usr/bin/pihole-FTL /usr/local/bin/pihole /var/www/html/admin

echo -e "${GREEN}Install Pi-Hole${NOCOLOR}"
wget -O basic-install.sh https://install.pi-hole.net
sudo bash basic-install.sh

echo -e "${GREEN}set password pihole${NOCOLOR}"
sudo pihole -a -p

echo -e "${GREEN}Pi-hole 1${NOCOLOR}"
echo -e "${GREEN}Role: Master or Active server${NOCOLOR}"
echo -e "${GREEN}Hostname: pihole-dns-01${NOCOLOR}"
echo -e "${GREEN}IP: 192.168.1.253${NOCOLOR}"

echo -e "${GREEN}Pi-hole 2 (THIS)${NOCOLOR}"
echo -e "${GREEN}Role: Backup or Standby server${NOCOLOR}"
echo -e "${GREEN}Hostname: pihole-dns-02${NOCOLOR}"
echo -e "${GREEN}IP: 192.168.1.252${NOCOLOR}"

echo -e "${GREEN}High Availability:${NOCOLOR}"
echo -e "${GREEN}IP: 192.168.1.254${NOCOLOR}"

echo -e "${GREEN}Setting pi-hole gemini${NOCOLOR}"

echo -e "${GREEN}remove old gemini${NOCOLOR}"
rm -r /usr/local/bin/pihole-gemini /opt/pihole/gravity.sh /etc/scripts/chk_ftl

echo -e "${GREEN}Setting gemini file${NOCOLOR}"
#cd /usr/local/bin
wget -P /usr/local/bin https://raw.githubusercontent.com/bintangsofyan/pihole-gemini/main/pihole-gemini
sudo chmod +x pihole-gemini

#echo -e "${GREEN}back to root directory
#cd /root/

echo -e "${GREEN}Create an SSH key${NOCOLOR}"
ssh-keygen -t rsa

echo -e "${GREEN}Send the SSH key to your ‘other’ Pi-hole machine.${NOCOLOR}"
ssh-copy-id root@192.168.1.253

echo -e "${GREEN}integrate the script into Pi-hole${NOCOLOR}"
sudo cp /opt/pihole/gravity.sh /opt/pihole/gravity.sh.bak
#cd /opt/pihole
wget -P /opt/pihole/ https://raw.githubusercontent.com/bintangsofyan/pihole-gemini/main/gravity.sh

#echo -e "${GREEN}back to root directory
#cd /root/

echo -e "${GREEN}enable keepalived${NOCOLOR}"
sudo systemctl enable keepalived.service

echo -e "${GREEN}create the pihole-FTL service check script${NOCOLOR}"
sudo mkdir /etc/scripts
#cd /etc/scripts/
wget -P /etc/scripts/ https://raw.githubusercontent.com/bintangsofyan/pihole-gemini/main/chk_ftl
sudo chmod 755 /etc/scripts/chk_ftl

#echo -e "${GREEN}back to root directory
#cd /root/

echo -e "${GREEN}setup keepalived${NOCOLOR}"
#cd /etc/keepalived/
wget -P etc/keepalived/ https://raw.githubusercontent.com/bintangsofyan/pihole-gemini/main/keepalived.conf
sudo systemctl restart keepalived.service

cd /root/
sudo rm*
