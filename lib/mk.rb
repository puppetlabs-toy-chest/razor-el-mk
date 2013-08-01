require 'forwardable'

# A convenience namespace for shared code in our Microkernel Razor
# client implementation.
module MK
  extend Forwardable

  # The version of the Microkernel client code in use.  This follows the
  # tenets of [semantic versioning](http://semver.org), and this version
  # number reflects the rules as of SemVer 2.0.0
  #
  # Note: the string `0.0.0-DEVELOPMENT` is special: the release version is
  # "burned in" to the code during the build process for our release packages.
  # As part of that, this string vanishes.  If you are working directly from
  # source, you shouldn't trust the version number at all.
  VERSION = '0.0.0-DEVELOPMENT'

  # Convenience accessor for the current node data.
  def_delegator 'MK::Node', 'instance', 'node'
  module_function 'node'

  # Convenience accessor for shared configuration data.
  def_delegator 'MK::Config', 'instance', 'config'
  module_function 'config'

  # Convenience accessor for our "server" RPC abstraction.
  def_delegator 'MK::Server', 'instance', 'server'
  module_function 'server'
end

require_relative 'mk/node'
require_relative 'mk/config'
require_relative 'mk/server'
