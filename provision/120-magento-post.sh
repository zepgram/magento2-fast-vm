#!/bin/bash

# ------------------------------------- #
# Fast VM - Magento2                    #
#                                       #
# Author: zepgram                       #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Magento post-installation sequence ---'

# Magento cli
chmod +x "$PROJECT_PATH"/bin/magento
ln -sf "$PROJECT_PATH"/bin/magento /usr/local/bin/magento

# Enable nginx
if [ -f "${PROJECT_PATH}/nginx.conf.sample" ] && [ ! -f "${PROJECT_PATH}/nginx.conf" ]; then
  sudo -u vagrant cp "$PROJECT_PATH"/nginx.conf.sample "$PROJECT_PATH"/nginx.conf.tmp
fi
if [ -f "${PROJECT_PATH}/nginx.conf" ]; then
  sudo -u vagrant cp "$PROJECT_PATH"/nginx.conf /home/vagrant/extra/"${PROJECT_NAME}".nginx.conf;
else
  sudo -u vagrant cp "$PROJECT_PATH"/nginx.conf.tmp /home/vagrant/extra/"${PROJECT_NAME}".nginx.conf;
  sudo -u vagrant rm -f "$PROJECT_PATH"/nginx.conf.tmp
fi
sudo -u vagrant sed -i "s/fastcgi_buffers 1024 4k;/fastcgi_buffers 16 14k;\n    fastcgi_buffer_size 32k;/" /home/vagrant/extra/"${PROJECT_NAME}".nginx.conf;

# Composer config
if [ "$PROJECT_SOURCE" == "composer" ]; then
  # Enable php ini
  if [ -f "${PROJECT_PATH}/php.ini.sample" ] && [ ! -f "${PROJECT_PATH}/php.ini" ]; then
    sudo -u vagrant cp "$PROJECT_PATH"/php.ini.sample "$PROJECT_PATH"/php.ini
  fi
  # Enable npm
  if [ -f "${PROJECT_PATH}/package.json.sample" ] && [ ! -f "${PROJECT_PATH}/package.json" ]; then
    sudo -u vagrant cp "$PROJECT_PATH"/package.json.sample "$PROJECT_PATH"/package.json
  fi
  # Enable grunt
  if [ -f "${PROJECT_PATH}/Gruntfile.js.sample" ] && [ ! -f "${PROJECT_PATH}/Gruntfile.js" ]; then
    sudo -u vagrant cp "$PROJECT_PATH"/Gruntfile.js.sample "$PROJECT_PATH"/Gruntfile.js
  fi
fi

# Npm install
if [ -f "${PROJECT_PATH}/package.json" ] && [ -f "${PROJECT_PATH}/Gruntfile.js" ]; then
  cd "$PROJECT_PATH" \
    && echo 'Executing npm install...' \
    && sudo -u vagrant npm install &> /dev/null \
    && sudo -u vagrant npm update
fi

# Change materialization strategy for nfs
if [ "$PROJECT_MOUNT" == "nfs" ] && [ "$PROJECT_MOUNT_PATH" != "app" ]; then
  if [ -f "${PROJECT_PATH}/.git/config" ]; then
      git --git-dir "$PROJECT_PATH"/.git update-index --assume-unchanged app/etc/di.xml
  fi
  sudo -u vagrant sed -i 's/<item name="view_preprocessed" xsi:type="object">Magento\\\Framework\\\App\\\View\\\Asset\\\MaterializationStrategy\\\Symlink/<item name="view_preprocessed" xsi:type="object">Magento\\\Framework\\\App\\\View\\\Asset\\\MaterializationStrategy\\\Copy/' "$PROJECT_PATH"/app/etc/di.xml
fi

# Magento config
redis-cli flushall
if $(dpkg --compare-versions "${PROJECT_VERSION}" "gt" "2.2"); then
  sudo -u vagrant "$PROJECT_PATH"/bin/magento -n setup:config:set \
        --cache-backend=redis \
        --cache-backend-redis-server=127.0.0.1 \
        --cache-backend-redis-port=6379 \
        --cache-backend-redis-db=0 \
        --page-cache=redis \
        --page-cache-redis-server=127.0.0.1 \
        --page-cache-redis-port=6379 \
        --page-cache-redis-db=1 \
        --page-cache-redis-compress-data=1

  sudo -u vagrant "$PROJECT_PATH"/bin/magento -n setup:config:set \
        --session-save=redis \
        --session-save-redis-host=127.0.0.1 \
        --session-save-redis-port=6379 \
        --session-save-redis-db=2

  sudo -u vagrant "$PROJECT_PATH"/bin/magento config:set "admin/security/session_lifetime" "31536000"
  sudo -u vagrant "$PROJECT_PATH"/bin/magento config:set "admin/security/lockout_threshold" "180"
  sudo -u vagrant "$PROJECT_PATH"/bin/magento config:set "admin/security/password_lifetime" ""
  sudo -u vagrant "$PROJECT_PATH"/bin/magento config:set "admin/security/password_is_forced" "0"
  sudo -u vagrant "$PROJECT_PATH"/bin/magento config:set "web/secure/use_in_adminhtml" "1"
  sudo -u vagrant "$PROJECT_PATH"/bin/magento config:set "web/secure/use_in_frontend" "1"
  sudo -u vagrant "$PROJECT_PATH"/bin/magento config:set "web/secure/enable_hsts" "1"
  if $(dpkg --compare-versions "${PROJECT_VERSION}" "lt" "2.3.5-p2"); then
    sudo -u vagrant "$PROJECT_PATH"/bin/magento config:set "catalog/search/engine" "elasticsearch6"
  else
    sudo -u vagrant "$PROJECT_PATH"/bin/magento config:set "catalog/search/engine" "elasticsearch7"
  fi
else
  # Force https on unsecure request for older versions
  mysql -u vagrant -pvagrant -e "USE ${PROJECT_NAME}; UPDATE core_config_data set value='https://${PROJECT_URL}/' where path='web/unsecure/base_url';"
fi

# Set crypt key
if [ -n "$PROJECT_CRYPT_KEY" ] && [ -f /home/vagrant/extra/db-dump.sql ]; then
  sudo -u vagrant bin/magento setup:config:set -n --key "${PROJECT_CRYPT_KEY}"
fi

# Extra post-build
if [ -f /home/vagrant/extra/120-post-build.sh ]; then
  bash /home/vagrant/extra/120-post-build.sh
fi

# Get config from source project
if [ "$PROJECT_SOURCE" != "composer" ]; then
  git --git-dir "$PROJECT_PATH"/.git checkout app/etc/config.php
fi

# Clean compiled files
rm -rf "$PROJECT_PATH"/var/generation/
rm -rf "$PROJECT_PATH"/generated/code/
sudo -u vagrant "$PROJECT_PATH"/bin/magento setup:upgrade
sudo -u vagrant "$PROJECT_PATH"/bin/magento deploy:mode:set "$PROJECT_MODE"
sudo -u vagrant "$PROJECT_PATH"/bin/magento cache:enable
sudo -u vagrant "$PROJECT_PATH"/bin/magento cache:flush

# Restart services
/etc/init.d/php"${PROJECT_PHP_VERSION}"-fpm restart
/etc/init.d/nginx restart
/etc/init.d/mysql restart
/etc/init.d/redis-server restart
/etc/init.d/postfix restart
permission
