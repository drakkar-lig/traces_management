#!/bin/bash
#/////////////////////////////////////////////////////////////////////////////////////////
# This program synchronizes the traces taken from multiple points to be taken at the same 
#time and to last the same, it also collects information on the current status of the
#network and saves everything under a name with the date and hour
#/////////////////////////////////////////////////////////////////////////////////////////
#!/bin/bash
# Argument = -t test -r server -p password -v

usage()
{
cat << EOF
usage: $0 options

Starts a configuration on the local machine to tansmit/receive/trace in UDP/TCP and will create a pseudo sincronous start with other machines, it will also create traces 
were possible

OPTIONS:
   -h      Show this message
   -s      Starting date, it can be given in full YYYYmmddHHMMSS or just HHMMSS to start the same day
   -c      Channel in wich the experiment will take place
   -d      Duration of the experiment in seconds, be adviced that in some machines it will not start immediately
   -m      mode t for TCP u for UDP
   -i      information of the current machine
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
function infor
{
	        echo "Showing Information..."
            echo "  ////////////////////////////////////////////////////////"
			echo " ///////////////// network //////////////////////////////"
			echo "////////////////////////////////////////////////////////"
            ifconfig
            echo "  ////////////////////////////////////////////////////////"
			echo " ///////////////// wireless /////////////////////////////"
			echo "////////////////////////////////////////////////////////"
            iwconfig
            echo "  ////////////////////////////////////////////////////////"
			echo " //////////////////// macos /////////////////////////////"
			echo "////////////////////////////////////////////////////////"
            airport -I
}
function waitt
{
head="$head `echo "Program Called at: "`"
head="$head `date +'%d/%m/%Y %H:%M:%S'`"
#
echo "[waitt]set to start at: $1"
echo "[waitt]Program Called at: "
date
echo "__________________________________"
#
echo "[waitt]waiting..."
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

function WFsnifferTR
{
	#mac sniffer
	#prepare interface
	echo "configuring to capture 802.11 packets in Channel "$2
	sudo airport -z
	sudo airport -c$2
#	echo $head>>config_$fileName.txt
#	echo $head2>>config_$fileName.txt
	echo "__________________________________">>config_$fileName.txt
	echo "SNIFFER CONFIGURATION.">>config_$fileName.txt
	echo "net Config.">>config_$fileName.txt
	echo "__________________________________">>config_$fileName.txt
	ifconfig>>config_$fileName.txt
	echo "Wifi pre-Config.">>config_$fileName.txt
	echo "__________________________________">>config_$fileName.txt
	airport -I>>config_$fileName.txt
	
	tshark -i en1 -I -a duration:$DUR -w $fileName.pcapng
	echo "Program ended at $(date +'%d/%m/%Y %H:%M:%S')" | cat - config_$fileName.txt > temp && mv temp config_$fileName.txt
	echo "trace duration: "$DUR"segs" | cat - config_$fileName.txt > temp && mv temp config_$fileName.txt
	echo $head2 | cat - config_$fileName.txt > temp && mv temp config_$fileName.txt
	echo $head | cat - config_$fileName.txt > temp && mv temp config_$fileName.txt
	
	
	#echo "Program ended at $(date +'%d/%m/%Y %H:%M:%S')">>config_$fileName.txt

}

function gatewayTR
{
	#prepares a trace form the gateway
	sudo sed -i "27s/./channel=$3/" /etc/hostapd/hostapd.conf
	sudo service hostapd restart
	sudo tshark -i wlan0 -a duration:$DUR -w $fileName.pcapng
}
function namer 
{
	#Give better names to known experiment machines
	echo "The hostname is "$HN
	case $HN in
		castillo.imag.fr)
		LocMachine="MAC(sniffer)_"
		fileName="${LocMachine}_${nowF}"
		WFsnifferTR $1 $2
		;;


#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
		macbook-pro-de-pierangelo.home)
		LocMachine="MAC(sniffer)_"
		fileName="${LocMachine}_${nowF}"
		WFsnifferTR $1 $2
		;;
		MacBook-Pro-de-Pierangelo.local)
		LocMachine="MAC(sniffer)_"
		fileName="${LocMachine}_${nowF}"
		WFsnifferTR $1 $2
		;;
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


		ANDROID)
		LocMachine="ANDROID(client)_"
		;;
		drakkarexp1)
		LocMachine="RBP1(gateway)_"
		;;
		drakkarexp4)
		LocMachine="RBP4(gateway)_"
		;;
		walt-OptiPlex-380)
		LocMachine="UBUNTU(server)_"
		;;
		*)
		LocMachine=$HN
		;;
	esac
	echo "LocalM: "$LocMachine
}

#  ////////////////////////////////////////////////////////
# ///////////////// PROGRAM //////////////////////////////
#////////////////////////////////////////////////////////

HN=`hostname`
nowF="$(date +'%d%m%Y_%H%M%S')"
DUR=300
while getopts “hs:c:d:i” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         s)
echo "[pr] date OK? ($OPTARG)"
			len=${#OPTARG}
             startAT=$OPTARG
             if [ $len -eq 14 ]; then
                now="$(date +'%Y%m%d%H%M%S')"
                #waitt $1 $2 $channel
        	elif [ $len -eq 6 ]; then
                now="$(date +'%H%M%S')"
                #waitt $1 $2 $channel
        	else
                echo "use --14 digits date yyyymmddHHMMSS or 4 digits hour HHSSMM"
                exit 1
        	fi
             ;;
         c)
echo "[pr] Channel OK ($OPTARG)"
             cha=$OPTARG
             ;;
         d)
echo "[pr] duración OK? ($OPTARG)"
             if [ $OPTARG ]; then
				DUR=$OPTARG
			else
				DUR=300
			fi
             ;;
         i)
			infor
            exit
             ;;
         ?)
             usage
             exit
             ;;
     esac
done
echo "durara.. $DUR"
waitt $startAT $cha
head2="`echo "Program start request at $(date +'%d/%m/%Y %H:%M:%S')"`"
echo "[trace/service]requesting start..."
date
namer $startAT $cha

