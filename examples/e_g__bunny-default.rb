#!/usr/bin/env ruby

require 'bunny'

puts '=> Default or "" exchange routing (direct)'
puts
# This kind of routing is wide used inside
# applications with many workers

conn = Bunny.new
conn.start

ch = conn.create_channel
q  = ch.queue('bunny.examples.hello_world', auto_delete: true)
# the name of queue is also used by default exchange as
# routing key

q.subscribe do |_delivery_info, _properties, payload|
  puts "Received #{payload}"
end

q.publish('Hello!', routing_key: q.name)

sleep 1.0
conn.close
