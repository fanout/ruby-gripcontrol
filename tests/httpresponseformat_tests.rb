require 'httpresponseformat'
require 'base64'
require 'minitest/autorun'

class TestHttpResponseFormat < Minitest::Test
  def test_initialize
    format = HttpResponseFormat.new
    assert_equal(format.code, nil);
    assert_equal(format.reason, nil);
    assert_equal(format.headers, nil);
    assert_equal(format.body, nil);
    format = HttpResponseFormat.new('code', 'reason', 'headers', 'body')
    assert_equal(format.code, 'code');
    assert_equal(format.reason, 'reason');
    assert_equal(format.headers, 'headers');
    assert_equal(format.body, 'body');
  end

  def test_name
    format = HttpResponseFormat.new
    assert_equal(format.name, 'http-response');
  end

  def test_export
    format = HttpResponseFormat.new
    assert_equal(format.export, {});
    format = HttpResponseFormat.new('code', 'reason', 'headers', 'body')
    assert_equal(format.export, {'code' => 'code', 'reason' => 'reason',
        'headers' => 'headers', 'body' => 'body'});
    format = HttpResponseFormat.new('code', 'reason', 'headers',
        'body'.force_encoding('ASCII-8BIT'))
    assert_equal(format.export, {'code' => 'code', 'reason' => 'reason',
        'headers' => 'headers', 'body-bin' => Base64.encode64('body')});
  end
end
