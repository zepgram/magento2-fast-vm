#!/bin/bash

# ------------------------------------- #
# NFS Vagrant - Magento2                #
#                                       #
# Author: zpgram                        #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Magento pre-installation sequence ---'

# Create db
mysql -u root -ppassword -e "DROP DATABASE IF EXISTS ${PROJECT_NAME};"
mysql -u root -ppassword -e "CREATE DATABASE ${PROJECT_NAME} COLLATE 'utf8mb4_general_ci';"

# Project name url
cat <<EOF > /etc/apache2/sites-available/010-$PROJECT_NAME.conf
<VirtualHost *:80>
  ServerName ${PROJECT_URL}
  DocumentRoot "${PROJECT_PATH}"
  SetEnv VAGRANT 1
  ErrorLog /var/log/apache2/${PROJECT_NAME}.error.log
  CustomLog /var/log/apache2/${PROJECT_NAME}.access.log combined
  SetEnvIf X-Forwarded-Proto https HTTPS=on
  <Directory "${PROJECT_PATH}">
    Order Deny,Allow
    Allow from all
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
a2ensite 010-"$PROJECT_NAME"

# Composer authentication
sudo -u vagrant mkdir -p /home/vagrant/.composer
sudo -u vagrant cat <<EOF > /home/vagrant/.composer/auth.json
{
    "http-basic": {
        "repo.magento.com": {
            "username": "${PROJECT_COMPOSER_USER}",
            "password": "${PROJECT_COMPOSER_PASS}"
        }
    }
}
EOF

# Permission script
sudo -u vagrant cat <<EOF > /home/vagrant/permission.bak
echo 'Applying permissions to $PROJECT_PATH project'
cd "$PROJECT_PATH" \\
&& sudo find var vendor pub/static pub/media app/etc -type f -exec chmod g+w {} \; \\
&& sudo find var vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} \; \\
&& sudo chown -R www-data:www-data . && sudo chmod u+x bin/magento
EOF
grep '[^[:blank:]]' < /home/vagrant/permission.bak > /home/vagrant/permission
ln -sf /home/vagrant/permission /usr/local/bin/permission
chmod +x /usr/local/bin/permission

# Extra pre-build
if [ -f /home/vagrant/provision/100-pre-build.sh ]; then
  bash /home/vagrant/provision/100-pre-build.sh
fi

# Flush and restart
/etc/init.d/apache2 restart
/etc/init.d/mysql restart
/etc/init.d/redis-server restart
/etc/init.d/postfix restart
