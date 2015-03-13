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
    format = HttpStreamFormat.new('content')
    assert_equal(format.export, {'content' => 'content'});
    format = HttpStreamFormat.new('content'.force_encoding('ASCII-8BIT'))
    assert_equal(format.export, {'content-bin' => Base64.encode64('content')});
  end
end
