#!/bin/bash
#/////////////////////////////////////////////////////////////////////////////////////////
# This program manages traces and sends them to a local computer
# 
#
#/////////////////////////////////////////////////////////////////////////////////////////
function waitt
{
	echo ""
	echo "press Enter to continue..."
	read qwe
}
function headr
{
	clear
	local st1="$1"
	local st2="$2"
	local st3="$3"
	echo "Trace manager V 1.0"
	echo "__________________________________________________________________________________"
	echo "LOCAL DIR: ${st1}"
	echo "REMOTE DIR: ${st2}"
	echo "PACKETS PER SEGMENT: ${st3}"
	echo "__________________________________________________________________________________"
}
function currDir # looks for a file containing the local dir, if not found asigns current
{
	if [[ -a ldir ]]; then
        loc_dir=`cat ldir`
	else
        loc_dir=`pwd`
        echo $loc_dir > ldir
	fi
}
function remDir #checks for file containing the remote dir, if not found, ask for one
{
	if [[ -a rdir ]]; then
        rem_dir=`cat rdir`
	else
		echo "Please input the remote path to save the traces with user and host:"
		echo "user@host:path"
		read redir
        echo $redir > rdir
        rem_dir=$redir
	fi
}
function packNum
{
	if [[ -a pnum ]]; then
        pac_num=`cat pnum`
	else
        pac_num="100"
        echo "100" > pnum
	fi
}
function setRBPpath
{
	clear
	headr
	echo "please input the local directory where traces will be stored ~/work/TRACES/wifi/"
	echo "If left blank, the last ubication will be use, or current location if 1st time"
	echo "Remember it needs 777 permits"

	read lodir
	if [[ -z "$lodir" ]]; then
		echo "using last or current directory: " $loc_dir
		waitt
	else
    	echo $lodir > ldir
	fi
}
function setPCpath
{
	clear
	headr
	echo "Please input the remote path to save the traces with user and host:"
	echo "user@host:path"
	read redir
	if [[ -z "$redir" ]]; then
		echo "using last directory: " $rem_dir
		waitt
	else
		echo $redir > rdir
	fi
}
function numcheck
{
	if [ "$1" -eq "$1" ] 2>/dev/null
	then
		echo $1 > pnum
	else
		headr $loc_dir $rem_dir $pac_num
		echo ""
		echo "Error: Not a number, try again"
		setpacketNum
	fi
}
function setpacketNum
{
	echo ""
	echo "please insert the number of packets of each segment:"
	read pamun
	if [[ -z "$pamun" ]]; then
		echo "using last number of packets: " $pac_num
		waitt
	else
	numcheck $pamun
	fi
}

function startTrace
{
	local st="$1"
	rm temp.pcapng
	now="$(date +'%d%m%Y_%H%M')"
	file="${now}_traceResult.pcapng" 
	desc="${now}_Description"
	var=1
	echo "" > $desc.txt
	headr $loc_dir $rem_dir $pac_num
	echo "A trace will start"
	waitt
	while : ; do
		headr $loc_dir $rem_dir $pac_num
		echo ""
		echo "Stage $var:"
		echo "_____________________________"
		echo "Please enter a description for this stage or"
		echo "Type Enter to stop this session"
		read descr
		if [[ -z $descr  ]]; then
			echo "Session ended"
			if [ $var \= 1 ]; then
				echo "No packets were captured.."
				waitt
				break
			else
				echo "transfering the files.. input remote pass..."
				sudo scp $file $desc.txt $rem_dir
				break
			fi
		else
			echo "${var}. ${descr}" >> $desc.txt
			echo $pac_num
			if [ $st \= 1 ]; then
				sudo tshark -c $pac_num -i wlan0 -w temp.pcapng
			else
				sudo cp -p $file temp2.pcapng
				sudo tshark -c 100 -i wlan0 -w temp.pcapng
			fi
			if [ $var \= 1 ]; then	
				echo "creating first file form temp"
				sudo cp -p temp.pcapng $file
				waitt
			else
				echo "merging file with new temp"
				sudo mergecap temp.pcapng temp2.pcapng -w $file
				waitt
			fi
			((var++))
		fi
		
	done

}

function menu
{
	echo "1. Start a wifi segmented trace "
	echo "2. Start a wifi trace for 100 packets"
	echo "  3. set RBP directory"
	echo "  4. set PC (remote) directory"
	echo "  5. set number of packets for each segment"
	echo "6. Help"
	echo "7. Exit"
	read opt
	case $opt in
		1)
		headr $loc_dir $rem_dir $pac_num 
		startTrace 1
		headr $loc_dir $rem_dir $pac_num
		menu
		;;
		2)
		headr $loc_dir $rem_dir $pac_num
		startTrace 2
		headr $loc_dir $rem_dir $pac_num
		menu
		;;
		3)
		headr $loc_dir $rem_dir $pac_num
		setRBPpath
		headr $loc_dir $rem_dir $pac_num
		menu
		;;
		4)
		headr $loc_dir $rem_dir $pac_num
		setPCpath
		headr $loc_dir $rem_dir $pac_num
		menu
		;;
		5)
		headr $loc_dir $rem_dir $pac_num
		setpacketNum
		headr $loc_dir $rem_dir $pac_num
		menu
		;;
		6)
		headr $loc_dir $rem_dir $pac_num
		helpI
		headr $loc_dir $rem_dir $pac_num
		menu
		;;
		7)
		exit 0
		;;
		*)
		echo "Please select from 1 to 7"
		waitt
		headr $loc_dir $rem_dir $pac_num
		menu
		;;
	esac
}
############################################################
############################################################
#Start of program
############################################################
############################################################
#initialization
currDir
remDir
packNum

headr $loc_dir $rem_dir $pac_num
menu
