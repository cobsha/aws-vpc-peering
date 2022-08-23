#!/bin/bash

yum install httpd -y
yum install mysql -y
amazon-linux-extras install php7.4 -y
systemctl enable httpd --now
mkdir /var/website
cd /var/website
wget https://wordpress.org/wordpress-5.8.4.tar.gz
tar -xzf wordpress-5.8.4.tar.gz
mv wordpress/* /var/www/html
chown -R apache:apache /var/www/html
cd /var/www/html
sed 's/database_name_here/wordpress/g; s/username_here/wordpress/g; s/password_here/wordpress/g; s/localhost/db.shafi.com/g' wp-config-sample.php >wp-config.php
