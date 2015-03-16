require 'httpstreamformat'
require 'base64'
require 'minitest/autorun'

class TestHttpStreamFormat < Minitest::Test
  def test_initialize
    format = HttpStreamFormat.new('content')
    assert_equal(format.content, 'content');
    assert_equal(format.close, false);
    format = HttpStreamFormat.new(nil, true)
    assert_equal(format.content, nil);
    assert_equal(format.close, true);
    was_exception_raised = false
    begin 
      HttpStreamFormat.new        
    rescue => e
      was_exception_raised = true
    end
    assert(was_exception_raised)
  end

  def test_name
    format = HttpStreamFormat.new('content')
    assert_equal(format.name, 'http-stream');
  end

  def test_export
    format = HttpStreamFormat.new(nil, true)
    assert_equal(format.export, {'action' => 'close'});
    format = HttpStreamFormat.new("body\u2713")
    assert_equal(format.export, {'content' => "body\u2713"});
    # Verify non-UTF8 data passed as the body is exported as content-bin
    format = HttpStreamFormat.new(["d19b86"].pack('H*'))
    assert_equal(format.export, {'content-bin' => Base64.encode64(
        ["d19b86"].pack('H*'))});
  end
end
