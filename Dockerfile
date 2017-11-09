FROM phusion/baseimage

# ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# change resolv.conf
RUN echo 'nameserver 8.8.8.8' >> /etc/resolv.conf

# setup
ENV HOME /root
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

# install latest version of nodejs & npm
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash -
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y -f nodejs
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y git

# install PHP repository
RUN apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ondrej/php

# update sources
RUN DEBIAN_FRONTEND="noninteractive" apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y upgrade
RUN DEBIAN_FRONTEND="noninteractive" apt-get update --fix-missing

# install php7.1
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install php7.1
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install php7.1-fpm \
                                                        php7.1-common \
                                                        php7.1-cli \
                                                        php7.1-mysqlnd \
                                                        php7.1-mcrypt \
                                                        php7.1-curl \
                                                        php7.1-bcmath \
                                                        php7.1-mbstring \
                                                        php7.1-soap \
                                                        php7.1-xml \
                                                        php7.1-zip \
                                                        php7.1-json \
                                                        php7.1-imap \
                                                        php7.1-opcache \
                                                        php7.1-odbc \
                                                        php7.1-bz2 \
                                                        php7.1-pgsql \
                                                        php7.1-intl \
                                                        php7.1-gd \
                                                        php7.1-gmp \
                                                        php7.1-cgi \
                                                        php7.1-dev \
                                                        php7.1-sqlite3 \
                                                        php-xdebug

# install nginx (full)
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx-full

# install vim
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y vim

# install supervisor
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y supervisor

# install php redis
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y php-redis

# install yarn
RUN DEBIAN_FRONTEND="noninteractive" curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN DEBIAN_FRONTEND="noninteractive" echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get install yarn

# install laravel echo server
RUN cd ${HOME} && yarn add global laravel-echo-server
RUN ln -s ${HOME}/node_modules/laravel-echo-server/bin/server.js /usr/bin/laravel-echo-server

# remove apache2
RUN apt-get purge -y apache2

# install php composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# set WWW public folder
RUN mkdir -p /var/www
RUN chown -R www-data:www-data /var/www
RUN chmod 755 /var/www
RUN rm -r /var/www/html

# copy files from repo
ADD build/supervisor/laravel-echo-server.conf /etc/supervisor/conf.d/laravel-echo-server.conf
ADD build/supervisor/php7.1-fpm.conf /etc/supervisor/conf.d/php7.1-fpm.conf
ADD build/supervisor/nginx.conf /etc/supervisor/conf.d/nginx.conf

ADD build/nginx/upstream.conf /etc/nginx/conf.d/upstream.conf
ADD build/nginx/nginx.conf /etc/nginx/nginx.conf
ADD build/nginx/default.conf /etc/nginx/sites-available/default

ADD build/laravel-echo-server.json /var/www/laravel-echo-server.json

ADD build/generate_certificate.sh /etc/ssl/private/generate_certificate.sh

ADD build/.bashrc /root/.bashrc

# generate an ssl certificate
RUN chmod +x /etc/ssl/private/generate_certificate.sh
RUN cd /etc/ssl/private && (/bin/bash generate_certificate.sh)

# disable services start
RUN update-rc.d -f apache2 remove
RUN update-rc.d -f nginx remove
RUN update-rc.d -f php7.1-fpm remove

# set php-fpm configuration values
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/display_errors = Off/display_errors = On/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/post_max_size = .*/post_max_size = 12M/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini

RUN sed -i -e "s/pid =.*/pid = \/var\/run\/php7.1-fpm.pid/" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i -e "s/error_log =.*/error_log = \/proc\/self\/fd\/2/" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf
RUN sed -i "s/listen = .*/listen = 9000/" /etc/php/7.1/fpm/pool.d/www.conf
RUN sed -i "s/;catch_workers_output = .*/catch_workers_output = yes/" /etc/php/7.1/fpm/pool.d/www.conf

# set timezone machine to America/Denver
RUN cp /usr/share/zoneinfo/America/Denver /etc/localtime

# set UTF-8 environment
RUN echo 'LC_ALL=en_US.UTF-8' >> /etc/environment
RUN echo 'LANG=en_US.UTF-8' >> /etc/environment
RUN echo 'LC_CTYPE=en_US.UTF-8' >> /etc/environment

# enable xdebug
RUN echo 'xdebug.remote_enable=1' >> /etc/php/7.1/mods-available/xdebug.ini
RUN echo 'xdebug.remote_connect_back=1' >> /etc/php/7.1/mods-available/xdebug.ini
RUN echo 'xdebug.show_error_trace=1' >> /etc/php/7.1/mods-available/xdebug.ini
RUN echo 'xdebug.remote_port=9000' >> /etc/php/7.1/mods-available/xdebug.ini
RUN echo 'xdebug.scream=0' >> /etc/php/7.1/mods-available/xdebug.ini
RUN echo 'xdebug.show_local_vars=1' >> /etc/php/7.1/mods-available/xdebug.ini
RUN echo 'xdebug.idekey=PHPSTORM' >> /etc/php/7.1/mods-available/xdebug.ini

# set PHP7.1 timezone to America/Denver
RUN sed -i "s/;date.timezone =*/date.timezone = America\/Denver/" /etc/php/7.1/fpm/php.ini
RUN sed -i "s/;date.timezone =*/date.timezone = America\/Denver/" /etc/php/7.1/cli/php.ini

# create run directories
RUN mkdir -p /var/run/php
RUN chown -R www-data:www-data /var/run/php

# create log directories
RUN mkdir -p /var/log/php7.1-fpm
RUN mkdir -p /var/log/nginx
RUN mkdir -p /var/log/supervisor

# set terminal environment
ENV TERM=xterm

# ports and settings
EXPOSE 80 443 3000 6001 6379 8080 9000

# cleanup apt and lists
RUN apt-get clean
RUN apt-get autoclean
RUN apt-get -y autoremove

CMD ["service", "supervisor", "start"]
