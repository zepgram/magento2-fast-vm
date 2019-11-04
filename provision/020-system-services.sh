#!/bin/bash

# ------------------------------------- #
# Fast VM - Magento2                    #
#                                       #
# Author: zepgram                       #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Configure system services ---'

# Create db user
mysql -u root -ppassword -e "CREATE USER IF NOT EXISTS 'vagrant'@'localhost' IDENTIFIED BY 'vagrant';"
mysql -u root -ppassword -e "CREATE USER IF NOT EXISTS 'vagrant'@'%' IDENTIFIED BY 'vagrant';"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON * . * TO 'vagrant'@'localhost';"
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON * . * TO 'vagrant'@'%';"
mysql -u root -ppassword -e "FLUSH PRIVILEGES;"

# Mysqld conf
if ! grep -qF "innodb_buffer_pool_size" /etc/mysql/percona-server.conf.d/mysqld.cnf; then
cat <<EOF >> /etc/mysql/percona-server.conf.d/mysqld.cnf
# Innodb
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 1
innodb_flush_method = O_DIRECT
EOF
fi


# -----------------------------------------------------------------------------------------------------


# Add binary entry for sendmail
ln -sfn /usr/sbin/sendmail /usr/local/bin/

# Postfix config
sed -i.bak '/relayhost/,/^/d' /etc/postfix/main.cf
echo 'relayhost = 127.0.0.1:1025
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128' | tee -a /etc/postfix/main.cf

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
/usr/sbin/sendmail -t -i -f $PROJECT_GIT_EMAIL <<MAIL_END
Subject: Vagrant: MailCatcher
To: $PROJECT_GIT_EMAIL

Test to validate catch email.
MAIL_END


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


# Fpm php configuration
sed -i 's/;opcache.enable=.*/opcache.enable=1/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/;opcache.enable_cli=.*/opcache.enable_cli=1/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/;opcache.memory_consumption=.*/opcache.memory_consumption=512/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=4/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=60000/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/;opcache.validate_timestamps=.*/opcache.validate_timestamps=1/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/memory_limit = .*/memory_limit = 2G/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i "s|;date.timezone =|date.timezone = ${PROJECT_TIME_ZONE}|" /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 1800/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/zlib.output_compression = .*/zlib.output_compression = On/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i "s|;sendmail_path.*|sendmail_path=/usr/sbin/sendmail -t -i -f vagrant@$PROJECT_URL|" /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i "s|;sendmail_from.*|sendmail_from=vagrant@$PROJECT_URL|" /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/smtp_port.*/smtp_port = 1025/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i "s|;opcache.file_cache=|opcache.file_cache=/tmp/php-opcache/|" /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini

# Cli php configuration
sed -i 's/;opcache.enable=.*/opcache.enable=1/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/;opcache.enable_cli=.*/opcache.enable_cli=1/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/;opcache.memory_consumption=.*/opcache.memory_consumption=512/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=4/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=60000/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/;opcache.validate_timestamps=.*/opcache.validate_timestamps=1/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/memory_limit = .*/memory_limit = 2G/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i "s|;date.timezone =|date.timezone = ${PROJECT_TIME_ZONE}|" /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 1800/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/zlib.output_compression = .*/zlib.output_compression = On/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i "s|;sendmail_path.*|sendmail_path=/usr/sbin/sendmail -t -i -f vagrant@$PROJECT_URL|" /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i "s|;sendmail_from.*|sendmail_from=vagrant@$PROJECT_URL|" /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/smtp_port.*/smtp_port = 1025/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i "s|;opcache.file_cache=|opcache.file_cache=/tmp/php-opcache/|" /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini

if ! grep -qF "/tmp/php-opcache" /etc/tmpfiles.d/php-cli-opcache.conf; then
cat <<EOF >> /etc/tmpfiles.d/php-cli-opcache.conf
d /tmp/php-opcache 1777 root root 1d
EOF
fi
systemd-tmpfiles --create /etc/tmpfiles.d/php-cli-opcache.conf


# -----------------------------------------------------------------------------------------------------


# SSL certificates
mkdir /home/vagrant/ssl
cd /home/vagrant/ssl && openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.${PROJECT_URL}" \
    -keyout www.${PROJECT_URL}.key -out www.${PROJECT_URL}.crt
cp /home/vagrant/ssl/www.${PROJECT_URL}.crt /etc/ssl/certs/www.${PROJECT_URL}.crt
cp /home/vagrant/ssl/www.${PROJECT_URL}.key /etc/ssl/private/www.${PROJECT_URL}.key
rm -rf /home/vagrant/ssl && cd /home/vagrant

# Nginx
perl -ne 'if ( m|\#location.*php\$ \{| .. m|^\s*#\}| ) { s/#//g; } print' -i /etc/nginx/sites-available/default
sed -i "s|fastcgi_pass unix:/var/run/php/.*|fastcgi_pass unix:/var/run/php/php${PROJECT_PHP_VERSION}-fpm.sock;|" /etc/nginx/sites-available/default
sed -i "s/With php-.*//" /etc/nginx/sites-available/default
sed -i "s/fastcgi_pass 127.0.0.1:9000;//" /etc/nginx/sites-available/default
sed -i 's/index index.html index.htm index.nginx-debian.html;/index index.php index.html index.htm index.nginx-debian.html;/' /etc/nginx/sites-available/default

# Fpm
sed -i 's/pm.max_children = .*/pm.max_children = 10/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/pool.d/www.conf
sed -i 's/pm.start_servers = .*/pm.start_servers = 2/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/pool.d/www.conf
sed -i 's/pm.min_spare_servers = .*/pm.min_spare_servers = 2/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/pool.d/www.conf
sed -i 's/pm.max_spare_servers = .*/pm.max_spare_servers = 5/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/pool.d/www.conf


# -----------------------------------------------------------------------------------------------------


# Elastic search
sed -i "s/#network.host: .*/network.host: 127.0.0.1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/#http.port: .*/http.port: 9200/" /etc/elasticsearch/elasticsearch.yml
sed -i "s|#JAVA_HOME.*|JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java|" /etc/default/elasticsearch
/bin/systemctl daemon-reload
/bin/systemctl enable elasticsearch.service
/bin/systemctl start elasticsearch.service

# Server permissions
mkdir -p /var/www/html

# Adminer in default
mkdir -p /var/www/html/adminer
curl -sL -o /var/www/html/adminer/index.php https://www.adminer.org/latest-en.php

# Add php info
mkdir -p /var/www/html/php/
cat <<-EOF > /var/www/html/php/index.php
<?php
  phpinfo();
EOF
php -v

chown -R www-data:www-data /var/www/
usermod -a -G www-data vagrant
