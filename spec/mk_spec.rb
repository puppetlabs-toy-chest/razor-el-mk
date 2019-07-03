require 'spec_helper'
require 'mk'

describe MK do
  it "should return the node on request" do
    expect( MK.node ).to be_an_instance_of MK::Node
  end

  it "should return the configuration on request" do
    expect( MK.config ).to be_an_instance_of MK::Config
  end
end
