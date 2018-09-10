#!/usr/bin/ruby
# @Author: Dev_NIX

require 'getoptlong'

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
			puts "\033[0m" << " - All dependencies already satisfied" << "\e[0m"
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

# Get OS
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