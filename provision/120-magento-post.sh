#!/bin/bash

# ------------------------------------- #
# NFS Vagrant - Magento2                #
#                                       #
# Author: zpgram                        #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Magento post-installation sequence ---'

# Post setup
magento deploy:mode:set "$PROJECT_MODE"
magento config:set "admin/security/session_lifetime" "31536000"
magento config:set "admin/security/lockout_threshold" "180"

# Composer config
if [ $PROJECT_SOURCE == "composer" ]; then
  # Enable php ini
  if [ -f "${PROJECT_PATH}/php.ini.sample" ]; then
  	cp "$PROJECT_PATH"/php.ini.sample "$PROJECT_PATH"/php.ini
  fi
  # Run npm install if required files exist
  if [ -f "${PROJECT_PATH}/Gruntfile.js.sample" ]; then
  	cp "$PROJECT_PATH"/Gruntfile.js.sample "$PROJECT_PATH"/Gruntfile.js
  fi
  if [ -f "${PROJECT_PATH}/package.json.sample" ]; then
  	cp "$PROJECT_PATH"/package.json.sample "$PROJECT_PATH"/package.json
  fi
  if [ -f "${PROJECT_PATH}/package.json" ] && [ -f "${PROJECT_PATH}/Gruntfile.js" ]; then
  	cd "$PROJECT_PATH"; npm install &> /dev/null; npm update
  fi
else
  if [ -f "${PROJECT_PATH}/.git/config" ]; then
    # Git config (ignore permission change)
    git --git-dir "$PROJECT_PATH"/.git config user.name "$PROJECT_USER_NAME"
    git --git-dir "$PROJECT_PATH"/.git config user.email "$PROJECT_USER_EMAIL"
    git --git-dir "$PROJECT_PATH"/.git config core.filemode false
  fi
fi

# Redis configuration
magento setup:config:set \
      --cache-backend=redis \
      --cache-backend-redis-server=127.0.0.1 \
      --cache-backend-redis-port=6379 \
      --cache-backend-redis-db=0 \
      --page-cache=redis \
      --page-cache-redis-server=127.0.0.1 \
      --page-cache-redis-port=6379 \
      --page-cache-redis-db=1 \
      --page-cache-redis-compress-data=1

magento setup:config:set \
      --session-save=redis \
      --session-save-redis-host=127.0.0.1 \
      --session-save-redis-port=6379 \
      --session-save-redis-db=2

# Apply rights before post-build
permission

# Extra post-build
if [ -f /home/vagrant/provision/120-post-build.sh ]; then
  bash /home/vagrant/provision/120-post-build.sh
  # Apply rights after post-build
  permission
fi
