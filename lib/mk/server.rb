require_relative '../mk'

require 'singleton'
require 'uri'
require 'net/http'

class MK::Server
  include Singleton

  # Submit a registration request to the server.  This will raise an exception
  # if the request fails.
  def send_register(body, headers)
    url = URI(MK.config['register'])
    raise "HTTPS is not yet supported in #{url}" if url.scheme =~ /\Ahttps\Z/i
    raise "bad URL scheme for #{url}" unless url.scheme =~ /\Ahttp\Z/i

    Net::HTTP.start(url.host, url.port) do |http|
      # Build the request object...
      post      = Net::HTTP::Post.new(url.path, headers)
      post.body = body.is_a?(String) ? body : body.to_json

      # ...submit, and consider the result we got.
      response = http.request(post)

      case response
      when Net::HTTPSuccess, Net::HTTPRedirection
        # @todo danielp 2013-07-30: I am going to assume that the HTTP
        # redirect response is a success, and they want to send us politely to
        # the "here are your results" page or something.  Is that right?
        # Should I be stricter about what we accept?
        #
        # @todo danielp 2013-07-30: right now we get a synchronous command
        # returned from the server.  We should extract that, and submit it
        # internally for processing.
        response.content_type.downcase == 'application/json' or
          raise "unknown response content type #{response.content_type.inspect}"

        # This is the "untrusted" parser, as it should be: we might take some
        # deliberate action in response to this.
        result = JSON.parse(response.body)

        # ...and we are done.  Return the results of the submission, decoded,
        # to the caller.
        result

      else
        # This will raise an exception capturing the state of the response.
        # Yes, that name is terrible; I blame the Ruby folks for that one.
        response.value
      end
    end
  end
end
