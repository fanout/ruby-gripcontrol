require 'base64'
require 'pubcontrol'

class Channel
	def initialize(name, prev_id=nil)
		@name = name
		@prev_id = prev_id
  end
end

class Response
	def initialize(code=nil, reason=nil, headers=nil, body=nil)
		@code = code
		@reason = reason
		@headers = headers
		@body = body
  end
end

class HttpResponseFormat < Format
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
      # REVIEW is this the right way to check for binary encoding?
			if @body.encoding.name == 'ASCII-8BIT'
				out['body-bin'] = Base64.encode64(@body)
			else
				out['body'] = @body
      end
    end
		return out
  end
end

class HttpStreamFormat < Format
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

class WebSocketMessageFormat(Format)
	def initialize(content)
		@content = content
  end

	def name
		return 'ws-message'
  end

	def export
		out = Hash.new
			if @content.encoding.name == 'ASCII-8BIT'
				out['body-bin'] = Base64.encode64(@content)
			else
				out['body'] = @content
      end
		return out
  end
end

class WebSocketEvent
	def initialize(type, content=nil)
		@type = type
		@content = content
  end
end

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
			http_response = HttpStreamFormat.new(nil, nil, nil, http_stream)
    end
		item = Item.new(http_stream, id, prev_id)
		super_publish(channel, item)
  end

	def publish_http_stream_async(channel, http_stream, id=nil, prev_id=nil, callback=nil)
		if http_stream.is_a?(String)
			http_response = HttpStreamFormat.new(nil, nil, nil, http_stream)
    end
		item = Item.new(http_stream, id, prev_id)	
		super_publish_async(channel, item, callback)
  end
end

class GripControl
  def self.create_hold(mode, channels, response)
	  hold = Hash.new
	  hold['mode'] = mode
	  if channels.is_a?(Channel)
		  channels = [channels]
	  elsif channels.is_a?(String)
		  channels = [Channel.new(channels)]
    end
	  raise 'channels.length equal to 0' unless channels.length > 0
	  ichannels = []
    channels.each do |channel|
	    if channel.is_a?(String)
			  channel = Channel(channel)
      end
		  ichannel = Hash.new
		  ichannel['name'] = channel.name
		  if !channel.prev_id.nil?
			  ichannel['prev-id'] = channel.prev_id
      end
		  ichannels.append(ichannel)
    end
	  hold['channels'] = ichannels
	  iresponse = nil
	  if !response.nil?
		  if response.is_a?(String)
			  response = Response(nil, nil, nil, response)
      end
		  iresponse = Hash.new
		  if !response.code.nil?
			  iresponse['code'] = response.code
      end
		  if !response.reason.nil?
			  iresponse['reason'] = response.reason
      end
		  if !response.headers.nil? and response.headers.length > 0
			  iresponse['headers'] = response.headers
      end
		  if !response.body.nil?
			  if response.body.encoding.name == 'ASCII-8BIT'
				  iresponse['body'] = response.body
			  else
				  iresponse['body-bin'] = Base64.encode64(response.body)
        end
      end
    end
	  instruct = Hash.new
	  instruct['hold'] = hold
	  if !iresponse.nil?
		  instruct['response'] = iresponse
    end
	  return instruct.to_json
  end

  def create_hold_response(channels, response=nil)
	  return create_hold('response', channels, response)

  def create_hold_stream(channels, response=nil)
	  return create_hold('stream', channels, response)

  def validate_sig(token, key)
	  # jwt expects the token in utf-8
	  if isinstance(token, unicode)
		  token = token.encode('utf-8')

	  try
		  claim = jwt.decode(token, key, verify_expiration=false)
	  except
		  return false

	  exp = claim.get('exp')
	  if not exp
		  return false

	  if Time.now.utc.to_i >= exp
		  return false

	  return true

  def decode_websocket_events(body)
	  out = list()
	  start = 0
	  while start < len(body)
		  at = body.find('\r\n', start)
		  if at == -1
			  raise ValueError('bad format')
		  typeline = body[startat]
		  start = at + 2

		  at = typeline.find(' ')
		  if at != -1
			  etype = typeline[at]
			  clen = int('0x' + typeline[at + 1], 16)
			  content = body[startstart + clen]
			  start += clen + 2
			  e = WebSocketEvent(etype, content)
		  else
			  e = WebSocketEvent(typeline)

		  out.append(e)

	  return out

  def encode_websocket_events(events)
	  out = ''
	  for e in events
		  if e.content is not nil
			  out += '%s %x\r\n%s\r\n' % (e.type, len(e.content), e.content)
		  else
			  out += '%s\r\n' % e.type
	  return out

  def websocket_control_message(type, args=nil)
	  if args
		  out = deepcopy(args)
	  else
		  out = dict()
	  out['type'] = type
	  return json.dumps(out)
end
