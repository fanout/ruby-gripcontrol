#    channel.rb
#    ~~~~~~~~~
#    This module implements the Channel class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

# The Channel class is used to represent a channel in for a GRIP proxy and
# tracks the previous ID of the last message.
class Channel
  attr_accessor :name
  attr_accessor :prev_id

  # Initialize with the channel name and an optional previous ID.
  def initialize(name, prev_id=nil)
    @name = name
    @prev_id = prev_id
  end
end

