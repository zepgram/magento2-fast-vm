# Fast Virtual Machine for Magento2

[![vagrant](https://img.shields.io/badge/vagrant-debian:stretch-blue.svg?longCache=true&style=flat&label=vagrant&logo=vagrant)](https://app.vagrantup.com/debian/boxes/stretch64)
[![dev-box](https://img.shields.io/badge/source-git--composer-blue.svg?longCache=true&style=flat&label=magento2%20&logo=magento)](https://github.com/zepgram/magento2-fast-vm/blob/master/config.yaml.example)
[![license](https://img.shields.io/badge/license-MIT-blue.svg?longCache=true&style=flat&label=license)](https://github.com/zepgram/magento2-fast-vm/blob/master/LICENSE)
[![release](https://img.shields.io/badge/release-v1.2-blue.svg?longCache=true&style=flat&label=release)](https://github.com/zepgram/magento2-fast-vm/releases)

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
&#9888; DO NOT USE SSH KEY WITH PASSPHRASE, this vagrant installation is non-interactive.<br>
If your ssh key has been created with a passphrase, please create an other one and add it to your git account.

### First installation
1. Clone this project: ``git clone git@github.com:zepgram/magento2-fast-vm.git magento2``
1. On linux only, run: ``sudo apt install nfs-kernel-server`` if you wish to use NFS option.
1. Copy and past ``ssh.example``, rename it ``ssh`` and put your id_rsa and id_rsa.pub keys.
1. Copy and past ``config.yaml.example``, rename it ``config.yaml`` and change user variables as explained in [Yaml options overview](#yaml-options-overview).
1. Add vm_conf[network_ip] and magento[url] in your hosts file. Add 127.0.0.1 localhost if it's not already the case ``C:\Windows\System32\drivers\etc\hosts`` on Windows, ``/etc/hosts`` on Linux/macOS.<br>
For default values: ``192.168.200.50       dev.magento.com``
1. On windows 10 start your terminal as administrator and uncomment option ``# v.gui=true`` in vagrant file, you can disable it after first installation
1. Run: ``vagrant up`` in your terminal, installation start! (duration: ~20 minutes)
1. Once installation is finished run: ``vagrant ssh`` to access to shell machine

### Extra provisionners
You can add your custom shell provisioners which will be executed on pre-defined sequences:
1. ``extra/001-env.sh`` his purpose is to provide extra environment variables or extra package, executed on ``system-env.sh`` provision
1. ``extra/100-pre-build.sh`` define your specific system configuration before installation, hook on magento ``pre-build.sh`` provision
1. ``extra/120-post-build.sh`` you can execute magento command in this sequence, executed on magento ``post-build.sh`` provision

### Yaml options overview
* Vmconf
   * machine_name: oracle virtual machine name (Vagrant Magento 2)
   * network_ip: virtual machine ip (192.168.200.50)
   * host_name: virtual machine host name (zepgram)
   * memory: RAM of virtual machine (4096)
   * cpus: CPU usage (2)
   * mount: nfs / rsync / default (nfs)
   * path:
      * 'app' mount app directory /var/www/magento/app (drastically improve performance but you cannot access to root directory from host machine)
      * 'root' mount whole directory /var/www/magento (require nfs or rsync option to keep good performance)
   * provision: define shell provisionning sequence (all)
      * 'all' run all provisionner files
      * 'system' run only machine provisionner
      * 'magento' run magento installation
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
   * version: set magento version and also define PHP version (2.3.0)
   * sample: install sample data, used only on composer source installation (true)
   * mode: magento mode (developer)
   * currency: set currency (USD)
   * language: set language (en_US)
   * time_zone: set time zone (Europe/London)

## Mount options

### Rsync - new (v1.2.0)
The most efficient mount option, recommended if your mount path is ``root``.<br>
* The drawback is about files who are not instantly updated between host and guest machine:<br>
Even if ``vagrant rsync-auto`` is launched by default, if you need to force an update run ``vagrant rsync``
* Generated files are not shared between host and guest machine resulting in drastic increase of vagrant performance
* Folders ignored: ``generated/code/*``, ``var/page_cache/*``, ``var/view_preprocessed/*``, ``pub/static/*``
[See Rsync option](https://www.vagrantup.com/docs/synced-folders/rsync.html)

### Nfs
Recommended if your mount path is ``root`` or ``app`` directory.
[See NFS option](https://www.vagrantup.com/docs/synced-folders/nfs.html)

### Default
Recommended if your mount path is ``app`` directory.
[See basic usage](https://www.vagrantup.com/docs/synced-folders/basic_usage.html)

### Path
* <b>app directory:</b> magento2 development must be provided in app directory, so mounting the entire project is not necessary according to documentation and best practice provided by magento. Furthermore, by mounting only this directory the virtual machine grants great performance: generated files and static content are not shared between guest and host machine.
* <b>root directory:</b> if you wish to mount the entire project you can, but I highly recommend you to enable NFS or RSYNC option to improve performance between guest and host machine.

## Usage

### Permission
Magento file system owner is configured for ``magento`` user, it means all commands in magento project must be executed by this user.<br>
Command line ``vagrant ssh`` will log you as magento user by default.<br>
* To logout and get back to vagrant user you can run ``exit``
* To login as magento user you can run ``sudo su magento`` or ``bash``
* To re-apply magento permission you can run ``permission`` in command line, only used for ``app`` mount directory
<b>Password for magento user is ``magento``</b>

### Command line
* magento (Magento CLI for your project)
* magento-cloud (Cloud-specific version of the Magento CLI)
* pestle (A collection of command line scripts for Magento 2 code generation)
* magerun (The swiss army knife for Magento developers)
* permission (Apply magento2 permissions on project)

### Magento mode
After installation you can change magento statement.<br>
Default mode is an installation statement, you can't switch to default mode if you choose a statement before.

Set magento to developer mode:
```
./bin/magento deploy:mode:set developer
```

Set magento to production mode:
```
./bin/magento deploy:mode:set production
```

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
- php + requiered extensions
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

### PhpStorm
To setup phpStorm configuration you can follow magento2 [official documentation](http://devdocs.magento.com/guides/v2.1/install-gde/docker/docker-phpstorm-project.html).

## Issues

### WFM
There is a major issue with windows 7 host machine:<br>
When running vagrant up machine hangs, this problem is encountered with newest version of VirtualBox and Vagrant.<br>
- Solution is to upgrade powershell to version 4.0 by downloading [WFM 4.0](https://www.microsoft.com/fr-fr/download/details.aspx?id=40855).
<br>The file setup is Windows6.1-KB2819745<br>

### Others
- If you have trouble during installation please open a new issue on this git repository.
