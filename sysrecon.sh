#!/usr/bin/env bash
#Author: Eli
#A script for scraping system information

clear

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ _______  __   __  _______  ______    _______  _______  _______  __    _ +"
echo "+|       ||  | |  ||       ||    _ |  |       ||       ||       ||  |  | |+"
echo "+|  _____||  |_|  ||  _____||   | ||  |    ___||       ||   _   ||   |_| |+"
echo "+| |_____ |       || |_____ |   |_||_ |   |___ |       ||  | |  ||       |+"
echo "+|_____  ||_     _||_____  ||    __  ||    ___||      _||  |_|  ||  _    |+"
echo "+ _____| |  |   |   _____| ||   |  | ||   |___ |     |_ |       || | |   |+"
echo "+|_______|  |___|  |_______||___|  |_||_______||_______||_______||_|  |__|+"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""

# ----------Options---------- #

while [ $# -gt 0 ];
do
	case "$1" in
		-h|--help)
			echo "Simple system recon bash script that fetches some system info and writes the info to files (or as file names), zips them together, and cleans up."
			echo "Default: 	Internet connectivity, network adapter info, kernal info, running processes, installed apps, open ports, users, and startup apps."
			echo ""
			echo "Options:"
			echo "-h, --help	Show this menu"
			echo "-v, --verbose	Add verbosity"
			exit 0
			;;
		-v|--verbose)
			set -x
			break
			;;
		*)
			break
			;;
	esac
done			


# ----------Body---------- #

#Check for internet access
echo "--> Checking for internet..."

ping -c1 8.8.8.8 > /dev/null
internet=$?

if [ "$internet" != 0 ]
then
	internet="internet-failed"
else 
	internet="internet-confirmed"
fi


#Get hostname
echo "--> Getting hostname..."
host=$(hostname)


#Get network adapter information
echo "--> Getting net adapter info..."
netinfo=$(ip addr)


#Get routing table
echo "--> Getting routing table..."
route=$(ip route)


#Get system information
echo "--> Getting system info..."
kernal=$(uname -v) 


#Get process info 
echo "--> Getting process info..."
processes=$(systemctl | grep running)


#Get installed apps
echo "--> Getting program list..."
declare -A os;

os[/etc/redhat-release]="dnf list installed" 
os[/etc/arch-release]="pacman -Q" 
os[/etc/SuSE-release]="zypper search --installed-only"
os[/etc/debian_version]="dpkg -l"

declare apps;
for pac in "${!os[@]}"
do
	if [ -f $pac ] 
	then
		 apps=$(${os[$pac]})
	fi
done


#Get listening internet ports
echo "--> Getting listening ports..."
ports=$(ss -lutn)


#Get users
echo "--> Getting users..."
users=$(cat /etc/passwd)


#Get startup apps
echo "--> Getting starup apps..."
startup=$(systemctl list-unit-files --state=enabled)


#Writable files
echo "--> Finding writable locations..."
writable=$(find / -perm -222 -type d 2>/dev/null)


#Group sticky bit
echo "--> Finding files with group sticky bit..." 
gbit=$(find / -perm -g=s -type f 2>/dev/null)


#Owner sticky bit
echo "--> Finding files with owner sticky bit..."
obit=$(find / -perm -u=s -type f 2>/dev/null)


#Write and zip
echo "--> Writing files..."
mkdir /tmp/sysrecon

touch "/tmp/sysrecon/$internet-$host".txt
echo "$netinfo" > /tmp/sysrecon/netinfo-$host.txt
echo "$route" > /tmp/sysrecon/route-$host.txt
touch "/tmp/sysrecon/$kernal-$host".txt
echo "$processes" > /tmp/sysrecon/proc-$host.txt
echo "$apps" > /tmp/sysrecon/apps-$host.txt
echo "$ports" > /tmp/sysrecon/ports-$host.txt
echo "$users" > /tmp/sysrecon/users-$host.txt
echo "$startup" > /tmp/sysrecon/startup-$host.txt
echo "$writable" > /tmp/sysrecon/writable-$host.txt
echo "$gbit" > /tmp/sysrecon/gbit-$host.txt
echo "$obit" > /tmp/sysrecon/obit-$host.txt

echo "--> Zipping up..."
zip -j $host.zip /tmp/sysrecon/* > /dev/null

echo "--> Cleaning up"
rm -r /tmp/sysrecon
set +x
