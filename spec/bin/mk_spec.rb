require 'spec_helper'
require 'pathname'
require 'open3'

describe "bin/mk script" do
  include Open3

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

  let :mk do (Pathname(__FILE__).dirname + '../../bin/mk').realpath.to_s end

  it "should have a relevant message if the command is omitted" do
    output, status = capture2e(mk)
    status.should be_exited
    status.should_not be_success
    output.should =~ /no command/i
  end

  it "should have a relevant message if the command is unknown" do
    output, status = capture2e(mk, 'no such command is defined')
    status.should be_exited
    status.should_not be_success
    output.should =~ /unknown command/i
  end

  it "should exit zero if the command executed successfully" do
    env = {'razor.commands' => dir_of('true')}
    output, status = capture2e(env, mk, 'execute', 'true')
    status.should be_exited
    status.should be_success
  end

  it "should exit non-zero if the command executed but returned non-zero" do
    env = {'razor.commands' => dir_of('false')}
    output, status = capture2e(env, mk, 'execute', 'false')
    status.should be_exited
    status.should_not be_success
  end
end
