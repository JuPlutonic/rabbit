#!/usr/bin/ruby
# frozen_string_literal: true

# Listen to exchange from args
#           queue, channel and routing key
# replies are seen in the terminal.

require 'bundler/setup'
require 'pathname'
require 'bunny'
require 'logger'
require 'yaml'
require 'optparse'
require 'msgpack'
require 'zlib'
require 'json'
require_relative '../app/app'
App.config!
require_relative '../app/monkeys'

cfg = {
  mq: Cfg.mq.main.conn.symbolize_keys,
  x: Cfg.mq.main.x.symbolize_keys,
  q: { name: 'amqp_listener', opts: { durable: false } },
  output: $stdout,
  listen_key: 'main.reply'
}

OptionParser.new do |opts|
  opts.banner = "#{$PROGRAM_NAME} [options]"
  opts.on('-h', '--help', '') { puts opts; exit }
  opts.on('-a', '--host ADDRESS', "host (#{cfg[:mq][:host]})") { |v| cfg[:mq][:host] = v }
  opts.on('-p', '--port N', "port (#{cfg[:mq][:port]})") { |v| cfg[:mq][:port] = v }
  opts.on('-v', '--vhost NAME', "vhost (#{cfg[:mq][:vhost]})") { |v| cfg[:mq][:vhost] = v }
  opts.on('-u', '--username USERNAME', "(#{cfg[:mq][:user]})") { |v| cfg[:mq][:user] = v }
  opts.on('-w', '--password PASSWORD', "(#{cfg[:mq][:password]})") { |v| cfg[:mq][:password] = v }
  opts.on('-k', '--routing_key KEY', "listen to routing key (#{cfg[:listen_key]})") { |v| cfg[:listen_key] = v }
  opts.on('-s', '--[no-]ssl', "need ssl? (#{cfg[:mq][:ssl]})") { |ssl| cfg[:mq][:ssl] = ssl }
  opts.on('-x', '--exchange NAME', "exchange (#{cfg[:x][:name]})") { |v| cfg[:x][:name] = v }
  opts.on('-t', '--xtype TYPE', "exchange type (#{cfg[:x][:opts][:type]})") { |v| cfg[:x][:opts][:type] = v }
  opts.on('-e', '--[no-]exchange-autodelete', "exchange auto delete flag (#{cfg[:x][:opts][:auto_delete]})") { |v| cfg[:x][:opts][:auto_delete] = v }
  opts.on('-d', '--[no-]exchange-durable', "exchange durable flag (#{cfg[:x][:opts][:durable]})") { |v| cfg[:x][:opts][:durable] = v }
  opts.on('-q', '--queue NAME', "queue (#{cfg[:q][:name]})") { |v| cfg[:q][:name] = v }
  opts.on('-l', '--[no-]queue-durable', "queue is durable? (#{cfg[:q][:opts][:durable]})") { |v| cfg[:q][:opts][:durable] = v }
  opts.on('-f', '--file FILENAME', "print to file (#{cfg[:output].class.name})") do |v|
    if Pathname.new(v).dirname.exist?
      cfg[:output] = File.new(v, 'w')
    else
      raise "#{v} doesn't exist'!"
    end
  end
end.parse!

puts 'Connection settings:'
pp cfg
puts '-------------'

(rabbit  = Bunny.new(cfg[:mq])).start
queue    = (channel = rabbit.create_channel).queue(cfg[:q][:name], cfg[:q][:opts])
exchange = channel.exchange(cfg[:x][:name], cfg[:x][:opts])
queue.bind(exchange, routing_key: cfg[:listen_key])
consumer = queue.subscribe(block: true) do |di, props, body|
  # Object types: meta Bunny::DeliveryInfo; headers Bunny::MessageProperties; body: String.
  data = {}
  if props.content_type == 'application/msgpack'
    data = MessagePack.unpack(body)
    content = Zlib::Inflate.inflate data['Content']
    content.force_encoding 'UTF-8'
    diff = Zlib::Inflate.inflate data['Diff']
    diff.force_encoding 'UTF-8'
    cfg[:output].write <<~EINSPECT
      B-----
      #{Time.now.strftime '%H:%M:%S:%L'}
      meta: #{di.inspect}
      headers: #{props.inspect}
      body:
      --title
      #{data['Title']}
      #{data['Timestamp']}
      #{data.dig('Revision', 'Old')} => #{data.dig('Revision', 'New')}
      #{data['User']}
      #{data['Namespace']}
      --content:
      #{content}

      --diff:
      #{diff}
       E-----
    EINSPECT
  elsif props.content_type == 'application/json'
    data = begin
             JSON.parse(body)
           rescue StandardError
             (data || '<<NIL>>')
           end
    props.app_id&.force_encoding('UTF-8')
    cfg[:output].write <<~EINSPECTJSON
      B-----
      #{Time.now.strftime '%H:%M:%S:%L'}
      meta: #{di.inspect}
      headers: #{props.inspect}
      body: ---
      #{data.inspect}
      E-----
    EINSPECTJSON
  end
end

cfg[:output].close
