# traces_management

Testbench for Wireless/wired/mixed Network experiments using Wi-Fi and Bluetooth, a start time or date can be set, it is advisable to syncronize the time in all the network components i.e. install a NTP server. 


___________________________EXAMPLES_________________________

EXAMPLE 1:
Android phone acting as a TCP Client transmitting to a Ubuntu TCP server through a RBP Access Point, the experiment is set to start running at 17:50:00

topology:
								
Client[Debian] 	<----(Wi-Fi)---> 	Access Point[raspbian] 	<--(Ethernet)--> 	Server[Ubuntu]
		Wi-Fi Sniffer[Mac]

Client[Debian]	<---(ibeacon)---	Access Point[raspbian]
		BLE Sniffer[Raspbian]						
								
							
commands:

[Client]				utrace -d 300 -k c -a 129.88.49.84 -s 175005
[Server]				utrace -d 310 -k s -s 175000
[Access Point]	utrace -d 300 -k g -c 1 -s 175000
[Wi-Fi Sniffer]	utrace -d 300 -k f -c 1 -s 175000
[BLE Sniffer]		uble -s 175000

EXAMPLE 2:
A simple UDP client server that collects th Network info and traces in every point of the network, the experiment is set to start running at 12:00:00
topology:								
Client[Linux] 	<--(Ethernet)--> 	Access Point[raspbian] 	<--(Ethernet)--> 	Server

commands:
[Client]				utrace -d 300 -k c -a 129.88.49.84 -m u -s 120005
[Server]				utrace -d 310 -k s -m u -s 120000
[Access Point]	utrace -d 300 -k g -c 1 -s 120000
