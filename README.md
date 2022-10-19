## Crear LAMP
### Paso 1. Crear y editar archivo Vagrantfile
Usamos el comando "vagrant init" desde una terminal cmd que nos creara un archivo llamado Vagrantfile.
Editamos ese archivo con un editor de texto y eliminamos la siguiente linea:
> config.vm.box = "base"

Y añadimos estas líneas que serán las que indicaran el hostname, sistema instalado, tipo de red, cantidad de memoria RAM, limite de procesadores y la ubicación de sus respectivos script bash de aprovisionamiento de las dos maquinas llamadas "Billy-Apache" y "Billy-mysql".

	config.vm.define "servidor-apache" do |apache|
		apache.vm.hostname = "Billy-Apache"
		apache.vm.box = "generic/debian11"
		apache.vm.network "public_network"
		apache.vm.network "private_network", ip:"192.168.100.2", :dev => "eth0",
			virtualbox__intnet: "priv"
		apache.vm.provider "virtualbox" do |v|
			v.memory = 1024
			v.cpus = 1
		end
		apache.vm.provision :shell, privileged:true, path: "script-apache.sh"
	end
	config.vm.define "servidor-mysql" do |db|
		db.vm.hostname = "Billy-mysql"
		db.vm.box = "generic/debian11"
		db.vm.network "private_network", ip:"192.168.100.3", 
			virtualbox__intnet: "priv"
		db.vm.provider "virtualbox" do |v|
			v.memory = 1024
			v.cpus = 1
		end
		db.vm.provision :shell, privileged:true, path: "script-sql.sh"
	end
	

### Paso 2. Editamos el script de aprovisionamiento del servidor apache
Ahora crearemos en la misma carpeta un archivo llamado "script-apache.sh" en el incluiremos las siguientes lineas:
- Para actualiza los repositorios del servidor apache:

		apt update
- Instalar los paquetes necesarios en el servidor apache:

		apt install apache2 php libapache2-mod-php php-mysql git -y
- Descargar archivos de configuración para el servidor apache:
	git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
- Copiar los archivos a la correcta ubicación:
	cp iaw-practica-lamp/src/* /var/www/ && rm -rf iaw-practica-lamp
- Edita la direccion del servidor mysql en el archivo config.php:
	sed -i 's/localhost/192.168.100.3/' /var/www/config.php
- Entra a la carpeta de los sitios disponibles de apache:
	cd /etc/apache2/sites-available
- Crea y edita el archivo apache de configuacion para le nuevo sitio:
	cp 000-default.conf sitio-php.conf && sed -i 's%/var/www/html%/var/www%g' sitio-php.conf
- Deshabilita la antigua pagina web y habilita la nueva:
	a2dissite 000-default.conf
	a2ensite sitio-php.conf
- Busca en el servidor apache si la interface "eth1" tiene asignada una direccion por dhcp y si la tiene deshabilita la puerta de enlace de "eth0" (Creada por defecto en vagrant) y establece como predeterminada la puerta de enlace la IP de la interface "eth1".
	if [ -f /var/lib/dhcp/dhclient.eth1.leases ]; then
		prub1=`cat /var/lib/dhcp/dhclient.eth0.leases|grep "option routers"|head -n 1|cut -d " " -f5|cut -d ";" -f1`
		prub2=`cat /var/lib/dhcp/dhclient.eth1.leases|grep "option routers"|head -n 1|cut -d " " -f5|cut -d ";" -f1`
		ip route del default via $prub1
		ip route add default via $prub2
	fi
- Recargamos la configuracion del servidor apache:
	systemctl reload apache2

Una vez hecho todo esto guardamos el archivo.

### Paso 3.  Editamos el script de aprovisionamiento del servidor mysql

Ahora crearemos en la misma carpeta un archivo llamado "script-mysql.sh" en el incluiremos las siguientes lineas:
- Con esta linea actualizamos los respositorios del servidor mysql: \
	apt update
- Con esta linea se instalan los paquetes necesario para el servidor mysql:
	apt install default-mysql-server git -y
- Con esta linea descargamos los archivos necesarios para el servidor mysql:
	git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
- Con esta linea enviamos el archivo database.sql para que lo ejecute el servidor mysql:
	mysql -u root -proot < iaw-practica-lamp/db/database.sql
- Con esta linea eliminamos de configuracion ya no necesarios:
	rm -rf iaw-practica-lamp
- Creamos un archivo adicional para reconfigurar el la base de datos mysql:
	echo "use mysql; alter user 'lamp_user'@'%' identified by 'lamp_password'; grant all privileges on lamp_db.* to 'lamp_user'@'%'; flush privileges;" > temp.sql
	mysql -u root -proot < temp.sql
	rm temp.sql
- Con estas lineas editamos la direccion del servidor mysql:
	cat /etc/mysql/mariadb.conf.d/50-server.cnf|grep -v "bind-address" > temp1.txt
	printf "[mariadb]\nbind-address = 192.168.100.3\n" >> temp1.txt
	mv temp1.txt /etc/mysql/mariadb.conf.d/50-server.cnf
- Con estas lineas deshabilitamos la puerta del enlace creada por defecto por Vagrant:
	prub=`arp -n|grep "eth0"|cut -d " " -f1`
	route delete default gw $prub
- Con esta linea reiniciamos el servicio mysql:
	systemctl restart mysql


