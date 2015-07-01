#!/bin/bash
#/////////////////////////////////////////////////////////////////////////////////////////
# This program synchronizes the traces taken from multiple points to be taken at the same 
#time and to last the same, it also collects information on the current status of the
#network and saves everything under a name with the date and hour
#/////////////////////////////////////////////////////////////////////////////////////////
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
   -c      Channel in wich the experiment will take place
   -d      Duration of the experiment in seconds, be adviced that in some machines it will not start immediately
   -m      mode: u for UDP, "anything" for TCP
   -k      current Terminal s,g,f,c for: Server > Gateway -- sniFfer -- > Client
   -a      server IP address
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
	head="$head `echo "    ////////////////////////////////////////////////////\n"`"
	head="$head`echo "    / Program Called at:         "`"
	head="$head `date +'%d/%m/%Y %H:%M:%S'`\n"
	echo "[utrace]waiting..."
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
#	echo $head>>$fileName-config.txt
#	echo $head2>>$fileName-config.txt
	printf "__________________________________\nSNIFFER CONFIGURATION.\nnet Config.\n__________________________________\n">>$fileName-config.txt
	ifconfig>>$fileName-config.txt
	printf "Wifi pre-Config.\n__________________________________\n">>$fileName-config.txt
	airport -I>>$fileName-config.txt
	tshark -i en1 -I -a duration:$DUR -w $fileName.pcapng
	printf "////////////////////////////////////////////////////////\nnote: the real start time is the endTime-duration\n////////////////////////////////////////////////////////\n" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	echo " /    Program ended at            $(date +'%d/%m/%Y %H:%M:%S')" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	#echo $head2 | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	printf "$head  /   trace duration:             $DUR segs\n" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
}

function gatewayTR
{
	#Raspberry Pi gateway
	echo "[gateway] Configuring Cahnnel and starting trace"
	#prepares a trace form the gateway
	sudo sed -i "27s/./channel=$2/" /etc/hostapd/hostapd.conf
	sudo service hostapd restart
	sudo ifconfig wlan0 192.168.42.1
	printf "__________________________________\nGATEWAY CONFIGURATION.\nnet Config.\n__________________________________\n">>$fileName-config.txt
	ifconfig>>$fileName-config.txt
	printf "Wifi Config.\n__________________________________\n">>$fileName-config.txt
	iwconfig>>$fileName-config.txt
	lshw -C network>>$fileName-config.txt
	sudo tshark -i wlan0 -a duration:$DUR -w $fileName.pcapng
	printf "////////////////////////////////////////////////////////\nnote: the real start time is the endTime-duration\n////////////////////////////////////////////////////////\n" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	echo " /    Program ended at            $(date +'%d/%m/%Y %H:%M:%S')" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	#echo $head2 | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	printf "$head  /   trace duration:             $DUR segs\n" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt

}

function clientTRSR
{
	#Android CLient
	echo "[client] Starting transmition and trace"
	#command to iperf...
	CM="iperf -c $IPs -i 1 -w 30000 -t $DUR -y C -m $mode"
	if [ "$mode" == "-u" ]; then
		hcc="UDP (cient)\ncommand: iperf -c $IPs -i 1 -w 30000 -t $DUR -y C -m $mode \ntimestamp, ipS, portS, ipD, portD, Interval, TRANSFER,BANDWIDTH\n"
	else
		hcc="TCP (cient)\ncommand: iperf -c $IPs -i 1 -w 30000 -t $DUR -y C -m $mode \ntimestamp, ipS, portS, ipD, portD, Interval, TRANSFER,BANDWIDTH\n"
	fi
	hc="     ////////////////////////////////////////////////////\n$hcc////////////////////////////////////////////////////////\n"
	printf "__________________________________\CLIENT CONFIGURATION.\nWifi Config.\n__________________________________\n">>$fileName-config.txt
	iwconfig>>$fileName-config.txt
	#starting parallel iperf/trace
	$CM  >> $fileName-iperf.txt &
	tshark -a duration:$DUR -w $fileName.pcapng &
	wait	
	printf "$hc" | cat - $fileName-iperf.txt  > temp &&mv temp $fileName-iperf.txt
	touch $fileName.pcapng

	printf "////////////////////////////////////////////////////////\nnote: the real start time is the endTime-duration\n////////////////////////////////////////////////////////\n" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	echo " /    Program ended at            $(date +'%d/%m/%Y %H:%M:%S')" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	#echo $head2 | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	printf "$head  /   trace duration:             $DUR segs\n" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt

	#copy the files to the /tmp 
	echo "[client] Transfering the files to /tmp"
	cp -p $fileName-iperf.txt /tmp
	cp -p $fileName-config.txt /tmp
	cp -p $fileName.pcapng /tmp
}

function serverTRSR
{
	#UBUNTU - home test MAC with home brew
	echo "[server] entering mode: $HN"	
	CM="iperf -s -i 1 -V -y C $mode"
	if [ "$mode" == "-u" ]; then
		hcc=" UDP (cient)\ncommand: $CM \ntimestamp, ipS, portS, ipD, portD, interval, TRANSFER, BANDWIDTH, JITTER, LOST/,TOTAL, DATAGRAMS, ?\n"
	else
		hcc=" TCP (cient)\ncommand: $CM \ntimestamp, ipS, portS, ipD, portD, Interval, TRANSFER,BANDWIDTH\n"
	fi
	hc="     ////////////////////////////////////////////////////\n$hcc////////////////////////////////////////////////////////\n"
	printf "__________________________________\SERVER CONFIGURATION.\nnet Config.\n__________________________________\n">>$fileName-config.txt
	ifconfig>>$fileName-config.txt
	#starting parallel iperf/trace

	timeout $DUR $CM >> $fileName-iperf.txt &
	sudo tshark -i eth0 -a duration:$DUR -w $fileName.pcapng &
	#gtimeout $DUR $CM >> $fileName-iperf.txt &
	#tshark -i en0 -a duration:$DUR -w $fileName.pcapng &
	wait
	echo "[serve] preparing files"
	printf "$hc" | cat - $fileName-iperf.txt  > temp &&mv temp $fileName-iperf.txt
	sudo touch $fileName.pcapng

	printf "////////////////////////////////////////////////////////\nnote: the real start time is the endTime-duration\n////////////////////////////////////////////////////////\n" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	echo " /    Program ended at            $(date +'%d/%m/%Y %H:%M:%S')" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	#echo $head2 | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
	printf "$head  /   trace duration:             $DUR segs\n" | cat - $fileName-config.txt > temp && mv temp $fileName-config.txt
}

function namer 
{
	#Give better names to known experiment machines $start $channel
	case $HN in
		f|castillo.imag.fr|macbook-pro-de-pierangelo.home|MacBook-Pro-de-Pierangelo.local)
		LocMachine="MAC(sniffer)_"
		fileName="${LocMachine}_${nowF}"
		WFsnifferTR $1 $2
		;;
		c|ANDROID)
		LocMachine="ANDROID(client)_"
		fileName="${LocMachine}_${nowF}"
		clientTRSR
		;;
		g|drakkarexp1|drakkarexp4)
		LocMachine="RBP(gateway)_"
		fileName="${LocMachine}_${nowF}"
		gatewayTR $1 $2
		;;
		s|walt-OptiPlex-380)
		LocMachine="UBUNTU(server)_"
		fileName="${LocMachine}_${nowF}"
		serverTRSR
		;;
		*)
		LocMachine=$HN
		;;
	esac
}

#  ////////////////////////////////////////////////////////
# ///////////////// PROGRAM //////////////////////////////
#////////////////////////////////////////////////////////

HN=`hostname`
IPs="129.88.49.84"
mode=""
nowF="$(date +'%d%m%Y_%H%M%S')"
DUR=300
while getopts “hs:c:d:m:k:a:i” OPTION
do
     case $OPTION in
     	 a)
			IPs=$OPTARG
			;;
         h)
             usage
             exit 1
             ;;
         s)
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
             cha=$OPTARG
             ;;
         d)
             if [ $OPTARG ]; then
				DUR=$OPTARG
			else
				DUR=300
			fi
             ;;
         m)
			#UDP or TCP
			if [ $OPTARG == "u" ]; then
				mode="-$OPTARG"
			else
				mode=""
			fi
			;;
		k)
			HN=$OPTARG
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
waitt $startAT $cha
head="$head`echo "   /  Program start request at    $(date +'%d/%m/%Y %H:%M:%S')\n"`"
echo "[trace/service]requesting start..."
namer $startAT $cha
echo "[utrace] All task done..."
