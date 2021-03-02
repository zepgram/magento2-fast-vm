#!/bin/bash

# ------------------------------------- #
# Fast VM - Magento2                    #
#                                       #
# Author: zepgram                       #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Magento pre-installation sequence ---'

# Create db
mysql -u root -ppassword -e "DROP DATABASE IF EXISTS ${PROJECT_NAME};"
mysql -u root -ppassword -e "CREATE DATABASE ${PROJECT_NAME} COLLATE 'utf8mb4_general_ci';"

# Nginx project conf
cat <<-EOF > /etc/nginx/sites-available/010-"$PROJECT_NAME"
upstream fastcgi_backend {
    server  unix:/run/php/php${PROJECT_PHP_VERSION}-fpm.sock;
}

server {
    listen 80;
    listen [::]:80;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name ${PROJECT_URL} www.${PROJECT_URL};
    set MAGE_ROOT /var/www/html/${PROJECT_NAME};
    include /home/vagrant/extra/${PROJECT_NAME}.nginx.conf;

    ssl_certificate /etc/ssl/certs/www.${PROJECT_URL}.crt;
    ssl_certificate_key /etc/ssl/private/www.${PROJECT_URL}.key;
    ssl_protocols TLSv1.2 TLSv1.1 TLSv1;

    access_log /var/log/nginx/${PROJECT_NAME}.access.log;
    error_log /var/log/nginx/${PROJECT_NAME}.error.log error;
}
EOF
sed -i 's/MAGE_ROOT/$MAGE_ROOT/' /etc/nginx/sites-available/010-"$PROJECT_NAME"
ln -sfn /etc/nginx/sites-available/010-"$PROJECT_NAME" /etc/nginx/sites-enabled/010-"$PROJECT_NAME"

# Permission script
cat <<-EOF > /home/vagrant/permission.bak
echo 'Applying permissions to $PROJECT_PATH'
cd "$PROJECT_PATH" \\
&& sudo find var vendor pub/static pub/media app/etc -type f -exec chmod g+w {} \; \\
&& sudo find var vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} \; \\
&& sudo find ./var ./generated -type d -exec chmod 777 {} \; \\
&& sudo chmod u+x bin/magento \\
&& sudo chown -fR :www-data . || :
EOF
grep '[^[:blank:]]' < /home/vagrant/permission.bak > /usr/local/bin/permission
rm -rf /home/vagrant/permission.bak
chmod +x /usr/local/bin/permission

# Credentials
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 600 /home/vagrant/.ssh/id_rsa.pub
rm -rf /home/vagrant/.ssh/known_hosts /home/vagrant/.ssh/config
echo -e "StrictHostKeyChecking no\n" >> /home/vagrant/.ssh/config
ssh-keyscan -t rsa "${PROJECT_HOST_REPOSITORY}" >> /home/vagrant/.ssh/known_hosts
composer config --global http-basic.repo.magento.com "${PROJECT_COMPOSER_USER}" "${PROJECT_COMPOSER_PASS}"
sudo -u vagrant composer config --global http-basic.repo.magento.com "${PROJECT_COMPOSER_USER}" "${PROJECT_COMPOSER_PASS}"

# Auth.json
cat <<-EOF > /home/vagrant/auth.json
{
    "http-basic": {
        "repo.magento.com": {
            "username": "${PROJECT_COMPOSER_USER}",
            "password": "${PROJECT_COMPOSER_PASS}"
        }
    }
}
EOF

# Git global config
if [ "$PROJECT_SOURCE" != "composer" ]; then
  sudo -u vagrant git config --global user.name "$PROJECT_GIT_USER"
  sudo -u vagrant git config --global user.email "$PROJECT_GIT_EMAIL"
  sudo -u vagrant git config --global core.filemode false
fi

# Reapply rights for vagrant user
chown -R vagrant:vagrant /home/vagrant

# Execute import sql
if [ -f /home/vagrant/extra/db-dump.sql.gz ]; then
	rm -f /home/vagrant/extra/db-dump.sql
	gunzip /home/vagrant/extra/db-dump.sql.gz
fi
if [ -f /home/vagrant/extra/db-dump.sql ]; then
	echo '--- Magento db dump import ---'
	mysql -u vagrant -pvagrant -e "USE ${PROJECT_NAME};SET FOREIGN_KEY_CHECKS = 0;source /home/vagrant/extra/db-dump.sql;SET FOREIGN_KEY_CHECKS = 1;"
fi

# Extra pre-build
if [ -f /home/vagrant/extra/100-pre-build.sh ]; then
  bash /home/vagrant/extra/100-pre-build.sh
fi
