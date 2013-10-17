require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
  add_filter ".erb"
end

# Load, but don't immediately use, the fake filesystem magic
# See https://github.com/defunkt/fakefs for details
require 'fakefs/safe'
require 'fakefs/spec_helpers'


module StubHelpers
  # Stub Facter to return a fixed set of MAC addresses for interfaces:
  # `stub_interfaces('eth0' => 'aa:bb:cc:dd:ee:ff', 'eth1' => '...')`
  def stub_interfaces(interfaces)
    # Facter::Util::IP.stub(:get_interfaces).and_return(interfaces.keys)
    # Facter::Util::IP.stub(:get_interface_value) do |name, value|
    #   case value
    #   when 'macaddress'
    #     interfaces.has_key?(name) or
    #       raise "facter really just explodes, but we have a nice error message"
    #     interfaces[name]
    #   when 'ipaddress'  then '127.0.0.1'
    #   when 'ipaddress6' then "\n"
    #   when 'netmask'    then '255.0.0.0'
    #   when 'mtu'        then '16384'
    #   when 'network'    then '127.0.0.0'
    #   else puts "unsupported interface value #{value.inspect}"
    #   end
    # end

    interfaces.each do |name, address|
      # This isn't the whole tree, so is kinda coupled to the implementation.
      # Right now I don't think that is actually a problem.  If you do, you
      # can go dig out the symlink locations and fake it better. ;)
      base = Pathname('/sys/class/net') + name
      base.mkpath               # because we need the directory and parents

      (base + 'type').open('w')    do |fh| fh.puts "1" end
      (base + 'address').open('w') do |fh| fh.puts address end
    end
  end
end

RSpec.configure do |c|
  c.include StubHelpers
end
