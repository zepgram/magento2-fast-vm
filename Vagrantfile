# ------------------------------------- #
# Fast VM - Magento2                    #
#                                       #
# Author: zepgram                       #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

# Requiered plugins
# -*- mode: ruby -*-
# vi: set ft=ruby :
rootPath = File.dirname(__FILE__)
require 'yaml'
require "#{rootPath}/dependency.rb"

# Load yaml configuration
configValues = YAML.load_file("#{rootPath}/config.yaml")
vmconf       = configValues['vmconf']
composer     = configValues['composer']
git          = configValues['git']
magento      = configValues['magento']
projectName  = 'magento'

# Check plugin
check_plugins ['vagrant-vbguest','vagrant-bindfs','vagrant-rsync-back']
if OS.is_windows
  check_plugins ['vagrant-winnfsd']
end

# Mount directory option
hostDirectory = "./www/#{projectName}"
guestDirectory = "/srv/#{projectName}"
if vmconf['path'] == 'app'
  hostDirectory = "./www/#{projectName}/app"
  guestDirectory = "/srv/#{projectName}/app"
end

# Vagrant configure
Vagrant.configure(2) do |config|
  # Virtual machine
  config.vm.box = 'debian/stretch64'
  
  # Host manager configuration
  config.vm.define vmconf['host_name']
  config.vm.hostname = vmconf['host_name']
  config.vm.network :private_network, type: 'dhcp'
  config.vm.network :private_network, ip: vmconf['network_ip']
  
  # VBox config
  config.vm.provider 'virtualbox' do |v|
    v.name = vmconf['machine_name']
    v.memory = vmconf['memory']
    v.cpus = vmconf['cpus']
    # Share VPN connections
    v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    # Use multiple CPUs in VM
    v.customize ['modifyvm', :id, '--ioapic', 'on']
    # Enable symlink
    v.customize ['setextradata', :id, 'VBoxInternal2/SharedFoldersEnableSymlinksCreate/var/www/', '1']
    # Uncomment option below to avoid issues with VirtualBox on Windows 10
    # v.gui=true
  end

  # Default options
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.bindfs.default_options = {
    force_user:   'magento',
    force_group:  'www-data',
    perms:        'u=rwx:g=rwx:o=r'
  }

  # NFS mount
  if vmconf['mount'] == 'nfs'
    if OS.is_windows
      config.winnfsd.uid = 1
      config.winnfsd.gid = 1
    end
    # Linux NFS specification
    if OS.is_linux
      config.vm.synced_folder hostDirectory, guestDirectory, create: true, :nfs => true, 
      linux__nfs_options: ['rw','no_subtree_check','all_squash','async'], nfs_version: 4, nfs_udp: false
    else
      config.vm.synced_folder hostDirectory, guestDirectory, create: true, :nfs => true
    end
    config.nfs.map_uid = Process.uid
    config.nfs.map_gid = Process.gid
  end
  # Rsync mount
  if vmconf['mount'] == 'rsync'
    config.vm.synced_folder hostDirectory, guestDirectory, create: true, type: 'rsync', 
    rsync__args: ['--archive', '-z', '--copy-links'],
    rsync__exclude: rsync_exclude
  end
  # Default mount
  if vmconf['mount'] != 'rsync' && vmconf['mount'] != 'nfs'
    vmconf['mount'] = 'default';
    config.vm.synced_folder hostDirectory, guestDirectory, create: true
  end

  # Bindfs
  config.bindfs.bind_folder guestDirectory, guestDirectory, after: :provision

  # SSH key provisioning
  config.vm.provision 'file', source: './ssh/id_rsa', destination: '~/.ssh/id_rsa'
  config.vm.provision 'file', source: './ssh/id_rsa.pub', destination: '~/.ssh/id_rsa.pub'

  # Extra provisionner
  process_extra_file(config, 'extra/001-env.sh')
  process_extra_file(config, 'extra/100-pre-build.sh')
  process_extra_file(config, 'extra/120-post-build.sh')

  # Environment provisioning
  config.vm.provision 'shell', path: 'provision/001-system-env.sh', run: 'always', keep_color: true, args: [
    projectName, composer['username'], composer['password'],
    git['name'], git['email'], git['host'], git['repository'],
    magento['url'], magento['php_version'], magento['source'], magento['edition'],
    magento['version'], magento['sample'], magento['mode'], magento['currency'],
    magento['language'], magento['time_zone'], vmconf['mount'], vmconf['path']
  ]

  # Shell provisioning 
  if vmconf['provision'] == 'all'
    config.vm.provision 'shell', path: 'provision/010-system-packages.sh', keep_color: true
    config.vm.provision 'shell', path: 'provision/020-system-services.sh', keep_color: true
    config.vm.provision 'shell', path: 'provision/100-magento-pre.sh', keep_color: true
    config.vm.provision 'shell', path: 'provision/110-magento-app.sh', keep_color: true
    config.vm.provision 'shell', path: 'provision/120-magento-post.sh', keep_color: true
  end
  if vmconf['provision'] == 'system'
    config.vm.provision 'shell', path: 'provision/010-system-packages.sh', keep_color: true
    config.vm.provision 'shell', path: 'provision/020-system-services.sh', keep_color: true
  end
  if vmconf['provision'] == 'magento'
    config.vm.provision 'shell', path: 'provision/100-magento-pre.sh', keep_color: true
    config.vm.provision 'shell', path: 'provision/110-magento-app.sh', keep_color: true
    config.vm.provision 'shell', path: 'provision/120-magento-post.sh', keep_color: true
  end

  # SSH
  config.ssh.forward_agent = true

  # Post up message
  config.vm.post_up_message = 
"
---------------------------------------------------------
Vagrant machine ready to use for #{git['name']}
   magento         #{magento['url']}
   mount           #{vmconf['mount']}
   phpinfo         #{vmconf['network_ip']}/phpinfo
   adminer         #{vmconf['network_ip']}/adminer
   mailcatcher     #{vmconf['network_ip']}:1080
"

  # Triggers
  triggers(config, vmconf['mount'], vmconf['host_name'], hostDirectory)
end
