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
			echo "Simple bash recon script to fetch various system information"
			echo "With no arguments this script will run all options and print to stdin. "
			echo ""
			echo "Options:"
			echo "-h, --help	Show this menu"
			echo "-v, --verbose	Add verbosity"
			echo "--options=	Specify what information to gather, comma seperated list no spaces (--options=this,is,an,example)"
			echo "    internet"
			echo "    netadapter"
			echo "    route"
			echo "    sysinfo"
			echo "    proc"
			echo "    installedapp"
			echo "    port"
			echo "    user"
			echo "    startupapp"
			echo "    writable"
			echo "    stickygroup"
			echo "    stickyowner"
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
					internet) 
						optionSet[internet]=checkInternet
						;;				
					netadapter)
						optionSet[netadapter]=getNetInfo
						;;
					route)
						optionSet[route]=getRoutes
						;;
					sysinfo)
						optionSet[sysinfo]=getSysInfo
						;;
					proc)
						optionSet[proc]=getProcInfo
						;;
					installedapp)
						optionSet[installedapp]=getInstalledApps
						;;
					port)
						optionSet[port]=getListeningPorts
						;;
					user) 
						optionSet[user]=getUsers
						;;
					startupapp)
						optionSet[startupapp]=getStartup
						;;
					writable)
						optionSet[writable]=writableFiles
						;;
					stickygroup)
						optionSet[stickygroup]=findStickyGroup
						;;
					stickyowner)
						optionset[stickyowner]=findStickyOwner
						;;
					*)
						echo "Error in --options"
				esac
			done 
			;;
		*)
			echo "Error with flags"
			exit 0
			;;
	esac
done			


# ----------Functions---------- #

#Get hostname
getHostname(){
	echo "--> Getting hostname..."
	echo "$(hostname)"
	echo ""
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
	echo ""
}


#Get network adapter information
getNetInfo(){
	echo "--> Getting net adapter info..."
	echo "$(ip addr)"
	echo ""		
}


#Get routing table
getRoutes(){
	echo "--> Getting routing table..."
	echo "$(ip route)"
	echo ""
}


#Get system information
getSysInfo(){
	echo "--> Getting system info..."
	echo "$(uname -a)"
	echo ""
}


#Get process info
getProcInfo(){ 
	echo "--> Getting process info..."
	echo "$(systemctl | grep running)"
	echo ""
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
	echo ""
}


#Get listening internet ports
getListeningPorts(){
	echo "--> Getting listening ports..."
	echo "$(ss -lutn)"
	echo ""
}


#Get users
getUsers(){
	echo "--> Getting users..."
	echo "$(cat /etc/passwd)"
	echo ""
}


#Get startup apps
getStartup(){
	echo "--> Getting starup apps..."
	echo "$(systemctl list-unit-files --state=enabled)"
	echo ""
}


#Writable files
writableFiles(){
	echo "--> Finding writable locations..."
	echo "$(find / -perm -222 -type d 2>/dev/null)"
	echo ""
}


#Group sticky bit
findStickyGroup(){
	echo "--> Finding files with group sticky bit..." 
	echo "$(find / -perm -g=s -type f 2>/dev/null)"
	echo ""
}


#Owner sticky bit
findStickyOwner(){
	echo "--> Finding files with owner sticky bit..."
	echo "$(find / -perm -u=s -type f 2>/dev/null)"
	echo ""
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
		output+=$(getHostname)
	 	output+=$(checkInternet)
		output+=$(getNetInfo)
		output+=$(getRoutes)
		output+=$(getSysInfo)
		output+=$(getProcInfo)
		output+=$(getInstalledApps)
		output+=$(getListeningPorts)
		output+=$(getUsers)
		output+=$(getStartup)
		output+=$(writableFiles)
		output+=$(findStickyGroup)
		output+=$(findStickyOwner)
		#echo "${output[@]}"
		end

	for ops in ${output[@]}
	do
		echo $ops
	done
else	
	for ops in ${!optionSet[@]}
	do
		${optionSet[$ops]}
	done
	end
fi
