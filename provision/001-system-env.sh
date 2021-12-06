#!/bin/bash

# ------------------------------------- #
# Fast VM - Magento2                    #
#                                       #
# Author: zepgram                       #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Environment variables ---'

# Set php version
PROJECT_VERSION=${12};
PROJECT_PHP_VERSION='7.4';
if $(dpkg --compare-versions "${PROJECT_VERSION}" "lt" "2.3.6"); then
  PROJECT_PHP_VERSION='7.3';
fi
if $(dpkg --compare-versions "${PROJECT_VERSION}" "lt" "2.3"); then
  PROJECT_PHP_VERSION='7.1';
fi
if $(dpkg --compare-versions "${PROJECT_VERSION}" "lt" "2.2"); then
  PROJECT_PHP_VERSION='7.0';
fi
if [ "${9}" != 'default' ]; then
  PROJECT_PHP_VERSION="${9}"
fi

# Set environment variable
cat <<EOF > /etc/profile.d/env.sh
export PROJECT_NAME="${1}"
export PROJECT_USER="${1}"
export PROJECT_PATH="/home/vagrant/${1}"
export PROJECT_COMPOSER_USER="${2}"
export PROJECT_COMPOSER_PASS="${3}"
export PROJECT_GIT_USER="${4}"
export PROJECT_GIT_EMAIL="${5}"
export PROJECT_HOST_REPOSITORY="${6}"
export PROJECT_REPOSITORY="${7}"
export PROJECT_URL="${8}"
export PROJECT_PHP_VERSION="${PROJECT_PHP_VERSION}"
export PROJECT_SOURCE="${10}"
export PROJECT_EDITION="${11}"
export PROJECT_VERSION="${PROJECT_VERSION}"
export PROJECT_SAMPLE="${13}"
export PROJECT_MODE="${14}"
export PROJECT_CURRENCY="${15}"
export PROJECT_LANGUAGE="${16}"
export PROJECT_TIME_ZONE="${17}"
export PROJECT_CRYPT_KEY="${18}"
export PROJECT_MOUNT="${19}"
export PROJECT_MOUNT_PATH="${20}"
EOF
source /etc/profile.d/env.sh

# Project path
if [[ -z $(grep "${PROJECT_PATH}" "/home/vagrant/.bashrc") ]]; then
cat <<-EOF >> /home/vagrant/.bashrc
cd $PROJECT_PATH
EOF
fi

# Patch extra files
sudo -u vagrant mkdir -p /home/vagrant/extra
if [[ ! $(dpkg-query -l 'dos2unix') ]]; then 
 	sudo apt-get install -y dos2unix
fi
if [ -f /home/vagrant/extra/001-env.sh ]; then
	dos2unix /home/vagrant/extra/001-env.sh
fi
if [ -f /home/vagrant/extra/100-pre-build.sh ]; then
	dos2unix /home/vagrant/extra/100-pre-build.sh
fi
if [ -f /home/vagrant/extra/120-post-build.sh ]; then
	dos2unix /home/vagrant/extra/120-post-build.sh
fi

# Extra env
if [ -f /home/vagrant/extra/001-env.sh ]; then
	bash /home/vagrant/extra/001-env.sh
fi

# Source and display
source /etc/profile
cat /etc/profile.d/env.sh
