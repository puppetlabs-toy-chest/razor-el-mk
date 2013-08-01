require 'spec_helper'
require 'mk'

describe MK do
  it "should return the node on request" do
    MK.node.should be_an_instance_of MK::Node
  end

  it "should return the configuration on request" do
    MK.config.should be_an_instance_of MK::Config
  end
end
