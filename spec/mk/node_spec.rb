require 'spec_helper'
require 'mk/node'

describe MK::Node do
  subject(:node) { MK::Node.instance }

  context "hw_id" do
    # every test in this block will run with a fresh, fake filesystem
    include FakeFS::SpecHelpers

    # @todo danielp 2013-07-25: the semantics of this situation are unclear to
    # me, but I think that "fail and assume that either the MK reboots, or a
    # network interface eventually shows up when we are restarted" are
    # reasonable semantics for now...
    it "should raise an exception if there are no interfaces" do
      stub_interfaces({})
      expect {
        node.hw_id
      }.to raise_error RuntimeError, /no network interfaces detected/
    end

    it "should ignore non-eth addresses when considering interfaces" do
      stub_interfaces({'lo0' => nil})
      expect {
        node.hw_id
      }.to raise_error RuntimeError, /no network interfaces detected/
    end

    it "should concatenate multiple Ethernet-ish MACs" do
      stub_interfaces(
        'lo0'   => nil,
        'wlan0' => 'c8:bc:c8:d8:4f:04',
        'eth0'  => 'c8:bc:c8:96:67:51',
        'eth1'  => '00:0c:29:82:5e:22')

      expect( node.hw_id ).to eq('c8bcc8966751_000c29825e22_c8bcc8d84f04')
    end

    it "should concatenate multiple Ethernet-ish MACs in sorted-by-name order" do
      stub_interfaces(
        'lo0'   => nil,
        'eth1'  => 'c8:bc:c8:96:67:51',
        'eth0'  => '00:0c:29:82:5e:22')

      expect( node.hw_id ).to eq('000c29825e22_c8bcc8966751')
    end

    it "should ignore inaccessible MACs on Ethernet-ish interfaces" do
      # This is the way Facter handles the situation; I don't know this
      # *should* every happen, but the original did, so I assume that there
      # was some horrible breakage in hardware or software somewhere, and we
      # should preserve that security blanket.
      stub_interfaces(
        'lo0'   => nil,
        'wlan0' => 'c8:bc:c8:d8:4f:04',
        'eth1'  => nil,
        'eth0'  => '00:0c:29:82:5e:22')

      expect( node.hw_id ).to eq('000c29825e22_c8bcc8d84f04')
    end
  end

  context "facts" do
    let :facts do Facter.to_hash end

    it "should return facts as a hash" do
      expect( node.facts ).to be_an_instance_of Hash
    end

    it "should have only string keys" do
      node.facts.keys.each {|key| expect( key ).to be_an_instance_of String }
    end

    it "should return all the current nodes facts" do
      expect( node.facts ).to include facts
    end
  end

  context "user_agent" do
    subject(:ua) { node.user_agent }

    # Based on the ABNF from the RFC.
    ValidToken           = %r{[^()<>@,;:\\"\/\[\]?={} \x0-\x1f\x7f]+}o
    ValidProduct         = %r{#{ValidToken}/#{ValidToken}}o
    ValidUserAgentHeader = %r{\A#{ValidProduct}(?: #{ValidProduct})*\Z}o

    it "should be a valid user agent header" do
      expect( ua ).to match(ValidUserAgentHeader)
    end

    %w[razor facter ruby kernel].each do |field|
      it "should include a valid #{field} version token" do
        expect( ua ).to match(/\b#{field}\/#{ValidToken}\b/i)
      end
    end
  end
end
