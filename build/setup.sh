#!/usr/bin/env bash

# remove default configs
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default

# set WWW public folder
mkdir -p /var/www
chown -R www-data:www-data /var/www
chmod 755 /var/www
rm -r /var/www/html

# set php-fpm ini
sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini
sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini
sed -i "s/display_errors = Off/display_errors = On/" /etc/php/7.1/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php/7.1/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 12M/" /etc/php/7.1/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini

# set php-fpm conf
sed -i -e "s/pid =.*/pid = \/var\/run\/php7.1-fpm.pid/" /etc/php/7.1/fpm/php-fpm.conf
sed -i -e "s/error_log =.*/error_log = \/proc\/self\/fd\/2/" /etc/php/7.1/fpm/php-fpm.conf
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf
sed -i "s/listen = .*/listen = 9000/" /etc/php/7.1/fpm/pool.d/www.conf
sed -i "s/;catch_workers_output = .*/catch_workers_output = yes/" /etc/php/7.1/fpm/pool.d/www.conf

# set timezone machine to America/Denver
cp /usr/share/zoneinfo/America/Denver /etc/localtime

# set UTF-8 environment
echo 'LC_ALL=en_US.UTF-8' >> /etc/environment
echo 'LANG=en_US.UTF-8' >> /etc/environment
echo 'LC_CTYPE=en_US.UTF-8' >> /etc/environment

# enable xdebug
echo 'xdebug.remote_enable=1' >> /etc/php/7.1/mods-available/xdebug.ini
echo 'xdebug.remote_connect_back=1' >> /etc/php/7.1/mods-available/xdebug.ini
echo 'xdebug.show_error_trace=1' >> /etc/php/7.1/mods-available/xdebug.ini
echo 'xdebug.remote_port=9000' >> /etc/php/7.1/mods-available/xdebug.ini
echo 'xdebug.scream=0' >> /etc/php/7.1/mods-available/xdebug.ini
echo 'xdebug.show_local_vars=1' >> /etc/php/7.1/mods-available/xdebug.ini
echo 'xdebug.idekey=PHPSTORM' >> /etc/php/7.1/mods-available/xdebug.ini

# set PHP7.1 timezone to America/Denver
sed -i "s/;date.timezone =*/date.timezone = America\/Denver/" /etc/php/7.1/fpm/php.ini
sed -i "s/;date.timezone =*/date.timezone = America\/Denver/" /etc/php/7.1/cli/php.ini

# generate ssl certificate
chmod +x /etc/ssl/private/generate_certificate.sh
cd /etc/ssl/private && /bin/bash generate_certificate.sh

# create run directories
mkdir -p /var/run/php
chown -R www-data:www-data /var/run/php

# create log directories
mkdir -p /var/log/php7.1-fpm
mkdir -p /var/log/nginx
mkdir -p /var/log/supervisor

# disable startup services
update-rc.d -f apache2 remove
update-rc.d -f nginx remove
update-rc.d -f php7.1-fpm remove

# disable xdebug on the cli
phpdismod -s cli xdebug
