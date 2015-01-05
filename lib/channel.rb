#    channel.rb
#    ~~~~~~~~~
#    This module implements the Channel class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

class Channel
  attr_accessor :name
  attr_accessor :prev_id

	def initialize(name, prev_id=nil)
		@name = name
		@prev_id = prev_id
  end
end

