#!/usr/bin/env ruby
# frozen_string_literal: true

# The routing is enabled by specifying
# a routing pattern to the Bunny::Queue#bind

####### Topics Exchange USE-CASES
# Topic exchanges are great for  multicast routing.
# Topic exchanges can be used for broadcast routing,
# but fanout exchanges are usually more efficient
#
# Three classic examples of topic-based routing
# are stock price updates, news updates and location-specific
# data (for instance, weather broadcasts),
# those behaviour similar to RSS-subscriptions with added filter
# pattern what indicates which topics are needed.
#
# In application layer some technics used to talk with topic exchanges:
# 1) tagging
# 2) categorization
# 3) various publish/subscribe pattern variations
#
# Also topic exchanges used in
# Background task processing done by multiple workers,
# each capable of handling specific set of tasks
# Orchestration of services of different kinds in the cloud
# Distributed architecture/OS-specific software builds or packaging
# where each builder can handle only one architecture or OS

####### Pattern # and * explanation
# The "#" part of the pattern matches 0 or more words.
# The following routing keys match the "americas.south.#" pattern:
#
#     americas.south
#     americas.south.brazil
#     americas.south.brazil.saopaolo
#     americas.south.chile.santiago
#
# The "*" part of the pattern matches 1 word only.
# For the pattern "americas.south.*", some matching routing keys are:
#
#     americas.south.brazil
#     americas.south.chile
#     americas.south.peru
#
# but not
#
#     americas.south
#     americas.south.chile.santiago
# rubybunny.info ©

require 'bunny'

connection = Bunny.new
connection.start

@channel = connection.create_channel

# Subscribers.

# topic exchange name can be any string
# x    = ch.topic('weather', auto_delete: true)
#
# q = ch.queue('americas.south', auto_delete: true)
#       .bind(x, routing_key: 'americas.south.#')
#
# q.subscribe do |delivery_info, _properties, payload|
#   puts "An update for South America: #{
#           payload
#         }, routing key is #{delivery_info.routing_key}"
# end

def topic_binding(dlvry_info, payload)
  yield("#{payload}, routing key is #{dlvry_info.routing_key}") if bloc_given?
end

def topic_and_puts_call(queue_name, key, place)
  @channel
    .queue(queue_name)
    .bind(exchange, routing_key: key)
    .subscribe do |delivery_info, _properties, payload|
    # do block, not intended
    topic_binding(
      delivery_info,
      payload
    ) { |yld| puts "An update for #{place}: #{yld}" }
    # end of do block
  end
end

topic_and_puts_call('americas.north', 'americas.north.#', 'North America')
topic_and_puts_call('americas.south', 'americas.south.#', 'South America')
topic_and_puts_call('us.california', 'americas.north.us.ca.*', 'US/California')
topic_and_puts_call('us.tx.austin', '#.tx.austin', 'Austin, TX')
topic_and_puts_call('it.rome', 'europe.italy.rome', 'Rome, Italy')
topic_and_puts_call('asia.hk', 'asia.southeast.hk.#', 'Hong Kong')

exchange
  .publish('San Diego update', routing_key: 'americas.north.us.ca.sandiego')
  .publish('Berkeley update',  routing_key: 'americas.north.us.ca.berkeley')
  .publish('San Francisco update', routing_key: 'americas.north.us.ca.sanfrancisco')
  .publish('New York update',  routing_key: 'americas.north.us.ny.newyork')
  .publish('São Paolo update', routing_key: 'americas.south.brazil.saopaolo')
  .publish('Hong Kong update', routing_key: 'asia.southeast.hk.hongkong')
  .publish('Kyoto update',     routing_key: 'asia.southeast.japan.kyoto')
  .publish('Shanghai update',  routing_key: 'asia.southeast.prc.shanghai')
  .publish('Rome update',      routing_key: 'europe.italy.roma')
  .publish('Paris update',     routing_key: 'europe.france.paris')

sleep 1.0

connection.close
