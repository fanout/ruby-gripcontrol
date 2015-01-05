#    grippubcontrol.rb
#    ~~~~~~~~~
#    This module implements the GripPubControl class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'pubcontrol'

class GripPubControl < PubControl
  alias super_publish publish
  alias super_publish_async publish_async

	def publish_http_response(channel, http_response, id=nil, prev_id=nil)
		if http_response.is_a?(String)
			http_response = HttpResponseFormat.new(nil, nil, nil, http_response)
    end
		item = Item.new(http_response, id, prev_id)
		super_publish(channel, item)
  end

	def publish_http_response_async(channel, http_response, id=nil,
      prev_id=nil, callback=nil)
		if http_response.is_a?(String)
			http_response = HttpResponseFormat.new(nil, nil, nil, http_response)
    end
		item = Item.new(http_response, id, prev_id)
		super_publish_async(channel, item, callback)
  end

	def publish_http_stream(channel, http_stream, id=nil, prev_id=nil)
		if http_stream.is_a?(String)
			http_stream = HttpStreamFormat.new(http_stream)
    end
		item = Item.new(http_stream, id, prev_id)
		super_publish(channel, item)
  end

	def publish_http_stream_async(channel, http_stream, id=nil,
      prev_id=nil, callback=nil)
		if http_stream.is_a?(String)
			http_stream = HttpStreamFormat.new(http_stream)
    end
		item = Item.new(http_stream, id, prev_id)	
		super_publish_async(channel, item, callback)
  end
end
