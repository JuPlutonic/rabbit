# frozen_string_literal: true

# CLI: gem install stomp
# require 'rubygems'
require 'stomp'
require 'builder' # gem to build XML-files

class ErrorReporter
  # Pushes message
  # to queue
  def self.report!(error_object, queue = '/queue/errors')
    # Uses Stomp client
    # to queue message
    reporter = Stomp::Client.new
    reporter.send queue, generate_xml(error_object)
  end

  private

  def generate_xml(error_object)
    payload = ''
    # Generates
    # the payload
    builder = Builder::XmlMarkup.new(target: payload)
    builder.instruct!

    # Writes
    # document
    # element
    builder.error do |error|
      error.type error_object.class.to_s
      error.message error_object.message
      error.backtrace error_object.backtrace.join('\n')
    end
  end
end

#
#
# OR APP
#   maybe need some additional error handling libraries
#
#

# Raises and reports
# e ( error_object )
# via ErrorReporter
def error_method
  FakeConstant.non_existent_method!
rescue StandardError => e
  ErrorReporter.report! e
end
