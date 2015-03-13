require 'websocketevent'
require 'minitest/autorun'

class TestWebSocketEvent < Minitest::Test
  def test_initialize
    event = WebSocketEvent.new('type')
    assert_equal(event.type, 'type');
    assert_equal(event.content, nil);
    event = WebSocketEvent.new('type', 'content')
    assert_equal(event.type, 'type');
    assert_equal(event.content, 'content');
  end
end
