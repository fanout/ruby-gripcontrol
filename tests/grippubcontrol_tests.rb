require 'grippubcontrol'
require 'httpresponseformat'
require 'httpstreamformat'
require 'base64'
require 'minitest/autorun'

class GripPubControlTestClass < GripPubControl
  attr_accessor :was_finish_called
  attr_accessor :publish_channel
  attr_accessor :publish_item
  attr_accessor :publish_callback

  def initialize
    @was_finish_called = false
    @publish_channel = nil
    @publish_item = nil
    @publish_callback = nil
  end

  def finish
    @was_finish_called = true
  end

  def super_publish(channel, item)
    @publish_channel = channel
    @publish_item = item
  end

  def super_publish_async(channel, item, callback=nil)
    @publish_channel = channel
    @publish_item = item
    @publish_callback = callback
  end
end

class TestGripPubControl < Minitest::Test
  def test_initialize
    pc = GripPubControl.new
    assert_equal(pc.instance_variable_get(:@clients).length, 0)
    config = {'control_uri' => 'uri', 'control_iss' => 'iss', 'key' => 'key'}
    pc = GripPubControl.new(config)
    assert_equal(pc.instance_variable_get(:@clients).length, 1)
    config = [{'control_uri' => 'uri', 'control_iss' => 'iss', 'key' => 'key'},
        {'control_uri' => 'uri', 'control_iss' => 'iss', 'key' => 'key'}]
    pc = GripPubControl.new(config)
    assert_equal(pc.instance_variable_get(:@clients).length, 2)
  end

  def test_apply_grip_config
    pc = GripPubControl.new
    config = {'control_uri' => 'uri'}
    pc.apply_grip_config(config)
    assert_equal(pc.instance_variable_get(
        :@clients)[0].instance_variable_get(:@uri), 'uri')
    pc = GripPubControl.new
    config = [{'control_uri' => 'uri'},
        {'control_uri' => 'uri1', 'control_iss' => 'iss1', 'key' => 'key1'},
        {'control_uri' => 'uri2', 'control_iss' => 'iss2', 'key' => 'key2'}]
    pc.apply_grip_config(config)
    assert_equal(pc.instance_variable_get(
        :@clients)[0].instance_variable_get(:@uri), 'uri')
    assert_equal(pc.instance_variable_get(
        :@clients)[0].instance_variable_get(:@auth_jwt_claim), nil)
    assert_equal(pc.instance_variable_get(
        :@clients)[0].instance_variable_get(:@auth_jwt_key), nil)
    assert_equal(pc.instance_variable_get(
        :@clients)[1].instance_variable_get(:@uri), 'uri1')
    assert_equal(pc.instance_variable_get(
        :@clients)[1].instance_variable_get(:@auth_jwt_claim),
        {'iss' => 'iss1'})
    assert_equal(pc.instance_variable_get(
        :@clients)[1].instance_variable_get(:@auth_jwt_key), 'key1')
    assert_equal(pc.instance_variable_get(
        :@clients)[2].instance_variable_get(:@uri), 'uri2')
    assert_equal(pc.instance_variable_get(
        :@clients)[2].instance_variable_get(:@auth_jwt_claim),
        {'iss' => 'iss2'})
    assert_equal(pc.instance_variable_get(
        :@clients)[2].instance_variable_get(:@auth_jwt_key), 'key2')
  end

  def test_publish_http_response_string
    pc = GripPubControlTestClass.new
    pc.publish_http_response('channel', 'item', 'id')
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export,
        Item.new(HttpResponseFormat.new(nil, nil, nil, 'item'), 'id').export)
  end

  def test_publish_http_response_httpresponseformat
    pc = GripPubControlTestClass.new
    pc.publish_http_response('channel', HttpResponseFormat.new('code',
        'reason', 'headers', 'body'), 'id', 'prev-id')
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpResponseFormat.new(
        'code', 'reason', 'headers', 'body'), 'id', 'prev-id').export)
  end

  def test_publish_http_response_async_without_callback_string
    pc = GripPubControlTestClass.new
    pc.publish_http_response_async('channel', 'body', 'id')
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpResponseFormat.new(
        nil, nil, nil, 'body'), 'id').export)
    assert_equal(pc.publish_callback, nil)
  end

  def test_publish_http_response_async_without_callback_format
    pc = GripPubControlTestClass.new
    pc.publish_http_response_async('channel', HttpResponseFormat.new('code',
        'reason', 'headers', 'body'))
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpResponseFormat.new(
        'code', 'reason', 'headers', 'body')).export)
    assert_equal(pc.publish_callback, nil)
  end

  def callback_for_testing(result, error)
    assert_equal(@has_callback_been_called, false)
    assert_equal(result, false)
    assert_equal(error, 'error')
    @has_callback_been_called = true
  end

  def test_publish_http_response_async_with_callback_string
    @has_callback_been_called = false
    pc = GripPubControlTestClass.new
    pc.publish_http_response_async('channel', HttpResponseFormat.new('code',
        'reason', 'headers', 'body'), 'id', 'prev-id', method(:callback_for_testing))
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpResponseFormat.new(
        'code', 'reason', 'headers', 'body'), 'id', 'prev-id').export)
    pc.publish_callback.call(false, 'error')
    assert(@has_callback_been_called)
  end

  def test_publish_http_response_async_with_callback_format
    @has_callback_been_called = false
    pc = GripPubControlTestClass.new
    pc.publish_http_response_async('channel', HttpResponseFormat.new('code',
        'reason', 'headers', 'body'), nil, nil, method(:callback_for_testing))
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpResponseFormat.new(
        'code', 'reason', 'headers', 'body')).export)
    pc.publish_callback.call(false, 'error')
    assert(@has_callback_been_called)
  end

  def test_publish_http_stream_string
    pc = GripPubControlTestClass.new
    pc.publish_http_stream('channel', 'item', nil, 'prev-id')
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpStreamFormat.new(
        'item'), nil, 'prev-id').export)
  end

  def test_publish_http_stream_httpstreamformat
    pc = GripPubControlTestClass.new
    pc.publish_http_stream('channel', HttpStreamFormat.new(nil, true))
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpStreamFormat.new(
        nil, true)).export)
  end

  def test_publish_http_stream_async_without_callback_string
    pc = GripPubControlTestClass.new
    pc.publish_http_stream('channel', 'item', nil, 'prev-id')
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpStreamFormat.new(
        'item'), nil, 'prev-id').export)
    assert_equal(pc.publish_callback, nil)
  end

  def test_publish_http_stream_async_without_callback_format
    pc = GripPubControlTestClass.new
    pc.publish_http_stream_async('channel', HttpStreamFormat.new(nil, true))
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpStreamFormat.new(
        nil, true)).export)
    assert_equal(pc.publish_callback, nil)
  end

  def test_publish_http_stream_async_with_callback_string
    @has_callback_been_called = false
    pc = GripPubControlTestClass.new
    pc.publish_http_stream_async('channel', 'item', nil, 'prev-id',
        method(:callback_for_testing))
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpStreamFormat.new(
        'item'), nil, 'prev-id').export)
    pc.publish_callback.call(false, 'error')
    assert(@has_callback_been_called)
  end

  def test_publish_http_stream_async_with_callback_format
    @has_callback_been_called = false
    pc = GripPubControlTestClass.new
    pc.publish_http_stream_async('channel', HttpStreamFormat.new(nil, true),
        nil, nil, method(:callback_for_testing))
    assert_equal(pc.publish_channel, 'channel')
    assert_equal(pc.publish_item.export, Item.new(HttpStreamFormat.new(
        nil, true)).export)
    pc.publish_callback.call(false, 'error')
    assert(@has_callback_been_called)
  end
end
