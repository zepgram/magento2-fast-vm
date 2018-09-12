#!/bin/bash

# ------------------------------------- #
# NFS Vagrant - Magento2                #
#                                       #
# Author: zpgram                        #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Magento post-installation sequence ---'

# Magento cli
chmod +x "$PROJECT_PATH"/bin/magento
ln -sf "$PROJECT_PATH"/bin/magento /usr/local/bin/magento

# Post setup
sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento deploy:mode:set "$PROJECT_MODE"
sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento config:set "admin/security/session_lifetime" "31536000"
sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento config:set "admin/security/lockout_threshold" "180"

# Redis configuration
sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento setup:config:set \
      --cache-backend=redis \
      --cache-backend-redis-server=127.0.0.1 \
      --cache-backend-redis-port=6379 \
      --cache-backend-redis-db=0 \
      --page-cache=redis \
      --page-cache-redis-server=127.0.0.1 \
      --page-cache-redis-port=6379 \
      --page-cache-redis-db=1 \
      --page-cache-redis-compress-data=1

sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento setup:config:set \
      --session-save=redis \
      --session-save-redis-host=127.0.0.1 \
      --session-save-redis-port=6379 \
      --session-save-redis-db=2

# Composer config
if [ $PROJECT_SOURCE == "composer" ]; then
  # Enable php ini
  if [ -f "${PROJECT_PATH}/php.ini.sample" ]; then
    sudo -u "$PROJECT_SETUP_OWNER" cp "$PROJECT_PATH"/php.ini.sample "$PROJECT_PATH"/php.ini
  fi
  # Run npm install if required files exist
  if [ -f "${PROJECT_PATH}/Gruntfile.js.sample" ]; then
    sudo -u "$PROJECT_SETUP_OWNER" cp "$PROJECT_PATH"/Gruntfile.js.sample "$PROJECT_PATH"/Gruntfile.js
  fi
  if [ -f "${PROJECT_PATH}/package.json.sample" ]; then
    sudo -u "$PROJECT_SETUP_OWNER" cp "$PROJECT_PATH"/package.json.sample "$PROJECT_PATH"/package.json
  fi
  if [ -f "${PROJECT_PATH}/package.json" ] && [ -f "${PROJECT_PATH}/Gruntfile.js" ]; then
    cd "$PROJECT_PATH" \
      && sudo -u "$PROJECT_SETUP_OWNER" npm install &> /dev/null \
      && sudo -u "$PROJECT_SETUP_OWNER" npm update
  fi
else
  if [ -f "${PROJECT_PATH}/.git/config" ]; then
    # Git config (ignore permission change)
    git --git-dir "$PROJECT_PATH"/.git config user.name "$PROJECT_USER_NAME"
    git --git-dir "$PROJECT_PATH"/.git config user.email "$PROJECT_USER_EMAIL"
    git --git-dir "$PROJECT_PATH"/.git config core.filemode false
  fi
fi

# Extra post-build
if [ -f /home/vagrant/provision/120-post-build.sh ]; then
  bash /home/vagrant/provision/120-post-build.sh
fi

# Set permission to magento
/etc/init.d/apache2 restart
/etc/init.d/redis-server restart
permission
