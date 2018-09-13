#!/bin/bash

# ------------------------------------- #
# NFS Vagrant - Magento2                #
#                                       #
# Author: zpgram                        #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

export DEBIAN_FRONTEND=noninteractive

echo '--- Magento installation sequence ---'

# Prepare directory 
rm -rf "$PROJECT_BUILD" &> /dev/null
rm -rf "$PROJECT_PATH" &> /dev/null
sudo -u vagrant mkdir -p /home/vagrant/build/

# Get installation files from source
if [ $PROJECT_SOURCE == "composer" ]; then
	# Install magento source code
	sudo -u vagrant composer create-project --no-install --no-progress --repository-url=https://repo.magento.com/ \
		magento/project-"$PROJECT_EDITION"-edition="$PROJECT_VERSION" "$PROJECT_BUILD"
	# Install sample data
	if [ $PROJECT_SAMPLE == "true" ]; then
		sudo -u vagrant composer require -d "$PROJECT_BUILD" \
		magento/module-bundle-sample-data magento/module-widget-sample-data \
		magento/module-theme-sample-data magento/module-catalog-sample-data \
		magento/module-customer-sample-data magento/module-cms-sample-data \
		magento/module-catalog-rule-sample-data magento/module-sales-rule-sample-data \
		magento/module-review-sample-data magento/module-tax-sample-data \
		magento/module-sales-sample-data magento/module-grouped-product-sample-data \
		magento/module-downloadable-sample-data magento/module-msrp-sample-data \
		magento/module-configurable-sample-data magento/module-product-links-sample-data \
		magento/module-wishlist-sample-data magento/module-swatches-sample-data \
		magento/sample-data-media magento/module-offline-shipping-sample-data --no-update
	fi
else
	# Install from git branch
	sudo -u vagrant git clone "$PROJECT_REPOSITORY" "$PROJECT_BUILD"
	cd "$PROJECT_BUILD"; sudo -u vagrant git fetch --all; git reset --hard; git checkout "$PROJECT_SOURCE" --force;
fi

# Composer install
sudo -u vagrant composer install -d "$PROJECT_BUILD" --no-progress

# Rsync directory
if [ $PROJECT_BUILD != $PROJECT_PATH ]; then
rsync -a --remove-source-files "$PROJECT_BUILD"/ "$PROJECT_PATH"/ || true
fi

# Apply basic rights on regular mount
if [ $PROJECT_NFS != "true" ] || [ $PROJECT_MOUNT == "app" ]; then
	chown -fR "$PROJECT_SETUP_OWNER":www-data "$PROJECT_PATH"
fi

# Run install
sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento setup:uninstall -n -q
sudo -u "$PROJECT_SETUP_OWNER" "$PROJECT_PATH"/bin/magento setup:install \
--base-url="http://${PROJECT_URL}/" \
--base-url-secure="https://${PROJECT_URL}/" \
--db-host="localhost"  \
--db-name="${PROJECT_NAME}" \
--db-user="vagrant" \
--db-password="vagrant" \
--admin-firstname="admin" \
--admin-lastname="admin" \
--admin-email="${PROJECT_USER_EMAIL}" \
--admin-user="admin" \
--admin-password="admin123" \
--language="${PROJECT_LANGUAGE}" \
--currency="${PROJECT_CURRENCY}" \
--timezone="${PROJECT_TIME_ZONE}" \
--use-rewrites="1" \
--backend-frontname="admin"
