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

# Composer config
if [ "$PROJECT_SOURCE" == "composer" ]; then
  # Enable php ini
  if [ -f "${PROJECT_PATH}/php.ini.sample" ]; then
    sudo -u "$PROJECT_SETUP_OWNER" cp "$PROJECT_PATH"/php.ini.sample "$PROJECT_PATH"/php.ini
  fi
  # Enable npm
  if [ -f "${PROJECT_PATH}/package.json.sample" ]; then
    sudo -u "$PROJECT_SETUP_OWNER" cp "$PROJECT_PATH"/package.json.sample "$PROJECT_PATH"/package.json
  fi
  # Enable grunt
  if [ -f "${PROJECT_PATH}/Gruntfile.js.sample" ]; then
    sudo -u "$PROJECT_SETUP_OWNER" cp "$PROJECT_PATH"/Gruntfile.js.sample "$PROJECT_PATH"/Gruntfile.js
  fi
fi

# Npm install
if [ -f "${PROJECT_PATH}/package.json" ] && [ -f "${PROJECT_PATH}/Gruntfile.js" ]; then
  cd "$PROJECT_PATH" \
    && echo 'Executing npm install...' \
    && sudo -u "$PROJECT_SETUP_OWNER" npm install &> /dev/null \
    && sudo -u "$PROJECT_SETUP_OWNER" npm update
fi

# Change materialization strategy for nfs
if [ "$PROJECT_MOUNT" == "nfs" ] && [ "$PROJECT_MOUNT_PATH" != "app" ]; then
  if [ -f "${PROJECT_PATH}/.git/config" ]; then
      git --git-dir "$PROJECT_PATH"/.git update-index --assume-unchanged app/etc/di.xml
  fi
  sudo -u "$PROJECT_SETUP_OWNER" sed -i 's/<item name="view_preprocessed" xsi:type="object">Magento\\\Framework\\\App\\\View\\\Asset\\\MaterializationStrategy\\\Symlink/<item name="view_preprocessed" xsi:type="object">Magento\\\Framework\\\App\\\View\\\Asset\\\MaterializationStrategy\\\Copy/' "$PROJECT_PATH"/app/etc/di.xml
fi

# Clean compiled files and cache
rm -rf "$PROJECT_PATH"/var/generation/
rm -rf "$PROJECT_PATH"/generated/code/
sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento cache:clean

# Magento config
if $(dpkg --compare-versions "${PROJECT_VERSION}" "gt" "2.2"); then
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

  sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento config:set "admin/security/session_lifetime" "31536000"
  sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento config:set "admin/security/lockout_threshold" "180"
  sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento config:set "admin/security/password_lifetime" ""
  sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento config:set "admin/security/password_is_forced" "0"
  sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento config:set "web/secure/use_in_adminhtml" "1"
else
  mysql -u vagrant -pvagrant -e "USE ${PROJECT_NAME}; UPDATE core_config_data set value='https://${PROJECT_URL}/' where path='web/unsecure/base_url';"
fi

# Extra post-build
if [ -f /home/vagrant/extra/120-post-build.sh ]; then
  bash /home/vagrant/extra/120-post-build.sh
fi

# Clean compiled files
rm -rf "$PROJECT_PATH"/var/generation/
rm -rf "$PROJECT_PATH"/generated/code/
sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento setup:upgrade
sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento deploy:mode:set "$PROJECT_MODE"
sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento cache:enable

# Restart
/etc/init.d/apache2 restart
/etc/init.d/redis-server restart
permission
