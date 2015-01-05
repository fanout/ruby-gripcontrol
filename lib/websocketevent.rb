#    websocketevent.rb
#    ~~~~~~~~~
#    This module implements the WebSocketEvent class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

class WebSocketEvent
  attr_accessor :type
  attr_accessor :content

	def initialize(type, content=nil)
		@type = type
		@content = content
  end
end
