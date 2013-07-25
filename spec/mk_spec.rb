require 'spec_helper'
require 'mk'

describe MK do
  it "should return the node on request" do
    MK.node.should be_an_instance_of MK::Node
  end
end
