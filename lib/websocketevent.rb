#    websocketevent.rb
#    ~~~~~~~~~
#    This module implements the WebSocketEvent class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

# The WebSocketEvent class represents WebSocket event information that is
# used with the GRIP WebSocket-over-HTTP protocol. It includes information
# about the type of event as well as an optional content field.
class WebSocketEvent
  attr_accessor :type
  attr_accessor :content

  # Initialize with a specified event type and optional content information.
  def initialize(type, content=nil)
    @type = type
    @content = content
  end
end
