require "test_helper"
require "system_test_helper"

ENV["HTTP_HOST"] = "localhost"
ENV["HTTP_PORT"] = "3001"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include SystemTestHelper
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  Capybara.server_host = ENV["HTTP_HOST"]
  Capybara.server_port = ENV["HTTP_PORT"]
  Capybara.app_host = "http://#{ENV['HTTP_HOST']}:#{ENV['HTTP_PORT']}"
  Capybara.default_host = "http://#{ENV['HTTP_HOST']}:#{ENV['HTTP_PORT']}"
  Capybara.default_max_wait_time = 3
  Rails.application.routes.default_url_options = { host: ENV["HTTP_HOST"], port: ENV["HTTP_PORT"] }

  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: { args: %w[headless disable-gpu no-sandbox disable-dev-shm-usage] }

  teardown do
    Organisation.delete_all
    Team.delete_all
    User.delete_all
  end
end
