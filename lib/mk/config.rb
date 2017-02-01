require_relative '../mk'

require 'singleton'

# An abstraction around configuration for the Razor MK client, hiding the gory
# details of how we locate and prefer configuration data from the rest of
# the code.
#
# This is a singleton: access it via `MK::Config.instance`, or `MK.config`.
#
# @todo danielp 2013-07-29: at the moment, setting the URLs for register, etc,
# is kind of nasty: you always have to supply the full value.  It would be
# nice to follow the path of Debian preseeds (see B.2.3. in
# http://www.debian.org/releases/stable/i386/apbs02.html.en for details.)
class MK::Config
  include Singleton

  # Provide a reader for our configuration data.  This is case-folding, and
  # will normalize string/symbol differences, but provides no traversal or
  # similar mechanisms.
  #
  # If the key is not present in any configuration source, returns `nil`.
  # Error handling and key sanitation is up to the caller.
  def [](key)
    key = key.to_s.downcase
    get_from_runtime(key) or
      get_from_kernel_command_line(key) or
      get_from_DHCP_option(key) or
      get_from_config_file(key) or
      get_from_default_config(key) or
      nil
  end

  def set(key, val)
    if File.file?(RuntimeConfigurationFile)
      if File.readable? RuntimeConfigurationFile
        runtime = JSON.parse(File.read(RuntimeConfigurationFile), 
          :create_additions => false) rescue {}
      else
        #If the file exists, but its not readable, somethings really wrong.
        return nil
      end
    else
      runtime = {}
    end
    
    key = key.to_s.downcase
    runtime[key] = val

    fd = File.new(RuntimeConfigurationFile,'w')
    fd.write(runtime.to_json)
    fd.close
  end

  # Default configuration values
  DefaultConfiguration = {
    'register' => 'http://razor:8080/svc/checkin',
    'extend'   => 'http://razor:8080/svc/mk/extension.zip',
    'commands' => '/usr/lib/razor'
  }.freeze

  # Configuration File path.
  #
  # This is assumed to be a file containing JSON, with the configuration data
  # directly within the top level map.  eg:
  #
  #     {"server": "razor.example.com"}
  ConfigurationFile    = '/etc/razor-mk-client.conf'
  
  #Runtime File path.
  #
  # This file will preserve runtime configuration between runs.  ENV used
  # to be good for this, however now that the script runs on a timer
  # rather than a daemon, ENV is sanitised each run.
  RuntimeConfigurationFile = '/tmp/razor-mk-runtime.conf'


  ########################################################################
  # internal implementation from here on down
  private

  KernelCommandLineFile = '/proc/cmdline'

  # Fetch a Razor setting from the environment.
  #
  # This fetches a value of "razor.#{key}" case-insensitively from
  # the environment.
  def get_from_runtime(key)
    # This returns false if the file does not exist.
    return nil unless File.readable? RuntimeConfigurationFile

    # Parse, but don't use any magic to vivify richer objects than the basic
    # JSON spec allows -- not date/time magic, or anything else, just Hash,
    # String, Array, and primitive types.
    #
    # In the event of an error, treat the file as empty.
    data = JSON.parse(File.read(RuntimeConfigurationFile), :create_additions => false) rescue {}
    return nil unless data.is_a? Hash

    found = data.keys.find {|n| key.casecmp(n) == 0 }
    found and data[found]
  end

  # Fetch a Razor setting from the kernel command line.
  #
  # This fetches a value of "razor.#{key} case-insensitively from the
  # arguments passed on the kernel command line.
  def get_from_kernel_command_line(key)
    return nil unless File.readable? KernelCommandLineFile

    data  = Hash[File.read(KernelCommandLineFile).scan(/\brazor\.(\w+)=([^\s]+)/i)]
    found = data.keys.find {|n| key.casecmp(n) == 0 }
    found and data[found]
  end

  # Fetch a Razor setting from a DHCP option value.
  #
  # @todo danielp 2013-07-26: this is not implemented; it needs to be reworked
  # in view of the different DHCP client in the EL Microkernel, and perhaps
  # reconsidered in view of wanting to support more than one sort of MK?
  def get_from_DHCP_option(key)
    nil
  end

  # Fetch a Razor setting from the fixed configuration file on disk.
  def get_from_config_file(key)
    # This returns false if the file does not exist.
    return nil unless File.readable? ConfigurationFile

    # Parse, but don't use any magic to vivify richer objects than the basic
    # JSON spec allows -- not date/time magic, or anything else, just Hash,
    # String, Array, and primitive types.
    #
    # In the event of an error, treat the file as empty.
    data = JSON.parse(File.read(ConfigurationFile), :create_additions => false) rescue {}
    return nil unless data.is_a? Hash

    found = data.keys.find {|n| key.casecmp(n) == 0 }
    found and data[found]
  end

  # Fetch a Razor setting from the default, build-in configuration.
  def get_from_default_config(key)
    DefaultConfiguration[key]
  end
end
