require_relative '../mk'

require 'facter'
require 'facter/util/ip'        # not automatically loaded in all cases

require 'singleton'
require 'forwardable'

class MK::Node
  include Singleton
  extend  Forwardable

  # Determine the hardware ID of this node -- essentially, the concatenated
  # MAC address of all "Ethernet-ish" network cards as enumerated by
  # the kernel.
  #
  # Ethernet-ish is defined as "named starting with 'eth'", to match the
  # Linux kernel default naming of your NICs; no relationship to actually
  # being an Ethernet interface, or even an important network interface, is
  # intended or implied.
  def hw_id
    ifaces = Facter::Util::IP.get_interfaces.select do |iface|
      # @todo danielp 2013-07-25: Razor would previously limit this to only
      # Ethernet interfaces, which seems (a) limited, and (b) likely to fail
      # in Fedora 20 and beyond, when they rename the interfaces based
      # on topology.  IMO, we should have a more sensible policy than this.
      iface =~ /^eth\d+$/
    end

    # Since we might have eliminated the only interfaces present on this
    # machine, this needs to apply *after* the filtering is done.
    ifaces.empty? and
      raise "no network interfaces detected; cannot generate a hardware ID"

    # @todo danielp 2013-07-25: Razor did nothing to normalize case in the
    # hardware identifier, depending on either the server doing that, or
    # simple chance to ensure that they matched.  We currently follow...
    ifaces.map do |iface|
      Facter::Util::IP.get_interface_value(iface, 'macaddress')
    end.compact.join('_').gsub(':', '')
  end

  # Fetch the facts for the current node.
  #
  # Traditionally, this was a superset of the "standard" Facter facts, and
  # included a selection of hardware based facts.  In this implementation, we
  # simply return what Facter does -- and deploy additional facts of our own
  # as required to add more data.
  def_delegator 'Facter', 'to_hash', 'facts'


  # Calculate the "user agent" string, which is a collection of versioning
  # information potentially useful to supply to the server.
  #
  # Presently includes:
  # * MK client version
  # * Facter version
  # * Ruby version
  # * Linux kernel version
  def user_agent
    values = {
      'razor'  => MK::VERSION,
      'facter' => Facter.version, # sigh
      'ruby'   => RUBY_VERSION,
      # @todo danielp 2013-07-30: I can't find a better way to do this...
      'kernel'  => Facter.kernel + '-' + Facter.kernelversion
    }.reject{|k,v| v.nil?}.map{|k,v| k+'/'+v}.join(' ')
  end
end
