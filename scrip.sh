#!/bin/bash

bucle="seguir"

while [[ $bucle != "salir" ]]; do

	#Obtiene la informacion del estado de la maquina
	estadomq=$(virsh list --all | egrep "debian8-1" | tr -s " " | cut -d " " -f 4)

	#Este IF hace referencia a la comprobacion del estado de la maquina si esta levantada comprueba su estado pero si no esta, procede a iniciarla
	if [[ $estadomq == "running" ]];
	then
		#Obtiene la informacion de la ocupacion de procesamiento en la maquina anfitriona
		control=$(ps aux | egrep libvirt+ | tr -s " " | cut -d " " -f 4 | sort -r | head -1 )
		
		#Obtiene la ip de la maquina si esta en ejecucion
		ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
		
		#Este IF se cumple si la carga de trabajo de la primera maquina llega al maximo en el uso de RAM
		if [[ $control == "7.0" ]];
		then
			#Iniciamos la segunda maquina virtual 
			virsh -c qemu:///system start debian8-2

			#Desasociamos el volumen de la maquina primera y la apagamos
			virsh -c qemu://session detach-disk debian8-1 /dev/disco/lv1
			virsh -c qemu:///system shutdown debian8-1

			#Redimensionamos la particion
			lvresize -L +10M /dev/disco/lv1

			#Montamos el volumen para redimensionar el sistema de archivos
			mount /dev/disco/lv1 /mnt/

			#Redimensionamos el sistema de ficheros
			xfs_growfs /dev/disco/lv1 

			#Desmontamos el volumen del directorio temporal
			umount /mnt/

			#Asociamos el volumen a la otra maquina
			virsh -c qemu://session attach-disk debian8-1 /dev/disco/lv1 vda

			#Obtiene la ip de la maquina que esta en ejecucion
			ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
		
			#Monta el volumen
			rsh -i /home/kiki/.ssh/cloud.key root@$ip mount /dev/vda /var/www/html/
		
			#Añadimos regla IPTables en la maquina virtual para que acepte peticiones de fuera de su red virutal y devuelva la peticion
			rsh -i /home/kiki/.ssh/cloud.key root@$ip iptables -t nat -A POSTROUTING -s 192.168.1.1/24 -o eth0 -j MASQUERADE
			
			#Añadimos regla IPTable en la maquina Anfitriona para que pueda saber donde mandar la peticion
			iptables -t nat -A PREROUTING -i virbr1 -p tcp --dport 80 -j DNAT --to $ip
			
			#Salimos del Bucle while
			bucle="salir"
	else
		#Iniciamos la maquina, esperamos 5 segundos y asociamos el volumen a la maquina
		virsh -c qemu:///system start debian8-1
		sleep 5
		virsh -c qemu:///session attach-disk debian8-1 /dev/disco/lv1 vda
		
		#Obtiene la ip de la maquina
		ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
		
		#Monta el volumen
		rsh -i /home/kiki/.ssh/cloud.key root@$ip mount /dev/vda /var/www/html/
		
		#Añadimos regla IPTables en la maquina virtual para que acepte peticiones de fuera de su red virutal y devuelva la peticion
		rsh -i /home/kiki/.ssh/cloud.key root@$ip iptables -t nat -A POSTROUTING -s 192.168.1.1/24 -o eth0 -j MASQUERADE
		
		#Añadimos regla IPTable en la maquina Anfitriona para que pueda saber donde mandar la peticion
		iptables -t nat -A PREROUTING -i virbr1 -p tcp --dport 80 -j DNAT --to $ip
		
		#En este punto podremos comprobar en el navegador como podemos acceder a la pagina si tenemos en el volumen algun index.html (recordad que el Apache tiene que esta configurado previamente)
	fi
done

bucle2="salir"

while [[ $bucle2 == "salir" ]]; do
	
	#Obtiene la informacion de la ocupacion de procesamiento en la maquina anfitriona
	control=$(ps aux | egrep libvirt+ | tr -s " " | cut -d " " -f 4 | sort -r | head -1 )
	
	if [[ $control == "7.0" ]]; then
		
	fi
done

echo $control
echo $ip