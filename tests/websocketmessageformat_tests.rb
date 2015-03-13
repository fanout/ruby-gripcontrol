require 'websocketmessageformat'
require 'base64'
require 'minitest/autorun'

class TestWebSocketMessageFormat < Minitest::Test
  def test_initialize
    format = WebSocketMessageFormat.new('content')
    assert_equal(format.content, 'content');
    assert_equal(format.instance_variable_get(:@binary), false);
    format = WebSocketMessageFormat.new('content', true)
    assert_equal(format.content, 'content');
    assert_equal(format.instance_variable_get(:@binary), true);
  end

  def test_name
    format = WebSocketMessageFormat.new('content')
    assert_equal(format.name, 'ws-message');
  end

  def test_export
    format = WebSocketMessageFormat.new('content')
    assert_equal(format.export, {'content' => 'content'});
    format = WebSocketMessageFormat.new('content', true)
    assert_equal(format.export, {'content-bin' => Base64.encode64('content')});
  end
end
