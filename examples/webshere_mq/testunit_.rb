# Test case for putting message in ACCOUNTS.CREATED
module Test::Unit::WMQTest
  # Reads and caches
  # WebSphere MQ
  # configuration
  #
  # Read the WMQ configuration for this environment.
  def wmq_config
    @wmq_config ||= YAML.safe_load(File.read("#{RAILS_ROOT}config/wmq.yml"))
    # =>
    [RAILS_ENV].symbolize_keys
  end

  # Retrieve last message from the named queue, assert that it exists
  # and yield it to the block to make more assertions.
  def wmq_check_message(q_name)
    WMQ::QueueManager.connect(wmq_config) do |qmgr|
      qmgr.open_queue(q_name: q_name,
                      mode: :input) do |queue|
        # Checks last
        # message
        # from queue
        message = WMQ::Message.new
        assert queue.get(message: message)
        yield message if block_given?
      end
    end
  end

  # Empty queues at the end of the test.
  #
  # Empties queue of
  # messages (used in
  # teardown)
  ######################################
  def wmq_empty_queues(*q_names)
    WMQ::QueueManager.connect(wmq_config) do |qmgr|
      q_names.each do |q_name|
        qmgr.open_queue(q_name: q_name,
                        mode: :input) do |queue|
          queue.each { |message| }
        end
      end
    end
  end
end

class AccountsControllerTest < Test::Unit::TestCase
  include Test::Unit::WMQTest
  def setup
    @q_name = 'ACCOUNTS.CREATED'
    @attributes = { 'first_name' => 'John', 'last_name' => 'Smith',
                    'company' => 'ACME', 'email' => 'john@acme.com' }
  end

  # Tests account creation
  def test_wmq_account_created
    # Places new
    # message in
    # queue
    post :create, account: @attributes

    # Checks message
    # existence and contents
    wmq_check_message @q_name do |message|
      from_xml = Hash.from_xml(message.data)
      app = @account.merge('application' => 'test.host')
      assert_equal app, from_xml['account']
    end
  end

  def teardown
    # Empties queue
    # before next text
    wmq_empty_queues @q_name
  end
end
