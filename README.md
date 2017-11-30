# migracionKVM
Script realizado en bash que se encarga de monitorizar la cantidad de carga que tiene una maquina KVM y en el caso en el que esa maquina tenga una carga de trabajo excesiva, a traves de la API de libvirt realizaremos la migracion de esta maquina virtual a una con mas capacidades de responder a peticiones ya que nuestro equipo ofrece un servicio de Apache2 (Esta accion es denominada como integracion continua).

En el caso que deseais utilizarlo tendreis que adaptar el scrip a vuestrar necesidades de cara a los parametros que tiene indicados en el script.

# ¿Que pasos realiza el script?

El script realiza los siguinetes pasos:
1- Obtiene la informacion del estado de la maquina (si la maquina esta iniciada empezara a monitorizar el estado de la memoria, si no lo está pues pasaremos al paso 2).

2- Si la maquina no esta iniciada pues iniciamos la maquina, esperamos 5 segundos y asociamos el volumen a la maquina y acto seguido monta el volumen.

3- En el momento en el que este montado el volumen procederemos a añadir la regla IPtable en la maquina Anfitriona para que pueda saber donde mandar la peticion.
<pre>
iptables -I FORWARD -d "IP de la Maquina virtual"/32 -p tcp --dport 80 -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination "IP de la Maquina virtual":80
</pre>

4- En este punto podremos comprobar en el navegador como podemos acceder a la pagina si tenemos en el volumen algun index.html (recordad que el Apache tiene que esta configurado previamente)

5- En el caso en el que la maquina este encendida los pasos 2,3 y 4 no los realizará y pasará directamente a realizar la comprobacion del estado de la memoria de la maquina.

6- Cuando esta comprobando la memoria, tendremos que realizar un stress en la maquina virtual y en el momento en el que la memoria de la maquina se llene, se dispondrá a iniciar la segunda maquina y con ello el desmontaje del volumen y la desasociacion del disco de la primera maquina y por ello el apagado de la misma.

7- En el momento en el que la segunda maquina este iniciada se dispondra a realizar la redimension del volumen y de su sistema de ficheros  siendo en nuestro caso de un tamado de 10MB mas del tamaño que tiene y cuando ya lo realice, procedera asociar el volumen a la segunda maquina y a montarla.

8- Acto seguido se eliminará la configuracion de iptables y actualizara estas regla con la direccion ip de nuestra segunda maquina  y en ese momento ya tendremos la maquina operativa para seguir ofreciendo el servicio de apache.

9- Una vez que ya este operativa la segunda maquina se realizara un seguimiento de la misma para que en caso de que se agote la memoria ram de esta maquina automaticamente realice el aumento de la misma a 1Gb mas de lo que tiene y con ello finalizara la ejecucion del programa.
