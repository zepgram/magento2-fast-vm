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
echo "percona-server-server-5.7 percona-server-server-5.7/root-pass password password" | debconf-set-selections
echo "percona-server-server-5.7 percona-server-server-5.7/re-root-pass password password" | debconf-set-selections

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
rm -rf /etc/apt/sources.list.d/*
apt-get update -y && apt-get install -y \
  curl graphviz htop net-tools rsync sudo tree wget unzip zip g++ gnupg2 \
  libsqlite3-dev libxml2-utils build-essential software-properties-common \
  postfix mailutils libsasl2-2 libsasl2-modules ca-certificates libnss3-tools \
  apt-transport-https openssl redis-server nginx \
  python golang-go openjdk-11-jdk openjdk-11-jre \
  vim git git-flow

# Php Repository
wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

# Percona repository
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
rm -f percona-release_latest.$(lsb_release -sc)_all.deb

# Elasticsearch repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
if $(dpkg --compare-versions "${PROJECT_VERSION}" "ge" "2.4.0"); then
  echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list
else
  echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-6.x.list
fi

# PHP and additional
apt-get update -y && apt-get install -y \
  php"${PROJECT_PHP_VERSION}" php"${PROJECT_PHP_VERSION}"-common php"${PROJECT_PHP_VERSION}"-cli \
  php"${PROJECT_PHP_VERSION}"-curl php"${PROJECT_PHP_VERSION}"-gd php"${PROJECT_PHP_VERSION}"-intl \
  php"${PROJECT_PHP_VERSION}"-mbstring php"${PROJECT_PHP_VERSION}"-soap php"${PROJECT_PHP_VERSION}"-zip \
  php"${PROJECT_PHP_VERSION}"-xml php"${PROJECT_PHP_VERSION}"-xml php"${PROJECT_PHP_VERSION}"-bcmath \
  php"${PROJECT_PHP_VERSION}"-mysql php"${PROJECT_PHP_VERSION}"-sqlite3 php"${PROJECT_PHP_VERSION}"-fpm \
  php"${PROJECT_PHP_VERSION}"-memcache php"${PROJECT_PHP_VERSION}"-redis php"${PROJECT_PHP_VERSION}"-opcache \
  php"${PROJECT_PHP_VERSION}"-sockets elasticsearch
if $(dpkg --compare-versions "${PROJECT_PHP_VERSION}" "lt" "7.2"); then
  apt-get install -y php"${PROJECT_PHP_VERSION}"-mcrypt
fi

# MySQL
if $(dpkg --compare-versions "${PROJECT_VERSION}" "ge" "2.4.0"); then
  percona-release setup ps80
  apt-get install -y percona-server-server
else
  apt-get install -y percona-server-server-5.7
fi


# Composer
if $(dpkg --compare-versions "${PROJECT_VERSION}" "lt" "2.4.2"); then
  # Composer v1
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --1
  # Prestissimo
sudo -u vagrant composer global require hirak/prestissimo
else
  # Composer v2
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

# Postfix
wget -P ~/ https://www.thawte.com/roots/thawte_Premium_Server_CA.pem && \
    mv ~/thawte_Premium_Server_CA.pem /usr/local/share/ca-certificates/thawte_Premium_Server_CA.crt && \
    update-ca-certificates;

# Mailhog
go get github.com/mailhog/MailHog
ln -sfn /root/go/bin/MailHog /usr/local/bin/mailhog

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
apt-get purge grub-pc -yq
apt-get -y upgrade && apt-get -y clean autoclean && apt-get -y autoremove
