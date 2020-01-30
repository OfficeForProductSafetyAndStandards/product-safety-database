require "test_helper"
require "system_test_helper"
require_relative "test_helpers/devise"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include SystemTestHelper
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include TestHelpers::Devise

  Capybara.default_max_wait_time = 3

  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: { args: %w[headless disable-gpu no-sandbox disable-dev-shm-usage] }

  # Import all relevant models into Elasticsearch
  def self.import_into_elasticsearch
    unless @models_imported
      ActiveRecord::Base.descendants.each do |model|
        if model.respond_to?(:__elasticsearch__) && !model.superclass.respond_to?(:__elasticsearch__)
          model.import force: true, refresh: :wait_for
        end
      end
      @models_imported = true
    end
  end

  setup do
    self.class.import_into_elasticsearch
  end

  teardown do
    Organisation.delete_all
    Team.delete_all
    User.delete_all
    User.current = nil
  end
end
