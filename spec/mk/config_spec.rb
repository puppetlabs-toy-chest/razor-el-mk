require 'spec_helper'
require 'mk/config'

require 'tempfile'
require 'json'

describe MK::Config do
  subject(:config) { MK::Config.instance }

  it "should return the instance" do
    MK::Config.instance.should be_an_instance_of MK::Config
  end

  # @todo danielp 2013-07-26: these tests feel like they poke too far into the
  # implementation to me; is there a better way to model this?
  it "should return a value from the default configuration" do
    config['register'].should == MK::Config::DefaultConfiguration['register']
  end

  it "should be case insensitive for normal configuration" do
    config['Register'].should == MK::Config::DefaultConfiguration['register']
  end

  context "kernel command line" do
    def with_command_line(content)
      Tempfile.open('proc-cmdline') do |fh|
        fh.write(content) and fh.flush
        stub_const('MK::Config::KernelCommandLineFile', fh.path)
        yield
      end
    end

    it "should use the default value if the option is missing" do
      with_command_line('') do
        config['register'].should == MK::Config::DefaultConfiguration['register']
      end
    end

    it "should use the command line value if present" do
      with_command_line('razor.register=http://boot.example.com:8140/svc/checkin') do
        config['register'].should == 'http://boot.example.com:8140/svc/checkin'
      end
    end

    it "should find the option with other values before the option" do
      with_command_line('acpi=force quiet razor.register=win') do
        config['register'].should == 'win'
      end
    end

    it "should find the option with other values after the option" do
      with_command_line('razor.register=win acpi=force quiet') do
        config['register'].should == 'win'
      end
    end

    it "should find the option between other values" do
      with_command_line('acpi=force razor.register=win quiet') do
        config['register'].should == 'win'
      end
      with_command_line('quiet razor.register=win acpi=force') do
        config['register'].should == 'win'
      end
    end

    it "should not find a match partially embedded in another" do
      with_command_line('therazor.register=win') do
        config['register'].should == MK::Config::DefaultConfiguration['register']
      end
    end

    it "should match case-insensitively" do
      with_command_line('Razor.register=win') do
        config['register'].should == 'win'
      end
    end
  end

  context "configuration file" do
    def with_config(data)
      Tempfile.open('razor-mk-config') do |fh|
        fh.write(data.to_json) and fh.flush
        stub_const('MK::Config::ConfigurationFile', fh.path)
        yield
      end
    end

    it "should use the default value if the option is missing" do
      with_config({}) do
        config['register'].should == MK::Config::DefaultConfiguration['register']
      end
    end

    it "should use the default value if the content is not a map" do
      with_config([]) do
        config['register'].should == MK::Config::DefaultConfiguration['register']
      end
    end

    it "should use the configuration file value if present" do
      with_config('register' => 'win') do
        config['register'].should == 'win'
      end
    end

    it "should match case-insensitively in the configuration file" do
      with_config('Register' => 'win') do
        config['register'].should == 'win'
      end
    end
  end
end
