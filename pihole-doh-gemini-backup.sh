/bin/bash

# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

echo ${GREEN}SInstall additional package
sudo apt install curl wget bash sudo keepalived libipset*

echo ${GREEN}remove existing cloudflared
sudo systemctl stop cloudflared
sudo systemctl disable cloudflared
sudo systemctl daemon-reload
sudo deluser cloudflared
sudo rm /etc/default/cloudflared
sudo rm /etc/systemd/system/cloudflared.service
sudo rm /usr/local/bin/cloudflared

echo ${GREEN}install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo apt-get install ./cloudflared-linux-amd64.deb
cloudflared -v

echo ${GREEN}adduser cloudflared
sudo useradd -s /usr/sbin/nologin -r -M cloudflared

echo ${GREEN}created /etc/default/cloudflared
printf "#Commandline args for cloudflared, using Cloudflare DNS \nCLOUDFLARED_OPTS=--port 5053 --upstream https://8.8.8.8/dns-query --upstream https://8.8.4.4/dns-query --upstream https://9.9.9.9/dns-query --upstream https://149.112.112.112/dns-query --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query --upstream https://76.76.19.19/dns-query --upstream https://76.223.122.150/dns-query --upstream https://94.140.14.14/dns-query --upstream https://94.140.15.15/dns-query --upstream https://84.200.69.80/dns-query --upstream https://84.200.70.40/dns-query --upstream https://8.26.56.26/dns-query --upstream https://8.20.247.20/dns-query --upstream https://205.171.3.66/dns-query --upstream https://205.171.202.166/dns-query --upstream https://195.46.39.39/dns-query --upstream https://195.46.39.40/dns-query --upstream https://172.98.193.42/dns-query --upstream https://66.70.228.164/dns-query --upstream https://216.146.35.35/dns-query --upstream https://216.146.36.36/dns-query --upstream https://45.33.97.5/dns-query --upstream https://37.235.1.177/dns-query --upstream https://77.88.8.8/dns-query --upstream https://77.88.8.1/dns-query --upstream https://91.239.100.100/dns-query --upstream https://89.233.43.71/dns-query --upstream https://74.82.42.42/dns-query --upstream https:// /dns-query --upstream https://109.69.8.51/dns-query --upstream https:// /dns-query --upstream https://64.6.64.6/dns-query --upstream https://64.6.65.6/dns-query --upstream https://45.77.165.194/dns-query --upstream https://45.32.36.36/dns-query" >> /etc/default/cloudflared

echo ${GREEN}Make chown /etc/default/cloudflared and /usr/local/bin/cloudflared
sudo chown cloudflared:cloudflared /etc/default/cloudflared
sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared

echo ${GREEN}created /etc/systemd/system/cloudflared.service
printf "[Unit] \nDescription=cloudflared DNS over HTTPS proxy \nAfter=syslog.target network-online.target \n \n[Service] \nType=simple \nUser=cloudflared \nEnvironmentFile=/etc/default/cloudflared \nExecStart=/usr/local/bin/cloudflared proxy-dns $CLOUDFLARED_OPTS \nRestart=on-failure \nRestartSec=10 \nKillMode=process \n \n[Install] \nWantedBy=multi-user.target" >> /etc/systemd/system/cloudflared.service

echo ${GREEN}Running Service Cloudflare
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
#sudo systemctl status cloudflared

echo ${GREEN}back to root directory
cd /root/

echo ${GREEN}Uninstall Pi-Hole
sudo pihole uninstall
sudo rm -rf /etc/.pihole /etc/pihole /opt/pihole /usr/bin/pihole-FTL /usr/local/bin/pihole /var/www/html/admin

echo ${GREEN}Install Pi-Hole
wget -O basic-install.sh https://install.pi-hole.net
sudo bash basic-install.sh

echo ${GREEN}Pi-hole 1
echo ${GREEN}Role: Master or Active server
echo ${GREEN}Hostname: pihole-dns-01
echo ${GREEN}IP: 192.168.1.253

echo ${GREEN}Pi-hole 2 (THIS)
echo ${GREEN}Role: Backup or Standby server
echo ${GREEN}Hostname: pihole-dns-02
echo ${GREEN}IP: 192.168.1.252

echo ${GREEN}High Availability:
echo ${GREEN}IP: 192.168.1.254

echo ${GREEN}Setting pi-hole gemini

echo ${GREEN}Setting gemini file
#cd /usr/local/bin
wget -P /usr/local/bin https://raw.githubusercontent.com/bintangsofyan/pihole-gemini/main/pihole-gemini
sudo chmod +x pihole-gemini

#echo ${GREEN}back to root directory
#cd /root/

echo ${GREEN}Create an SSH key 
ssh-keygen -t rsa

echo ${GREEN}Send the SSH key to your ‘other’ Pi-hole machine.
ssh-copy-id root@192.168.1.253

echo ${GREEN}integrate the script into Pi-hole
sudo cp /opt/pihole/gravity.sh /opt/pihole/gravity.sh.bak
#cd /opt/pihole
wget -P /opt/pihole/ https://raw.githubusercontent.com/bintangsofyan/pihole-gemini/main/gravity.sh

#echo ${GREEN}back to root directory
#cd /root/

echo ${GREEN}enable keepalived
sudo systemctl enable keepalived.service

echo ${GREEN}create the pihole-FTL service check script
sudo mkdir /etc/scripts
#cd /etc/scripts/
wget -P /etc/scripts/ https://raw.githubusercontent.com/bintangsofyan/pihole-gemini/main/chk_ftl
sudo chmod 755 /etc/scripts/chk_ftl

#echo ${GREEN}back to root directory
#cd /root/

echo ${GREEN}setup keepalived
#cd /etc/keepalived/
wget -P etc/keepalived/ https://raw.githubusercontent.com/bintangsofyan/pihole-gemini/main/keepalived.conf
sudo systemctl restart keepalived.service
