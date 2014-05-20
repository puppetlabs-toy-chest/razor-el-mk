require_relative '../mk'

require 'facter'
require 'facter/util/ip'        # not automatically loaded in all cases

require 'singleton'
require 'forwardable'

require 'pathname'

class MK::Node
  include Singleton
  extend  Forwardable

  # Determine the hardware ID of this node -- essentially, the concatenated
  # MAC address of all "Ethernet-ish" network cards as enumerated by
  # the kernel.
  #
  # Ethernet-ish was originally defined -- in the first cut of Razor, and
  # early rewrite microkernels -- as "named starting with 'eth'", to match the
  # Linux kernel default naming of your NICs; no relationship to actually
  # being an Ethernet interface, or even an important network interface, is
  # intended or implied.
  #
  # That expanded to accept the "em..." names in Fedora 18, and now is
  # rewritten to just avoid Facter entirely -- because we know our
  # environment, and don't actually *need* the portability that it gave us.
  #
  # That portability also came at the cost of using hacks to filter to
  # Ethernet type, which we can now do (fairly) cleanly by checking the sysfs
  # attribute directly in our code.
  #
  # Overall this should result in a higher quality, more reliable detection of
  # network interfaces with zero user maintenance, and most importantly, zero
  # need to have a mutable regexp to work out what is or isn't "good" on
  # this machine in terms of hardware ID extraction.
  def hw_id
    # Observe that we sort the pathnames before turning them into MAC
    # addresses, because that gives us a stable ordering when run multiple
    # times on the same machine.
    hw_id = Pathname.glob('/sys/class/net/*').select do |sysfs|
      # This should skip everything except Ethernet style interfaces, which is
      # maybe the right thing to do?  Different rule to what we use in DHCP
      # though, so maybe we should just skip if name == 'lo'?
      File.read(sysfs + 'type').chomp == '1'
    end.sort.map do |sysfs|
      address = File.read(sysfs + 'address').chomp
      # this ensures that we strip out empty address fields next
      address.empty? ? nil : address
    end.compact.join('_').gsub(':', '').downcase

    # Make sure we actually got *some* hardware ID.
    if hw_id.nil? or hw_id.empty?
      raise "no network interfaces detected; cannot generate a hardware ID"
    end

    hw_id
  end

  # Fetch the facts for the current node.
  #
  # Traditionally, this was a superset of the "standard" Facter facts, and
  # included a selection of hardware based facts.  In this implementation, we
  # simply return what Facter does -- and deploy additional facts of our own
  # as required to add more data.
  def facts
    if ENV['MK_EXTERNAL_FACTS']
      begin
        Facter::Util::Config.ext_fact_loader = Facter::Util::DirectoryLoader.loader_for(ENV['MK_EXTERNAL_FACTS'])
      rescue Facter::Util::DirectoryLoader::NoSuchDirectoryError
        # An error here should go back to the server; though how ?
        # But carry on anyway
      end
    end
    Facter::to_hash
  end

  # Calculate the "user agent" string, which is a collection of versioning
  # information potentially useful to supply to the server.
  #
  # Presently includes:
  # * MK client version
  # * Facter version
  # * Ruby version
  # * Linux kernel version
  def user_agent
    kernel = Facter[:kernel] ? Facter[:kernel].value : 'unknown'
    kvers  = Facter[:kernelversion] ? Facter[:kernelversion].value : 'unknown'
    values = {
      'razor'  => MK::VERSION,
      'facter' => Facter.version, # sigh
      'ruby'   => RUBY_VERSION,
      'kernel' => "#{kernel}-#{kvers}"
    }.reject{|k,v| v.nil?}.map{|k,v| k+'/'+v}.join(' ')
  end
end
