ruby-gripcontrol
================

Author: Konstantin Bokarius <bokarius@comcast.net>

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

```Ruby
require 'gripcontrol'

# django: HttpResponse.new(http_body, content_type='application/grip-instruct')
http_body = GripControl.create_hold_response('<channel>')
grippubcontrol = GripPubControl.new('https://api.fanout.io/realm/<myrealm>')
grippubcontrol.set_auth_jwt({'iss' => '<myrealm>'}, 
    Base64.decode64('<myrealmkey>'))
grippubcontrol.publish_http_response('<channel>', 'Test publish!\n')
```
