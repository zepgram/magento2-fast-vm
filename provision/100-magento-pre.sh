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
usermod -a -G www-data "$PROJECT_USER"

# Permission script
cat <<EOF > /home/vagrant/permission.bak
if [ "$PROJECT_NFS" != "true" ] || [ "$PROJECT_MOUNT" == "app" ]; then
echo 'Applying permissions to $PROJECT_PATH project'
cd "$PROJECT_PATH" \\
&& sudo find var vendor pub/static pub/media app/etc -type f -exec chmod g+w {} \; \\
&& sudo find var vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} \; \\
&& sudo chmod u+x bin/magento \\
&& sudo chown -fR $PROJECT_USER:www-data . || :
fi
EOF
grep '[^[:blank:]]' < /home/vagrant/permission.bak > /usr/local/bin/permission
rm -rf /home/vagrant/permission.bak
chmod +x /usr/local/bin/permission

# Credentials
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 600 /home/vagrant/.ssh/id_rsa.pub
echo -e "Host ${PROJECT_HOST_REPOSITORY}\n\tStrictHostKeyChecking no\n" >> /home/vagrant/.ssh/config
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

# Copy credentials to project user
cp -r /home/vagrant/.composer /home/"$PROJECT_USER"/.composer
cp -r /home/vagrant/.ssh /home/"$PROJECT_USER"/.ssh
chown -R "$PROJECT_USER":"$PROJECT_USER" /home/"$PROJECT_USER"/.composer
chown -R "$PROJECT_USER":"$PROJECT_USER" /home/"$PROJECT_USER"/.ssh

# Extra pre-build
if [ -f /home/vagrant/provision/100-pre-build.sh ]; then
  bash /home/vagrant/provision/100-pre-build.sh
fi

# Restart services
/etc/init.d/apache2 restart
/etc/init.d/mysql restart
/etc/init.d/redis-server restart
/etc/init.d/postfix restart
