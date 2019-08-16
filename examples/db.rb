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

class Dbtask < Thor
  package_name 'db'
  desc 'g class_name', ' migration-file in db/migrations'
  def g(class_name)
    tstamp = Time.now.strftime '%Y%m%d%H%M%S'
    fname = ''
    App.init!
    if Dir["#{Cfg.root}/db/migrations/#{tstamp}_*.rb"].any?
      counter = 0
      while Dir["#{Cfg.root}/db/migrations/#{tstamp}#{format('%02d', counter)}_*.rb"].any?
        counter += 1
      end
      fname = "#{Cfg.root}/db/migrations/#{tstamp}_#{format('%02d', counter)}_#{class_name}.rb"
    else
      fname = "#{Cfg.root}/db/migrations/#{tstamp}_#{class_name}.rb"
    end
    Log.info { "Creating migration-file #{fname}" }
    File.open(fname, 'w') do |f|
      f.write <<~EFILE
        Sequel.migration do
          up do
            create_table :#{class_name} do
              primary_key :id, type: :Bignum
               column :created_at, DateTime, null: false, index: true, default: Sequel.lit("now()")
              column :updated_at, DateTime, null: false, index: true, default: Sequel.lit("now()")
            end
            run <<~EUP
              DO $$
              BEGIN
                --triggers
                IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = '#{class_name}_update_timestamp') THEN
                  CREATE TRIGGER #{class_name}_update_timestamp
                    BEFORE INSERT OR UPDATE ON #{class_name}
                    FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
                END IF;
              END $$;
            EUP
          end
          down { run 'DROP TABLE #{class_name} CASCADE' }
        end
      EFILE
    end
  end

  desc 'm', 'Migrate, you could add STEP=N'
  def m(point = nil)
    point = point[/(\d+)/, 1].to_i if point
    App.init!
    Log.warn { "DB is Migrating to #{point}" }
    if point
      Sequel::Migrator.run(Db, 'db/migrations', target: point)
    else
      Sequel::Migrator.run(Db, 'db/migrations')
    end
    v
  end

  desc 'r', 'Rollback all, or use STEP=N in command-line'
  def r(point = '0')
    point = point[/(\d+)/, 1].to_i if point
    App.init!
    Log.warn { "DB is rolling-back to #{point}" }
    if point
      Sequel::Migrator.run(Db, 'db/migrations', target: point)
    else
      Sequel::Migrator.run(Db, 'db/migrations')
    end
    v
  end

  desc 'v', 'Print current version in DB'
  def v
    App.init!
    version =
      if Db.tables.include?(:schema_migrations)
        (f = Db[:schema_migrations].all).any? ? f.last[:filename] : 'empty'
      else
        'empty'
      end
    puts "Last migration: #{version}"
  end

  desc 'create', 'Create DB'
  def create
    rootdb = superdb
    Log.warn { "User: #{Cfg.db.user} and DB: #{Cfg.db.database} creation." }
    begin
      rootdb["CREATE USER #{Cfg.db.user} WITH LOGIN PASSWORD '#{Cfg.db.password}'"].all
    rescue Exception => e
      Log.info { e.message }
    end
    begin
      rootdb["CREATE DATABASE #{Cfg.db.database} OWNER #{Cfg.db.user}"].all
    rescue Exception => e
      Log.info { e.message }
    end
  end

  desc 'scratch', 'DB deletion, reapply all migrations again'
  def scratch(db = nil)
    App.init!
    db = superdb
    Log.debug { 'Disconnecting from the DB' }
    Db.disconnect
    unless db.test_connection
      Log.warn { "Testing connection to DB is failed. #{superuser.inspect}" }
      exit 255
    end
    Log.warn { "DB deletion #{Cfg.db.database}" }
    begin
      db << "DROP DATABASE #{Cfg.db.database}"
    rescue Exception => e
      Log.error e.message
    end
    create
    m
  end

  no_commands do
    # Connecting as administrator
    # It is hardcoded with these settings: 'postgres' without password, scheme 'public'
    def superdb
      if !@rootdb || !@rootdb.test_connection
        superuser = Marshal.load(Marshal.dump(Cfg.db))
        superuser[:adapter]  = 'postgres'
        superuser[:user]     = 'postgres'
        superuser[:database] = 'postgres'
        superuser.delete :password
        Log.debug { "Trying to connect as administrator #{superuser.inspect}" }
        @rootdb = Sequel.connect(superuser)
      end
      @rootdb
    end
  end
end

Dbtask.start
