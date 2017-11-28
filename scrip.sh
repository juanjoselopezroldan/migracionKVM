#!/bin/bash
echo "Iniciando"
bucle="seguir"

while [[ $bucle != "salir" ]]; do

	#Obtiene la informacion del estado de la maquina
	estadomq=$(virsh list --all | egrep "debian8-1" | tr -s " " | cut -d " " -f 4)

	#Este IF hace referencia a la comprobacion del estado de la maquina si esta levantada comprueba su estado pero si no esta, procede a iniciarla
	if [[ $estadomq == "running" ]];
	then
		#Obtiene la ip de la maquina si esta en ejecucion
		ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)

		#Obtiene la informacion de la ocupacion de procesamiento en la maquina virtual
		control=$(ssh -i /home/kiki/.ssh/cloud.key root@$ip free -m | egrep Mem | tr -s " " | cut -d " " -f 4)
		
		#Este IF se cumple si la carga de trabajo de la primera maquina llega al maximo en el uso de RAM
		if [[ $control -le "10" ]];
		then
			echo "Maquina 1 colapsada, inicio de maquina 2"
			#Iniciamos la segunda maquina virtual
			virsh -c qemu:///system start debian8-2

			echo "Desasociamos volumen de la maquina 1 y se realiza el apagado"
			#Desasociamos el volumen de la maquina primera y la apagamos
			virsh -c qemu:///session detach-disk debian8-1 /dev/disco/lv1
			virsh -c qemu:///system shutdown debian8-1

			sleep 20
			echo "Redimensionado de Disco"
			#Redimensionamos la particion
			lvresize -L +10M /dev/disco/lv1

			#Montamos el volumen para redimensionar el sistema de archivos
			mount /dev/disco/lv1 /mnt/

			#Redimensionamos el sistema de ficheros
			xfs_growfs /dev/disco/lv1 

			#Desmontamos el volumen del directorio temporal
			umount /mnt/

			#Asociamos el volumen a la otra maquina
			echo "Asociamos volumen a maquina 2"
			virsh -c qemu:///session attach-disk debian8-2 /dev/disco/lv1 vda

			sleep 15
			echo "Obtiene la ip de la segunda maquina"
			ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
			echo $ip
		
			#Monta el volumen
			ssh -i /home/kiki/.ssh/cloud.key root@$ip mount /dev/vda /var/www/html/
			
			#Añadimos regla IPTable en la maquina Anfitriona para que pueda saber donde mandar la peticion
			iptables -I FORWARD -d $ip/32 -p tcp --dport 80 -j ACCEPT
			iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip:80
			
			#Salimos del Bucle while
			bucle="salir"
			echo "Maquina 2 operativa"
		fi
	else
		echo "Levantamos la maquina por estar inactiva"
		#Iniciamos la maquina, esperamos 5 segundos y asociamos el volumen a la maquina
		virsh -c qemu:///system start debian8-1
		sleep 5
		virsh -c qemu:///session attach-disk debian8-1 /dev/disco/lv1 vda
		sleep 25
		
		echo "Obteniendo la ip de la maquina"
		ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
		
		echo $ip
		sleep 15
		#Monta el volumen
		ssh -i /home/kiki/.ssh/cloud.key root@$ip mount /dev/vda /var/www/html/
		
		#Añadimos regla IPTable en la maquina Anfitriona para que pueda saber donde mandar la peticion
		iptables -I FORWARD -d $ip/32 -p tcp --dport 80 -j ACCEPT
		iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination $ip:80
		
		#En este punto podremos comprobar en el navegador como podemos acceder a la pagina si tenemos en el volumen algun index.html (recordad que el Apache tiene que esta configurado previamente)
		echo "Maquina 1 operativa"
	fi
	sleep 10
done

#Obtiene la ip de la maquina si esta en ejecucion
ip=$(virsh net-dhcp-leases nat | tr -s " " | cut -d " " -f 6 | cut -d "/" -f 1 | tail -2)
echo "Control sobre la maquina: $ip"

#Una vez realizada la migracion correctamente, 
bucle="seguir"
while [[ $bucle != "salir" ]]; do
	#Obtiene la informacion de la ocupacion de procesamiento en la maquina virtual
	control=$(ssh -i /home/kiki/.ssh/cloud.key root@$ip  free -m | egrep Mem | tr -s " " | cut -d " " -f 4 )
	echo $control
	if [[ $control -le "60" ]]; then
		echo "Aumentando Memoria Ram a 2G"
		virsh setmem debian8-2 2G --live
		bucle="salir"		
	fi
	sleep 5
done
echo "Maquina 2 operativa con aumento de memoria Ram"