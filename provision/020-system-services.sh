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

# Mysql conf
if ! grep -qF "innodb_buffer_pool_size" /etc/mysql/mysql.conf.d/mysqld.cnf; then
cat <<EOF >> /etc/mysql/mysql.conf.d/mysqld.cnf
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
cat <<'EOF' > /etc/systemd/system/mailhog.service
[Unit]
Description=MailHog service

[Service]
ExecStart=/usr/local/bin/mailhog

[Install]
WantedBy=multi-user.target
EOF
systemctl start mailhog
systemctl enable mailhog

/usr/sbin/sendmail -t -i -f $PROJECT_GIT_EMAIL <<MAIL_END
Subject: Vagrant: MailHog
To: $PROJECT_GIT_EMAIL

Test to validate catch email.
MAIL_END


# -----------------------------------------------------------------------------------------------------


# Fpm php configuration
sed -i 's/memory_limit = .*/memory_limit = 4G/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i "s|;date.timezone =|date.timezone = ${PROJECT_TIME_ZONE}|" /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 1800/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini
sed -i 's/zlib.output_compression = .*/zlib.output_compression = On/' /etc/php/"$PROJECT_PHP_VERSION"/fpm/php.ini

# Cli php configuration
sed -i 's/memory_limit = .*/memory_limit = 4G/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i "s|;date.timezone =|date.timezone = ${PROJECT_TIME_ZONE}|" /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 1800/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini
sed -i 's/zlib.output_compression = .*/zlib.output_compression = On/' /etc/php/"$PROJECT_PHP_VERSION"/cli/php.ini

touch /etc/tmpfiles.d/php-cli-opcache.conf;
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
    -keyout www."${PROJECT_URL}".key -out www."${PROJECT_URL}".crt
cp /home/vagrant/ssl/www."${PROJECT_URL}".crt /etc/ssl/certs/www."${PROJECT_URL}".crt
cp /home/vagrant/ssl/www."${PROJECT_URL}".key /etc/ssl/private/www."${PROJECT_URL}".key
rm -rf /home/vagrant/ssl && cd /home/vagrant

# Nginx
perl -ne 'if ( m|\#location.*php\$ \{| .. m|^\s*#\}| ) { s/#//g; } print' -i /etc/nginx/sites-available/default
sed -i "s|fastcgi_pass unix:/run/php/.*|fastcgi_pass unix:/run/php/php${PROJECT_PHP_VERSION}-fpm.sock;|" /etc/nginx/sites-available/default
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
if $(dpkg --compare-versions "${PROJECT_VERSION}" "ge" "2.4.0"); then
  sed -i "s|#JAVA_HOME.*|JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre|" /etc/default/elasticsearch
else
  sed -i "s|#JAVA_HOME.*|JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java|" /etc/default/elasticsearch
fi
mkdir /etc/systemd/system/elasticsearch.service.d
cat <<'EOF' > /etc/systemd/system/elasticsearch.service.d/override.conf
[Service]
Restart=always
EOF

/bin/systemctl daemon-reload
/bin/systemctl enable elasticsearch.service
/bin/systemctl start elasticsearch.service


# -----------------------------------------------------------------------------------------------------


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
