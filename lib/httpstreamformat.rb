#    httpstreamformat.rb
#    ~~~~~~~~~
#    This module implements the HttpStreamFormat class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'base64'
require 'pubcontrol'

class HttpStreamFormat < Format
  attr_accessor :content
  attr_accessor :close

  def initialize(content=nil, close=false)
    @content = content
    @close = close
    if !@close and @content.nil?
      raise 'Content not set'
    end
  end

  def name
    return 'http-stream'
  end

  def export
    out = Hash.new
    if @close
      out['action'] = 'close'
    else
      if @content.encoding.name == 'ASCII-8BIT'
        out['body-bin'] = Base64.encode64(@content)
      else
        out['body'] = @content
      end
    end
    return out
  end
end

