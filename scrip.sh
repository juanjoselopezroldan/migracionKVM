#!/bin/bash

control=$(ps aux | egrep libvirt+ | tr -s " " | cut -d " " -f 4 | sort -r | head -1 )
ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
estadomq=$(virsh list --all | egrep "debian8-1" | tr -s " " | cut -d " " -f 4)

while [[ $control == "100" ]]; do
	control=$(ps aux | egrep libvirt+ | tr -s " " | cut -d " " -f 4 | sort -r | head -1 )

	if [[ $estadomq == "running" ]] 
	then
		
	else
		virsh -c qemu:///system start debian8-1
	fi
done


echo $control
echo $ip