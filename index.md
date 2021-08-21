[Tutorial] v2 - How to run 2 Pi-hole servers in HA (High Availability) & in-sync - v2
TL;DR

Skip the BS and scroll down to where the fun part begins: Requirements

 

pihole-gemini master/active script edited: https://pastebin.com/qBGRppSG

keepalived master/active config: https://pastebin.com/nsBnkShi

 

pihole-gemini backup/standby script edited: https://pastebin.com/CLGw2BrZ

keepalived backup/standby config: https://pastebin.com/HbdsUc07

 

check pihole-FTL service script: https://pastebin.com/npw6tcuk

 

Introduction...

Around 2 weeks ago I shared my tutorial here on Reddit to run 2 Pi-hole servers in HA and in-sync.

Not knowing that so many people would love such a setup. My topic received a lot of (positive) attention (thanks!) and I even received 2 Reddit GOLD! Absolutely not necessary, of course, but greatly appreciated! Again THANKS!

Also I was asked to write out my tutorial as a userguide for the Pi-hole Docs website. How cool is that?! 😃

I will do this later on when I have some more spare time.

 

All this positivity gave me energy to review my own tutorial, iron out some (minor) mistakes and adding some new functionality. Reddit user /u/Stinocon pointed out that Keepalived (which is used in my tutorial) is great for when 1 Pi-hole server goes down, but it does not, by default, check if for instance the Pi-hole DNS service is running or not.

I did some more research and testing and finally I can say that checking the service pihole-FTL

(which is essentially the DNS service for Pi-Hole), works great as well!

So when the DNS service goes down, for whatever reason, but the server itself (and thus Keepalived) is still running it will still switch to the backup/standby server.

The tutorial is still based on Raspbian/Debian Stretch.

 

Why do you want to run 2 Pi-hole servers?

When you only have 1 Pi-hole server running and it needs maintenance or updates you'll lose internet (DNS resolution) connection. Or if your Pi-hole server needs a reboot or has an outage you will lose that DNS resolution and thus cannot browse the internet properly. Or if the Pi-hole FTL service (DNS service) fails on your Pi-hole server you'll end up with the above problems. We all have that girlfriend, boyfriend, wife, husband, kid or pet that really really NEEDS the internet NOW and will fall apart if it doesn't work... For this situation you really need/want/must have 2 Pi-hole servers.

 

Why do you want to run in HA and why not use them as primary and secondary DNS servers?

Running 2 Pi-hole servers is a must, you must know that by now. You can let you DHCP server handout Pi-hole server 1 as primary DNS server and Pi-hole server 2 as secondary. This works, of course, and many prefer it this way. But I do not! Network client/machines randomly choose (not going into detail here) which DNS server they will use, thus sometimes they use the primary and sometimes the secondary DNS server. If you want to check your query logs you'll never know for sure which server (Pi-hole 1 or 2) the machine used for its DNS queries.

 

Also when using primary and secondary DNS servers on your network DNS resolution can be slow(er) when 1 of the 2 servers is down. Let me explain that... When one of the 2 DNS servers is down (maintenance, update, reboot etc) and a client is doing a DNS query it will randomly pick the primary or secondary. If the client hits the DNS server that is down it will automatically switch to the other DNS server (which is what you want), though this takes extra time. We're talking about mili seconds, but hey every (mili) second counts in this modern internet world.

 

There for I wanted to have 2 Pi-hole servers but only use 1 of them at the time. When the first one goes down or the DNS service is not working, I want to switch to the second. If the first one comes back online it may switch back to that one.

Makes sense, right?!

 

Requirements:

2 machines running Raspbian Stretch/Debian Stretch, this can be a Raspberry Pi, desktop, VM etc.

2 machines running Pi-hole (obvious).

DHCP server disabled on the Pi-hole's (DHCP needs to be done on your firewall, router or other device).

SSH access installed and enabled on both machines.

Rsync installed on both machines.

A user with the same username on both machines, which also has sudo permissions and SSH access.

 

Tutorial configuration:

In this tutorial I will use the following configuration, alter this to match your setup.

 

Pi-hole 1

Role: Master or Active server

Hostname: pihole-dns-01

IP: 192.168.1.11

 

Pi-hole 2

Role: Backup or Standby server

Hostname: pihole-dns-02

IP: 192.168.1.12

 

High Availability:

IP: 192.168.1.20

 

Tutorial part 1 - create a sync between the 2 Pi-hole machines:

All of the 11 steps below need to be taken on both Pi-hole machines.

01) Login to the machine with the user which will be used for the sync script.

Make sure this user has SSH and sudo permissions.

02) Change directory to /usr/local/bin

cd /usr/local/bin

03) Create a script file, named pihole-gemini, and edit this file.

You can use any preferred text editor, I used nano.

sudo nano pihole-gemini

04) Paste the script into the pihole-gemini script file.

I've edited and removed a few lines from the original pihole-gemini script to have it working correctly in a HA setup.

For the Master/Active server copy/paste this script: https://pastebin.com/qBGRppSG

For the Backup/Standby server copy/paste this script: https://pastebin.com/CLGw2BrZ

05) Change the values in the USER-DEFINED VARIABLES section to match your setup.

06) Save the file and exit the editor

07) Make the script executable.

sudo chmod +x pihole-gemini

08) Create an SSH key to allow remote connections without supplying a password for the user that you’re using to sync files between the 2 Pi-holes.

ssh-keygen -t rsa (do not use sudo with this command)

Answer the prompts (leaving them blank will use the default values, which are ok to use) to generate the SSH key.

09) Send the SSH key to your ‘other’ Pi-hole machine.

You should use the ‘other’ Pi-hole’s username @ the other Pi-hole’s ip address in the command.

ssh-copy-id other-pi-username@other-pi-ip-address

10) After configuring both Pi-hole SSH keys, test the passwordless SSH login from the command line.

ssh username@other-pihole-ip

11) Finally, we need to integrate the script into Pi-hole.

We will do this by editing Pi-hole’s gravity.sh script, but first, we need to back it up.

sudo cp /opt/pihole/gravity.sh /opt/pihole/gravity.sh.bak

Then we’ll edit the gravity.sh file.

sudo nano /opt/pihole/gravity.sh

Scroll down to the very end of the script. The very last line should read:

“${PIHOLE_COMMAND}” status

We will be adding a new command directly ABOVE that line, so that “${PIHOLE_COMMAND}” status remains the last line of the file.

The line we need to add is:

su -c /usr/local/bin/pihole-gemini - pi

Note that the “pi” at the end of the line should be replaced with the username of your sync user account.

Save the file and exit.

 

You can now invoke the script directly by calling pihole-gemini at the command line.

Try this now and see if everything works as expected. From now on, it will run automatically whenever you update gravity, add or remove items from the white or black list, or add or remove items from the block list (including enabling or disabling block lists).

 

Important note:

When upgrading to a new version of Pi-hole you will have to repeat step 11 in order to re-enable the pihole-gemini sync.

 

Tutorial part 2 - create a HA (active/standby) between the 2 Pi-hole machines:

01) I've used a package named keepalived to create a HA between my 2 Pi-hole machines.

First we need to install keepalived and libipset3. Run this command on both machines.

sudo apt update && sudo apt install keepalived libipset3 -y

02) After the install we need to enable keepalived. Run this command on both machines.

sudo systemctl enable keepalived.service

03) We will now create the pihole-FTL service check script.

Run the following commands, do this on both machines.

sudo mkdir /etc/scripts

sudo nano /etc/scripts/chk_ftl

Copy/paste the script: https://pastebin.com/npw6tcuk

Save and exit the editor.

sudo chmod 755 /etc/scripts/chk_ftl

04) Now we will add the keepalived configuration on the first Pi-hole machine, the Master/Active server.

Change the settings according to your setup.

sudo nano /etc/keepalived/keepalived.conf

Copy/paste the script: https://pastebin.com/nsBnkShi

Save and exit the editor.

 

Explanation of the options:

router_id: should be an unique name, for instance your Pi-hole hostname

state: describes which server is the Master/Active and which is the Backup/Standby server.

interface: change this according to your network interface (e.g. eth0, ens3 etc)

virtual_router_id: this can be any number between 0 and 255. Must be the same on the Master and Backup configs.

priority: the master server should have a higher priority than the backup server.

unicast_src_ip: should be the IP address of the (source) server.

unicast_peer: should be the IP address of the other (peer) server.

auth_pass: create your own (max 8 character) password. Must be the same on the Master and Backup configs.

virtual_ipaddress: this will be the HA IP address.

 

05) Now we will add the keepalived configuration on the second Pi-hole machine, the Backup/Standby server.

sudo nano /etc/keepalived/keepalived.conf

Copy/paste the script: https://pastebin.com/HbdsUc07

Save and exit the editor.

06) Restart the keepalived service. Run this command on both machines.

sudo systemctl restart keepalived.service

07) Change your DHCP server settings to hand out 1 (primary) DNS server and use the HA IP address: 192.168.1.20

 

Profit:

You're done! You now have a HA in-sync Pi-holed network. Whenever you change a whitelist, blacklist, blocklist or do a gravity update it will sync to the other Pi-Hole. The first Pi-hole server is being used as DNS server and can be reached on ip 192.168.1.20, whenever this machine goes down or the pihole-FTL (DNS) service is down the HA IP (192.168.1.20) will switch to the second Pi-hole server. When the first Pi-hole server comes back online it switches the HA IP (192.168.1.20) back to this server.

 

Closing words:

I have witnessed that a lot of people loved my v1 tutorial as much as I did. Hopefully you'll enjoy this v2 even more! Of course I would like to thank GeorgeT (https://discourse.pi-hole.net/u/GeorgeT) on the Pi-hole forum for his pihole-gemini sync script. Also the people behind Pi-hole itself are greatly thanked! Pi-hole is truly a kickass piece of software! Last but certainly not least I would like to thank all of you! The kind words I received on the v1 tutorial are really appreciated.

 

Thanks for the Silver, kind stranger!

Another Gold, many thanks!!

My first ever Platinum! Many many thanks!!

And another Platinum! 😃😃

 

If you see something incorrect in my tutorial or have any other suggestions, tips etc please do share them!
