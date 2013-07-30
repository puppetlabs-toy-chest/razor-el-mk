require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
  add_filter ".erb"
end

module StubHelpers
  # Stub Facter to return a fixed set of MAC addresses for interfaces:
  # `stub_interfaces('eth0' => 'aa:bb:cc:dd:ee:ff', 'eth1' => '...')`
  def stub_interfaces(interfaces)
    Facter::Util::IP.stub(:get_interfaces).and_return(interfaces.keys)
    Facter::Util::IP.stub(:get_interface_value) do |name, value|
      case value
      when 'macaddress'
        interfaces.has_key?(name) or
          raise "facter really just explodes, but we have a nice error message"
        interfaces[name]
      when 'ipaddress'  then '127.0.0.1'
      when 'ipaddress6' then "\n"
      when 'netmask'    then '255.0.0.0'
      when 'mtu'        then '16384'
      when 'network'    then '127.0.0.0'
      else puts "unsupported interface value #{value.inspect}"
      end
    end
  end
end

RSpec.configure do |c|
  c.include StubHelpers
end
