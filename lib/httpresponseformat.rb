#    httpresponseformat.rb
#    ~~~~~~~~~
#    This module implements the HttpResponseFormat class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'base64'
require 'pubcontrol'

# The HttpResponseFormat class is the format used to publish messages to
# HTTP response clients connected to a GRIP proxy.
class HttpResponseFormat < Format
  attr_accessor :code
  attr_accessor :reason
  attr_accessor :headers
  attr_accessor :body

  # Initialize with the message code, reason, headers, and body to send
  # to the client when the message is published.
  def initialize(code=nil, reason=nil, headers=nil, body=nil)
    @code = code
    @reason = reason
    @headers = headers
    @body = body
  end

  # The name used when publishing this format.
  def name
    return 'http-response'
  end

  # Export the message into the required format and include only the fields
  # that are set. The body is exported as base64 if the text is encoded as
  # binary.
  def export
    out = Hash.new
    if !@code.nil?
      out['code'] = @code
    end
    if !@reason.nil?
      out['reason'] = @reason
    end
    if !@headers.nil? and @headers.length > 0
      out['headers'] = @headers
    end
    if !@body.nil?
      if @body.clone.force_encoding("UTF-8").valid_encoding?   
        out['body'] = @body
      else
        out['body-bin'] = Base64.encode64(@body)
      end
    end
    return out
  end
end
