#!/usr/bin/env ruby
# encoding: utf-8

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

  desc "init", "Посоздавать клиентов, хосты на кролике и раздать права."
  def init
  # для управления пользуемся утилитой rabbitmqctl
    cmd = ''
    Cfg.mq.each do |bname, data|
      cmd = <<~ECMD
        rabbitmqctl add_vhost #{ data.conn.vhost }
        rabbitmqctl add_user #{ data.conn.user } #{ data.conn.password }
        rabbitmqctl set_permissions -p #{ data.conn.vhost } #{ data.conn.user } '.*' '.*' '.*'
      ECMD
      unless system("( #{ cmd } ) 2>/dev/null >/dev/null")
        puts "Ошибка выполнения команды.\n#{ cmd }\n."
      end
    end
  end

end

MQtask.start
