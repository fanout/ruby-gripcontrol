ruby-gripcontrol
================

Author: Konstantin Bokarius <kon@fanout.io>

A GRIP library for Ruby.

License
-------

ruby-gripcontrol is offered under the MIT license. See the LICENSE file.

Installation
------------

```sh
gem install gripcontrol
```

Usage
-----

Long polling instruction using the WEBrick gem:

```Ruby
require 'webrick'
require 'gripcontrol'

class GripHeadersResponse < WEBrick::HTTPServlet::AbstractServlet
 def do_GET(request, response)
   response.status = 200
   response['Grip-Hold'] = 'response'
   response['Grip-Channel'] = 
       GripControl.create_grip_channel_header('<channel>')
 end
end

server = WEBrick::HTTPServer.new(:Port => 80)
server.mount "/", GripHeadersResponse
trap "INT" do server.shutdown end
server.start
```

Publishing:

```Ruby
require 'gripcontrol'

def callback(result, message)
  if result
    puts 'Publish successful'
  else
    puts 'Publish failed with message: ' + message.to_s
  end
end

# GripPubControl can be initialized with or without an endpoint
# configuration. Each endpoint can include optional JWT authentication info.
# Multiple endpoints can be included in a single configuration.

grippub = GripPubControl.new({ 
    'control_uri' => 'https://api.fanout.io/realm/<myrealm>',
    'control_iss' => '<myrealm>'}
    'key' => Base64.decode64('<myrealmkey>')})

# Add new endpoints by applying an endpoint configuration:
grippub.apply_grip_config([{'uri' => '<myendpoint_uri_1>'}, 
    {'uri' => '<myendpoint_uri_2>'}])

# Remove all configured endpoints:
grippub.remove_all_clients

# Explicitly add an endpoint as a PubControlClient instance:
pubclient = PubControlClient.new('<myendpoint_uri'>)
# Optionally set JWT auth: pubclient.set_auth_jwt('<claim>', '<jkey>')
# Optionally set basic auth: pubclient.set_auth_basic('<user>', '<password>')
grippub.add_client(pubclient)

# Publish across all configured endpoints:
grippub.publish_http_response('<channel>', 'Test publish!')
grippub.publish_http_response_async('<channel>', 'Test async publish!')
grippub.publish_http_stream('<channel>', 'Test publish!')
grippub.publish_http_stream_async('<channel>', 'Test async publish!')

# Wait for all async publish calls to complete:
grippub.finish
```

Parse the GRIP URI to extract the URI, ISS, and key values:

```Ruby
config = GripControl.parse_grip_uri(
    'http://api.fanout.io/realm/<myrealm>?iss=<myrealm>' 
    '&key=base64:<myrealmkey>')
```

Validate the Grip-Sig request header from incoming GRIP messages. This ensures that the message was sent from a valid source and is not expired. Note that when using Fanout.io the key is the realm key, and when using Pushpin the key is configurable in Pushpin's settings.

```Ruby
is_valid = GripControl.validate_sig(request['Grip-Sig'], '<key>')
```
