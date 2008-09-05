=Bongo: Recording the beat of your Canopy jungle=

==General idea==
Given a list of AP LUID Subnets:
	Discover hosts within subnet that are alive
	Poll every host for the vital statistics
		Assume every radio has default community
	Record data in RRD - one per MAC address
		Subfolders by MAC prefix

==Assumptions==
All customer SMs on a AP have the same SNMP community
	Your SM Backhauls should not, instead they should 
	be graphed in your EMS/Cacti/Etc, not Bongo.
Disk is cheap. Allocate RRD to store stats at 5-minute
	intervals for 5 years.

==Config file==

==MIBs Tracked==
RSSI: 1.3.6.1.4.1.161.19.3.2.2.2.0
Jitter: 1.3.6.1.4.1.161.19.3.2.2.3.0
RFC1213-MIB::ifPhysAddress.2
RFC1213-MIB::ifInOctets.2'
RFC1213-MIB::ifOutOctets.2'
RFC1213-MIB::ifInUcastPkts.2'
RFC1213-MIB::ifOutUcastPkts.2'
RFC1213-MIB::ifInNUcastPkts.2'
RFC1213-MIB::ifOutNUcastPkts.2'
RFC1213-MIB::ifInErrors.2'
RFC1213-MIB::ifOutErrors.2'
RFC1213-MIB::ifInDiscards.2'
RFC1213-MIB::ifOutDiscards.2'
