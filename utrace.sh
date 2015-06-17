#!/bin/bash
#/////////////////////////////////////////////////////////////////////////////////////////
# This program synchronizes the traces taken from multiple points to be taken at the same 
#time and to last the same, it also collects information on the current status of the
#network and saves everything under a name with the date and hour
#/////////////////////////////////////////////////////////////////////////////////////////

HN=`hostname`
DUR=300


#Give better names to known experiment machines

case $HN in
	castillo.imag.fr)
	LocMachine = "MAC(sniffer)_"
	ANDROID)
	LocMachine = "ANDROID(client)_"
	drakkarexp1)
	LocMachine = "RBP1(gateway)_"
	drakkarexp4)
	LocMachine = "RBP4(gateway)_"
	walt-OptiPlex-380)
	LocMachine = "UBUNTU(server)_"
	*)
	LocMachine = $HN
esac

now="$(date +'%d%m%Y_%H%M%S')"
fileName="${LocMachine}_${now}"

function WFsniffer
{
	#mac sniffer

	#prepare interface
	sudo airport -z
	sudo airport c6
	tshark -i en1 -I -a duration:$DUR -w $fileName.pcapng

}

function gatewayTR
{
	#prepares a trace form the gateway
	sudo tshark -i wlan0 -a duration:$DUR -w $fileName.pcapng
}

