# frozen_string_literal: true

# require 'rubygems'
require 'rexml/document'
require 'stomp'

# Uses Stomp client to consume messages
client = Stomp::Client.new
# Subscribes to queue, consumes each message
client.subscribe('/queue/errors') do |message|
  # puts message.body
  # Parses the XML message body
  xml = REXML::Document.new(message.body)

  # Prints text value of various elements
  puts "Error: #{xml.elements['error/type'].text}"
  puts xml.elements['error/message'].text
  puts xml.elements['error/backtrace'].text
  puts
end

# Join the listener thread
client.join
