require 'gripcontrol'

def callback(result, message)
  if !result
    puts 'Publish failed with message: ' + message.to_s
  end    
end

pub = GripPubControl.new({
    'uri' => 'https://api.fanout.io/realm/' + ENV['FANOUT_REALM'],
    'iss' => ENV['FANOUT_REALM'],
    'key' => Base64.decode64(ENV['FANOUT_KEY'])
})
pub.publish_http_response('test', 'Test publish!')
index = 0
while index < 20 do
  pub.publish_http_response_async('test', 'Test publish!', nil, nil,
      method(:callback))
  index += 1
end
pub.finish
