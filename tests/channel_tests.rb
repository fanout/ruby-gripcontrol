require 'channel'
require 'base64'
require 'minitest/autorun'

class TestChannel < Minitest::Test
  def test_initialize
    channel = Channel.new('name')
    assert_equal(channel.name, 'name');
    assert_equal(channel.prev_id, nil);

    channel = Channel.new('name', 'prev-id')
    assert_equal(channel.name, 'name');
    assert_equal(channel.prev_id, 'prev-id');
  end
end
