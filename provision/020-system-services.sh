#!/bin/bash

# ------------------------------------- #
# NFS Vagrant - Magento2                #
#                                       #
# Author: zpgram                        #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Configure system services ---'

# Add git host
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 600 /home/vagrant/.ssh/id_rsa.pub
echo -e "Host ${PROJECT_HOST_REPOSITORY}\n\tStrictHostKeyChecking no\n" >> /home/vagrant/.ssh/config

# Create user
sed -i 's/bind-address/#bind-address/' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i 's/skip-external-locking/#skip-external-locking/' /etc/mysql/mariadb.conf.d/50-server.cnf

mysql -u root -ppassword -e "CREATE USER IF NOT EXISTS 'vagrant'@'localhost' IDENTIFIED BY 'vagrant';"
mysql -u root -ppassword -e "CREATE USER IF NOT EXISTS 'vagrant'@'%' IDENTIFIED BY 'vagrant';"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON * . * TO 'vagrant'@'localhost';"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON * . * TO 'vagrant'@'%';"
mysql -u root -ppassword -e "FLUSH PRIVILEGES;"

# -----------------------------------------------------------------------------------------------------


# First, remove old relayhost entry
sed -i.bak '/relayhost/,/^/d' /etc/postfix/main.cf

# Enter new information
echo "relayhost = 127.0.0.1:1025
myhostname = $PROJECT_URL
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128" | tee -a /etc/postfix/main.cf

# Php.ini configuration
sed -i 's/smtp_port.*/smtp_port = 1025/' /etc/php/"$PHP_VERSION"/apache2/php.ini
cat <<EOF >> /etc/php/"$PHP_VERSION"/apache2/php.ini
sendmail_path = "/usr/bin/env catchmail -f vagrant@$PROJECT_URL"' | sudo tee -a /etc/php/"$PHP_VERSION"/apache2/php.ini
EOF

# Configuration on booting
cat <<'EOF' > /etc/init.d/mailcatcher
#!/bin/sh

### BEGIN INIT INFO
# Provides:          mailcatcher
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

set -x
lsof -ti :1025 | xargs --no-run-if-empty kill -9
mailcatcher --http-ip=0.0.0.0
EOF
chmod +x /etc/init.d/mailcatcher
update-rc.d mailcatcher defaults

lsof -ti :1025 | xargs --no-run-if-empty kill -9
mailcatcher --http-ip=0.0.0.0


# -----------------------------------------------------------------------------------------------------


# Redis conf
cat <<'EOF' > /etc/systemd/system/rc-local.service
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

cat <<'EOF' > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0
EOF

chmod +x /etc/rc.local
systemctl enable rc-local

echo never > /sys/kernel/mm/transparent_hugepage/enabled
sysctl -w net.core.somaxconn=65535
sysctl vm.overcommit_memory=1

head -n -1 /etc/rc.local > /etc/rc.temp.local ; mv /etc/rc.temp.local /etc/rc.local
cat <<'EOF' >> /etc/rc.local
echo never > /sys/kernel/mm/transparent_hugepage/enabled
sysctl -w net.core.somaxconn=65535

exit 0
EOF

cat <<'EOF' >> /etc/sysctl.conf
vm.overcommit_memory=1
EOF


# -----------------------------------------------------------------------------------------------------


# Php memory limit
sed -i 's/memory_limit = .*/memory_limit = 2G/' /etc/php/"$PHP_VERSION"/apache2/php.ini
sed -i 's/memory_limit = .*/memory_limit = 2G/' /etc/php/"$PHP_VERSION"/cli/php.ini

# Max execution time
sed -i 's/max_execution_time = 30/max_execution_time = 60/' /etc/php/"$PHP_VERSION"/apache2/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 60/' /etc/php/"$PHP_VERSION"/cli/php.ini

# Php opcache apache
sed -i "s|;date.timezone =|date.timezone = ${PROJECT_TIME_ZONE}|" /etc/php/"$PHP_VERSION"/apache2/php.ini
sed -i 's/;opcache.enable=0/opcache.enable=1/' /etc/php/"$PHP_VERSION"/apache2/php.ini
sed -i 's/;opcache.enable_cli=0/opcache.enable_cli=1/' /etc/php/"$PHP_VERSION"/apache2/php.ini

# Php opcache cli
sed -i "s|;date.timezone =|date.timezone = ${PROJECT_TIME_ZONE}|" /etc/php/"$PHP_VERSION"/cli/php.ini
sed -i 's/;opcache.enable=0/opcache.enable=1/' /etc/php/"$PHP_VERSION"/cli/php.ini
sed -i 's/;opcache.enable_cli=0/opcache.enable_cli=1/' /etc/php/"$PHP_VERSION"/cli/php.ini

# File opcache for cli
cat <<EOF >> /etc/php/"$PHP_VERSION"/apache2/php.ini
opcache.file_cache=/tmp/php-opcache
EOF
cat <<EOF >> /etc/php/"$PHP_VERSION"/cli/php.ini
opcache.file_cache=/tmp/php-opcache
EOF

cat <<EOF >> /etc/tmpfiles.d/php-cli-opcache.conf
d /tmp/php-opcache 1777 root root 1d
EOF

systemd-tmpfiles --create /etc/tmpfiles.d/php-cli-opcache.conf


# -----------------------------------------------------------------------------------------------------

mkdir -p /var/www/html
chown -R www-data:www-data /var/www/

# Default
cat <<'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
  ServerName default
  DocumentRoot /var/www/html
  ErrorLog /var/log/apache2/default.error.log
  CustomLog /var/log/apache2/default.access.log combined
  SetEnvIf X-Forwarded-Proto https HTTPS=on
</VirtualHost>
EOF

# SSL
cat <<'EOF' > /etc/apache2/sites-available/001-ssl.conf
<IfModule mod_ssl.c>
  <VirtualHost _default_:443>
    SSLEngine on
    SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
    SSLHonorCipherOrder On
    SSLProtocol All -SSLv2 -SSLv3
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

    <Proxy *>
      Order deny,allow
      Allow from all
    </Proxy>

    ProxyPass / http://localhost:80/ retry=0
    ProxyPassReverse / http://localhost:80/
    ProxyPreserveHost on
    RequestHeader set X-Forwarded-Proto "https" early

    <FilesMatch "\.(shtml|phtml|php)$">
      SSLOptions +StdEnvVars
    </FilesMatch>

    ErrorLog /var/log/apache2/default.error.log
    CustomLog /var/log/apache2/default.access.log combined
  </VirtualHost>
</IfModule>
EOF

a2ensite 000-default
a2ensite 001-ssl
sudo a2enmod deflate expires headers proxy proxy_http rewrite ssl

service apache2 reload

# Adminer in default
mkdir -p /var/www/html/adminer
curl -sL -o /var/www/html/adminer/index.php https://www.adminer.org/latest-en.php

# Add php info
mkdir -p /var/www/html/php/
cat <<EOF > /var/www/html/php/index.php
<?php
  phpinfo();
EOF
php -v