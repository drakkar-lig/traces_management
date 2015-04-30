#!/bin/bash
#/////////////////////////////////////////////////////////////////////////////////////////
# This program manages traces and sends them to a local computer
# 
#
#/////////////////////////////////////////////////////////////////////////////////////////
function headr
{
	clear
	echo "Trace manager V 1.0"
	echo "__________________________________________________________________________________"
}
function currDir # looks for a file containing the local dir, if not found asigns current
{
	if [[ -a ldir ]]; then
        loc_dir=`cat ldir`
	else
        loc_dir=`pwd`
        echo $loc_dir >> ldir
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
        echo $redir >> rdir
        rem_dir=$redir
	fi
}
function packNum
{
	if [[ -a ldir ]]; then
        pac_num=`cat pnum`
	else
        pac_num="100"
        echo "100" >> pnum
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
	else
		echo "$lodir"
	fi
}
function setPCpath
{
	clear
	headr
	echo "Please input the remote path to save the traces with user and host:"
	echo "user@host:path"
	read redir
    echo $redir >> rdir
}
function setpacketNum
{
	echo "please insert the number of packets of each segment"
	read pamun
    echo $panum >> pnum
}

function menu
{
	echo "1. Start a wifi segmented trace "
	echo "2. Start a wifi trace for 100 packets"
	echo "3. set RBP directory"
	echo "4. set PC (remote) directory"
	echo "5. set number of packets for each segment"
	echo "6. Help"
	echo "7. Exit"
	read opt
	case $opt in
		1)
		headr 
		menu
		;;
		2)
		headr $bt_pres $bt_stat
		menu
		;;
		3)
		headr $bt_pres $bt_stat
		BLEchain b
		echo "press a key to continue..."
		read qwe
		headr $bt_pres $bt_stat
		menu
		;;
		4)
		sudo hciconfig hci0 up
		sudo hciconfig hci0 leadv 3
		sudo hciconfig hci0 noscan
		bt_stat=`hciconfig|head -3|tail -1|grep "UP\|DOWN"`
		echo "press a key to continue..."
		read qwe
		headr $bt_pres $bt_stat
		menu
		;;
		5)
		sudo hciconfig hci0 down
		bt_stat=`hciconfig|head -3|tail -1|grep "UP\|DOWN"`
		echo "press a key to continue..."
		read qwe
		headr $bt_pres $bt_stat
		menu
		;;
		6)
		helpI
		headr $bt_pres $bt_stat
		menu
		;;
		7)
		exit 0
		;;
		*)
		echo "Please select from 1 to 6"
		echo "press a key to continue..."
		read qwe
		headr $bt_pres $bt_stat
		menu
		;;
	esac
############################################################
############################################################
#Start of program
############################################################
############################################################
currDir
remDir
packNum

echo "loc: "$loc_dir" rem: "$rem_dir" packets: "$pac_num

}