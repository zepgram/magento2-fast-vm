#!/bin/bash

# ------------------------------------- #
# NFS Vagrant - Magento2                #
#                                       #
# Author: zpgram                        #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Install system packages ---'

# Mysql settings
debconf-set-selections <<< "mysql-server mysql-server/root_password password password"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password password"

# Postfix settings
debconf-set-selections <<< "postfix postfix/mailname string $PROJECT_URL"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

# Packages
apt-get install -y \
  curl dos2unix graphviz htop net-tools rsync sudo tree wget unzip zip \
  libsqlite3-dev libxml2-utils build-essential software-properties-common \
  postfix mailutils libsasl2-2 ca-certificates libsasl2-modules \
  mysql-client mysql-server redis-server \
  apache2 libapache2-mod-php openssl \
  g++ vim git git-flow \
  php php-cli \
  php-curl php-gd php-intl \
  php-mbstring php-soap php-zip \
  php-xml php-mcrypt php-bcmath \
  php-mysql php-sqlite3 \
  php-memcache php-redis php-opcache \
  python ruby ruby-dev

# Composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Prestissimo speed up installation
sudo -u vagrant composer global require hirak/prestissimo

# Postfix
wget -P ~/ https://www.thawte.com/roots/thawte_Premium_Server_CA.pem && \
    mv ~/thawte_Premium_Server_CA.pem /usr/local/share/ca-certificates/thawte_Premium_Server_CA.crt && \
    update-ca-certificates ;

# Mailcatcher
gem install mime-types --version "< 3" --no-ri --no-rdoc
gem install mailcatcher --no-ri --no-rdoc

# Grunt
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
apt-get install -y nodejs
npm install -g grunt-cli

# Pestle
curl -sL -o /usr/local/bin/pestle http://pestle.pulsestorm.net/pestle.phar
chmod +x /usr/local/bin/pestle

# Magerun
curl -sL -o /usr/local/bin/magerun https://files.magerun.net/n98-magerun2.phar
chmod +x /usr/local/bin/magerun

# Magento cloud
curl -sLS https://accounts.magento.cloud/cli/installer | php
mv /root/.magento-cloud/bin/magento-cloud /usr/local/bin
chmod +x /usr/local/bin/magento-cloud

# Clean
apt-get -y clean autoclean
apt-get -y autoremove
