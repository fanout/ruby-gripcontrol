#    httpresponseformat.rb
#    ~~~~~~~~~
#    This module implements the HttpResponseFormat class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'base64'
require 'pubcontrol'

class HttpResponseFormat < Format
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

  def name
    return 'http-response'
  end

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
      if @body.encoding.name == 'ASCII-8BIT'
        out['body-bin'] = Base64.encode64(@body)
      else
        out['body'] = @body
      end
    end
    return out
  end
end
