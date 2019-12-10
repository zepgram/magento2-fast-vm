#!/bin/bash

# ------------------------------------- #
# Fast VM - Magento2                    #
#                                       #
# Author: zepgram                       #
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

# Set default locale
if ! grep -qF "LANG" /home/vagrant/.bashrc; then
  cp /etc/locale.gen /etc/locale.gen.old
  sed -i "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen && /usr/sbin/locale-gen
  echo 'export LANG=en_US.UTF-8' | tee -a ~/.bashrc >> /home/vagrant/.bashrc
  echo 'export LC_CTYPE=en_US.UTF-8' | tee -a ~/.bashrc >> /home/vagrant/.bashrc
  echo 'export LC_ALL=en_US.UTF-8' | tee -a ~/.bashrc >> /home/vagrant/.bashrc
fi

# Required packages
apt-get install -y \
  curl graphviz htop net-tools rsync sudo tree wget unzip zip g++ \
  libsqlite3-dev libxml2-utils build-essential software-properties-common \
  postfix mailutils libsasl2-2 libsasl2-modules ca-certificates libnss3-tools \
  apt-transport-https openssl redis-server nginx \
  python ruby ruby-dev openjdk-8-jdk openjdk-8-jre \
  vim git git-flow

# Php Repository
wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -
echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list

# Percona repository
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb

# Elasticsearch repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-6.x.list

# Set php version
MAGENTO_PHP_VERSION='7.2';
if $(dpkg --compare-versions "${PROJECT_VERSION}" "gt" "2.3.2-p1"); then
  MAGENTO_PHP_VERSION='7.3';
fi
if $(dpkg --compare-versions "${PROJECT_VERSION}" "lt" "2.3"); then
  MAGENTO_PHP_VERSION='7.1';
fi
if $(dpkg --compare-versions "${PROJECT_VERSION}" "lt" "2.2"); then
  MAGENTO_PHP_VERSION='7.0';
fi
if [ $PROJECT_PHP_VERSION != 'default' ]; then
  MAGENTO_PHP_VERSION=$PROJECT_PHP_VERSION
fi

# Set php version env
sed -i '/export PROJECT_PHP_VERSION*/c\'"export PROJECT_PHP_VERSION=${MAGENTO_PHP_VERSION}" /etc/profile.d/env.sh
source /etc/profile.d/env.sh

# PHP and aditionals
apt-get update -y && apt-get install -y \
  php${PROJECT_PHP_VERSION} php${PROJECT_PHP_VERSION}-common php${PROJECT_PHP_VERSION}-cli \
  php${PROJECT_PHP_VERSION}-curl php${PROJECT_PHP_VERSION}-gd php${PROJECT_PHP_VERSION}-intl \
  php${PROJECT_PHP_VERSION}-mbstring php${PROJECT_PHP_VERSION}-soap php${PROJECT_PHP_VERSION}-zip \
  php${PROJECT_PHP_VERSION}-xml php${PROJECT_PHP_VERSION}-xml php${PROJECT_PHP_VERSION}-bcmath \
  php${PROJECT_PHP_VERSION}-mysql php${PROJECT_PHP_VERSION}-sqlite3 php${PROJECT_PHP_VERSION}-fpm \
  php${PROJECT_PHP_VERSION}-memcache php${PROJECT_PHP_VERSION}-redis php${PROJECT_PHP_VERSION}-opcache \
  percona-server-server-5.7 elasticsearch
if $(dpkg --compare-versions "${PROJECT_PHP_VERSION}" "lt" "7.2"); then
  apt-get install -y php${PROJECT_PHP_VERSION}-mcrypt
fi

# Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Prestissimo speed up installation
sudo -u vagrant composer global require hirak/prestissimo

# Postfix
wget -P ~/ https://www.thawte.com/roots/thawte_Premium_Server_CA.pem && \
    mv ~/thawte_Premium_Server_CA.pem /usr/local/share/ca-certificates/thawte_Premium_Server_CA.crt && \
    update-ca-certificates;

# Mailcatcher
gem install mime-types --version "< 3" --no-ri --no-rdoc
gem install mailcatcher --no-ri --no-rdoc

# Grunt
curl -sL https://deb.nodesource.com/setup_10.x | bash -
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

# Bash completion for magento cli
curl -o /etc/bash_completion.d/magento2-bash-completion https://raw.githubusercontent.com/yvoronoy/magento2-bash-completion/master/magento2-bash-completion
source /etc/bash_completion.d/magento2-bash-completion

# Clean
apt-get -y upgrade && apt-get -y clean autoclean && apt-get -y autoremove
