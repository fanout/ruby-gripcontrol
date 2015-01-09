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

grippubcontrol = GripPubControl.new({ 
    'uri' => 'https://api.fanout.io/realm/<myrealm>',
    'iss' => '<myrealm>'}
    'key' => Base64.decode64('<myrealmkey>')})
grippubcontrol.publish_http_response('<channel>', 'Test publish!')
```
