#!/bin/bash

control=$(ps aux | egrep libvirt+ | tr -s " " | cut -d " " -f 4 | sort -r | head -1 )
ip1=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 
)

#while [[  ]]; do
	#statements
#done