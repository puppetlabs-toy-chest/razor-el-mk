require 'spec_helper'
require 'mk/server'

describe MK::Server do
  subject(:server) { MK::Server.instance }

  context "send_register" do
    def port; 27007; end

    let :body do
      # A bit light on facts, but it will do for the purpose.
      {
        'hw_id' => '000000000000',
        'facts' => {
          'ps'            => 'ps auxwww',
          'puppetversion' => '3.2.1',
          'rubysitedir'   => '/usr/lib/ruby/site_ruby/1.9.1',
          'rubyversion'   => '1.9.3'
        }
      }
    end

    let :headers do
      {
        'Content-Type' => 'application/json',
        'User-Agent'   => "razor/0.0.0-DEVELOPMENT facter/1.7.2 ruby/1.9.3 kernel/Linux-2.6.32-6-amd64"
      }
    end

    before :all do
      @server = WEBrick::HTTPServer.new(
        :Port      => port,
        :Logger    => WEBrick::Log.new('/dev/null'),
        :AccessLog => WEBrick::Log.new('/dev/null'))

      @server.mount_proc '/500' do |req, res|
        res.status = 500
        res.body   = '500 you lose'
      end

      Thread.new { @server.start }
    end

    after :all do
      @server and @server.stop
    end

    around :each do |example|
      begin
        original = ENV['razor.register']
        example.run
      ensure
        if original.nil?
          ENV.delete('razor.register')
        else
          ENV['razor.register'] = original
        end
      end
    end

    [
      'ftp://example.com/registration',
      'gttp://example.com/',
      'http://example++',
      '/svc/checkin'
    ].each do |badness|
      it "should raise if the register URL is `#{badness}`" do
        ENV['razor.register'] = badness
        expect {
          server.send_register(body, headers)
        }.to raise_error
      end
    end

    it "should raise if the response is a 4xx code" do
      ENV['razor.register'] = "http://localhost:#{port}/404"
      expect {
        server.send_register(body, headers)
      }.to raise_error Net::HTTPServerException, /404/
    end

    it "should raise if the response is a 5xx code" do
      ENV['razor.register'] = "http://localhost:#{port}/500"
      expect {
        server.send_register(body, headers)
      }.to raise_error Net::HTTPFatalError, /500/
    end
  end
end
