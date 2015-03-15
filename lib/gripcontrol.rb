#    gripcontrol.rb
#    ~~~~~~~~~
#    This module implements the GripControl class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'base64'
require 'jwt'
require 'uri'
require 'cgi'
require_relative 'channel.rb'
require_relative 'httpresponseformat.rb'
require_relative 'httpstreamformat.rb'
require_relative 'websocketmessageformat.rb'
require_relative 'websocketevent.rb'
require_relative 'grippubcontrol.rb'
require_relative 'response.rb'

# The GripControl class provides functionality that is used in conjunction
# with GRIP proxies. This includes facilitating the creation of hold
# instructions for HTTP long-polling and HTTP streaming, parsing GRIP URIs
# into config objects, validating the GRIP-SIG header coming from GRIP
# proxies, creating GRIP channel headers, and also WebSocket-over-HTTP
# features such as encoding/decoding web socket events and generating
# control messages.
class GripControl

  # Create GRIP hold instructions for the specified mode, channels, response
  # and optional timeout value. The channel parameter can be specified as
  # either a string representing the channel name, a Channel instance or an
  # array of Channel instances. The response parameter can be specified as
  # either a string representing the response body or a Response instance.
  def self.create_hold(mode, channels, response, timeout=nil)
    hold = Hash.new
    hold['mode'] = mode
    channels = GripControl.parse_channels(channels)
    ichannels = GripControl.get_hold_channels(channels)
    hold['channels'] = ichannels
    if !timeout.nil?
      hold['timeout'] = timeout
    end
    iresponse = GripControl.get_hold_response(response)
    instruct = Hash.new
    instruct['hold'] = hold
    if !iresponse.nil?
      instruct['response'] = iresponse
    end
    return instruct.to_json
  end

  # Parse the specified GRIP URI into a config object that can then be passed
  # to the GripPubControl class. The URI can include 'iss' and 'key' JWT
  # authentication query parameters as well as any other required query string
  # parameters. The JWT 'key' query parameter can be provided as-is or in base64
  # encoded format.
  def self.parse_grip_uri(uri)
    uri = URI(uri)
    params = {}
    if (uri.query)
        params = CGI.parse(uri.query)
    end
    iss = nil
    key = nil
    if params.key?('iss')
      iss = params['iss'][0]
      params.delete('iss')
    end
    if params.key?('key')
      key = params['key'][0]
      params.delete('key')
    end
    if !key.nil? and key.start_with?('base64:')
      key = Base64.decode64(key[7..-1])
    end
    qs = []
    params.map do |name,values|
      values.map do |value|
        qs.push("#{CGI.escape name}=#{CGI.escape value}")
      end
    end
    qs = qs.join('&')
    path = uri.path
    if path.end_with?('/')
      path = path[0..-2]
    end
    port = ''
    if uri.port != 80
      port = ':' + uri.port.to_s
    end
    control_uri = uri.scheme + '://' + uri.host + port + path
    if !qs.nil? and !qs.empty?
      control_uri += '?' + qs
    end
    out = {'control_uri' => control_uri}
    if !iss.nil?
      out['control_iss'] = iss
    end
    if !key.nil?
      out['key'] = key
    end
    return out
  end

  # Validate the specified JWT token and key. This method is used to validate
  # the GRIP-SIG header coming from GRIP proxies such as Pushpin or Fanout.io.
  # Note that the token expiration is also verified.
  def self.validate_sig(token, key)
    token = token.encode('utf-8')
    begin
      claim = JWT.decode(token, key, true, {verify_expiration: false})
    rescue
      return false
    end
    if claim.length == 0 or !claim[0].key?('exp')
      return false
    end
    if Time.now.utc.to_i >= claim[0]['exp']
      return false
    end
    return true
  end

  # Create a GRIP channel header for the specified channels. The channels
  # parameter can be specified as a string representing the channel name,
  # a Channel instance, or an array of Channel instances. The returned GRIP
  # channel header is used when sending instructions to GRIP proxies via
  # HTTP headers.
  def self.create_grip_channel_header(channels)
    channels = parse_channels(channels)
    parts = []
    channels.each do |channel|
      s = channel.name
      if !channel.prev_id.nil?
        s += '; prev-id=%s' % [channel.prev_id]
      end
      parts.push(s)
    end
    return parts.join(', ')
  end

  # A convenience method for creating GRIP hold response instructions for HTTP
  # long-polling. This method simply passes the specified parameters to the
  # create_hold method with 'response' as the hold mode.
  def self.create_hold_response(channels, response=nil, timeout=nil)
    return GripControl.create_hold('response', channels, response, timeout)
  end

  # A convenience method for creating GRIP hold stream instructions for HTTP
  # streaming. This method simply passes the specified parameters to the
  # create_hold method with 'stream' as the hold mode.
  def self.create_hold_stream(channels, response=nil)
    return create_hold('stream', channels, response)
  end

  # Decode the specified HTTP request body into an array of WebSocketEvent
  # instances when using the WebSocket-over-HTTP protocol. A RuntimeError
  # is raised if the format is invalid.
  def self.decode_websocket_events(body)
    out = []
    start = 0
    while start < body.length do
      at = body.index("\r\n", start)
      if at.nil?
        raise 'bad format'
      end
      typeline = body[start..at - 1]
      start = at + 2
      at = typeline.index(' ')
      event = nil
      if !at.nil?
        etype = typeline[0..at - 1]
        clen = ('0x' + typeline[at + 1..-1]).to_i(16)
        content = body[start..start + clen - 1]
        start += clen + 2
        event = WebSocketEvent.new(etype, content)
      else
        event = WebSocketEvent.new(typeline)
      end
      out.push(event)
    end
    return out
  end

  # Encode the specified array of WebSocketEvent instances. The returned string
  # value should then be passed to a GRIP proxy in the body of an HTTP response
  # when using the WebSocket-over-HTTP protocol.
  def self.encode_websocket_events(events)
    out = ''
    events.each do |event|
      if !event.content.nil?
        out += "%s %x\r\n%s\r\n" % [event.type, event.content.length, 
            event.content]
      else
        out += "%s\r\n" % [event.type]
      end
    end
    return out
  end

  # Generate a WebSocket control message with the specified type and optional
  # arguments. WebSocket control messages are passed to GRIP proxies and
  # example usage includes subscribing/unsubscribing a WebSocket connection
  # to/from a channel.
  def self.websocket_control_message(type, args=nil)
    if !args.nil?
      out = Marshal.load(Marshal.dump(args))
    else
      out = Hash.new
    end
    out['type'] = type
    return out.to_json
  end

  private

  # Parse the specified parameter into an array of Channel instances. The
  # specified parameter can either be a string, a Channel instance, or
  # an array of Channel instances.
  def self.parse_channels(channels)
    if channels.is_a?(Channel)
      channels = [channels]
    elsif channels.is_a?(String)
      channels = [Channel.new(channels)]
    end
    raise 'channels.length equal to 0' unless channels.length > 0
    return channels
  end

  # Get an array of hashes representing the specified channels parameter. The
  # resulting array is used for creating GRIP proxy hold instructions.
  def self.get_hold_channels(channels)
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
    return ichannels
  end

  # Get a hash representing the specified response parameter. The
  # resulting hash is used for creating GRIP proxy hold instructions.
  def self.get_hold_response(response)
    iresponse = nil
    if !response.nil?
      if response.is_a?(String)
        response = Response.new(nil, nil, nil, response)
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
          iresponse['body-bin'] = Base64.encode64(response.body)
        else
          iresponse['body'] = response.body
        end
      end
    end
    return iresponse
  end
end
