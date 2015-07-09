#!/bin/bash
usage()
{
cat << EOF
usage: $0 options

Starts a configuration on the local machine to tansmit/receive/trace in UDP/TCP and will create a pseudo sincronous start with other machines, it will also create traces
were possible

OPTIONS:
   -h      Show this message
   -s      Starting date, it can be given in full YYYYmmddHHMMSS or just HHMMSS to start the same day
   -c      "1" Shuts down bluetooth interface, "anything else" to bring it up
   -d      Duration of the experiment in seconds, if not specified 5 minutes
   -f      frame to transmitt in the beacon (-m t MUST be send as well)
   -d      Duration of the experiment in seconds, be adviced that in some machines it will not start immediately
   -m      mode: t for transmission mode, "anything else" for scan mode
   -i      information of the current state
EXAMPLES:
   The command:
   		utrace -s 20150612153412 -c 6 -m t
   will start a trace in ~/work/TRACES/ at 15:34:12 5 min duration on channel 6
   or a TCP server/client for 5 minutes
   The command:
   		utrace -s 123235 -d 600 -c 3  -m u
   will start a trace Today 10 min duration on channel 3
   or a UDP server/client for 10 minutes
EOF
}

function reb
{
	sudo hciconfig hci0 down
	sudo hciconfig hci0 up
    sudo hciconfig hci0 leadv 3
    sudo hciconfig hci0 noscan
}
function waitt
{
	echo "[ble]waiting..."
        while [ $1 -gt $now  ]
        do
                if [ $len -eq 14 ]; then
                        now="$(date +'%Y%m%d%H%M%S')"
                elif [ $len -eq 6 ]; then
                        now="$(date +'%H%M%S')"
        else
                        echo "Unknown error..."
                        exit 1
                fi
        done
}

function bleStop
{
	if [ $ST == "1" ]; then
		echo "[ble]Shutting down bluetooth interface"
		sudo hciconfig hci0 down
	else
		echo "[ble]Turning on bluetooth interface"
		sudo hciconfig hci0 up
        sudo hciconfig hci0 leadv 3
        sudo hciconfig hci0 noscan
	fi
}

function bleInfo
{
	bt_id=""
	bt_pres="-"
	bt_stat="-"
	echo "[ble-stat]Looking for BLE dongle..."
	bt_id=`lsusb|grep ASUS|cut -c24-32`

	#check if the ASUS USB BLE is present, if not the program will end, else it checks the BLE state
	if [[ -z "$bt_id" ]]; then
		bt_pres="not found"
		headr $bt_pres $bt_stat
		echo "[Error]Bongle not found"
		exit 1
	else
		bt_pres="OK"
		bt_stat=`hciconfig|head -3|tail -1|grep "UP\|DOWN"`
		echo "[status] Dongle:"$bt_pres" Status:"$bt_stat
	fi
}
function bleScan
{
        reb
        timeout $DUR sudo hcitool lescan --duplicates>beacons.txt &
        timeout $DUR sudo hcidump --raw -w ibeacons.log &
        wait
}
ST=2
DUR=300
MODE="e"

while getopts “hs::mf:d:c:i” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         s)
			len=${#OPTARG}
             startAT=$OPTARG
             if [ $len -eq 14 ]; then
                now="$(date +'%Y%m%d%H%M%S')"
        	elif [ $len -eq 6 ]; then
                now="$(date +'%H%M%S')"
        	else
                echo "use --14 digits date yyyymmddHHMMSS or 6 digits hour HHSSMM"
                exit 1
        	fi
             ;;
         c)
             ST=$OPTARG
             bleStop 
             exit
             ;;
        d)
             if [ $OPTARG ]; then
				DUR=$OPTARG
			else
				DUR=300
			fi
             ;;
         m)
             MODE=$OPTARG
             ;;  
         f)
			FRM=$OPTARG
			;;
         i)
			 bleInfo
            exit
             ;;
         ?)
             usage
             exit
             ;;
     esac
done
if [ $len -gt 0 ]; then
	waitt $startAT
	echo "[ble]requesting start..."

	
	if [ $MODE == "t" ];then
		echo "[ble] Starting transmission..."
	else
		echo "[ble] Starting Scan, logs will be saved in current directory"
		bt_stat=`hciconfig|head -3|tail -1|grep "UP\|DOWN"`
		if [ "${bt_stat}" == "DOWN" ]; then
			echo "[ble]Can't complete task, bluetooth State:"$bt_stat
			exit
		else
			bleScan
		fi
	fi
else
	echo "[ble] Write uble -h for usage"
fi