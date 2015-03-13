#    websocketmessageformat.rb
#    ~~~~~~~~~
#    This module implements the WebSocketMessageFormat class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'base64'
require 'pubcontrol'

# The WebSocketMessageFormat class is the format used to publish data to
# WebSocket clients connected to GRIP proxies.
class WebSocketMessageFormat < Format
  attr_accessor :content

  # Initialize with the message content and a flag indicating whether the
  # message content should be sent as base64-encoded binary data.
  def initialize(content, binary=false)
    @content = content
    @binary = binary
  end

  # The name used when publishing this format.
  def name
    return 'ws-message'
  end

  # Exports the message in the required format depending on whether the
  # message content is binary or not.
  def export
    out = Hash.new
    if @binary
      out['content-bin'] = Base64.encode64(@content)
    else
      out['content'] = @content
    end
    return out
  end
end

