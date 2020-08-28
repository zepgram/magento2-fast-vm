# Fast Virtual Machine for Magento2

[![vagrant](https://img.shields.io/badge/vagrant-debian:stretch-blue.svg?longCache=true&style=flat&label=vagrant&logo=vagrant)](https://app.vagrantup.com/debian/boxes/stretch64)
[![dev-box](https://img.shields.io/badge/git/composer-blue.svg?longCache=true&style=flat&label=setup&logo=magento)](https://github.com/zepgram/magento2-fast-vm/blob/master/config.yaml.example)
[![mount](https://img.shields.io/badge/nfs/rsync-blue.svg?longCache=true&style=flat&label=mount)](https://github.com/zepgram/magento2-fast-vm/releases)
[![release](https://img.shields.io/badge/release-v1.3.6-blue.svg?longCache=true&style=flat&label=release)](https://github.com/zepgram/magento2-fast-vm/releases)
[![license](https://img.shields.io/badge/license-MIT-blue.svg?longCache=true&style=flat&label=license)](https://github.com/zepgram/magento2-fast-vm/blob/master/LICENSE)

![windows](https://img.shields.io/badge/windows-ok-green.svg?longCache=true&style=flat&label=windows&logo=windows)
![apple](https://img.shields.io/badge/mac-ok-green.svg?longCache=true&style=flat&label=mac&logo=apple)
![linux](https://img.shields.io/badge/linux-ok-green.svg?longCache=true&style=flat&label=linux&logo=linux)

![image](https://user-images.githubusercontent.com/16258478/68086496-0d43e100-fe4d-11e9-95ea-2bce3bee9884.png)&nbsp;&nbsp;&nbsp;&nbsp;![image](https://user-images.githubusercontent.com/16258478/68086436-70814380-fe4c-11e9-8ef4-6e39388cc679.png)&nbsp;&nbsp;&nbsp;&nbsp;![image](https://user-images.githubusercontent.com/16258478/68086442-7545f780-fe4c-11e9-8c5e-518ddba8735d.png)&nbsp;&nbsp;&nbsp;&nbsp;![image](https://user-images.githubusercontent.com/16258478/68086695-ba6b2900-fe4e-11e9-8f4f-68feb9bb0db2.png)&nbsp;&nbsp;&nbsp;&nbsp;![image](https://user-images.githubusercontent.com/16258478/68086427-62cbbe00-fe4c-11e9-83d5-24aec5b7c686.png)

[![associate-developer](https://images.youracclaim.com/size/340x340/images/48e73336-c91d-477f-a66f-3ad950acb597/Adobe_Certified_Professional_Experience_Cloud_products_Digital_Badge.png)](https://www.youracclaim.com/earner/earned/badge/406cc91a-0fda-4a6f-846b-19d7f8b59e0a)

## Requirements

### Virtualbox
[VirtualBox](https://www.virtualbox.org/) is an open source virtualizer, an application that can run an entire operating system within its own virtual machine.<br>
Stable version >= 5.2.0

1. Download the installer for your laptop operating system using the links below.
    * [VirtualBox download](https://www.virtualbox.org/wiki/Downloads)
1. Run the installer, choosing all of the default options.
    * Windows: Grant the installer access every time you receive a security prompt.
    * Mac: Enter your admin password.
    * Linux: Enter your user password if prompted.
1. Reboot your laptop if prompted to do so when installation completes.
1. Close the VirtualBox window if it pops up at the end of the install.

### Vagrant
[Vagrant](https://www.vagrantup.com/) is an open source command line utility for managing reproducible developer environments.<br>
Stable version >= 2.2.0

1. Download the installer for your laptop operating system using the links below.
    * [Vagrant download](https://www.vagrantup.com/downloads.html)
1. Reboot your laptop if prompted to do so when installation completes.

## Configurations

### Related guide
- Made by Onilab for Windows 10:<br>
https://onilab.com/blog/install-magento-2-on-localhost-a-windows-10-guide/

### Pre-installation

&#9888; DO NOT USE SSH KEY WITH PASSPHRASE, this vagrant installation is non-interactive.<br>
If your ssh key has been created with a passphrase, please create an other one.
1. On Windows only: open UEFI BIOS and make sure virtualization is turned 'on'
1. On Windows only: open powershell as administrator and run: ``Add-MpPreference -ExclusionProcess winnfsd.exe``
1. On Windows only: open ``C:\Windows\System32\drivers\etc\hosts`` as administrator then add ``network_ip`` and ``magento_url``<br>Default values would be: ``192.168.200.50       dev.magento.com``
1. On Linux only: in order to install NFS, run ``sudo apt install nfs-kernel-server``
1. On Linux/MacOS only: open ``/etc/hosts`` as sudo then add ``network_ip`` and ``magento_url``<br>Default values would be: ``192.168.200.50       dev.magento.com`` 

### Installation

1. Clone this project: ``git clone git@github.com:zepgram/magento2-fast-vm.git``
1. Copy/past: ``ssh.example`` rename it ``ssh`` then put your ``id_rsa`` and ``id_rsa.pub`` keys
1. Copy/past: ``config.yaml.example`` rename it ``config.yaml``<br>Then customize configurations according to [Yaml config overview](#yaml-config-overview)
1. If you want to import an existing database: create a compressed sql dump and name it ``db-dump.sql.gz``.<br>You must also fill ``crypt_key`` in config.yaml 
1. To start install run: ``vagrant up`` (duration: ~20 minutes)
1. Finally run: ``vagrant ssh`` to access to your guest machine

### Yaml config overview
* Vmconf
   * machine_name: oracle virtual machine name (Vagrant Magento 2)
   * network_ip: virtual machine ip (192.168.200.50)
   * host_name: virtual machine host name (zepgram)
   * memory: RAM of virtual machine (4096)
   * cpus: CPU usage (2)
   * mount: nfs / rsync / default (nfs)
   * path:
      * 'app' mount only app directory /var/www/magento/app
      * 'root' mount whole directory /var/www/magento
   * provision: define shell provisionning sequence (all)
      * 'all' run all provisionner files
      * 'system' run only machine provisionner
      * 'magento' run magento provisionner
* Composer
   * username: [magento access](https://marketplace.magento.com/customer/accessKeys/) set your magento credentials (magentoUsernameKey)
   * password: [magento access](https://marketplace.magento.com/customer/accessKeys/) set your magento credentials (magentoPasswordKey)
* Git (optional)
   * name: git account username (John Doe)
   * email: git account email (john@doe.com)
   * host: set your git host server to add ssh key to "known hosts" (github.com)
   * repository: clone your existing magento project (ssh://git@github.com:project-name.git)
* Magento
   * url: magento site host name (dev.magento.com)
   <br>FI [do not use .dev or .localhost as extension](https://ma.ttias.be/chrome-force-dev-domains-https-via-preloaded-hsts/)
    * source: define installation source (composer)
      * 'composer' install magento source code from official composer repository
      * 'git-branch-name' install magento project from your git repository based on defined branch (ex: master)
   * edition: magento project edition, used only on composer source installation (community)
      * 'community' install magento community edition
      * 'enterprise' install magento enterprise edition
   * version: set magento version and also define PHP version (2.3.3)
   * php_version: override the default required version by yours, for example '7.1' (default)
   * sample: install sample data, used only on composer source installation (true)
   * mode: magento mode (developer)
   * currency: set currency (USD)
   * language: set language (en_US)
   * time_zone: set time zone (Europe/London)
   * crypt_key: crypt key under your app/etc/env.php (only required if db-dump.sql.gz exist)


### Path
* <b>root directory:</b> mount the entire project.
* <b>app directory:</b> mount only app directory. Ensure great performance by not sharing generated files between machines.

### Mount options

#### RSYNC
Only useful on path set to ``root``.<br>
* Loss of performance is due to files generated on the fly, by excluding them you can mount the whole directory ``root`` and get performance equal to an ``app`` mount.
* The ``vagrant rsync-auto`` is launched by default on vagrant up, even with that if you need to force an update you can run ``vagrant rsync``. <b>Terminal should be kept open for rsync-auto: do not close it.</b>
* Rsync is unilateral, your host machine push files to guest but not the other way.<br>
Anyway if it's necessary, after a ``composer update`` for example, you can run ``vagrant rsync-back`` to push files from guest to host.<br>

[See Rsync option](https://www.vagrantup.com/docs/synced-folders/rsync.html)

#### NFS
Recommended for ``root`` and ``app`` path.<br>
The most stable option, config has been made to ensure compliance with all OS.
Less performant than rsync but files are perfectly shared between guest and host machine.

[See NFS option](https://www.vagrantup.com/docs/synced-folders/nfs.html)

#### DEFAULT
It can be used with ``app`` path if you encountered any issue with NFS and rsync mount.

[See basic usage](https://www.vagrantup.com/docs/synced-folders/basic_usage.html)

### Extra provisions
You can add extra shell provisions.<br>
Those provisions will be executed on pre-defined sequences:
1. ``extra/001-env.sh`` his purpose is to provide extra environment variables or extra package, executed after script ``001-system-env.sh``
1. ``extra/100-pre-build.sh`` define your specific system configuration before installation, executed after script ``100-magento-pre.sh``
1. ``extra/120-post-build.sh`` you can execute magento command in this sequence, executed after script ``120-magento-post.sh``

- To be executed you must remove the string `-example` from the filename script.
- As an example of use, you can adapt data from your database import by using the script ``100-pre-build.sh``

## Usage

### Permission
Magento file system owner is configured for ``vagrant`` user, it means all commands in magento project must be executed by this user.<br>
By default command line ``vagrant ssh`` will log you as vagrant user.<br>
* To re-apply magento permission you can run ``permission`` in command line: this is only applicable for ``app`` path or ``default`` mount configurations.

### Command line
* magento (Magento CLI for your project)
* magento-cloud (CLI provided for Magento Cloud)
* pestle (A collection of command line scripts for Magento 2 code generation)
* magerun (The swiss army knife for Magento developers)
* permission (Apply magento2 permissions on project)

### Cron   
Enable cron:
```
./bin/magento cron:install
```

Disable cron:
```
./bin/magento cron:remove
```

### Elasticsearch
Version 7.6.x of Elasticsearch is available for Magento.<br>
If your Magento version is lower than 2.4 then version 6.x will be installed.<br>
For version lower than 2.4, you can disable it and fall back to mysql:
```
./bin/magento config:set catalog/search/engine mysql
```

## Configuration

### Package & Software
- php + required extensions
- curl
- git
- gitflow
- vim
- composer
- nginx
- php-fpm
- percona
- redis-server
- elasticsearch
- grunt
- postfix
- mailcatcher
- pestle
- magereun
- adminer
- magento-cloud cli
- bin/magento bash completion

### Credentials
* User bash terminal
  * user: vagrant
* Back-office
  * url: magento[url]/admin 
  * user: magento.admin
  * pass: admin123
* Database
  * user: vagrant
  * pass: vagrant
  * name: magento
* Mailcatcher
  * url: [network_ip]:1080
* Adminer
  * url: [network_ip]/adminer
* Phpinfo
  * url: [network_ip]/php

## Issues

### Windows 10
There is a known [issue with composer installation](https://github.com/zepgram/magento2-fast-vm/issues/70) on windows 10.<br>
This issue could not be solved yet, and has already been reported 2 times.<br> 
- It's related to the computer and BIOS configuration.
- It's only with "nfs" setting for mount option.

To solve this, just try to set mount option to "rsync", then after full installation you should be able to fallback to NFS.

### Others
- If you have trouble during installation please open a new issue on this git repository.
