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

```Ruby
require 'gripcontrol'

grippubcontrol = GripPubControl.new({ 
    'uri' => 'https://api.fanout.io/realm/<myrealm>',
    'iss' => '<myrealm>'}
    'key' => Base64.decode64('<myrealmkey>')})
grippubcontrol.publish_http_response('<channel>', 'Test publish!')
```
