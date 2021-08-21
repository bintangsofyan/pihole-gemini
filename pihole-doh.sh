echo install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo apt-get install ./cloudflared-linux-amd64.deb
cloudflared -v

echo adduser
sudo useradd -s /usr/sbin/nologin -r -M cloudflared

echo created /etc/default/cloudflared
printf "#Commandline args for cloudflared, using Cloudflare DNS\nCLOUDFLARED_OPTS=--port 5053 --upstream https://8.8.8.8/dns-query --upstream https://8.8.4.4/dns-query --upstream https://9.9.9.9/dns-query --upstream https://149.112.112.112/dns-query --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query --upstream https://76.76.19.19/dns-query --upstream https://76.223.122.150/dns-query --upstream https://94.140.14.14/dns-query --upstream https://94.140.15.15/dns-query --upstream https://84.200.69.80/dns-query --upstream https://84.200.70.40/dns-query --upstream https://8.26.56.26/dns-query --upstream https://8.20.247.20/dns-query --upstream https://205.171.3.66/dns-query --upstream https://205.171.202.166/dns-query --upstream https://195.46.39.39/dns-query --upstream https://195.46.39.40/dns-query --upstream https://172.98.193.42/dns-query --upstream https://66.70.228.164/dns-query --upstream https://216.146.35.35/dns-query --upstream https://216.146.36.36/dns-query --upstream https://45.33.97.5/dns-query --upstream https://37.235.1.177/dns-query --upstream https://77.88.8.8/dns-query --upstream https://77.88.8.1/dns-query --upstream https://91.239.100.100/dns-query --upstream https://89.233.43.71/dns-query --upstream https://74.82.42.42/dns-query --upstream https:// /dns-query --upstream https://109.69.8.51/dns-query --upstream https:// /dns-query --upstream https://64.6.64.6/dns-query --upstream https://64.6.65.6/dns-query --upstream https://45.77.165.194/dns-query --upstream https://45.32.36.36/dns-query" >> /etc/default/cloudflared

echo chown
sudo chown cloudflared:cloudflared /etc/default/cloudflared
sudo chown cloudflared:cloudflared /usr/local/bin/cloudflared

echo created /etc/systemd/system/cloudflared.service
printf "[Unit]\nDescription=cloudflared DNS over HTTPS proxy\nAfter=syslog.target network-online.target\n\n[Service]\nType=simple\nUser=cloudflared\nEnvironmentFile=/etc/default/cloudflared\nExecStart=/usr/local/bin/cloudflared proxy-dns $CLOUDFLARED_OPTS\nRestart=on-failure\nRestartSec=10\nKillMode=process\n\n[Install]\nWantedBy=multi-user.target" >> /etc/systemd/system/cloudflared.service

echo status
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared
