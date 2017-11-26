#!/bin/bash

control=$(ps aux | egrep libvirt+ | tr -s " " | cut -d " " -f 4 | sort -r | head -1 )
ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
estadomq=$(virsh list --all | egrep "debian8-1" | tr -s " " | cut -d " " -f 4)

if 

#while [[  ]]; do
	#statements
#done

echo $control
echo $ip