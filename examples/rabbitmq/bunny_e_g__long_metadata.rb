# frozen_string_literal: true

now = Time.now
conn = Bunny.new
conn.start

# Routing key can be '' but never be nil.
# It depends on type of exchange '' - default exchange

queue_name = ''
# exit if conn.exchange_exist?('logs.default')
x.publish('hello',
          routing_key: queue_name,
          app_id: 'bunny.example',
          priority: 8,
          type: 'kinda.checkin',
          # headers table keys can be anything
          headers: {
            coordinates: {
              latitude: 59.35,
              longitude: 18.066667
            },
            time: now,
            participants: 11,
            venue: 'Stockholm',
            true_field: true,
            false_field: false,
            nil_field: nil,
            ary_field: ['one', 2.0, 3, [{ 'abc': 123 }]]
          },
          timestamp: now.to_i,
          reply_to: 'a.sender',
          correlation_id: 'r-1',
          message_id: 'm-1')
