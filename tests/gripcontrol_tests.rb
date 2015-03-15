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
    hold = JSON.parse(GripControl.create_hold('mode', 'channel', Response.new(
        'code', 'reason', 'headers', 'body'.force_encoding('ASCII-8BIT'))))
    assert_equal(hold['hold']['mode'], 'mode')
    assert_equal(hold['response'], {'code' => 'code',
        'reason' => 'reason', 'headers' => 'headers', 'body-bin' =>
        Base64.encode64('body')})
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
end
