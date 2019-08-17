# frozen_string_literal: true

class AccountsController < ApplicationController
  QUEUE_NAME = 'ACCOUNTS.CREATED'

  # Creates new account
  def create
    @account = Account.new(params[:account])
    # Validates and stores
    # account in database
    if @account.save
      # Queues account
      # creation message
      wmq_account_created @account
      # Created, send user back to main page.
      redirect_to root_url
    else
      # Error, show the registration form with error message
      render action: 'new'
    end
  end

  private

  def wmq_account_created(account)
    # Collects attributes
    # we need
    attributes = account.attributes
                        .slice('first_name', 'last_name', 'company', 'email')
    # <=
    attributes.update(application: request.host)

    # Turns attributes
    # into XML document
    xml = attributes.to_xml(root: 'account')
    config = self.class.wmq_config

    # Establishes connection
    # to WebSphere MQ
    WMQ::QueueManager.connect(config) do |qmgr|
      # Creates and
      # queues message
      message = WMQ::Message.new
      message.data = xml
      qmgr.put q_name: QUEUE_NAME, message: message

      msg_id = message.descriptor[:msg_id]
      logger.info "WMQ.put: message #{msg_id} in #{QUEUE_NAME}"
    end
  end
end
