FROM ubuntu:17.10

ARG NON_ROOT_USER=ubuntu

# update and upgrade system dependencies
RUN DEBIAN_FRONTEND="noninteractive" apt-get clean && apt-get update && apt-get -y upgrade

# install locales
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y locales

# ensure UTF-8
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# set terminal environment
ENV TERM=xterm

# set the env $HOME
ENV HOME /root

# create a non root user
RUN useradd -mU -s /bin/bash ${NON_ROOT_USER}

# install some PPAs
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y software-properties-common curl
RUN DEBIAN_FRONTEND="noninteractive" apt-add-repository ppa:nginx/development -y
RUN DEBIAN_FRONTEND="noninteractive" apt-add-repository ppa:ondrej/php -y
RUN DEBIAN_FRONTEND="noninteractive" apt-add-repository ppa:chris-lea/redis-server -y

# pull the latest node source
RUN DEBIAN_FRONTEND="noninteractive" curl -sL https://deb.nodesource.com/setup_9.x | bash -

# update sources
RUN DEBIAN_FRONTEND="noninteractive" apt-get update --fix-missing -y

# install latest version of nodejs & npm
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y -f nodejs

# install git
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y git

# install php7.1
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install php7.1 \
                                                        php7.1-fpm \
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
                                                        php-xdebug \
                                                        php-pear

# install nginx
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx

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

# install php composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# copy supervisor configs
COPY build/supervisor/laravel-echo-server.conf /etc/supervisor/conf.d/laravel-echo-server.conf
COPY build/supervisor/php7.1-fpm.conf /etc/supervisor/conf.d/php7.1-fpm.conf
COPY build/supervisor/nginx.conf /etc/supervisor/conf.d/nginx.conf

# copy nginx configs
COPY build/nginx/upstream.conf /etc/nginx/conf.d/upstream.conf
COPY build/nginx/nginx.conf /etc/nginx/nginx.conf
COPY build/nginx/default.conf /etc/nginx/sites-available/default

# copy echo server configs
COPY build/laravel-echo-server.json /etc/laravel-echo-server.json

# copy scripts
COPY build/generate_certificate.sh /etc/ssl/private/generate_certificate.sh
COPY build/setup.sh /tmp/setup.sh
COPY build/start.sh /usr/local/bin/start

# copy shell env
COPY build/.bashrc /root/.bashrc

# make start script executable
RUN chmod +x /usr/local/bin/start

# add ${NON_ROOT_USER} to www-data
RUN usermod -a -G www-data ${NON_ROOT_USER}
RUN id ${NON_ROOT_USER}
RUN groups ${NON_ROOT_USER}

# Install oh-my-zsh
RUN git clone git://github.com/robbyrussell/oh-my-zsh.git /home/${NON_ROOT_USER}/.oh-my-zsh
RUN cp /home/${NON_ROOT_USER}/.oh-my-zsh/templates/zshrc.zsh-template /home/${NON_ROOT_USER}/.zshrc
RUN chown -R ${NON_ROOT_USER}:${NON_ROOT_USER} /home/${NON_ROOT_USER}/.oh-my-zsh
RUN chown ${NON_ROOT_USER}:${NON_ROOT_USER} /home/${NON_ROOT_USER}/.zshrc
RUN chsh -s /usr/bin/zsh ${NON_ROOT_USER}

# run the setup script
RUN chmod +x /tmp/setup.sh
RUN cd /tmp && (/bin/bash /tmp/setup.sh)

# cleanup apt and lists
RUN apt-get clean
RUN apt-get autoclean
RUN apt-get -y autoremove

# ports
EXPOSE 80 443 9000