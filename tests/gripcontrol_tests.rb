require 'gripcontrol'
require 'base64'
require 'minitest/autorun'
require 'json'
require 'jwt'

class TestGripControl < Minitest::Test    
  def test_create_hold
    assert_raises RuntimeError do 
      assert_raises(GripControl.create_hold('mode', [], 'response'))
    end
    hold = JSON.parse(GripControl.create_hold('mode', 'channel', Response.new(
        'code', 'reason', 'headers', 'body')))
    assert_equal(hold['hold'].key?('timeout'), false)
    assert_equal(hold['hold']['mode'], 'mode')
    assert_equal(hold['hold']['channels'], [{'name' => 'channel'}])
    assert_equal(hold['response'], {'code' => 'code',
        'reason' => 'reason', 'headers' => 'headers', 'body' => 'body'})
    # Verify non-UTF8 data passed as the body is exported as content-bin
    hold = JSON.parse(GripControl.create_hold('mode', 'channel', Response.new(
        'code', 'reason', 'headers', ["d19b86"].pack('H*'))))
    assert_equal(hold['hold']['mode'], 'mode')
    assert_equal(hold['response'], {'code' => 'code',
        'reason' => 'reason', 'headers' => 'headers', 'body-bin' =>
        Base64.encode64(["d19b86"].pack('H*'))})
    hold = JSON.parse(GripControl.create_hold('mode', 'channel', nil))
    assert_equal(hold['hold']['mode'], 'mode')
    assert_equal(hold.key?('response'), false)
    hold = JSON.parse(GripControl.create_hold('mode', 'channel', nil, 'timeout'))
    assert_equal(hold['hold']['mode'], 'mode')
    assert_equal(hold['hold']['timeout'], 'timeout')
  end

  def test_parse_grip_uri
    uri = 'http://api.fanout.io/realm/realm?iss=realm' +
        '&key=base64:geag121321='
    config = GripControl.parse_grip_uri(uri)
    assert_equal(config['control_uri'], 'http://api.fanout.io/realm/realm')
    assert_equal(config['control_iss'], 'realm')
    assert_equal(config['key'], Base64.decode64('geag121321='))
    uri = 'https://api.fanout.io/realm/realm?iss=realm' +
        '&key=base64:geag121321='
    config = GripControl.parse_grip_uri(uri)
    assert_equal(config['control_uri'], 'https://api.fanout.io:443/realm/realm')
    config = GripControl.parse_grip_uri('http://api.fanout.io/realm/realm')
    assert_equal(config['control_uri'], 'http://api.fanout.io/realm/realm')
    assert_equal(config.key?('control_iss'), false)
    assert_equal(config.key?('key'), false)
    uri = 'http://api.fanout.io/realm/realm?iss=realm' +
        '&key=base64:geag121321=&param1=value1&param2=value2'
    config = GripControl.parse_grip_uri(uri)
    assert_equal(config['control_uri'], 'http://api.fanout.io/realm/realm?' +
        'param1=value1&param2=value2')
    assert_equal(config['control_iss'], 'realm')
    assert_equal(config['key'], Base64.decode64('geag121321='))
    config = GripControl.parse_grip_uri('http://api.fanout.io:8080/realm/realm/')
    assert_equal(config['control_uri'], 'http://api.fanout.io:8080/realm/realm')
    uri = 'http://api.fanout.io/realm/realm?iss=realm' +
        '&key=geag121321='
    config = GripControl.parse_grip_uri(uri)
    assert_equal(config['key'], 'geag121321=')
  end

  def test_validate_sig
    token = JWT.encode({'iss' => 'realm', 'exp' => Time.now.utc.to_i + 3600},
        'key')
    assert(GripControl.validate_sig(token, 'key'))
    token = JWT.encode({'iss' => 'realm', 'exp' => Time.now.utc.to_i - 3600},
        'key')
    assert_equal(GripControl.validate_sig(token, 'key'), false) 
    token = JWT.encode({'iss' => 'realm', 'exp' => Time.now.utc.to_i + 3600},
        'key')
    assert_equal(GripControl.validate_sig(token, 'wrong_key'), false) 
  end

  def test_create_grip_channel_header
    assert_raises RuntimeError do 
      assert_raises(GripControl.create_grip_channel_header([]))
    end
    header = GripControl.create_grip_channel_header('channel')
    assert_equal(header, 'channel')
    header = GripControl.create_grip_channel_header(Channel.new('channel'))
    assert_equal(header, 'channel')
    header = GripControl.create_grip_channel_header(Channel.new('channel',
        'prev-id'))
    assert_equal(header, 'channel; prev-id=prev-id')
    header = GripControl.create_grip_channel_header([Channel.new('channel1',
        'prev-id1'), Channel.new('channel2', 'prev-id2')])
    assert_equal(header, 'channel1; prev-id=prev-id1, channel2; prev-id=prev-id2')
  end

  def test_create_hold_response
    hold = JSON.parse(GripControl.create_hold_response('channel', Response.new(
        'code', 'reason', 'headers', 'body')))
    assert_equal(hold['hold']['mode'], 'response')
    assert_equal(hold['hold'].key?('timeout'), false)
    assert_equal(hold['hold']['channels'], [{'name' => 'channel'}])
    assert_equal(hold['response'], {'code' => 'code',
        'reason' => 'reason', 'headers' => 'headers', 'body' => 'body'})
    hold = JSON.parse(GripControl.create_hold_response('channel', nil, 'timeout'))
    assert_equal(hold['response'], nil)
    assert_equal(hold['hold']['mode'], 'response')
    assert_equal(hold['hold']['timeout'], 'timeout')
  end

  def test_create_hold_stream
    hold = JSON.parse(GripControl.create_hold_stream('channel', Response.new(
        'code', 'reason', 'headers', 'body')))
    assert_equal(hold['hold']['mode'], 'stream')
    assert_equal(hold['hold'].key?('timeout'), false)
    assert_equal(hold['hold']['channels'], [{'name' => 'channel'}])
    assert_equal(hold['response'], {'code' => 'code',
        'reason' => 'reason', 'headers' => 'headers', 'body' => 'body'})
    hold = JSON.parse(GripControl.create_hold_stream('channel', nil))
    assert_equal(hold['response'], nil)
    assert_equal(hold['hold']['mode'], 'stream')
  end

  def test_decode_websocket_events
    events = GripControl.decode_websocket_events("OPEN\r\nTEXT 5\r\nHello" + 
        "\r\nTEXT 0\r\n\r\nCLOSE\r\nTEXT\r\nCLOSE\r\n")
    assert_equal(events.length, 6)
    assert_equal(events[0].type, 'OPEN')
    assert_equal(events[0].content, nil)
    assert_equal(events[1].type, 'TEXT')
    assert_equal(events[1].content, 'Hello')
    assert_equal(events[2].type, 'TEXT')
    assert_equal(events[2].content, '')
    assert_equal(events[3].type, 'CLOSE')
    assert_equal(events[3].content, nil)
    assert_equal(events[4].type, 'TEXT')
    assert_equal(events[4].content, nil)
    assert_equal(events[5].type, 'CLOSE')
    assert_equal(events[5].content, nil)
    events = GripControl.decode_websocket_events("OPEN\r\n")
    assert_equal(events.length, 1)
    assert_equal(events[0].type, 'OPEN')
    assert_equal(events[0].content, nil)
    events = GripControl.decode_websocket_events("TEXT 5\r\nHello\r\n")
    assert_equal(events.length, 1)
    assert_equal(events[0].type, 'TEXT')
    assert_equal(events[0].content, 'Hello')
    assert_raises RuntimeError do 
      GripControl.decode_websocket_events("TEXT 5")
    end
    assert_raises RuntimeError do 
      GripControl.decode_websocket_events("OPEN\r\nTEXT")
    end
  end

  def test_encode_websocket_events  
    events = GripControl.encode_websocket_events([
        WebSocketEvent.new("TEXT", "Hello"), 
        WebSocketEvent.new("TEXT", ""),
        WebSocketEvent.new("TEXT", nil)])
    assert_equal(events, "TEXT 5\r\nHello\r\nTEXT 0\r\n\r\nTEXT\r\n")
    events = GripControl.encode_websocket_events([WebSocketEvent.new("OPEN")])
    assert_equal(events, "OPEN\r\n")
  end

  def test_websocket_control_message
    message = GripControl.websocket_control_message('type')
    assert_equal(message, '{"type":"type"}')
    message = JSON.parse(GripControl.websocket_control_message('type', {'arg1' => 'val1',
        'arg2' => 'val2'}))
    assert_equal(message['type'], 'type')
    assert_equal(message['arg1'], 'val1')
    assert_equal(message['arg2'], 'val2')
  end

  def test_parse_channels
    channels = GripControl.parse_channels('channel')
    assert_equal(channels[0].name, 'channel')
    assert_equal(channels[0].prev_id, nil)
    channels = GripControl.parse_channels(Channel.new('channel'))
    assert_equal(channels[0].name, 'channel')
    assert_equal(channels[0].prev_id, nil)
    channels = GripControl.parse_channels(Channel.new('channel', 'prev-id'))
    assert_equal(channels[0].name, 'channel')
    assert_equal(channels[0].prev_id, 'prev-id')
    channels = GripControl.parse_channels([Channel.new('channel1', 'prev-id'),
        Channel.new('channel2')])
    assert_equal(channels[0].name, 'channel1')
    assert_equal(channels[0].prev_id, 'prev-id')
    assert_equal(channels[1].name, 'channel2')
    assert_equal(channels[1].prev_id, nil)
    assert_raises RuntimeError do 
      GripControl.parse_channels([])
    end
  end

  def test_get_hold_channels
    hold_channels = GripControl.get_hold_channels([Channel.new('channel')])
    assert_equal(hold_channels[0], {'name' => 'channel'})
    hold_channels = GripControl.get_hold_channels([
        Channel.new('channel', 'prev-id')])
    assert_equal(hold_channels[0], {'name' => 'channel', 'prev-id' =>
        'prev-id'})
    hold_channels = GripControl.get_hold_channels([
        Channel.new('channel1', 'prev-id1'), Channel.new('channel2', 'prev-id2')])
    assert_equal(hold_channels[0], {'name' => 'channel1', 'prev-id' =>
        'prev-id1'})
    assert_equal(hold_channels[1], {'name' => 'channel2', 'prev-id' =>
        'prev-id2'})
  end

  def test_get_hold_response
    response = GripControl.get_hold_response(nil)
    assert_equal(response, nil)
    response = GripControl.get_hold_response('body')
    assert_equal(response['body'], 'body')
    assert_equal(response.key?('code'), false)
    assert_equal(response.key?('reason'), false)
    assert_equal(response.key?('headers'), false)
    # Verify non-UTF8 data passed as the body is exported as content-bin
    response = GripControl.get_hold_response(["d19b86"].pack('H*'))
    assert_equal(response['body-bin'], Base64.encode64(["d19b86"].pack('H*')))
    response = GripControl.get_hold_response(Response.new('code', 'reason',
        {'header1' => 'val1'}, "body\u2713"))
    assert_equal(response['code'], 'code')
    assert_equal(response['reason'], 'reason')
    assert_equal(response['headers'], {'header1' => 'val1'})
    assert_equal(response['body'], "body\u2713")
    response = GripControl.get_hold_response(Response.new(nil, nil, {}, nil))
    assert_equal(response.key?('headers'), false)
    assert_equal(response.key?('body'), false)
    assert_equal(response.key?('reason'), false)
    assert_equal(response.key?('headers'), false)
  end
end
