#!/bin/bash

# ------------------------------------- #
# NFS Vagrant - Magento2                #
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

# Required packages
apt-get install -y \
  curl dos2unix graphviz htop net-tools rsync sudo tree wget unzip zip \
  libsqlite3-dev libxml2-utils build-essential software-properties-common \
  postfix mailutils libsasl2-2 ca-certificates libsasl2-modules \
  apt-transport-https mysql-client mysql-server redis-server \
  openssl apache2 \
  g++ vim git git-flow

# Sury Repository
wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list

# Set required php version
MAGENTO_PHP_VERSION="7.2";
if $(dpkg --compare-versions "${PROJECT_VERSION}" "lt" "2.3"); then
  MAGENTO_PHP_VERSION="7.1";
fi
if $(dpkg --compare-versions "${PROJECT_VERSION}" "lt" "2.1"); then
  MAGENTO_PHP_VERSION="7.0";
fi

# PHP packages
apt-get update -y && apt-get install -y \
  php${MAGENTO_PHP_VERSION} php${MAGENTO_PHP_VERSION}-common php${MAGENTO_PHP_VERSION}-cli \
  php${MAGENTO_PHP_VERSION}-curl php${MAGENTO_PHP_VERSION}-gd php${MAGENTO_PHP_VERSION}-intl \
  php${MAGENTO_PHP_VERSION}-mbstring php${MAGENTO_PHP_VERSION}-soap php${MAGENTO_PHP_VERSION}-zip \
  php${MAGENTO_PHP_VERSION}-xml php${MAGENTO_PHP_VERSION}-xml php${MAGENTO_PHP_VERSION}-bcmath \
  php${MAGENTO_PHP_VERSION}-mysql php${MAGENTO_PHP_VERSION}-sqlite3 libapache2-mod-php${MAGENTO_PHP_VERSION} \
  php${MAGENTO_PHP_VERSION}-memcache php${MAGENTO_PHP_VERSION}-redis php${MAGENTO_PHP_VERSION}-opcache \
  python ruby ruby-dev
if [ "${MAGENTO_PHP_VERSION}" != "7.2" ]; then
  apt-get install -y php${MAGENTO_PHP_VERSION}-mcrypt
fi

# Set php version env
if [[ -z $(grep "PHP_VERSION" "/etc/profile.d/env.sh") ]]; then
cat <<EOF >> /etc/profile.d/env.sh
export PHP_VERSION="${MAGENTO_PHP_VERSION}"
EOF
else
  sed -i '/export PHP_VERSION*/c\'"export PHP_VERSION=${MAGENTO_PHP_VERSION}" /etc/profile.d/env.sh
fi
source /etc/profile.d/env.sh

# Composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

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

# Bash completion for magento cli
sudo curl -o /etc/bash_completion.d/magento2-bash-completion https://raw.githubusercontent.com/yvoronoy/magento2-bash-completion/master/magento2-bash-completion
source /etc/bash_completion.d/magento2-bash-completion

# Clean
apt-get -y clean autoclean
apt-get -y autoremove
