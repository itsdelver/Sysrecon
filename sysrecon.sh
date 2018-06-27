#!/usr/bin/env bash
#Author: Eli
#A script for scraping system information


# ----------Options---------- #

logging=0
verbose=0
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
			echo "-l, --log 	Switches to file output"
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
			verbose=1
			;;
		-l|--logging)
			logging=1
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

#Prints the main banner
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


#Turns on file output if flag present
enableLogging(){
	exec 1<&- #Close STDOUT file descriptor
	exec 2<&- #Close STDERR file desriptor
	exec 2>&1 #Redirect STDERR to STDOUT
}


#Get hostname
getHostname(){
	echo ""
	echo "--> Getting hostname..."
	echo "$(hostname)"
}



#Check for internet access
checkInternet(){
	echo ""
	echo "--> Checking for internet..."

	ping -c1 8.8.8.8 > /dev/null
	internet=$?

	if [ "$internet" != 0 ]
	then
		echo "internet-failed"
	else 
		echo "internet-confirmed"
	fi
}


#Get network adapter information
getNetInfo(){
	echo ""
	echo "--> Getting net adapter info..."
	echo "$(ip addr)"	
}


#Get routing table
getRoutes(){
	echo ""
	echo "--> Getting routing table..."
	echo "$(ip route)"
}


#Get system information
getSysInfo(){
	echo ""
	echo "--> Getting system info..."
	echo "$(uname -a)"
}


#Get process info
getProcInfo(){ 
	echo ""
	echo "--> Getting process info..."
	echo "$(systemctl | grep running)"
}


#Get installed apps
getInstalledApps(){
	echo ""
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
	echo ""
	echo "--> Getting listening ports..."
	echo "$(ss -lutn)"
}


#Get users
getUsers(){
	echo ""
	echo "--> Getting users..."
	echo "$(cat /etc/passwd)"
}


#Get startup apps
getStartup(){
	echo ""
	echo "--> Getting starup apps..."
	echo "$(systemctl list-unit-files --state=enabled)"
}


#Writable files
writableFiles(){
	echo ""
	echo "--> Finding writable locations..."
	echo "$(find / -perm -222 -type d 2>/dev/null)"
}


#Group sticky bit
findStickyGroup(){
	echo ""
	echo "--> Finding files with group sticky bit..." 
	echo "$(find / -perm -g=s -type f 2>/dev/null)"
}


#Owner sticky bit
findStickyOwner(){
	echo ""
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
	output+=(getHostname)
	output+=(checkInternet)
	output+=(getNetInfo)
	output+=(getRoutes)
	output+=(getSysInfo)
	output+=(getProcInfo)
	output+=(getInstalledApps)
	output+=(getListeningPorts)
	output+=(getUsers)
	output+=(getStartup)
	output+=(writableFiles)
	output+=(findStickyGroup)
	output+=(findStickyOwner)
	
	if [ $logging -eq 1 ]
	then
		enableLogging
		for ops in ${output[@]}
		do 
			exec 1<>"$ops.txt" #Open STDOUT as a file for read and write	
			echo "$($ops)" 
		done
	else
		printBanner
		for ops in ${output[@]}
		do 
			echo "$($ops)" 
		done
	fi
else	
	if [ $logging -eq 1 ]
	then
		enableLogging
		for ops in ${!optionSet[@]}
		do
			exec 1<>"${optionSet[$ops]}.txt" #Open STDOUT as a file for read and write
			${optionSet[$ops]}
		done
	else
		printBanner
		for ops in ${!optionSet[@]}
		do
			${optionSet[$ops]}
		done
	fi
fi

