#    httpstreamformat.rb
#    ~~~~~~~~~
#    This module implements the HttpStreamFormat class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'base64'
require 'pubcontrol'

# The HttpStreamFormat class is the format used to publish messages to
# HTTP stream clients connected to a GRIP proxy.
class HttpStreamFormat < Format
  attr_accessor :content
  attr_accessor :close

  # Initialize with either the message content or a boolean indicating that
  # the streaming connection should be closed. If neither the content nor
  # the boolean flag is set then an error will be raised.
  def initialize(content=nil, close=false)
    @content = content
    @close = close
    if !@close and @content.nil?
      raise 'Content not set'
    end
  end

  # The name used when publishing this format.
  def name
    return 'http-stream'
  end

  # Exports the message in the required format depending on whether the
  # message content is binary or not, or whether the connection should
  # be closed.
  def export
    out = Hash.new
    if @close
      out['action'] = 'close'
    else
      if @content.encoding.name == 'ASCII-8BIT'
        out['content-bin'] = Base64.encode64(@content)
      else
        out['content'] = @content
      end
    end
    return out
  end
end

