#!/bin/bash

control="0"

while [[ $control == "100" ]]; do
	#Obtiene la informacion de la ocupacion de procesamiento en la maquina anfitriona
	control=$(ps aux | egrep libvirt+ | tr -s " " | cut -d " " -f 4 | sort -r | head -1 )
	#Obtiene la informacion del estado de la maquina
	estadomq=$(virsh list --all | egrep "debian8-1" | tr -s " " | cut -d " " -f 4)

	if [[ $estadomq == "running" ]] 
	then
		#Obtiene la ip de la maquina si esta en ejecucion
		ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
	
	else
		virsh -c qemu:///system start debian8-1
		virsh -c qemu:///session attach-disk debian8-1 /dev/disco/lv1 vda
		#Obtiene la ip de la maquina
		ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
		#Monta el volumen
		rsh -i /home/kiki/.ssh/cloud.key root@$ip mount /dev/vda /var/www/html/
		#Añadimos regla IPTables en la maquina virtual para que acepte peticiones de fuera de su red virutal y devuelva la peticion
		rsh -i /home/kiki/.ssh/cloud.key root@$ip iptables -t nat -A POSTROUTING -s 192.168.1.1/24 -o eth0 -j MASQUERADE
		#Añadimos regla IPTable en la maquina Anfitriona para que pueda saber donde mandar la peticion
		iptables -t nat -A PREROUTING -i virbr1 -p tcp --dport 80 -j DNAT --to $ip
	fi
done


echo $control
echo $ip