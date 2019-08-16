#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'bunny'
require 'yaml'
require 'optparse'
require 'msgpack'
require 'zlib'
require 'json'
require 'pry-byebug'
require_relative '../app/app'
App.config!
require_relative '../app/monkeys'

cfg = {
  mq: Cfg.mq.main.conn.symbolize_keys,
  x: Cfg.mq.main.x.symbolize_keys,
  q: { name: 'amqp_publisher', opts: { durable: false } },
  output: $stdout,
  reply_to: 'main.reply'
}

message = {
  props: { reply_to: cfg[:reply_to], headers: {} },
  body: ARGV[-1],
  routing_key: 'ping'
}

OptionParser.new do |opts|
  opts.banner = "#{$PROGRAM_NAME} [options] payload"

  if !message[:props] || !message[:body]
    puts "Отсылатель сообщений amqp. Использование: #{opts}."
    exit
  end

  opts.on('-h', '--help', '') do
    puts "Отсылатель сообщений amqp. Использование: #{opts}."
    exit
  end
  opts.on('-a', '--host ADDRESS', "host (#{cfg[:mq][:host]})") { |v| cfg[:mq][:host] = v }
  opts.on('-p', '--port N', "port (#{cfg[:mq][:port]})") { |v| cfg[:mq][:port] = v }
  opts.on('-v', '--vhost NAME', "vhost (#{cfg[:mq][:vhost]})") { |v| cfg[:mq][:vhost] = v }
  opts.on('-u', '--username USERNAME', "(#{cfg[:mq][:user]})") { |v| cfg[:mq][:user] = v }
  opts.on('-w', '--password PASSWORD', "(#{cfg[:mq][:password]})") { |v| cfg[:mq][:password] = v }
  opts.on('-k', '--routing_key KEY', "routing key для посылки (#{cfg[:routing_key]})") do |v|
    message[:props][:routing_key] = v
  end
  opts.on('-s', '--[no-]ssl', "need ssl? (#{cfg[:mq][:ssl]})") { |ssl| cfg[:mq][:ssl] = ssl }
  opts.on('-x', '--exchange NAME', "exchange (#{cfg[:x][:name]})") { |v| cfg[:x][:name] = v }
  opts.on('-t', '--xtype TYPE', "exchange (#{cfg[:x][:opts][:type]})") { |v| cfg[:x][:opts][:type] = v }
  opts.on('-e', '--[no-]exchange-autodelete', "exchange auto delete flag (#{cfg[:x][:opts][:auto_delete]})") { |v| cfg[:x][:opts][:auto_delete] = v }
  opts.on('-d', '--[no-]exchange-durable', "exchange durable flag (#{cfg[:x][:opts][:durable]})") { |v| cfg[:x][:opts][:durable] = v }
  opts.on('-q', '--queue NAME', "queue (#{cfg[:q][:name]})") { |v| cfg[:q][:name] = v }
  opts.on('-l', '--[no-]queue-durable', "queue is durable? (#{cfg[:q][:opts][:durable]})") { |v| cfg[:q][:opts][:durable] = v }
  opts.on('-f', '--file FILENAME', "вывод в файл (#{cfg[:output].class})") do |v|
    if Pathname.new(v).dirname.exist?
      cfg[:output] = File.new(v, 'w')
    else
      raise "#{v} не существует!"
    end
  end
  opts.on('-m', '--meta KEY:VALUE', "добавить в meta ключ:значение. (#{message[:props].inspect})") do |me|
    k, v = me.split(':', 2)
    message[:props][k.to_sym] = v
  end
  opts.on('-r', '--hdr KEY:VALUE', "добавить в headers ключ:значение. (#{message[:props][:headers].inspect})") do |me|
    k, v = me.split(':', 2)
    message[:props][:headers][k.to_sym] = v
  end
end.parse!

(rabbit  = Bunny.new(cfg[:mq])).start
queue    = (channel = rabbit.create_channel).queue(cfg[:q][:name], cfg[:q][:opts])
exchange = channel.exchange(cfg[:x][:name], cfg[:x][:opts])
Log.info { "props: #{message[:props]};" }
exchange.publish(message[:body], message[:props])
