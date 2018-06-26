#!/usr/bin/env bash
#Author: Eli
#A script for scraping system information


printBanner(){
	clear
	
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "+  _______  __   __  _______  ______    _______  _______  _______  __    _  +"
	echo "+ |       ||  | |  ||       ||    _ |  |       ||       ||       ||  |  | | +"
	echo "+ |  _____||  |_|  ||  _____||   | ||  |    ___||       ||   _   ||   |_| | +"
	echo "+ | |_____ |       || |_____ |   |_||_ |   |___ |       ||  | |  ||       | +"
	echo "+ |_____  ||_     _||_____  ||    __  ||    ___||      _||  |_|  ||  _    | +"
	echo "+  _____| |  |   |   _____| ||   |  | ||   |___ |     |_ |       || | |   | +"
	echo "+ |_______|  |___|  |_______||___|  |_||_______||_______||_______||_|  |__| +"
	echo "+                                                                           +"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo ""
}


# ----------Options---------- #

printBanner
declare -A optionSet;
for opts in $@
do
	case "$opts" in
		-h|--help)
			echo "Simple system recon bash script that fetches some system info and writes the info to files (or as file names), zips them together, and cleans up."
			echo "Default: 	Internet connectivity, network adapter info, kernal info, running processes, installed apps, open ports, users, and startup apps, routes, writable locations, files with sticky bit (owner and group) set"
			echo ""
			echo "Options:"
			echo "-h, --help	Show this menu"
			echo "-v, --verbose	Add verbosity"
			exit 0
			;;
		-v|--verbose)
			set -x
			;;
		--options=*)
			IFS=','	
			for curOpt in ${opts:10} 
			do
				case $curOpt in
					t) 
						echo "THIS WAS THE T"
						;;				
					e)
						echo "THERE WAS AN E"
						;;
					s)
						echo "FOUND AN S"
						;;
				esac
			done 
			;;
		*)
			echo "Error with options"
			exit 0
			;;
	esac
done			


# ----------Functions---------- #

#Get hostname
getHostname(){
	echo "--> Getting hostname..."
	echo "$(hostname)"
}



#Check for internet access
checkInternet(){
	echo "--> Checking for internet..."

	ping -c1 8.8.8.8 > /dev/null
	internet=$?

	if [ "$internet" != 0 ]
	then
		echo "internet-failed.txt"
	else 
		echo "internet-confirmed.txt"
	fi
}


#Get network adapter information
getNetInfo(){
	echo "--> Getting net adapter info..."
	echo "$(ip addr)"
}


#Get routing table
getRoutes(){
	echo "--> Getting routing table..."
	echo "$(ip route)"
}


#Get system information
getSysInfo(){
	echo "--> Getting system info..."
	echo "$(uname -a)"
}


#Get process info
getProcInfo(){ 
	echo "--> Getting process info..."
	echo "$(systemctl | grep running)"
}


#Get installed apps
getInstalledApps(){
	echo "--> Getting program list..."
	declare -A os;
	
	os[/etc/redhat-release]="dnf list installed" 
	os[/etc/arch-release]="pacman -Q" 
	os[/etc/SuSE-release]="zypper search --installed-only"
	os[/etc/debian_version]="dpkg -l"

	for pac in "${!os[@]}"
	do
		if [ -f $pac ] 
		then
			 echo "$(${os[$pac]})"
		fi
	done
}


#Get listening internet ports
getListeningPorts(){
	echo "--> Getting listening ports..."
	echo "$(ss -lutn)"
}


#Get users
getUsers(){
	echo "--> Getting users..."
	echo "$(cat /etc/passwd)"
}


#Get startup apps
getStartup(){
	echo "--> Getting starup apps..."
	echo "$(systemctl list-unit-files --state=enabled)"
}


#Writable files
writableFiles(){
	echo "--> Finding writable locations..."
	echo "$(find / -perm -222 -type d 2>/dev/null)"
}


#Group sticky bit
findStickyGroup(){
	echo "--> Finding files with group sticky bit..." 
	echo "$(find / -perm -g=s -type f 2>/dev/null)"
}


#Owner sticky bit
findStickyOwner(){
	echo "--> Finding files with owner sticky bit..."
	echo "$(find / -perm -u=s -type f 2>/dev/null)"
}


#Clean up
end(){
	mkdir /tmp/sysrecon

	echo "--> Zipping files..."
	zip -j $host.zip /tmp/sysrecon/* > /dev/null

	echo "--> Cleaning up..."
	rm -r /tmp/sysrecon
	set +x
	
	echo "--> Exiting"
	exit 0
}


# ----------Command Building---------- #
if [ ${#optionSet[@]} -eq 0 ] 
then
	end
else	
	end
fi

#printBanner
#getHostname
#checkInternet
#getNetInfo
#getRoutes
#getSysInfo
#getProcInfo
#getInstalledApps
#getListeningPorts
#getUsers
#getStartup
#writableFiles
#findStickyGroup
#findStickyOwner
#end
