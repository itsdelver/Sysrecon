#!/bin/bash
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
netinfo=$(ifconfig)


#Get system information
echo "--> Getting system info..."
kernal=$(uname -v) 


#Get process info 
echo "--> Getting process info..."
processes=$(ps -aux)


#Get installed aps
echo "--> Getting program list..."
declare -A os;

os[/etc/redhat-release]="yum list installed" 
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
ports=$(netstat -at)


#Get users
echo "--> Getting users..."
users=$(cat /etc/passwd)


#Get startup apps
echo "--> Getting starup apps..."
startup=$(ls /etc/init.d)


#Write and zip
echo "--> Writing files..."

touch "$internet-$host".txt
echo "$netinfo" > netinfo-$host.txt
touch "$kernal-$host".txt
echo "$processes" > proc-$host.txt
echo "$apps" > apps-$host.txt
echo "$ports" > ports-$host.txt
echo "$users" > users-$host.txt
echo "$startup" > startup-$host.txt

echo "--> Zipping up..."
zip $host.zip *-$host.txt > /dev/null

echo "--> Cleaning up"
rm *$host.txt
set +x
