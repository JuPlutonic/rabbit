#!/usr/bin/env ruby
# frozen_string_literal: true

# require 'rubygems'
require 'reliable-msg'

# Opens connection
# to orders queue
queue = ReliableMsg::Queue.new 'orders_queue'

# External while loop loops forever
while true
  while true
    # Processes each
    # message from queue
    # Breaks only internal while loop
    # when message are recieved
    break unless queue.get do |msg|
      msg.report!

      # If you had a Processor class...
      Processor.process! msg
      true
    end
  end
  sleep 10 # No messages? Hold on!
end

# Processor class to handle work orders
# …
