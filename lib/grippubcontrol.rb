#    grippubcontrol.rb
#    ~~~~~~~~~
#    This module implements the GripPubControl class.
#    :authors: Konstantin Bokarius.
#    :copyright: (c) 2015 by Fanout, Inc.
#    :license: MIT, see LICENSE for more details.

require 'pubcontrol'

# The GripPubControl class allows consumers to easily publish HTTP response
# and HTTP stream format messages to GRIP proxies. Configuring GripPubControl
# is slightly different from configuring PubControl in that the 'uri' and
# 'iss' keys in each config entry should have a 'control_' prefix.
# GripPubControl inherits from PubControl and therefore also provides all
# of the same functionality.
class GripPubControl < PubControl
  alias super_add_client add_client
  alias super_publish publish
  alias super_publish_async publish_async

  # Initialize with or without a configuration. A configuration can be applied
  # after initialization via the apply_grip_config method.
  def initialize(config=nil)
    @clients = Array.new
    if !config.nil?
      apply_grip_config(config)
    end
  end

  # Apply the specified configuration to this GripPubControl instance. The
  # configuration object can either be a hash or an array of hashes where
  # each hash corresponds to a single PubControlClient instance. Each hash
  # will be parsed and a PubControlClient will be created either using just
  # a URI or a URI and JWT authentication information.
  def apply_grip_config(config)
    if !config.is_a?(Array)
      config = [config]
    end
    config.each do |entry|
      if !entry.key?('control_uri')
        next
      end
      client = PubControlClient.new(entry['control_uri'])
      if entry.key?('control_iss')
        client.set_auth_jwt({'iss' => entry['control_iss']}, entry['key'])
      elsif entry.key?('key')
        client.set_auth_bearer(entry['key'])
      end
      super_add_client(client)
    end
  end

  # Synchronously publish an HTTP response format message to all of the
  # configured PubControlClients with a specified channel, message, and
  # optional ID and previous ID. Note that the 'http_response' parameter can
  # be provided as either an HttpResponseFormat instance or a string (in which
  # case an HttpResponseFormat instance will automatically be created and
  # have the 'body' field set to the specified string).
  def publish_http_response(channel, http_response, id=nil, prev_id=nil)
    if http_response.is_a?(String)
      http_response = HttpResponseFormat.new(nil, nil, nil, http_response)
    end
    item = Item.new(http_response, id, prev_id)
    super_publish(channel, item)
  end

  # Asynchronously publish an HTTP response format message to all of the
  # configured PubControlClients with a specified channel, message, and
  # optional ID, previous ID, and callback. Note that the 'http_response'
  # parameter can be provided as either an HttpResponseFormat instance or
  # a string (in which case an HttpResponseFormat instance will automatically
  # be created and have the 'body' field set to the specified string). When
  # specified, the callback method will be called after publishing is complete
  # and passed a result and error message (if an error was encountered).
  def publish_http_response_async(channel, http_response, id=nil,
      prev_id=nil, callback=nil)
    if http_response.is_a?(String)
      http_response = HttpResponseFormat.new(nil, nil, nil, http_response)
    end
    item = Item.new(http_response, id, prev_id)
    super_publish_async(channel, item, callback)
  end

  # Synchronously publish an HTTP stream format message to all of the
  # configured PubControlClients with a specified channel, message, and
  # optional ID and previous ID. Note that the 'http_stream' parameter can
  # be provided as either an HttpStreamFormat instance or a string (in which
  # case an HttStreamFormat instance will automatically be created and
  # have the 'content' field set to the specified string).
  def publish_http_stream(channel, http_stream, id=nil, prev_id=nil)
    if http_stream.is_a?(String)
      http_stream = HttpStreamFormat.new(http_stream)
    end
    item = Item.new(http_stream, id, prev_id)
    super_publish(channel, item)
  end

  # Asynchronously publish an HTTP stream format message to all of the
  # configured PubControlClients with a specified channel, message, and
  # optional ID, previous ID, and callback. Note that the 'http_stream'
  # parameter can be provided as either an HttpStreamFormat instance or
  # a string (in which case an HttpStreamFormat instance will automatically
  # be created and have the 'content' field set to the specified string). When
  # specified, the callback method will be called after publishing is complete
  # and passed a result and error message (if an error was encountered).
  def publish_http_stream_async(channel, http_stream, id=nil,
      prev_id=nil, callback=nil)
    if http_stream.is_a?(String)
      http_stream = HttpStreamFormat.new(http_stream)
    end
    item = Item.new(http_stream, id, prev_id)  
    super_publish_async(channel, item, callback)
  end
end
