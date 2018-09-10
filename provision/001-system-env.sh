#!/bin/bash

# ------------------------------------- #
# NFS Vagrant - Magento2                #
#										#
# Author: zpgram                        #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Environment variables ---'

# Set environment variable
cat <<EOF > /etc/profile.d/myvars.sh
export PROJECT_HOST_REPOSITORY="${1}"
export PROJECT_REPOSITORY="${2}"
export PROJECT_COMPOSER_USER="${3}"
export PROJECT_COMPOSER_PASS="${4}"
export PROJECT_USER_NAME="${5}"
export PROJECT_USER_EMAIL="${6}"
export PROJECT_NAME="${7}"
export PROJECT_URL="${8}"
export PROJECT_SOURCE="${9}"
export PROJECT_EDITION="${10}"
export PROJECT_VERSION="${11}"
export PROJECT_SAMPLE="${12}"
export PROJECT_MODE="${13}"
export PROJECT_CURRENCY="${14}"
export PROJECT_LANGUAGE="${15}"
export PROJECT_TIME_ZONE="${16}"
export PROJECT_BUILD="/home/vagrant/build/${7}"
export PROJECT_PATH="/var/www/${7}"
EOF

# Add php version if exist
if [ -x /usr/bin/php ]; then
	PHP_VERSION="$(php --version | head -n 1 | cut -d " " -f 2 | cut -c 1,2,3)";
	if [[ -z $(grep "PHP_VERSION" "/etc/profile.d/myvars.sh") ]]; then
		echo -e "export PHP_VERSION="${PHP_VERSION}"" >> /etc/profile.d/myvars.sh
	else
  		sed -i '/export PHP_VERSION*/c\'"export PHP_VERSION=$PHP_VERSION" /etc/profile.d/myvars.sh
	fi
fi
# Source to allow extra env usage
source /etc/profile.d/myvars.sh

# Log as www-data
if [[ -z $(grep "www-data" "/home/vagrant/.bashrc") ]]; then
cat <<EOF >> /home/vagrant/.bashrc
# Log as www-data user
cd /var/www && sudo -s -u www-data;
EOF
fi

# Extra env
if [ -f /home/vagrant/provision/001-env.sh ]; then
	bash /home/vagrant/provision/001-env.sh
fi

# Source and display
source /etc/profile.d/myvars.sh
cat /etc/profile.d/myvars.sh
