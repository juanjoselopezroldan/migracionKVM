# migracionKVM
Script realizado en bash que se encarga de monitorizar la cantidad de carga que tiene una maquina KVM y en el caso en el que esa maquina tenga una carga de trabajo excesiva, a traves de la API de libvirt realizaremos la migracion de esta maquina virtual a una con mas capacidades de responder a peticiones ya que nuestro equipo ofrece un servicio de Apache2 (Esta accion es denominada como integracion continua).

En el caso que deseais utilizarlo tendreis que adaptar el scrip a vuestrar necesidades de cara a los parametros que tiene indicados en el script.
