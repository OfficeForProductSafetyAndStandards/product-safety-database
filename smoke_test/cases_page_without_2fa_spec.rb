require 'capybara/rspec'
require "webmock"

RSpec.configure do |config|
  config.before do
    @session = Capybara::Session.new :selenium_headless
  end

  config.after do |example|
    take_screenshot_after_failed_example(example)
  end
end

def take_screenshot_after_failed_example(example)
  return unless example.exception
  @session.save_page("tmp/capybara/screenshot.html")
end

# Run this spec locally with
# SMOKE_TEST_URL=http://localhost:3000 SMOKE_USER=user@example.com SMOKE_PASSWORD=testpassword bundle exec rspec smoke_test/cases_page_without_2fa_spec.rb

RSpec.feature "Search smoke test" do
  scenario "sign-in and visit notifications page" do

    WebMock.allow_net_connect!
    @session.visit(smoke_uri)
    expect(@session).to have_css("h1", text: "Product Safety Database")
  end
end

def smoke_uri(path = nil)
  uri = URI.parse ENV["SMOKE_TEST_URL"]
  if ENV["IS_REVIEW_APP"] == "true"
    uri.user = ENV["SMOKE_TEST_REVIEW_APP_BASIC_AUTH_USER"]
    uri.password = ENV["SMOKE_TEST_REVIEW_APP_BASIC_AUTH_PASSWORD"]
  end
  uri = URI.join(uri, path) if path
  uri.to_s
end
