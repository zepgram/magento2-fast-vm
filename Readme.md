# NFS Vagrant - Magento2

## Requirements

### Virtualbox
[VirtualBox](https://www.virtualbox.org/) is an open source virtualizer, an application that can run an entire operating system within its own virtual machine.<br>
Stable version >= 5.1.10

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
Stable version >= 1.9.5

1. Download the installer for your laptop operating system using the links below.
    * [Vagrant download](https://www.vagrantup.com/downloads.html)
1. Reboot your laptop if prompted to do so when installation completes.

### WFM
There is a major issue with windows 7 host machine:<br>
When running vagrant up machine hangs, this problem is encountered with newest version of VirtualBox and Vagrant.<br>
- First solution is to upgrade powershell to version 4.0 by downloading [WFM 4.0](https://www.microsoft.com/fr-fr/download/details.aspx?id=40855).
  <br>The file setup is Windows6.1-KB2819745<br>
- Second solution is to downgrade to 1.9.5 for vagrant and 5.1.10 for VirtualBox<br>
You can found more about this issue on [github](https://github.com/hashicorp/vagrant/issues/8783).<br>

## Installation
&#9888; DO NOT USE SSH KEY WITH PASSPHRASE, this vagrant installation is non-interactive.<br>
If your ssh key has been created with a passphrase, please create an other one and add it to your git account.

### First installation
1. Clone this project: ``git clone git@github.com:zepgram/magento2-fast-vm.git magento2``
1. On linux only, run: ``sudo apt install nfs-kernel-server``
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
   * nfs: enable NFS mount (true)
   * mount:
      * 'app' mount app directory /var/www/magento/app (drastically improve performance, making nfs option not necessary)
      * 'root' mount whole directory /var/www/magento (require nfs option to keep good performance)
   * provision: define shell provisionning sequence (all)
      * 'all' run all provisionner files
      * 'system' run only machine provisionner
      * 'magento' run magento installation
* Credentials
   * git_host: url of git host server to add ssh key to known hosts on guest machine, used only on git source installation (github.com)
   * git_repository: repository to get magento-cloud version from magento/v2/source project, used only on git source installation (ssh://git@github.com:project-name.git)
   * composer_username: [magento access](https://marketplace.magento.com/customer/accessKeys/) to download project with composer (magentoUsernameKey)
   * composer_password: [magento access](https://marketplace.magento.com/customer/accessKeys/) to download project with composer (magentoPasswordKey)
   * name: your username for git configuration (Benjamin Calef)
   * email: your email for git configuration (contact@ivc-digital.com)
* Magento
   * url: magento site host name (dev.magento.com)
   <br>FI [do not use .dev or .localhost as extension](https://ma.ttias.be/chrome-force-dev-domains-https-via-preloaded-hsts/)
    * source: define installation source (composer)
      * 'composer' install version magento source from official composer repository
      * 'git-branch-name' install magento project from your git repository based on defined branch
   * edition: magento project edition, used only on composer source installation (community)
      * 'community' install magento community edition
      * 'enterprise' install magento enterprise edition
   * version: define magento version, used only on composer source installation (2.2.5)
   * sample: install sample data, used only on composer source installation (true)
   * mode: magento mode (developer)
   * currency: set currency (USD)
   * language: set language (en_US)
   * time_zone: set time zone (Europe/London)

### Mount
* <b>app directory:</b> magento2 development must be provided in app directory, so mounting the entire project is not necessary according to documentation and best practice provided by magento. Furthermore, by mounting only this directory the virtual machine grants great performance: generated files and static content are not shared between guest and host machine.
* <b>root directory:</b> if you wish to mount the entire project you can, but I highly recommend you to enable NFS option to improve performance between guest and host machine.

### NFS
NFS mount option can be a problem when you reach the point to make it available for all operating system.<br>
<b>If you experience any trouble during installation, you can disable NFS option in config.yaml</b><br>
* Operating system tested with NFS option:
  * Windows 7
  * Windows 10
  * Mac Sierra
  * Mac OS X
  * Ubuntu 14.04
  * Ubuntu 16.04
  * Ubuntu 17.04
  * Ubuntu 18.04
 
## Usage

### Permission
Magento file system owner is configured for ``magento`` user, it means all commands in magento project must be executed by this user.<br>
Command line ``vagrant ssh`` will log you as magento user by default.<br>
* To logout and get back to vagrant user you can run ``exit``
* To login as magento user you can run ``sudo su magento`` or ``bash``
* To re-apply magento permission you can run ``permission`` in command line
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

## Issue
- If you have trouble during installation please open a new issue on this git repository.
- In case of error with NFS mount [downgrade to version 1.9.5](https://releases.hashicorp.com/vagrant/1.9.5/). Problem is known and reported by vagrant community: https://github.com/hashicorp/vagrant/issues/5424
- If you encountered an unexpected error during vagrant provisionning. Don't forget to set NFS option to <b>false</b> and run ``vagrant provision``