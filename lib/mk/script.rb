require_relative '../mk'

# A namespace to hold our command line script support code.
module MK::Script
  module_function

  # Perform the node registration process, submitting our facts and hardware
  # identifiers to the Razor server.
  def register(arguments)
    arguments.empty? or raise '`register` does not take any arguments'

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
    MK.server.send_register(data, headers)

    # ...and we are good.
    return true
  end
end
