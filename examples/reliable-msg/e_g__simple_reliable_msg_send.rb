# frozen_string_literal: true

# 1st run in terminal `gem install reliable-msg`
# 2nd run `queues manager start` - this client
#   relays on DRb what was designed to make RPC calls between objects running
#   on different machines and for interprocess communication

# require 'rubygems'
require 'reliable-msg'

# Pushes message
# to ruby queue
queue = ReliableMsg::Queue.new 'ruby'
queue.put 'Hello.'
# Consumes
# message,
# prints it
msg = queue.get
puts msg.object
# => "Hello."

# message = Marshal::dump(message) - it is under the hood of the .put method
# and it means what where's no need in serialization of other formats e.g. XML.
