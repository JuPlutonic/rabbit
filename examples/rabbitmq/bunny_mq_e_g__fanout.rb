#!/usr/bin/env ruby
# frozen_string_literal: true

####### USE-CASES
# MMO games, sport sites, that distribute score updates to mobile clients
# configuration updates, AMQP messaging but XMPP is
# better bec' build-in concept of presence (Stop, what about Nack msg-s?).

require 'bunny'

puts '=> Fanout exchange routing'
puts

conn = Bunny.new
conn.start

ch = conn.create_channel
####### VARIANT I
#    Using the Bunny::Channel#fanout method
# x    = ch.fanout('activity.events')

####### VARIANT II
#    Instantiate Bunny::Exchange directly
# x    = Bunny::Exchange.new(ch, :fanout, 'activity.events')
x = ch.fanout('examples.pings')

10.times do
  q = ch.queue('', auto_delete: true).bind(x)
  q.subscribe do |_delivery_info, _properties, payload|
    puts "[consumer] #{q.name} received a message: #{payload}"
  end
end

x.publish('Ping')

sleep 0.5
x.delete
puts 'Disconnecting...'
conn.close
