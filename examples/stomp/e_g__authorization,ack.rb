# frozen_string_literal: true

# messaging using client-side acknowledgement:
message = nil

# client = Stomp::Client.new
# With authentication
client = Stomp::Client.new('username', 'pass', 'localhost', 13_333)
client.send '/queue/rb', 'Hi, Ruby!'
client.subscribe('/queue/rb', ack: 'client') { |msg| message = msg }
client.acknowledge message
