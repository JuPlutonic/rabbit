#!/usr/bin/env ruby
# frozen_string_literal: true

$progname = 'Sequel migration tool'
require 'bundler/setup'
require 'thor'
require 'uri'
require 'sequel'
require_relative '../app/app'
App.config!
Sequel.extension :migration

class MQtask < Thor
  package_name 'mq'

  desc 'init', 'Create clients, rabbitmq\'s hosts and add permissions to them.'
  def init
    # rabbitmqctl is used
    cmd = ''
    Cfg.mq.each do |_bname, data|
      cmd = <<~ECMD
        rabbitmqctl add_vhost #{data.conn.vhost}
        rabbitmqctl add_user #{data.conn.user} #{data.conn.password}
        rabbitmqctl set_permissions -p #{data.conn.vhost} #{data.conn.user} '.*' '.*' '.*'
      ECMD
      unless system("( #{cmd} ) 2>/dev/null >/dev/null")
        puts "CSomething happen during command execution.\n#{cmd}\n."
      end
    end
  end
end

MQtask.start
