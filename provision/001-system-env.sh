#!/bin/bash

# ------------------------------------- #
# Fast VM - Magento2                    #
#                                       #
# Author: zepgram                       #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Environment variables ---'

# Set environment variable
cat <<EOF > /etc/profile.d/env.sh
export PROJECT_NAME="${1}"
export PROJECT_USER="${1}"
export PROJECT_PATH="/srv/${1}"
export PROJECT_COMPOSER_USER="${2}"
export PROJECT_COMPOSER_PASS="${3}"
export PROJECT_GIT_USER="${4}"
export PROJECT_GIT_EMAIL="${5}"
export PROJECT_HOST_REPOSITORY="${6}"
export PROJECT_REPOSITORY="${7}"
export PROJECT_URL="${8}"
export PROJECT_SOURCE="${9}"
export PROJECT_EDITION="${10}"
export PROJECT_VERSION="${11}"
export PROJECT_SAMPLE="${12}"
export PROJECT_MODE="${13}"
export PROJECT_CURRENCY="${14}"
export PROJECT_LANGUAGE="${15}"
export PROJECT_TIME_ZONE="${16}"
export PROJECT_MOUNT="${17}"
export PROJECT_MOUNT_PATH="${18}"
EOF
source /etc/profile.d/env.sh

# Create magento user and password
if [[ ! -f "/root/.user-${PROJECT_USER}" ]]; then
	useradd -m -p $(python -c "import crypt; print crypt.crypt(\"magento\", \"\$6\$$(</dev/urandom tr -dc 'a-zA-Z0-9' | head -c 32)\$\")") "$PROJECT_USER"
	usermod -a -G sudo "$PROJECT_USER"
	usermod -g www-data "$PROJECT_USER"
	usermod --shell /bin/bash "$PROJECT_USER"
	touch /root/.user-"$PROJECT_USER"
cat <<EOF >> /home/"$PROJECT_USER"/.bashrc

# Source env
source /etc/profile.d/env.sh
source /etc/profile.d/setup-owner.sh
EOF
fi

# Log as magento user
if [[ -z $(grep "${PROJECT_USER}" "/home/vagrant/.bashrc") ]]; then
cat <<EOF >> /home/vagrant/.bashrc
# Log as $PROJECT_USER user
cd $PROJECT_PATH && sudo su $PROJECT_USER;
EOF
fi

# Extra env
if [ -f /home/vagrant/extra/001-env.sh ]; then
	bash /home/vagrant/extra/001-env.sh
fi

# Set project owner for setup
MOUNT_FULL_PATH=$PROJECT_PATH
if [ $PROJECT_MOUNT_PATH == "app" ]; then
	MOUNT_FULL_PATH=$PROJECT_PATH/app
fi
SETUP_OWNER="$(ls -ld $MOUNT_FULL_PATH | awk 'NR==1 {print $3}')"
if [ $SETUP_OWNER != "magento" ]; then
	SETUP_OWNER="vagrant"
fi
cat <<EOF > /etc/profile.d/setup-owner.sh
export PROJECT_SETUP_OWNER="${SETUP_OWNER}"
EOF

# Source and display
source /etc/profile
cat /etc/profile.d/setup-owner.sh
cat /etc/profile.d/env.sh
