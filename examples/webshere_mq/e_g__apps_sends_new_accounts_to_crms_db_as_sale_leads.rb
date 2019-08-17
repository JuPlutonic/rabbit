# frozen_string_literal: true

$progname = 'Rails + WebSphereMQ_Apps sends new accounts (ACCOUNTS.CREATED) to CRM\'s DB as sale leads'
# DB for saving sale leads can be from such CRM systems as SaleseForce's SaaS
#
# ==Gemfile:==
# gem 'activersalesforce'
#
# (require 'activersalesforce')==
#
# ==config/database.yml:==
# development:
# adapter: activesalesforce
# url: https://test.salesforce.com
# username: <your username>
# password: <your password>

# require 'rubygems'
require 'wmq'
require 'active_record'

WMQ_ENV = ENV['WMQ_ENV']

# Set up logging and configure the database connection.
#
# Sets up ActiveRecord
# logging and database
# connection
#######################################################
LOGGER = Logger.new(STDOUT)
ActiveRecord::Base.logger = LOGGER
database = YAML.safe_load(File.read('config/database.yml'))
# =>
[WMQ_ENV].symbolize_keys
ActiveRecord::Base.establish_connection database

# Define the Lead class.
#
# Uses ActiveRecord to
# access leads table
########################
class Lead < ActiveRecord::Base; end

# Read the WMQ configuration and open a connection.
wmq_config = YAML.safe_load(File.read('config/wmq.yml'))
# Connects to queue manager
# per configuration
# =>
[WMQ_ENV].symbolize_keys
WMQ::QueueManager.connect(wmq_config) do |q_mgr|
  q_mgr.open_queue(q_name: 'ACCOUNTS.CREATED', mode: :input) do |queue|
    # Processes each
    # message with
    # synchpoint
    queue.each(sync: true) do |message|
      begin
        # Parse the document, transform from XML to attributes.
        xml = REXML::Document.new(message.data)
        transform = { first_name: 'first-name',
                      last_name: 'last-name',
                      company: 'company',
                      email: 'email',
                      lead_source: 'application' }
        # Transforms XML
        # document into a Hash
        attributes = transform
                     .inject({}) do |hash, (target, source)|
          nodes = xml.get_text("/account/#{source}")
          hash.update(target => nodes.to_s)
        end
        # Create a new lead record in database.
        lead = Lead.create!(attributes)
        LOGGER.debug "Created new lead #{lead.id}"
      # Logs errors but
      # lets WMQ deal
      # with message
      rescue Exception => e
        LOGGER.error ex.message
        LOGGER.error ex.backtrace
        # Raise exception, WMQ keeps message in queue.
        raise
      end
    end
  end
end
