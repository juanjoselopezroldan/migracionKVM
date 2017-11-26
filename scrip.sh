#!/bin/bash

control="0"

while [[ $control == "100" ]]; do
	#Obtiene la informacion del estado de la maquina de cara al proceso
	control=$(ps aux | egrep libvirt+ | tr -s " " | cut -d " " -f 4 | sort -r | head -1 )
	estadomq=$(virsh list --all | egrep "debian8-1" | tr -s " " | cut -d " " -f 4)

	if [[ $estadomq == "running" ]] 
	then
		ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
	
	else
		virsh -c qemu:///system start debian8-1
		virsh -c qemu:///session attach-disk debian8-1 /dev/disco/lv1 vda
		ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)


	fi
done


echo $control
echo $ip