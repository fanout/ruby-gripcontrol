#    websocketmessageformat.rb
#    ~~~~~~~~~
#    This module implements the WebSocketMessageFormat class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'base64'
require 'pubcontrol'

class WebSocketMessageFormat < Format
  attr_accessor :content

  def initialize(content, binary=false)
    @content = content
    @binary = binary
  end

  def name
    return 'ws-message'
  end

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

