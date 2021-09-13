require "rails_helper"

RSpec.feature "Search smoke test" do
  let(:session) { Capybara::Session.new :mechanize }

  if ENV["RUN_SMOKE"] == "true"
    scenario "sign-in and visit case page" do
      WebMock.allow_net_connect!
      session.visit(ENV["SMOKE_TEST_URL"])
      expect(session).to have_css("h1", text: "Product Safety Database")
      session.visit("#{ENV["SMOKE_TEST_URL"]}/sign-in")
      session.fill_in "Email address", with: ENV["SMOKE_USER"]
      session.fill_in "Password", with: ENV["SMOKE_PASSWORD"]
      session.click_button "Continue"

      expect(session).to have_current_path(/\/two-factor/)
      expect(session).to have_content("Check your phone")
      #
      attempts = 0
      loop do
        code = get_code.scan(/\d{5}/).first
        smoke_complete_secondary_authentication_with(code, session)
        attempts += 1
        break if session.has_content?("Open a new case")
        break if attempts > 3

        sleep attempts * 10
      end
      #
      session.click_link "Cases"
      expect(session).to have_css(".govuk-grid-row.psd-case-card:nth-child(1)")
      expect(session).to have_css(".govuk-grid-row.psd-case-card:nth-child(10)")
    end
  end
end

def smoke_complete_secondary_authentication_with(fake_code, session)
  session.fill_in "Enter security code", with: fake_code
  session.click_on "Continue"
end

def get_code
  uri = URI(ENV["SMOKE_RELAY_CODE_URL"])

  req = Net::HTTP::Get.new(uri)
  req.basic_auth ENV["SMOKE_RELAY_CODE_USER"], ENV["SMOKE_RELAY_CODE_PASS"]

  http = Net::HTTP.new(uri.hostname, uri.port)
  http.use_ssl = true
  res = http.request(req)
  res.body
end
