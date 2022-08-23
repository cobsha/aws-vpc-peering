#!/bin/bash

yum install mariadb-server -y
systemctl enable mariadb --now
mysql -e "UPDATE mysql.user SET Password = PASSWORD('wordpress') WHERE User = 'root'"
mysql -e "DROP USER ''@'localhost'"
mysql -e "DROP USER ''@'$(hostname)'"
mysql -e "DROP DATABASE test"
mysql -e "CREATE DATABASE wordpress"
mysql -e "CREATE USER 'wordpress'@'%' IDENTIFIED BY 'wordpress'"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%'"
mysql -e "FLUSH PRIVILEGES"