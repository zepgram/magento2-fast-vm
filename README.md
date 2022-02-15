# Fast Virtual Machine for Magento2

[![vagrant](https://img.shields.io/badge/vagrant-debian:stretch-blue.svg?longCache=true&style=flat&label=vagrant&logo=vagrant)](https://app.vagrantup.com/debian/boxes/stretch64)
[![dev-box](https://img.shields.io/badge/git/composer-blue.svg?longCache=true&style=flat&label=setup&logo=magento)](https://github.com/zepgram/magento2-fast-vm/blob/master/config.yaml.example)
[![mount](https://img.shields.io/badge/nfs/rsync-blue.svg?longCache=true&style=flat&label=mount)](https://github.com/zepgram/magento2-fast-vm/releases)
[![release](https://img.shields.io/badge/release-v1.4.2-blue.svg?longCache=true&style=flat&label=release)](https://github.com/zepgram/magento2-fast-vm/releases)
[![license](https://img.shields.io/badge/license-MIT-blue.svg?longCache=true&style=flat&label=license)](https://github.com/zepgram/magento2-fast-vm/blob/master/LICENSE)

![windows](https://img.shields.io/badge/windows-ok-green.svg?longCache=true&style=flat&label=windows&logo=windows)
![apple](https://img.shields.io/badge/mac-ok-green.svg?longCache=true&style=flat&label=mac&logo=apple)
![linux](https://img.shields.io/badge/linux-ok-green.svg?longCache=true&style=flat&label=linux&logo=linux)

![image](https://user-images.githubusercontent.com/16258478/68086496-0d43e100-fe4d-11e9-95ea-2bce3bee9884.png)&nbsp;&nbsp;&nbsp;&nbsp;![image](https://user-images.githubusercontent.com/16258478/68086436-70814380-fe4c-11e9-8ef4-6e39388cc679.png)&nbsp;&nbsp;&nbsp;&nbsp;![image](https://user-images.githubusercontent.com/16258478/68086442-7545f780-fe4c-11e9-8c5e-518ddba8735d.png)&nbsp;&nbsp;&nbsp;&nbsp;![image](https://user-images.githubusercontent.com/16258478/68086695-ba6b2900-fe4e-11e9-8f4f-68feb9bb0db2.png)&nbsp;&nbsp;&nbsp;&nbsp;![image](https://user-images.githubusercontent.com/16258478/68086427-62cbbe00-fe4c-11e9-83d5-24aec5b7c686.png)

[![associate-developer](https://user-images.githubusercontent.com/16258478/121844932-02b62280-cce5-11eb-8351-726bbe9eed80.png)](https://www.youracclaim.com/badges/406cc91a-0fda-4a6f-846b-19d7f8b59e0a/public_url)

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
1. On MacOS only: to avoid issue with guest additions, run ``sudo apt install linux-headers-$(uname -r)``
1. On Linux/MacOS only: open ``/etc/hosts`` as sudo then add ``network_ip`` and ``magento_url``<br>Default values would be: ``192.168.200.50       dev.magento.com`` 

### Installation

1. Clone this project: ``git clone git@github.com:zepgram/magento2-fast-vm.git``
1. Copy/past: ``ssh.example`` rename it ``ssh`` then put your ``id_rsa`` and ``id_rsa.pub`` keys
1. Copy/past: ``config.yaml.example`` rename it ``config.yaml``<br>Then customize configurations according to [Yaml config overview](#yaml-config-overview)
1. If you want to import an existing database: create a compressed sql dump and name it ``db-dump.sql.gz``.<br>You must also fill ``crypt_key`` in config.yaml 
1. To start install run: ``vagrant up`` (duration: ~20 minutes)
1. Finally run: ``vagrant ssh`` to access to your guest machine

### Yaml config overview
Parent Node  |  Name  |  Default Value  |  Allowed Value  |  Is optional  |  Description
| --- | --- | --- | --- | --- |---
| vmconf |  machine_name |  Vagrant Magento 2 | string | no | Vagrant machine name
| |  network_ip |  192.168.200.50 | IP address |  no  | Accessible IP address /etc/hosts
| |  host_name |  zepgram | string |  no |  Virtual host name
| |  memory |  4096  |  number  |  no |  RAM allocated
| |  cpus |  1 |  number  |  no |  CPU allocated
| |  mount |  nfs | nfs / rsync / default |  no |  Mount strategy
| |  path |  root | app / root |  no |  Mount whole directory or `app/` only
| |  provision |  all | all / system / magento | no |  Define script provision
| composer |  username |  magentoUsernameKey | string |  no |  <a href="https://marketplace.magento.com/customer/accessKeys/" target="_blank">Composer auth user</a>
| |  password |  magentoPasswordKey | string |  no |  <a href="https://marketplace.magento.com/customer/accessKeys/" target="_blank">Composer auth password</a>
| git |  name |  John Doe | string |  yes |  Git user name
| |  email |  john@doe.com | email |  yes |  Git user email
| |  host |  github.com | url |  yes  |  Git host server name
| |  repository |  ssh://git@github.com:%.git | git repository |  yes  | Define repository to clone
| magento |  url |  dev.magento.com  | url |  no |  Magento site host name
| |  source |  composer | composer / (master/develop..) |  no |  Define source installation. On git install set the branch name to clone.
| |  edition |  community | community / enterprise |  no |  Magento project edition
| |  version |  2.4.2 |  >=2.2 |  no |  Magento version release
| |  php_version |  default | default / 7.x |  no |  PHP version
| |  sample |  true | true / false |  no |  Install sample data
| |  mode |  developer | developer / production |  no |  Magento execution mode
| |  currency |  USD | <a href="https://en.wikipedia.org/wiki/ISO_4217#Active_codes" target="_blank">ISO 4217</a> |  no |  Default currency
| |  language |  en_US |  <a href="https://www.iso.org/iso-639-language-codes.html" target="_blank">ISO 639-1</a> + <a href="https://www.iso.org/iso-3166-country-codes.html" target="_blank">ISO 3166</a> |  no |  Default language
| |  time_zone | America/New_York | <a href="https://www.php.net/manual/en/timezones.php" target="_blank">timezone</a> |  no |  Default timezone
| |  crypt_key |  -  | string |  yes |  Crypt key form app/etc/env.php for db-dump.sql.gz (db import)

### Path
* <b>root directory:</b> mount the entire project.
* <b>app directory:</b> mount only app directory. Not sharing generated files between machines ensure great performance but in return, source code /vendor is missing.

### Mount options

#### RSYNC
Only useful on path set to ``root``.<br>
* Loss of performance is due to files generated on the fly, by excluding them you can mount the whole directory ``root`` and get performance equal to an ``app`` mount.
* The ``vagrant rsync-auto`` is launched by default on vagrant up, even with that if you need to force an update you can run ``vagrant rsync``. <b>Terminal should be kept open for rsync-auto: do not close it.</b>
* Rsync is unilateral, your host machine push files to guest but not the other way.<br>
Anyway if it's necessary, after a ``composer update`` for example, you can run ``vagrant rsync-back`` to push files from guest to host.<br>
* After first installation, you must run ``vagrant reload`` to enable file watching with rsync-auto.<br>
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
* To re-apply magento permissions you can run ``permission`` directly in command line.

### Command line
* magento (Magento CLI alias)
* magento-cloud (Magento Cloud CLI)
* pestle (A collection of command line scripts for code generation)
* magerun (The swiss army knife for Magento developers)
* permission (Re-apply permissions to project)

### Cron
Enable cron:
```
./bin/magento cron:install
```

Disable cron:
```
./bin/magento cron:remove
```

### Mysql
Percona server 8.0 is installed for version >= 2.4.0

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
- If you have trouble during installation please open a new issue on this repository.
