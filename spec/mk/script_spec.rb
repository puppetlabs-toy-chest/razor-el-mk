require 'spec_helper'
require 'mk/script'

require 'webrick'

describe "register" do
  def port; 27006; end
  def last_registration; @last_registration; end

  before :all do
    @server = WEBrick::HTTPServer.new(
      :Port      => port,
      :Logger    => WEBrick::Log.new('/dev/null'),
      :AccessLog => WEBrick::Log.new('/dev/null'))

    @server.mount_proc '/svc/checkin' do |req, res|
      @last_registration = req
      res.status = 200
      res.body   = {"action" => "none"}.to_json
      res['Content-Type'] = 'application/json'
    end

    Thread.new { @server.start }

    ENV['razor.register'] = "http://localhost:#{port}/svc/checkin"
  end

  after :all do
    @server and @server.shutdown
  end

  it "should fail if arguments are given" do
    expect {
      MK::Script.register(["1"])
    }.to raise_error(/does not take any arguments/)
  end

  it "should register with the server" do
    stub_interfaces('eth0' => '00:00:00:00:00:00')
    MK::Script.register([])

    last_registration['Content-Type'].should == 'application/json'
    last_registration.body.should == 12
  end
end
