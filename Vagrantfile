# ------------------------------------- #
# NFS Vagrant - Magento2                #
#                                       #
# Author: zpgram                        #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

# Requiered plugins
# -*- mode: ruby -*-
# vi: set ft=ruby :
rootPath = File.dirname(__FILE__)
require "yaml"
require "#{rootPath}/dependency.rb"

# Check plugin
check_plugins ["vagrant-vbguest","vagrant-bindfs"]
if OS.is_windows
  check_plugins ["vagrant-vbguest","vagrant-bindfs","vagrant-winnfsd"]
end

# Load yaml configuration
configValues = YAML.load_file("#{rootPath}/config.yaml")
vmconf       = configValues['vmconf']
credentials  = configValues['credentials']
magento      = configValues['magento']
projectName  = 'magento'

# Mount directory option
hostDirectory = "./www/#{projectName}/app"
guestDirectory = "/var/www/#{projectName}/app"
if vmconf['mount'] == 'root'
  hostDirectory = "./www/#{projectName}"
  guestDirectory = "/var/www/#{projectName}"
end

# Vagrant configure
Vagrant.configure(2) do |config|
  # Virtual machine
  config.vm.box = "debian/stretch64"
  
  # Host manager configuration
  config.vm.define vmconf['host_name']
  config.vm.hostname = vmconf['host_name']
  config.vm.network :private_network, type: "dhcp"
  config.vm.network :private_network, ip: vmconf['network_ip']
  
  # VBox config
  config.vm.provider "virtualbox" do |v|
    v.name = vmconf['machine_name']
    v.memory = vmconf['memory']
    v.cpus = vmconf['cpus']
    # Share VPN connections
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    # Use multiple CPUs in VM
    v.customize ["modifyvm", :id, "--ioapic", "on"]
    # Enable symlink
    v.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/var/www/", "1"]
    # Uncomment option below to avoid issues with VirtualBox on Windows 10
    # v.gui=true
  end

  # Sync
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.bindfs.default_options = {
    force_user:   'magento',
    force_group:  'www-data',
    perms:        'u=rwx:g=rwx:o=r'
  }
  if vmconf['nfs'] == "true"
    # Windows NFS specification
    if OS.is_windows
      config.winnfsd.uid = 1
      config.winnfsd.gid = 1
    end
    if OS.is_linux
      # Linux NFS specification
      config.vm.synced_folder hostDirectory, guestDirectory, create: true, :nfs => true, 
      linux__nfs_options: ['rw','no_subtree_check','all_squash','async'], nfs_version: 3
    else
      config.vm.synced_folder hostDirectory, guestDirectory, create: true, :nfs => true
    end
      config.bindfs.bind_folder guestDirectory, guestDirectory, after: :provision
      config.nfs.map_uid = Process.uid
      config.nfs.map_gid = Process.gid
  else
    # Regular mount
    config.vm.synced_folder hostDirectory, guestDirectory, create: true
    config.bindfs.bind_folder guestDirectory, guestDirectory, after: :provision
  end

  # SSH key provisioning
  config.vm.provision "file", source: "./ssh/id_rsa", destination: "~/.ssh/id_rsa"
  config.vm.provision "file", source: "./ssh/id_rsa.pub", destination: "~/.ssh/id_rsa.pub"

  # Extra provisionner
  if File.file?("./extra/001-env.sh")
    config.vm.provision "file", source: "./extra/001-env.sh", destination: "/home/vagrant/provision/001-env.sh", run: "always"
  end
  if File.file?("./extra/100-pre-build.sh")
    config.vm.provision "file", source: "./extra/100-pre-build.sh", destination: "/home/vagrant/provision/100-pre-build.sh", run: "always"
  end
  if File.file?("./extra/120-post-build.sh")
    config.vm.provision "file", source: "./extra/120-post-build.sh", destination: "/home/vagrant/provision/120-post-build.sh", run: "always"
  end
  
  # Environment provisioning
  config.vm.provision "shell", path: "provision/001-system-env.sh", run: "always", keep_color: true, args: [
    credentials['git_host'], credentials['git_repository'], credentials['composer_username'], 
    credentials['composer_password'], credentials['name'], credentials['email'], 
    projectName, magento['url'], magento['source'], magento['edition'], magento['version'], 
    magento['sample'], magento['mode'], magento['currency'], magento['language'],
    magento['time_zone']
  ]

  # Shell provisioning 
  if vmconf['provision'] == "all"
    config.vm.provision "shell", path: "provision/010-system-packages.sh", keep_color: true
    config.vm.provision "shell", path: "provision/020-system-services.sh", keep_color: true
    config.vm.provision "shell", path: "provision/100-magento-pre.sh", keep_color: true
    config.vm.provision "shell", path: "provision/110-magento-app.sh", keep_color: true
    config.vm.provision "shell", path: "provision/120-magento-post.sh", keep_color: true
  end
  if vmconf['provision'] == "system"
    config.vm.provision "shell", path: "provision/010-system-packages.sh", keep_color: true
    config.vm.provision "shell", path: "provision/020-system-services.sh", keep_color: true
  end
  if vmconf['provision'] == "magento"
    config.vm.provision "shell", path: "provision/100-magento-pre.sh", keep_color: true
    config.vm.provision "shell", path: "provision/110-magento-app.sh", keep_color: true
    config.vm.provision "shell", path: "provision/120-magento-post.sh", keep_color: true
  end

  # SSH
  config.ssh.forward_agent = true

  # Post up message
  config.vm.post_up_message = 
"
---------------------------------------------------------
Vagrant machine ready to use for #{credentials['name']}

   magento         #{magento['url']}
   phpinfo         #{vmconf['network_ip']}/phpinfo
   adminer         #{vmconf['network_ip']}/adminer
   mailcatcher     #{vmconf['network_ip']}:1080

"
end
