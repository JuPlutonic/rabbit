#!/usr/bin/env ruby
# frozen_string_literal: true

####### Direct Exchange USE-CASES
#
# Supporting unicast routing of messages. Although this exchange
#  can be used for multicast (one-to-many-of-many or many-to-M-of-M) as well.
# Delivering geocast (points of sales) messages.
# Direct (near real-time) messages to individual MMO players.
# Distributing tasks between workers/instances (all having the same
# function, for example image processors).
# Passing data between workflow steps,
# each having an identifier (also consider using headers exchange).
# And delivering notifications to individual software services in the network.
#
# FYI. There are also anycast and broadcast(=fanout exchange) messages.

require 'bunny'

puts '=> Direct exchange routing'
puts

conn = Bunny.new
conn.start

ch   = conn.create_channel
####### VARIANT I
#    Using the Bunny::Channel#direct method
# x    = ch.direct('imaging')

####### VARIANT II
#    Instantiate Bunny::Exchange directly
# x    = Bunny::Exchange.new(ch, :direct, 'imaging')
x    = ch.direct('examples.imaging')

q1 = ch.queue('', auto_delete: true).bind(x, routing_key: 'resize')
q1.subscribe do |_delivery_info, _properties, _payload|
  puts "[consumer] #{q1.name} received a 'resize' message"
end
q2 = ch.queue('', auto_delete: true).bind(x, routing_key: 'watermark')
q2.subscribe do |_delivery_info, _properties, _payload|
  puts "[consumer] #{q2.name} received a 'watermark' message"
end

# just an example
data = rand.to_s
x.publish(data, routing_key: resize)
x.publish(data, routing_key: watermark)

x.publish('Ping')

sleep 0.5
x.delete
q1.delete
q2.delete

puts 'Disconnecting...'
conn.close
