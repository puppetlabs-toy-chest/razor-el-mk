require 'spec_helper'
require 'mk/script'

require 'webrick'
require 'thread'
require 'tmpdir'
require 'json'

describe "register" do
  def port; 27006; end

  # We need to use a global variable for the queue, so that both threads see
  # the same value.  (rspec will memoize across the threads differently, and
  # member variables are not as reliable as you might hope: the before hook
  # and the query happen in different objects, so you can be certain that they
  # will NOT see the same members.)
  def last_registration
    if @last_registration.nil? or $queue.size > 0
      @last_registration = $queue.pop
    end
    @last_registration
  end

  before :all do
    $queue = Queue.new          # meh

    @server = WEBrick::HTTPServer.new(
      :Port      => port,
      :Logger    => WEBrick::Log.new('/dev/null'),
      :AccessLog => WEBrick::Log.new('/dev/null'))

    @server.mount_proc '/svc/checkin' do |req, res|
      # We have to force reading the body now, or it will be discarded before
      # the request is fetched off the queue; the Ruby library will cache the
      # result against future calls to `body`.
      req.body
      $queue.push req

      res.status = 200
      res.body   = {"action" => "none"}.to_json
      res['Content-Type'] = 'application/json'
    end

    Thread.new { @server.start }

    ENV['razor.register'] = "http://localhost:#{port}/svc/checkin"
  end

  after :all do
    @server and @server.shutdown
    ENV.delete('razor.register')
  end

  it "should fail if arguments are given" do
    expect {
      MK::Script.register("1")
    }.to raise_error ArgumentError, /wrong number of arguments/
  end

  it "should register with the server" do
    # We have to force facter to load facts before we fake the filesystem;
    # sorry this is so ugly.
    Facter.to_hash

    FakeFS.activate!
    stub_interfaces('eth0' => '00:00:00:00:00:00')
    MK::Script.register
    FakeFS.deactivate!

    last_registration['Content-Type'].should == 'application/json'

    data = JSON.parse(last_registration.body)

    # Sadly, RSpec still has limited support for fuzzy matching on hash values.
    data.keys.should include('hw_id', 'facts')
    data['hw_id'].should == '000000000000'
    data['facts'].should be_an_instance_of Hash

    # Make sure we passed a sampling of facts through correctly; should be
    # testing `nil == nil` if the fact isn't defined on this platform, which
    # is a pass, and an acceptable default position to take.
    %w[architecture hostname path rubyversion sshdsakey virtual].each do |fact|
      data['facts'][fact].should == Facter.send(fact)
    end
  end
end


describe "execute" do
  def dir_of(command)
    dir = ENV['PATH'].
      split(':').
      map {|x| Pathname(x) + command }.
      select {|x| x.executable? }.
      first.
      dirname.
      to_s

    dir or raise "command #{command} not found on PATH"
  end

  it "should fail if `commands` is not in the configuration" do
    MK.config.stub(:[]).and_return(nil)
    expect {
      MK::Script.execute('true')
    }.to raise_error RuntimeError, /not set in the configuration/
  end

  it "should fail if the command does not exist on the command path" do
    Dir.mktmpdir do |root|
      ENV['razor.commands'] = root
      expect {
        MK::Script.execute('true')
      }.to raise_error RuntimeError, /unknown command/
    end
  end

  it "should fail if the command is not an executable" do
    Dir.mktmpdir do |root|
      ENV['razor.commands'] = root
      file = (Pathname(root) + 'true')
      file.open('w') {|f| f.puts ''} # create...
      file.chmod(0644)               # ...and non-executable

      expect {
        MK::Script.execute('true')
      }.to raise_error RuntimeError, /not executable/

      ENV.delete('razor.commands')
    end
  end

  it "should raise if the command returns non-zero" do
    ENV['razor.commands'] = dir_of('false')

    expect {
      MK::Script.execute('false')
    }.to raise_error RuntimeError, /failed invoking/

    ENV.delete('razor.commands')
  end

  it "should return true if the commands returns zero" do
    ENV['razor.commands'] = dir_of('true')

    MK::Script.execute('true').should be_true

    ENV.delete('razor.commands')
  end
end
