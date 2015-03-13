#    response.rb
#    ~~~~~~~~~
#    This module implements the Response class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

# The Response class is used to represent a set of HTTP response data.
# Populated instances of this class are serialized to JSON and passed
# to the GRIP proxy in the body. The GRIP proxy then parses the message
# and deserialized the JSON into an HTTP response that is passed back 
# to the client.
class Response
  attr_accessor :code
  attr_accessor :reason
  attr_accessor :headers
  attr_accessor :body

  # Initialize with an HTTP response code, reason, headers, and body.
  def initialize(code=nil, reason=nil, headers=nil, body=nil)
    @code = code
    @reason = reason
    @headers = headers
    @body = body
  end
end
