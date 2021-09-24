require 'capybara/rspec'
require 'capybara/mechanize'
require "webmock"

# we need to use machanize in order to make remote requests
Capybara.register_driver :mechanize do |app|
  Capybara::Mechanize::Driver.new(proc {})
end

RSpec.feature "Search smoke test" do
  let(:session) { Capybara::Session.new :mechanize }

  scenario "sign-in and visit case page" do
    WebMock.allow_net_connect!
    session.driver.browser.agent.add_auth("https://psd-pr-1599.london.cloudapps.digital/", "psd", "reviewAPP")
    session.visit("https://psd-pr-1599.london.cloudapps.digital/")
    expect(session).to have_css("h1", text: "Product Safety Database")
    session.visit("#{"https://staging.product-safety-database.service.gov.uk/"}/sign-in")
    session.fill_in "Email address", with: "smoketest@example.com"
    session.fill_in "Password", with: "JHxztd534MeFw4Q"
    session.click_button "Continue"

    expect(session).to have_current_path(/\/two-factor/)
    expect(session).to have_content("Check your phone")

    attempts = 0
    loop do
      code = get_code
      break unless code

      smoke_complete_secondary_authentication_with(code, session)
      attempts += 1
      break if session.has_content?("Open a new case")
      break if attempts > 3

      sleep attempts * 10
    end

    session.click_link "Cases"
  begin
    session.find(".govuk-grid-row.psd-case-card:nth-child(1)")
    session.find(".govuk-grid-row.psd-case-card:nth-child(11)")
  rescue
    session.save_page("tmp/capybara/screenshot")
  end
    expect(session).to have_css(".govuk-grid-row.psd-case-card:nth-child(1)")
    expect(session).to have_css(".govuk-grid-row.psd-case-card:nth-child(1000)")
  end
end

def smoke_complete_secondary_authentication_with(code, session)
  session.fill_in "Enter security code", with: code
  session.click_on "Continue"
end

def get_code
  uri = URI("https://beis-opss-text-relay.london.cloudapps.digital/text")

  req = Net::HTTP::Get.new(uri)
  req.basic_auth "sendatext", "itsforsmoketest"

  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = true
  res = http.request(req)
  res.body.scan(/\d{5}/).first
end
