require 'spec_helper'
require 'mk/server'
require 'webrick'
require 'json'

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

    GoodResponse = {'action' => 'none'}

    before :all do
      @server = WEBrick::HTTPServer.new(
        :Port      => port,
        :Logger    => WEBrick::Log.new('/dev/null'),
        :AccessLog => WEBrick::Log.new('/dev/null'))

      @server.mount_proc '/500' do |req, res|
        res.status = 500
        res.body   = '500 you lose'
      end

      @server.mount_proc '/good-body' do |req, res|
        res.status       = 200
        res.body         = GoodResponse.to_json
        res.content_type = 'application/json'
      end

      @server.mount_proc '/not-json-c-t' do |req, res|
        res.status       = 200
        res.body         = {'action' => 'none'}.to_json
        res.content_type = 'application/definitely-not-json'
      end

      @server.mount_proc '/not-valid-json' do |req, res|
        res.status       = 200
        res.body         = '{"action": "none"'
        res.content_type = 'application/json'
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
      ['ftp://example.com/registration', RuntimeError],
      ['gttp://example.com/', RuntimeError],
      ['http://example++', MK::Server::ConnectionFailedError],
      ['/svc/checkin', RuntimeError]
    ].each do |badness, error_type|
      it "should raise if the register URL is `#{badness}`" do
        ENV['razor.register'] = badness
        expect {
          server.send_register(body, headers)
        }.to raise_error(error_type)
      end
    end

    it "should raise if the response is a 4xx code" do
      ENV['razor.register'] = "http://localhost:#{port}/erroring"
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

    it "should raise if the response is not JSON by content-type" do
      ENV['razor.register'] = "http://localhost:#{port}/not-json-c-t"
      expect {
        server.send_register(body, headers)
      }.to raise_error RuntimeError, /unknown response content type/
    end

    it "should raise if the response does not decode as JSON" do
      ENV['razor.register'] = "http://localhost:#{port}/not-valid-json"
      expect {
        server.send_register(body, headers)
      }.to raise_error JSON::ParserError
    end

    it "should return the body, decoded as JSON, on success" do
      ENV['razor.register'] = "http://localhost:#{port}/good-body"
      expect( server.send_register(body, headers) ).to eq(GoodResponse)
    end
  end
end
