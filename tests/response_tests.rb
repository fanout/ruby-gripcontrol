require 'response'
require 'minitest/autorun'

class TestResponseEvent < Minitest::Test
  def test_initialize
    response = Response.new
    assert_equal(response.code, nil);
    assert_equal(response.reason, nil);
    assert_equal(response.headers, nil);
    assert_equal(response.body, nil);
    response = Response.new('code', 'reason', 'headers', 'body')
    assert_equal(response.code, 'code');
    assert_equal(response.reason, 'reason');
    assert_equal(response.headers, 'headers');
    assert_equal(response.body, 'body');
  end
end
