require 'forwardable'

# A convenience namespace for shared code in our Microkernel Razor
# client implementation.
module MK
  extend Forwardable

  # Convenience accessor for the current node data.
  def_delegator 'MK::Node', 'instance', 'node'
  module_function 'node'
end

require_relative 'mk/node'

