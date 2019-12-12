#!/usr/bin/env bash
#
# Nginx - new server block

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; } # Green


# Variables
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
WEB_DIR='/var/www/vtiger'
WEB_USER='www-data'
USER='www-data'
zone='Europe\/Amsterdam'		# Time zone that will be auto selected when running setup make sure to inlcude the \ I recommend to leave this as is and change it during the setup.
					# you can find list of zones supported by vtiger at: https://discussions.vtiger.com/discussion/190812/time-zone-setting-list-is-empty
currency='Euro'				# Currency that will be auto selected when running setup Ex. Jamaica, Dollars | Isle of Man, Pounds | Iran, Rials | USA, Dollars | Netherlands Antilles, Guilders etc. If unsure, leave it as is, and change during setup.
date='dd-mm-yyyy'			# Date format that will be auto selected when running setup
date2='"dd-mm-yyyy"'			# Date format with  make sure to fill this one is as well must be the same as date
vtigeradmin='password'			# Password for the default admin user
rootpasswd='MYSQLROOTPASS'		# root password mysql used for making database
domain='example.com'

# Do NOT edit the following variables!!!
NGINX_SCHEME='$scheme'
NGINX_REQUEST_URI='$request_uri'
uri='$uri'
args='$args'
document_root='$document_root'
fastcgi_script_name='$fastcgi_script_name'
defaultzone='America\/Los_Angeles'
defaultcurrency='USA, Dollars'
defaultdate='"mm-dd-yyyy"'

# Sanity check
[ $(id -g) != "0" ] && die "Script must be run as root."
[ $# != "1" ] && die "Usage: $(basename $0) domainName"

# Create nginx config file
cat > $NGINX_AVAILABLE_VHOSTS/$1 <<EOF
# www to non-www
server {
    listen 80;
    # If user goes to www direct them to non www
    server_name *.$domain;
    return 301 $NGINX_SCHEME://$1$NGINX_REQUEST_URI;
}
server {
    # Just the server name
    listen 80;
    server_name $1.$domain;
    root        $WEB_DIR/$1/;
   index index.php index.html index.htm;
    # Logs
    access_log $WEB_DIR/logs/$1/access.log;
    error_log  $WEB_DIR/logs/$1/error.log;
location / {
 proxy_read_timeout 150;
 try_files $uri $uri/ /index.php?$args;
}
    location ~ \.php$ { 
include snippets/fastcgi-php.conf; 
fastcgi_pass unix:/var/run/php/php7.1-fpm.sock; 
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; 
include fastcgi_params;
fastcgi_read_timeout 600; 
proxy_connect_timeout 600; 
proxy_send_timeout 600; 
proxy_read_timeout 600;
send_timeout 600;
}
  }
EOF

# Creating {public,log} directories
mkdir -p $WEB_DIR/logs/$1


#tar -zxf $WEB_DIR/vtigercrm7.2.0.tar.gz
sleep 2
cp -r $WEB_DIR/vtigercrm/ $WEB_DIR/$1
echo "Succesfully copied contents to web dir"


# Changing permissions
chown -R $USER:$WEB_USER $WEB_DIR/$1

# Enable site by creating symbolic link
ln -s $NGINX_AVAILABLE_VHOSTS/$1 $NGINX_ENABLED_VHOSTS/$1

echo "serverblocks done"



#CREATE DATABASEANAME
dbname="$(openssl rand -base64 5 | tr -d "=+/" | cut -c1-25)$2"
echo "successfully created database name"
# CREATE DATABASE USERNAME

MAINDB="$(openssl rand -base64 8 | tr -d "=+/" | cut -c1-25)$2"
echo "successfully created database username"
# CREATE DATABASE USERNAME PASSWORD
PASSWDDB="$(openssl rand -base64 29 | tr -d "=+/" | cut -c1-25)"
echo "successfully created database username password"


        echo "Creating new MySQL database..."
        mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
        echo "Database successfully created!"
        echo "alterdatabase to use utf8_general_ci"
	mysql -uroot -p${rootpasswd} -e "ALTER DATABASE ${dbname} CHARACTER SET utf8 COLLATE utf8_general_ci;"
	echo "Creating new user..."
        mysql -uroot -p${rootpasswd} -e "CREATE USER ${MAINDB}@localhost IDENTIFIED BY '${PASSWDDB}';"
        echo "User successfully created!"
        echo "Granting ALL privileges on ${dbname} to ${MAINDB}!"
        mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${MAINDB}'@'localhost' WITH GRANT OPTION;"
        mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
	echo "Sucessfully granted privileges on ${dbname} to ${MAINDB}!"

# inject the db credentials and default user password in the form on the installation page

echo "injecting db credentials, default user password and email to setup page..."

sed -i "0,/''/s//'localhost'/" $WEB_DIR/$1/modules/Install/models/Utils.php
sed -i "0,/''/s//'$MAINDB'/" $WEB_DIR/$1/modules/Install/models/Utils.php
sed -i "0,/''/s//'${PASSWDDB}'/" $WEB_DIR/$1/modules/Install/models/Utils.php
sed -i "0,/''/s//'${dbname}'/" $WEB_DIR/$1/modules/Install/models/Utils.php
sed -i "0,/''/s//'$vtigeradmin'/" $WEB_DIR/$1/modules/Install/models/Utils.php
sed -i "0,/''/s//'info@$1.nl'/" $WEB_DIR/$1/modules/Install/models/Utils.php

# change default currency

echo "Changing default currency..."

sed -i "0,/USA, Dollars/s//$currency/" $WEB_DIR/$1/layouts/v7/modules/Install/Step4.tpl

# change the default date. NOTE: The default date (mm-dd-yyyy) will be replaced by the value provided in $date & $date2, if you need to edit this back to the default value, you have to manually edit the file.

echo "Changing default date..."

sed -i "0,/$defaultdate/s//$date2/" $WEB_DIR/$1/layouts/v7/modules/Install/Step4.tpl
sed -i "0,/mm-dd-yyyy/s//$date/" $WEB_DIR/$1/layouts/v7/modules/Install/Step4.tpl

sed -i "0,/America\/Los_Angeles/s//$zone/" $WEB_DIR/$1/layouts/v7/modules/Install/Step4.tpl

#edit the tpl file, so that db credentials are hidden.

echo "Hiding db credentials in setup page..."

sed -i "0,/input-table/s//style="display:none"/" $WEB_DIR/$1/layouts/v7/modules/Install/Step4.tpl
sed -i "0,/thead/s//thead style="display:none"/" $WEB_DIR/$1/layouts/v7/modules/Install/Step4.tpl
sed -i "0,/tbody/s//tbody style="display:none"/" $WEB_DIR/$1/layouts/v7/modules/Install/Step4.tpl

#now align the two columns
#does not work btw
sed -i "0,/class="col-sm-6"/s//text-align:center/" $WEB_DIR/$1/layouts/v7/modules/Install/Step4.tpl
sed -i "0,/class="col-sm-6"/s//text-align:center/" $WEB_DIR/$1/layouts/v7/modules/Install/Step4.tpl

echo "All done!"

chown -R $USER:$WEB_USER $WEB_DIR/$1
service nginx restart

echo "Permissions are changed and nginx has been restarted."
