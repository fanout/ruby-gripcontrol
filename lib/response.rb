#    response.rb
#    ~~~~~~~~~
#    This module implements the Response class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

class Response
  attr_accessor :code
  attr_accessor :reason
  attr_accessor :headers
  attr_accessor :body

  def initialize(code=nil, reason=nil, headers=nil, body=nil)
    @code = code
    @reason = reason
    @headers = headers
    @body = body
  end
end
