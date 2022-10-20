apt update
apt install apache2 php libapache2-mod-php php-mysql git -y
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
cp iaw-practica-lamp/src/* /var/www/ && rm -rf iaw-practica-lamp
sed -i 's/localhost/192.168.100.3/' /var/www/config.php
cd /etc/apache2/sites-available
cp 000-default.conf sitio-php.conf && sed -i 's%/var/www/html%/var/www%g' sitio-php.conf
a2dissite 000-default.conf
a2ensite sitio-php.conf
if [ -f /var/lib/dhcp/dhclient.eth1.leases ]; then
prub1=`cat /var/lib/dhcp/dhclient.eth0.leases|grep "option routers"|head -n 1|cut -d " " -f5|cut -d ";" -f1`
prub2=`cat /var/lib/dhcp/dhclient.eth1.leases|grep "option routers"|head -n 1|cut -d " " -f5|cut -d ";" -f1`
ip route del default via $prub1
ip route add default via $prub2
fi
systemctl reload apache2


