#    gripcontrol.rb
#    ~~~~~~~~~
#    This module implements the GripControl class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'base64'
require 'jwt'
require_relative 'channel.rb'
require_relative 'httpresponseformat.rb'
require_relative 'httpstreamformat.rb'
require_relative 'websocketmessageformat.rb'
require_relative 'websocketevent.rb'
require_relative 'grippubcontrol.rb'

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
		  ichannels.push(ichannel)
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

  def self.create_hold_response(channels, response=nil)
	  return GripControl.create_hold('response', channels, response)
  end

  def self.create_hold_stream(channels, response=nil)
	  return create_hold('stream', channels, response)
  end

  def self.validate_sig(token, key)
		token = token.encode('utf-8')
	  begin
		  claim = JWT.encode(claim, @auth_jwt_key).decode(token, key,
          verify_expiration=false)
	  rescue
		  return false
    end
	  exp = claim.get('exp')
    if !claim.has_key?('exp')
      return false
    end
	  if Time.now.utc.to_i >= claim['exp']
		  return false
    end
	  return true
  end

  def self.decode_websocket_events(body)
	  out = []
	  start = 0
	  while start < body.length do
		  at = body.index('\r\n', start)
		  if !at.nil?
			  raise 'bad format'
      end
		  typeline = body[start..at - 1]
		  start = at + 2
		  at = typeline.index(' ')
		  if !at.nil?
			  etype = typeline[0..at - 1]
			  clen = ('0x' + typeline[at + 1..-1]).to_s(16)
			  content = body[start:start + clen - 1]
			  start += clen + 2
			  e = WebSocketEvent.new(etype, content)
		  else
			  e = WebSocketEvent.new(typeline)
      end
		  out.push(e)
    end
	  return out
  end

  def self.encode_websocket_events(events)
	  out = ''
    events.each do |event|
		  if !event.content.nil?
			  out += '%s %x\r\n%s\r\n' % [e.type, len(event.content), event.content]
		  else
			  out += '%s\r\n' % [e.type]
      end
    end
	  return out
  end

  def self.websocket_control_message(type, args=nil)
	  if !args.nil?
      # REVIEW: is this deep copy workaround effective in this case?
		  out = Marshal.load(Marshal.dump(args))
	  else
		  out = Hash.new
    end
	  out['type'] = type
	  return out.to_json
  end
end
