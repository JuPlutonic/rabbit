# frozen_string_literal: true

require 'wmq'

# Provides WMQ
# configuration to
# all controllers
class ApplicationController < ActionController::Base

  def self.wmq_config
    # Caches configuration
    # in memory
    unless @wmq_config
      wmq_config_file = File.expand_path('config/wmq.yml', RAILS_ROOT)
      @wmq_config = YAML
                      .safe_load(File.read(wmq_config_file))[RAILS_ENV]
                      # <=
                      # Loads configuration for
                      # current environment
                      .symbolize_keys
    end
    @wmq_config
  end
end
