# ------------------------------------- #
# Fast VM - Magento2                    #
#                                       #
# Author: zepgram                       #
# Git: https://github.com/zepgram/      #
# ------------------------------------- #

require 'getoptlong'

## Get OS
module OS
    def OS.is_windows
        (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end
    def OS.is_mac
        (/darwin/ =~ RUBY_PLATFORM) != nil
    end
    def OS.is_linux
      !OS.is_windows and not OS.is_mac
    end
end

## Check install plugins
def check_plugins(dependencies)
	skip_dependency_manager = false

    ARGV.each_with_index do |value, index|
        case value
            when '--skip-dependency-manager'
                skip_dependency_manager = true
        end
    end

	if ['up', 'reload'].include?(ARGV[0]) && !skip_dependency_manager
		installed_dependencies = []

		puts "\033[0m" << "Checking dependencies..." << "\e[0m"

		raw_output = `vagrant plugin list`
		raw_list = raw_output.split("\n")

		raw_list.each do |plugin| 
			if plugin.index("\e[0m") != nil
				first = plugin.index("\e[0m")  + 4
			else
				first = 0
			end
			installed_dependencies.push plugin.slice((first)..(plugin.index("(").to_i-1)).strip
		end

		dependencies_already_satisfied = true

		dependencies.each_with_index do |dependency, index|
			if not installed_dependencies.include? dependency
				dependencies_already_satisfied = false
				puts "\033[0m" << " - Missing '#{dependency}'!" << "\e[0m"
				if not system "vagrant plugin install #{dependency}"
					puts "\n\033[0m" << " - Could not install plugin '#{dependency}'. " << "\e[0m\033[41m" <<"Stopped." << "\e[0m"
					exit -1
				end
			end
		end

		if dependencies_already_satisfied
			puts "\033[0m" << " - All dependencies are satisfied" << "\e[0m"
		else
			puts "\033[0m" << " - Dependencies installed" << "\e[0m"
			exec "vagrant " << "--skip-dependency-manager " << ARGV.join(" ")
			exit
		end
	end

	if ARGV.include?('--skip-dependency-manager')
		ARGV.delete_at(ARGV.index('--skip-dependency-manager'))
	end

end

## Force LF
def process_extra_file(config, file)
  if File.file?(file)
  	read = IO.read(file)
  	replace = read.gsub /\r\n?/, "\n"
  	newFile = File.open(file, 'w')
  	newFile.write(replace)
  	config.vm.provision 'file', source: file, destination: '/home/vagrant/' + file, run: 'always'
  end
end

## Define rsync exluded directories
def rsync_exclude
  return [
  	'generated/code/*', 'var/page_cache/*', 'var/view_preprocessed/*',
  	'pub/static/adminhtml/*', 'pub/static/base/*', 'pub/static/frontend/*',
  	'dev', 'node_modules', 'phpserver', 'setup', 'update'
  ]
end

## Post setup installation
def post_up_install(config, mount, hostname)
	config.trigger.after :up, :reload do |trigger|
		if !File.file?(".guest_deployed.flag")
			if OS.is_windows
				runner = 'ni .guest_deployed.flag'
			else
				runner = 'touch .guest_deployed.flag'
			end
		end
		# Add post-up message
  		if mount == 'rsync'
			trigger.info = config.vm.post_up_message
			trigger.info+= '>>> Do not close this terminal: open new one for ssh login
---------------------------------------------------------'
			# Deploy from guest to host
			if runner
		  		runner+= " | vagrant rsync-back #{hostname} | vagrant rsync-auto --rsync-chown #{hostname}"
			else
				# Run rsync-auto
				runner = "vagrant rsync-auto --rsync-chown #{hostname}"
			end
		end
		if runner
			trigger.run = {inline: "#{runner}"} 
		end
	end
	# Remove flag
	config.trigger.after :destroy do |trigger|
		if OS.is_windows
	      trigger.run = {inline: 'del .guest_deployed.flag'}
	    else
	      trigger.run = {inline: 'rm -f .guest_deployed.flag'}
	    end
	end
end