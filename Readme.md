# Fast Virtual Machine for Magento2

[![vagrant](https://img.shields.io/badge/vagrant-debian:stretch-blue.svg?longCache=true&style=flat&label=vagrant&logo=vagrant)](https://app.vagrantup.com/debian/boxes/stretch64)
[![dev-box](https://img.shields.io/badge/git/composer-blue.svg?longCache=true&style=flat&label=setup&logo=magento)](https://github.com/zepgram/magento2-fast-vm/blob/master/config.yaml.example)
[![mount](https://img.shields.io/badge/nfs/rsync-blue.svg?longCache=true&style=flat&label=mount)](https://github.com/zepgram/magento2-fast-vm/releases)
[![release](https://img.shields.io/badge/release-v1.2.0-blue.svg?longCache=true&style=flat&label=release)](https://github.com/zepgram/magento2-fast-vm/releases)
[![license](https://img.shields.io/badge/license-MIT-blue.svg?longCache=true&style=flat&label=license)](https://github.com/zepgram/magento2-fast-vm/blob/master/LICENSE)

![windows](https://img.shields.io/badge/windows-ok-green.svg?longCache=true&style=flat&label=windows&logo=windows)
![apple](https://img.shields.io/badge/mac-ok-green.svg?longCache=true&style=flat&label=mac&logo=apple)
![linux](https://img.shields.io/badge/linux-ok-green.svg?longCache=true&style=flat&label=linux&logo=linux)

[![associate-developer](https://u.magento.com/media/catalog/product/cache/17/small_image/92x165/9df78eab33525d08d6e5fb8d27136e95/a/s/assoc_dev-l.png)](https://u.magento.com/certification/directory/dev/2504796/)

## Requirements

### Virtualbox
[VirtualBox](https://www.virtualbox.org/) is an open source virtualizer, an application that can run an entire operating system within its own virtual machine.<br>
Stable version >= 5.2.0

1. Download the installer for your laptop operating system using the links below.
    * [VirtualBox download](https://www.virtualbox.org/wiki/Downloads)
1. Run the installer, choosing all of the default options.
    * Windows: Grant the installer access every time you receive a security prompt.
    * Mac: Enter your admin password.
    * Linux: Enter your root password if prompted.
1. Reboot your laptop if prompted to do so when installation completes.
1. Close the VirtualBox window if it pops up at the end of the install.

### Vagrant
[Vagrant](https://www.vagrantup.com/) is an open source command line utility for managing reproducible developer environments.<br>
Stable version >= 2.2.0

1. Download the installer for your laptop operating system using the links below.
    * [Vagrant download](https://www.vagrantup.com/downloads.html)
1. Reboot your laptop if prompted to do so when installation completes.

## Installation

### Related guide
- Made by Onilab for Windows 10:
https://onilab.com/blog/install-magento-2-on-localhost-a-windows-10-guide/

### First installation

&#9888; DO NOT USE SSH KEY WITH PASSPHRASE, this vagrant installation is non-interactive.<br>
If your ssh key has been created with a passphrase, please create an other one and add it to your git account.
1. Clone this project: ``git clone git@github.com:zepgram/magento2-fast-vm.git``
1. On linux only in order to install NFS, run: ``sudo apt install nfs-kernel-server``
1. On windows only, make sur virtualization is turned 'on' in UEFI BIOS
1. Copy and past ``ssh.example``, rename it ``ssh`` and put your ``id_rsa`` and ``id_rsa.pub`` keys
1. Copy and past ``config.yaml.example``, rename it ``config.yaml`` and add your configurations according to [Yaml config overview](#yaml-config-overview)
1. As admin open your host file: ``C:\Windows\System32\drivers\etc\hosts`` for Windows or ``/etc/hosts``for Linux/macOS and add vm_conf[network_ip] and magento[url]<br>
Default values would be: ``192.168.200.50       dev.magento.com``
1. On windows 10 start your terminal as administrator and uncomment option ``# v.gui=true`` in VagrantFile. You can disable it after first setup
1. Run: ``vagrant up`` in your terminal: setup start! (duration: ~20 minutes)
1. Once installation is done run: ``vagrant ssh`` to access to your guest machine

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
   * version: set magento version and also define PHP version (2.3.*)
   * php_version: override the default required version by yours, for example '7.1' (default)
   * sample: install sample data, used only on composer source installation (true)
   * mode: magento mode (developer)
   * currency: set currency (USD)
   * language: set language (en_US)
   * time_zone: set time zone (Europe/London)


### Path
* <b>root directory:</b> mount the entire project.
* <b>app directory:</b> mount only app directory. Ensure great performance by not sharing generated files between machines.

### Mount options

#### RSYNC - new (v1.2.0)
Only usefull on path set to ``root``.<br>
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
You can add your custom shell provisions.<br>
For example in order to [import your database from existing project](https://github.com/zepgram/magento2-fast-vm/wiki/Setup-with-database-from-an-existing-project).<br>
Those provisions will be executed on pre-defined sequences:
1. ``extra/001-env.sh`` his purpose is to provide extra environment variables or extra package, executed on ``system-env.sh`` provision
1. ``extra/100-pre-build.sh`` define your specific system configuration before installation, hook on magento ``pre-build.sh`` provision
1. ``extra/120-post-build.sh`` you can execute magento command in this sequence, executed on magento ``post-build.sh`` provision

## Usage

### Permission
Magento file system owner is configured for ``magento`` user, it means all commands in magento project must be executed by this user.<br>
By default command line ``vagrant ssh`` will log you as magento user.<br>
* To logout and get back to vagrant user you can run ``exit``
* To login as magento user you can run ``sudo su magento`` or ``bash``
* To re-apply magento permission you can run ``permission`` in command line, used only for ``app`` path and ``default`` mount.

<b>FI: Password for magento user is ``magento``</b>

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

## Configuration

### Package & Software
- php + required extensions
- curl
- git
- gitflow
- vim
- mariadb
- apache2
- redis-server
- composer
- magento-cloud CLI
- magento bash completion
- pestle
- magereun
- adminer
- grunt
- postfix
- mailcatcher

### Credentials
* User bash terminal
  * user: magento
  * password: magento 
* Back-office
  * url: magento[url]/admin 
  * user: admin
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

### WFM
There is a major issue with windows 7 host machine:<br>
When running vagrant up machine hangs, this problem is encountered with newest version of VirtualBox and Vagrant.<br>
- Solution is to upgrade powershell to version 4.0 by downloading [WFM 4.0](https://www.microsoft.com/fr-fr/download/details.aspx?id=40855).
<br>The file setup is Windows6.1-KB2819745<br>

### Others
- If you have trouble during installation please open a new issue on this git repository.
