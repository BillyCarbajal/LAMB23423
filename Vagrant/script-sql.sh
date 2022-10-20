apt update
apt install default-mysql-server git -y
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
mysql -u root -proot < iaw-practica-lamp/db/database.sql
rm -rf iaw-practica-lamp
echo "use mysql; alter user 'lamp_user'@'%' identified by 'lamp_password'; grant all privileges on lamp_db.* to 'lamp_user'@'%'; flush privileges;" > temp.sql
mysql -u root -proot < temp.sql
rm temp.sql
cat /etc/mysql/mariadb.conf.d/50-server.cnf|grep -v "bind-address" > temp1.txt
printf "[mariadb]\nbind-address = 192.168.100.3\n" >> temp1.txt
mv temp1.txt /etc/mysql/mariadb.conf.d/50-server.cnf
prub=`arp -n|grep "eth0"|cut -d " " -f1`
route delete default gw $prub
systemctl restart mysql
