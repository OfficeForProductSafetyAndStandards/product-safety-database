require "rails_helper"

RSpec.feature "Reporting dashboard", :with_stubbed_mailer, :with_stubbed_notify, type: :feature do
  let(:user) { create(:user, roles: %w[opss]) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user, name: user1.name) }

  before do
    configure_requests_for_report_domain

    user1
    user2
    user3

    sign_in user
  end

  after do
    reset_domain_request_mocking
  end

  scenario "Searching for an account that exists" do
    expect(page).to have_h1("Dashboard")
  end
end
