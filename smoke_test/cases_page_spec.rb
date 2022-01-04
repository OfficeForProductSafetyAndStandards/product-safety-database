require 'capybara/rspec'
require 'capybara/mechanize'
require "webmock"

# we need to use machanize in order to make remote requests
Capybara.register_driver :mechanize do |app|
  Capybara::Mechanize::Driver.new(proc {})
end

RSpec.configure do |config|
  config.before do
    @session = Capybara::Session.new :mechanize
  end

  config.after do |example|
    take_screenshot_after_failed_example(example)
  end
end

def take_screenshot_after_failed_example(example)
  return unless example.exception
  puts "Saving screenshot to screenshot.html"
  @session.save_page("tmp/capybara/screenshot.html")
end

RSpec.feature "Search smoke test" do
  scenario "sign-in and visit case page" do
    WebMock.allow_net_connect!
    @session.driver.browser.agent.add_auth(ENV["SMOKE_TEST_URL"], ENV["SMOKE_TEST_REVIEW_APP_BASIC_AUTH_USER"], ENV["SMOKE_TEST_REVIEW_APP_BASIC_AUTH_PASSWORD"]) if ENV["IS_REVIEW_APP"] == "true"
    @session.visit(ENV["SMOKE_TEST_URL"])
    expect(@session).to have_css("h1", text: "Product Safety Database")
    @session.visit("#{ENV["SMOKE_TEST_URL"]}/sign-in")
    @session.fill_in "Email address", with: ENV["SMOKE_USER"]
    @session.fill_in "Password", with: ENV["SMOKE_PASSWORD"]
    @session.click_button "Continue"

    expect(@session).to have_current_path(/\/two-factor/)
    expect(@session).to have_content("Check your phone")

    attempts = 0
    loop do
      code = get_code
      break unless code && @session.has_current_path?(/\/two-factor/) && attempts < 4

      smoke_complete_secondary_authentication_with(code, @session)
      attempts += 1

      sleep attempts * 10
    end

    @session.click_link "Cases"
    expect(@session).to have_css("tbody.govuk-table__body:nth-child(3)")
    expect(@session).to have_css("tbody.govuk-table__body:nth-child(13)")
  end
end

def smoke_complete_secondary_authentication_with(code, session)
  session.fill_in "Enter security code", with: code
  session.click_on "Continue"
end

def get_code
  uri = URI(ENV["SMOKE_RELAY_CODE_URL"])

  req = Net::HTTP::Get.new(uri)
  req.basic_auth ENV["SMOKE_RELAY_CODE_USER"], ENV["SMOKE_RELAY_CODE_PASS"]

  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = true
  res = http.request(req)
  res.body.scan(/\d{5}/).first
end
