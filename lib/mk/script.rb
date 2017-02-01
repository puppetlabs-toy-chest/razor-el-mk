require_relative '../mk'

require 'pathname'
require 'open3'
require 'json'

# A namespace to hold our command line script support code.
module MK::Script
  module_function

  # Perform the node registration process, submitting our facts and hardware
  # identifiers to the Razor server.  Since the Razor server synchronously
  # returns a command to be processed, this will also dispatch that internally
  # to be executed.
  def register
    # Grab the facts for this node
    facts = MK.node.facts
    hw_id = MK.node.hw_id

    # Format the body of our register as a JSON message
    data = { 'hw_id' => hw_id, 'facts' => facts }.to_json

    # Grab our user agent header.
    user_agent = MK.node.user_agent

    # Build our headers for the request.
    headers = {
      'Content-Type' => 'application/json',
      'User-Agent'   => user_agent
    }

    # Send our RPC registration command to the server; this will raise if
    # something goes wrong in the submission process.
    result = MK.server.send_register(data, headers)

    # Dispatch the command we received, unless there is none...
    execute(result['action']) unless result['action'] == 'none'

    if result['id']
      MK.config.set('id', result['id'])
    end

    # ...and we are good.
    return true
  end

  # Perform local execution of a command requested by the remote
  # Razor server.  This wraps the process of discovering and executing the
  # on-disk command; unpacking and formatting the command is handled through
  # other parts of the process.
  #
  # @param command   [String] the name of the command to execute
  # @param arguments [Array<String>] the arguments to the command
  def execute(command, *arguments)
    command_path = MK.config['commands'] or
      raise "`commands` not set in the configuration!"

    executable = Pathname(command_path) + command
    executable.exist? or raise "unknown command `#{command}`"
    executable.executable? or raise "unable to execute `#{command}`: not executable"

    options = {:pgroup => true, :chdir => '/tmp', :umask => 0022}
    output, status = Open3.capture2e(executable.to_s, *arguments, options)
    # Note: there is no guarantee that we well ever reach this line of code,
    # or any other line of code following this.  The command could very well
    # have been `reboot`, and already underway.
    unless status.success?
      # @todo danielp 2013-08-01: this should be logged to the server.
      puts output
      raise "failed invoking `#{command} #{arguments.join(' ')}`: #{status.inspect}"
    end

    # ...all good, job done.
    return true
  end

  def config(name)
    value = MK.config[name]
    puts value
    !!value
  end
end
